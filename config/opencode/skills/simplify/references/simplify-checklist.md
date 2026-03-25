# Simplify Checklist

Run this checklist quickly before applying changes.

## 1) Scope and intent

- Is the simplify request scoped to a concrete diff or path?
- Are we preserving externally observable behavior?
- Is this cleanup, not a migration disguised as cleanup?

## 2) Boundary safety

- Does module, package, or service ownership remain the same?
- Are compatibility contracts still preserved?
- Are invariant-enforcing helpers still used where they matter?
- Are side effects still happening through the correct path?

## 3) Classification

- `safe-to-apply`: low risk, high confidence, no boundary shift
- `proposal-only`: useful but requires a behavior or ownership decision
- `do-not-apply`: breaks invariants or compatibility

## 4) Verification

- Run the smallest relevant test, typecheck, or lint command
- Add focused checks when async, UI, or state behavior changed
- If no automated check exists, include explicit manual verification steps

## 5) Output quality

- Report exactly what was simplified and why it is safe
- List what was skipped and why
- Call out any residual risks or assumptions
