# Autonomous LOOP Agent Rules

These rules apply to every Codex invocation in this repository, including invocations started by `scripts/run-autonomous-loop.ps1`.

## Safety boundary

- Work only on a branch whose name starts with `autonomy/` when operating through the autonomous runner.
- Never switch to, merge into, commit on, or push `master`.
- Never push any branch, create or merge a pull request, create a tag or release, or delete a local or remote branch.
- Never use `git branch -D`, force push, rebase, amend, `git reset --hard`, `git clean -fd`, `--yolo`, or `--dangerously-bypass-approvals-and-sandbox`.
- Do not install programs, add dependencies, access secrets, or broaden filesystem/network permissions.
- Respect `workspace-write` and `approval_policy="never"`; do not request interactive approval.
- Run autonomous quality iterations only with Node.js `v22.17.0`; stop with a report on any other version.
- Stop and report when the work requires authority outside these rules.

## Iteration discipline

- Read `AUTONOMOUS_GOAL.md`, the current iteration analysis, and the relevant code before changing files.
- Select or implement at most one small, reviewable quality improvement per iteration.
- Preserve all existing CLI behavior unless the goal explicitly authorizes a behavior change.
- Add or strengthen tests before implementation when practical. Never delete, skip, weaken, or rewrite tests merely to make them pass.
- Keep changes directly tied to maintainability, reliability, tests, diagnostics, or documentation accuracy.
- Do not edit `AGENTS.md`, `AUTONOMOUS_GOAL.md`, `scripts/run-autonomous-loop.ps1`, `.gitignore`, or runtime artifacts while executing an autonomous quality iteration.
- Do not commit. The runner owns commits after verification and review.
- Do not write outside the repository except for tool-managed temporary files.

## Verification and review

- Treat `npm run verify` as the required quality gate.
- Explain any expected failing test before implementation; do not hide unexpected failures.
- Keep the working tree understandable and free of unrelated formatting or generated files.
- An independent `codex review` decides whether correction is required.
- If the root cause is unclear, the required change is broad, or verification remains red, stop rather than guessing.

## Output contract

- State the single improvement attempted, files touched, tests run, and remaining risk.
- Analysis stages must not edit repository files.
- Review stages must end with exactly one marker: `REVIEW_PASS` or `REVIEW_CHANGES_REQUESTED`.
