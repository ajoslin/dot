import fs from "node:fs";
import path from "node:path";

import { tool } from "@opencode-ai/plugin";

let envCache: Record<string, string> | null = null;

function loadEnv(): Record<string, string> {
	if (envCache) return envCache;
	envCache = {};

	const toolDir = path.resolve(__dirname, "../..");
	let currentDir = toolDir;
	for (let i = 0; i <= 3; i++) {
		const envPath = path.join(currentDir, ".env.opencode");
		try {
			if (fs.statSync(envPath).isFile()) {
				const content = fs.readFileSync(envPath, "utf8");
				for (const raw of content.split("\n")) {
					const trimmed = raw.trim();
					if (!trimmed || trimmed.startsWith("#")) continue;
					const eq = trimmed.indexOf("=");
					if (eq <= 0) continue;
					const key = trimmed.slice(0, eq).trim();
					let value = trimmed.slice(eq + 1).trim();
					if (
						(value.startsWith('"') && value.endsWith('"')) ||
						(value.startsWith("'") && value.endsWith("'"))
					) {
						value = value.slice(1, -1);
					}
					envCache[key] = value;
				}
				return envCache;
			}
		} catch {
			// not found, walk up
		}
		const parent = path.dirname(currentDir);
		if (parent === currentDir) break;
		currentDir = parent;
	}

	return envCache;
}

function envVar(name: string): string | undefined {
	return process.env[name] || loadEnv()[name] || undefined;
}

function getLinearConfig() {
	const apiKey = envVar("LINEAR_API_KEY");
	if (!apiKey) {
		throw new Error(
			"Linear is not configured for the production environment (missing LINEAR_API_KEY).",
		);
	}

	return {
		apiKey,
		url: "https://api.linear.app/graphql",
	};
}

async function linearGraphql(
	query: string,
	variables?: Record<string, unknown>,
): Promise<unknown> {
	const { apiKey, url } = getLinearConfig();
	const res = await fetch(url, {
		method: "POST",
		headers: {
			Authorization: apiKey,
			"Content-Type": "application/json",
		},
		body: JSON.stringify({ query, variables }),
	});

	const text = await res.text().catch(() => "");
	let data: { data?: unknown; errors?: unknown } | undefined;

	if (text) {
		try {
			data = JSON.parse(text) as { data?: unknown; errors?: unknown };
		} catch {
			// fall through to error handling below
		}
	}

	if (!res.ok) {
		throw new Error(`Linear ${res.status} ${res.statusText}: ${text}`);
	}

	if (data?.errors) {
		throw new Error(`Linear GraphQL error: ${JSON.stringify(data.errors)}`);
	}

	return data?.data ?? null;
}

const DESCRIPTION = `Linear GraphQL tool — run raw GraphQL queries against Linear using \`LINEAR_API_KEY\`.

This tool is production-only. It sends requests to \`https://api.linear.app/graphql\`.
Use standard GraphQL queries, mutations, and introspection via \`__schema\` and \`__type\`.

Arguments:
- \`query\`: GraphQL query or mutation string
- \`variables\`: optional JSON object of GraphQL variables

Example:
  query: "query { viewer { id name email } }"

Example with variables:
  query: "query Issue($id: String!) { issue(id: $id) { id title } }"
  variables: { "id": "APP-123" }`;

export default tool({
	description: DESCRIPTION,
	args: {
		query: tool.schema.string(),
		variables: tool.schema.record(tool.schema.string(), tool.schema.unknown()).optional(),
	},
	async execute(args: { query: string; variables?: Record<string, unknown> }) {
		const result = await linearGraphql(args.query, args.variables);

		if (result === undefined || result === null) return "null";
		if (typeof result === "string") return result;
		return JSON.stringify(result, null, 2);
	},
});
