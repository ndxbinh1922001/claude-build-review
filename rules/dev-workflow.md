Feature and bug-fix work uses two tools: the superpowers skills for intake and test-first discipline, and the build-review workflow (`~/.claude/workflows/build-review.md`) for build, independent review and auto fix. These rules take precedence over the superpowers skills, `using-superpowers` included.

Do not use for: questions and explanations, code review of existing changes, or edits to Claude configuration files.

## Routing

| Situation | Use |
|---|---|
| The request leaves a real choice open (design ambiguity, or a standard / large change with an open question about behaviour) | `superpowers:brainstorming` |
| Clear request, trivial or small change | no brainstorming |
| Bug, failing test, unexpected behaviour | `superpowers:systematic-debugging`; its reproduction becomes the first failing test |
| Writing or changing code | `superpowers:test-driven-development`: a failing test before production code |
| Before saying done, fixed or passing | `superpowers:verification-before-completion` |
| Weighing review findings | `superpowers:receiving-code-review`: verify each finding before acting on it |

## Execution

1. The user asks for build-review: run `~/.claude/workflows/build-review.md`. Its PHASE 0 runs brainstorming or debugging; do not run them a second time before it.
2. Brainstorming outside build-review: once the user approves the design, ask once which way to build it, before writing a plan:
   - build-review: independent Codex / Antigravity review and auto fix, slower; br-planner writes the plan.
   - this session: `superpowers:writing-plans` writes the plan, the user approves it, then implement here with test-driven-development and verification-before-completion.
3. A clear request without build-review: implement in this session, test first. Do not ask about build-review.

Never use `superpowers:subagent-driven-development`, `superpowers:executing-plans`, `superpowers:requesting-code-review` or `superpowers:finishing-a-development-branch`: build-review owns execution, review and finishing, and outside it the session implements directly. Use `superpowers:using-git-worktrees` only when Orca does not manage the worktree.

## Overrides of superpowers defaults

- Never commit, push or merge. Leave every "Commit" step out of designs and plans; the user commits.
- Save the design to `.review/round-1/design.md` and a plan to `.review/round-1/plan.md`, not under `docs/superpowers/`, unless the user names another place. If `.review/` is not git-ignored, add it to `.git/info/exclude`.
- The design header quotes the user's request verbatim and ends with `APPROVED: <YYYY-MM-DD>` once the user approves it. build-review reuses only a design that carries both for the current request.
- Skip brainstorming when the user says to just do it ("làm luôn", "khỏi hỏi", "just do it") or the request already fixes every choice.
- The writing-plans handoff never offers "Subagent-driven" or "Native"; it asks only for plan approval.
