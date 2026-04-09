type ToolInput = {
	tool: string;
};

type ToolOutput = {
	args?: {
		command?: string;
	};
};

type CommandGuardHooks = {
	"tool.execute.before": (
		input: ToolInput,
		output: ToolOutput,
	) => Promise<void>;
};

const COMMAND_GUARD_PATTERNS = {
	BYPASS_RE: /(?:^|\s)COMMAND_GUARD_BYPASS=1(?:\s|$)/,
	QUICK_REJECT_RE: /\b(?:git|rm|gh)\b/,
	SPLIT_COMMAND_RE: /(?:&&|\|\||;|\n)/,
	DATA_CONTEXT_RE: /^(?:echo\b|printf\b|grep\b|rg\b|awk\b|sed\b|cat\b|#)/,
	SAFE_GIT_CHECKOUT_BRANCH_RE: /^git\s+checkout\s+(?:-b\b|--orphan\b)/,
	SAFE_GIT_RESTORE_STAGED_RE:
		/^git\s+restore\b(?=.*(?:^|\s)(?:--staged|-S)(?:\s|$))(?!.*(?:^|\s)(?:-W|--worktree)(?:\s|$))/,
	SAFE_GIT_CLEAN_DRY_RUN_RE:
		/^git\s+clean\b(?=.*(?:^|\s)(?:-n|--dry-run)(?:\s|$))/,
	SAFE_GIT_PUSH_FORCE_WITH_LEASE_RE:
		/^git\s+push\b(?=.*(?:^|\s)--force-with-lease(?:\s|$))/,
	SAFE_GIT_BRANCH_DELETE_RE: /^git\s+branch\s+-d\b/,
	SAFE_RM_TARGET_RE:
		/^(?:\/tmp(?:\/|$)|\/var\/tmp(?:\/|$)|\$TMPDIR(?:\/|$)|\$\{TMPDIR\}(?:\/|$)|(?:\.\/)?node_modules(?:\/|$)|(?:\.\/)?\.cache(?:\/|$)|(?:\.\/)?dist(?:\/|$)|(?:\.\/)?build(?:\/|$)|(?:\.\/)?__pycache__(?:\/|$)|(?:\.\/)?\.next(?:\/|$)|(?:\.\/)?\.turbo(?:\/|$)|(?:\.\/)?coverage(?:\/|$))/,
	DESTRUCTIVE_GIT_RESET_HARD_RE:
		/^git\s+reset\b(?=.*(?:^|\s)--hard(?:\s|$))/,
	DESTRUCTIVE_GIT_RESET_MERGE_RE:
		/^git\s+reset\b(?=.*(?:^|\s)--merge(?:\s|$))/,
	DESTRUCTIVE_GIT_CHECKOUT_DISCARD_RE: /^git\s+checkout\s+--(?:\s|$)/,
	DESTRUCTIVE_GIT_RESTORE_RE: /^git\s+restore\b/,
	DESTRUCTIVE_GIT_CLEAN_FORCE_RE: /^git\s+clean\b/,
	DESTRUCTIVE_GIT_PUSH_FORCE_RE: /^git\s+push\b/,
	DESTRUCTIVE_GIT_BRANCH_FORCE_DELETE_RE: /^git\s+branch\s+-D\b/,
	DESTRUCTIVE_GIT_STASH_DROP_RE: /^git\s+stash\s+drop\b/,
	DESTRUCTIVE_GIT_STASH_CLEAR_RE: /^git\s+stash\s+clear\b/,
	DESTRUCTIVE_RM_RE: /^rm\b/,
	DESTRUCTIVE_GH_REPO_DELETE_RE: /^gh\s+repo\s+delete\b/,
	DESTRUCTIVE_GH_GIST_DELETE_RE: /^gh\s+gist\s+delete\b/,
	DESTRUCTIVE_GH_RELEASE_DELETE_RE: /^gh\s+release\s+delete\b/,
	DESTRUCTIVE_GH_SSH_KEY_DELETE_RE: /^gh\s+ssh-key\s+delete\b/,
	SHORT_FLAG_CLUSTER_RE: /^-[^-]+$/,
} as const;

const {
	BYPASS_RE,
	QUICK_REJECT_RE,
	SPLIT_COMMAND_RE,
	DATA_CONTEXT_RE,
	SAFE_GIT_CHECKOUT_BRANCH_RE,
	SAFE_GIT_RESTORE_STAGED_RE,
	SAFE_GIT_CLEAN_DRY_RUN_RE,
	SAFE_GIT_PUSH_FORCE_WITH_LEASE_RE,
	SAFE_GIT_BRANCH_DELETE_RE,
	SAFE_RM_TARGET_RE,
	DESTRUCTIVE_GIT_RESET_HARD_RE,
	DESTRUCTIVE_GIT_RESET_MERGE_RE,
	DESTRUCTIVE_GIT_CHECKOUT_DISCARD_RE,
	DESTRUCTIVE_GIT_RESTORE_RE,
	DESTRUCTIVE_GIT_CLEAN_FORCE_RE,
	DESTRUCTIVE_GIT_PUSH_FORCE_RE,
	DESTRUCTIVE_GIT_BRANCH_FORCE_DELETE_RE,
	DESTRUCTIVE_GIT_STASH_DROP_RE,
	DESTRUCTIVE_GIT_STASH_CLEAR_RE,
	DESTRUCTIVE_RM_RE,
	DESTRUCTIVE_GH_REPO_DELETE_RE,
	DESTRUCTIVE_GH_GIST_DELETE_RE,
	DESTRUCTIVE_GH_RELEASE_DELETE_RE,
	DESTRUCTIVE_GH_SSH_KEY_DELETE_RE,
	SHORT_FLAG_CLUSTER_RE,
} = COMMAND_GUARD_PATTERNS;

const normalizePart = (part: string): string => {
	return part
		.trim()
		.replace(/^sudo\s+/, "")
		.replace(/^([A-Za-z_][A-Za-z0-9_]*=(?:"[^"]*"|'[^']*'|\S+)\s+)*/, "")
		.replace(/^\/?(?:[^\s/]+\/)+(git|rm|gh)(?=\s|$)/, "$1");
};

const splitCommands = (command: string): string[] => {
	return command
		.split(SPLIT_COMMAND_RE)
		.map((part: string) => normalizePart(part))
		.filter(Boolean);
};

const getTokens = (part: string): string[] => {
	return part.match(/"(?:\\.|[^"])*"|'(?:\\.|[^'])*'|\S+/g) ?? [];
};

const unquote = (token: string): string => {
	if (
		(token.startsWith('"') && token.endsWith('"')) ||
		(token.startsWith("'") && token.endsWith("'"))
	) {
		return token.slice(1, -1);
	}

	return token;
};

const hasShortFlag = (token: string, flag: string): boolean => {
	return SHORT_FLAG_CLUSTER_RE.test(token) && token.includes(flag);
};

const hasRecursiveForceFlags = (tokens: string[]): boolean => {
	let hasRecursive = false;
	let hasForce = false;

	for (const token of tokens) {
		if (!token.startsWith("-")) {
			continue;
		}

		if (token === "--") {
			break;
		}

		if (token === "--recursive") {
			hasRecursive = true;
		}

		if (token === "--force") {
			hasForce = true;
		}

		if (hasShortFlag(token, "r")) {
			hasRecursive = true;
		}

		if (hasShortFlag(token, "f")) {
			hasForce = true;
		}
	}

	return hasRecursive && hasForce;
};

const hasForceFlag = (tokens: string[]): boolean => {
	return tokens.some((token: string): boolean => {
		if (token === "--force") {
			return true;
		}

		return hasShortFlag(token, "f");
	});
};

const getCommandTargets = (tokens: string[]): string[] => {
	const targets: string[] = [];
	let seenDoubleDash = false;

	for (let index = 1; index < tokens.length; index += 1) {
		const token = tokens[index];

		if (token === "--") {
			seenDoubleDash = true;
			continue;
		}

		if (!seenDoubleDash && token.startsWith("-")) {
			continue;
		}

		targets.push(unquote(token));
	}

	return targets;
};

const isSafeRmPart = (part: string): boolean => {
	const tokens = getTokens(part);
	if (tokens.length === 0 || tokens[0] !== "rm") {
		return false;
	}

	if (!hasRecursiveForceFlags(tokens.slice(1))) {
		return false;
	}

	const targets = getCommandTargets(tokens);
	if (targets.length === 0) {
		return false;
	}

	return targets.every((target: string): boolean => SAFE_RM_TARGET_RE.test(target));
};

const block = (reason: string, tip: string): never => {
	throw new Error(
		`BLOCKED: ${reason}. ${tip}. To proceed, ask the user for permission. If approved, re-run prefixed with COMMAND_GUARD_BYPASS=1`,
	);
};

export const CommandGuardPlugin: () => Promise<CommandGuardHooks> = async () => {
	return {
		"tool.execute.before": async (
			input: ToolInput,
			output: ToolOutput,
		): Promise<void> => {
			if (input.tool !== "bash") {
				return;
			}

			const command = output.args?.command;
			if (typeof command !== "string") {
				return;
			}

			if (BYPASS_RE.test(command)) {
				return;
			}

			if (!QUICK_REJECT_RE.test(command)) {
				return;
			}

			const parts = splitCommands(command);

			for (const part of parts) {
				if (DATA_CONTEXT_RE.test(part)) {
					continue;
				}

				if (
					SAFE_GIT_CHECKOUT_BRANCH_RE.test(part) ||
					SAFE_GIT_RESTORE_STAGED_RE.test(part) ||
					SAFE_GIT_CLEAN_DRY_RUN_RE.test(part) ||
					SAFE_GIT_PUSH_FORCE_WITH_LEASE_RE.test(part) ||
					SAFE_GIT_BRANCH_DELETE_RE.test(part) ||
					isSafeRmPart(part)
				) {
					continue;
				}

				if (DESTRUCTIVE_GIT_RESET_HARD_RE.test(part)) {
					block(
						"git reset --hard destroys uncommitted changes",
						"Use 'git stash' first to save changes",
					);
				}

				if (DESTRUCTIVE_GIT_RESET_MERGE_RE.test(part)) {
					block(
						"git reset --merge destroys uncommitted changes",
						"Use 'git stash' first",
					);
				}

				if (DESTRUCTIVE_GIT_CHECKOUT_DISCARD_RE.test(part)) {
					block(
						"git checkout -- discards file modifications",
						"Use 'git stash' first to save changes",
					);
				}

				if (
					DESTRUCTIVE_GIT_RESTORE_RE.test(part) &&
					!SAFE_GIT_RESTORE_STAGED_RE.test(part)
				) {
					block(
						"git restore discards uncommitted changes",
						"Use 'git restore --staged' to unstage only",
					);
				}

				if (
					DESTRUCTIVE_GIT_CLEAN_FORCE_RE.test(part) &&
					hasForceFlag(getTokens(part).slice(2))
				) {
					block(
						"git clean -f permanently deletes untracked files",
						"Use 'git clean -n' first to preview",
					);
				}

				if (
					DESTRUCTIVE_GIT_PUSH_FORCE_RE.test(part) &&
					!SAFE_GIT_PUSH_FORCE_WITH_LEASE_RE.test(part) &&
					hasForceFlag(getTokens(part).slice(2))
				) {
					block(
						"git push --force overwrites remote history",
						"Use '--force-with-lease' instead",
					);
				}

				if (DESTRUCTIVE_GIT_BRANCH_FORCE_DELETE_RE.test(part)) {
					block(
						"git branch -D force-deletes without merge check",
						"Use 'git branch -d' (lowercase) for safe delete",
					);
				}

				if (DESTRUCTIVE_GIT_STASH_DROP_RE.test(part)) {
					block(
						"git stash drop permanently deletes a stash",
						"Verify the stash index before dropping",
					);
				}

				if (DESTRUCTIVE_GIT_STASH_CLEAR_RE.test(part)) {
					block(
						"git stash clear permanently deletes all stashes",
						"Use 'git stash list' first",
					);
				}

				if (
					DESTRUCTIVE_RM_RE.test(part) &&
					hasRecursiveForceFlags(getTokens(part).slice(1))
				) {
					block(
						"rm with recursive force permanently deletes files",
						"Verify the path carefully before running manually",
					);
				}

				if (DESTRUCTIVE_GH_REPO_DELETE_RE.test(part)) {
					block(
						"gh repo delete permanently deletes a GitHub repository",
						"This action is irreversible",
					);
				}

				if (DESTRUCTIVE_GH_GIST_DELETE_RE.test(part)) {
					block(
						"gh gist delete permanently deletes a gist",
						"This action is irreversible",
					);
				}

				if (DESTRUCTIVE_GH_RELEASE_DELETE_RE.test(part)) {
					block(
						"gh release delete removes a GitHub release",
						"Verify the release tag first",
					);
				}

				if (DESTRUCTIVE_GH_SSH_KEY_DELETE_RE.test(part)) {
					block(
						"gh ssh-key delete removes an SSH key from GitHub",
						"Verify the key ID first",
					);
				}
			}
		},
	};
};
