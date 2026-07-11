# Autonomous Quality Goal

## Mission

Improve the long-term maintainability and reliability of the CSV amount CLI through a sequence of small, independently verified changes. The runner may perform at most one coherent quality improvement in each iteration and must preserve the public CLI contract.

## Priority order

1. Fix a reproducible correctness or reliability defect covered by a focused regression test.
2. Strengthen missing edge-case tests without weakening existing expectations.
3. Reduce clear duplication or complexity when behavior can be proven unchanged.
4. Improve diagnostics, comments, or operational documentation when they are inaccurate or incomplete.
5. Stop for no progress when no safe, valuable, small improvement is available.

## Allowed scope

- `app.js`, `test.js`, `verify.js`
- `fixtures/` when a focused regression case requires it
- `README.md` and `HANDOFF.md` when implementation or verification facts need correction
- `package.json` only for an existing-script quality improvement that adds no dependency

## Excluded scope

- New user-facing output modes or features
- Dependency additions, package installation, broad source reorganization, or build-system replacement
- GitHub workflow, branch, remote, release, deployment, credential, or secret changes
- Changes to autonomous runner control files or LOOP history files
- Any master merge, push, rebase, amend, force operation, or branch deletion

## Required quality gates

- Existing tests remain at least as strict as before.
- `npm run verify` passes after implementation and after any review correction.
- The independent review returns `REVIEW_PASS` before commit.
- `git diff --check` passes and the diff contains only explained files.
- A successful iteration ends in one normal local commit on the autonomy branch.

## Stop instead of guessing

Stop the run when a change needs a product decision, changes public behavior, requires external access or installation, has an unclear root cause, produces repeated verification failures, or cannot demonstrate measurable progress within the configured limits.
