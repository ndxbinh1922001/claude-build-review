# RISK-BASED BUILD + INDEPENDENT REVIEW + AUTO FIX WORKFLOW

Claude Code (this session) is the COORDINATOR only.

Specialised Claude subagents (br-*) plan, build, write tests, validate,
review and verify. They are defined in ~/.claude/agents/br-*.md and
launched with the Agent tool.

OpenCodeReview (OCR) is the specialized structured code-review stage.
OCR prepares the review scope; the br-review-* specialists do the
reasoning.

CODEX and ANTIGRAVITY / AGY are independent peer REVIEWERS and TESTERS.

The br-* agents use the ECC plugin (ecc@ecc) as reference knowledge
only: ECC skills and ECC agent checklists. ECC does not drive this
workflow; this file and the br-* agent contracts win on any conflict.

The superpowers plugin supplies intake and discipline: brainstorming
and systematic-debugging (PHASE 0), the writing-plans task format
(PHASE 1), test-first order (PHASE 2) and
verification-before-completion (FINAL REPORT). Its execution skills
(subagent-driven-development, executing-plans, requesting-code-review,
finishing-a-development-branch) are not used: this workflow executes,
reviews and finishes. This file wins on any conflict. Nothing commits.

Use Orca /orchestration when independent Orca reviewers are selected.
Select reviewers from the risk of the change, not from a fixed roster.
The coordinator records why each reviewer was selected or omitted.


======================================================================
ARCHITECTURE
======================================================================

                         USER FEATURE
                              |
                              v
                   CLAUDE CODE COORDINATOR
                  Change size classification
                              |
                              v
                 PHASE 0 intake (superpowers)
       bug: systematic-debugging | unclear: brainstorming
                              |
                              v
                          br-planner
                 (standard / large only)
                              |
                              v
           br-test-writer (RED)  ->  br-builder (GREEN)
                              |
                              v
                         br-validator
               (FAIL -> br-builder -> br-validator)
                              |
                              v
                     ocr delegate preview
                Review scope + rule resolution
                              |
                              v
               selected reviewers (ONE fan-out)
                              |
        +----------+----------+----------+----------+
        |          |          |          |          |
        v          v          v          v          v
      CODEX       AGY    br-review-go  br-review-  br-review-
    Reviewer   if high risk             reliability security / data
      (Orca)     (Orca)  \_________ OCR specialists _________/
        |          |          |          |          |
        +----------+----------+----------+----------+
                              |
                              v
                        WAIT FOR ALL
                              |
                              v
                 COORDINATOR clusters findings
                              |
                              v
                      br-verifier x M
               VALID / INVALID / NEEDS_HUMAN
                              |
                              v
                  per VALID issue, in order:
             br-test-writer (red) -> br-builder (green)
                              |
                              v
                         br-validator
                              |
                              v
           TARGETED DELTA REVIEW; FULL REVIEW IF HIGH RISK
                              |
                              v
                  SELECTED GATES PASS
                              |
                              v
                      HUMAN DIFF REVIEW


======================================================================
CORE RESPONSIBILITIES
======================================================================

CLAUDE COORDINATOR (this session):

- initialization and repository inspection
- change size classification
- PHASE 0 intake: brainstorming with the user, read-only root-cause
  investigation for bugs
- OCR CLI runs (ocr delegate preview / ocr delegate rule)
- reviewer briefs for CODEX and ANTIGRAVITY
- dispatching br-* subagents and Orca reviewers, waiting at barriers
- clustering and deduplicating findings
- choosing fix order
- round numbering and review invalidation
- questions to the user
- final report

The coordinator does NOT edit production code or tests itself.
Every code change goes through br-builder or br-test-writer.


CLAUDE SUBAGENTS (~/.claude/agents/):

| Agent                 | Phase       | Writes                          |
| --------------------- | ----------- | ------------------------------- |
| br-planner            | 1           | .review/ only                   |
| br-builder            | 2, 3, 10    | production code                 |
| br-test-writer        | 2, 10       | *_test.go and testdata/ only    |
| br-validator          | 3, 11       | .review/ only                   |
| br-review-go          | 5 (OCR)     | .review/ only (+ /tmp copies)   |
| br-review-reliability | 5 (OCR)     | .review/ only (+ /tmp copies)   |
| br-review-security    | 5 (OCR)     | .review/ only (+ /tmp copies)   |
| br-review-data        | 5 (OCR)     | .review/ only (+ /tmp copies)   |
| br-verifier           | 9           | .review/ only (+ /tmp copies)   |

Only br-builder may intentionally modify production code.

Only br-test-writer may add or change tests. br-builder may touch an
existing test only to keep it compiling after a signature change, and
must report it.


OPEN CODE REVIEW:

- deterministic review-scope preparation (ocr delegate preview)
- review rule resolution (ocr delegate rule)
- precise changed-file review by the br-review-* specialists
- line-level issue detection
- structured review output

OCR MUST NOT be treated as an implementation agent.


CODEX:

- independent senior reviewer
- independent tester
- architecture/correctness reviewer
- regression reviewer

CODEX MUST NOT intentionally modify production code.


ANTIGRAVITY / AGY:

- independent adversarial reviewer
- independent tester
- edge-case reviewer
- reliability/concurrency/security reviewer

ANTIGRAVITY MUST NOT intentionally modify production code.


======================================================================
REVIEW INDEPENDENCE
======================================================================

OCR, CODEX, and ANTIGRAVITY are independent review sources.

CODEX and ANTIGRAVITY are PEER reviewers.

When selected, they MUST:

- review the SAME code revision
- receive the SAME ORIGINAL FEATURE REQUEST
- independently inspect the implementation
- inspect shared validation results and independently run focused
  reproduction tests when needed
- NOT read each other's findings
- NOT influence each other's conclusions
- NOT modify production code

IMPORTANT:

Do NOT provide OCR findings to CODEX before CODEX finishes.

Do NOT provide OCR findings to ANTIGRAVITY before ANTIGRAVITY finishes
when ANTIGRAVITY is selected.

Do NOT provide CODEX findings to ANTIGRAVITY.

Do NOT provide ANTIGRAVITY findings to CODEX.

Do NOT provide CODEX or ANTIGRAVITY findings to the br-review-*
specialists.

Each br-review-* specialist is a separate subagent with its own fresh
context. Do NOT give one specialist another specialist's report.

Reviewer independence must be preserved until all reviewer reports
for the current review round have been collected.


======================================================================
INITIALIZATION
======================================================================

Before doing any implementation work:

1. Read:

   AGENTS.md

2. Read if present:

   CLAUDE.md

3. Read relevant repository documentation.

4. Use:

   /orchestration

   for Orca multi-agent coordination.

5. When Orca CLI/orchestration syntax is required, load the CURRENT
   version-matched Orca instructions.

   Do NOT rely on stale hard-coded Orca syntax when the current
   skill guide provides different instructions.

6. Inspect:

   - git status
   - current branch
   - current worktree
   - complete current git diff
   - repository structure
   - Makefile
   - CI configuration
   - scripts
   - existing tests
   - lint commands
   - static-analysis commands
   - build commands

7. Determine repository-defined validation commands.

8. Confirm the br-* subagent types are available in this session
   (the Agent tool's agent type list). If they are missing because
   ~/.claude/agents/ was created after this session started, tell the
   user to restart the session. Do NOT fall back to doing their work
   inline.

9. Create .review/round-1/.

Do not invent validation commands when repository-defined commands exist.


======================================================================
GIT SAFETY
======================================================================

Never automatically:

- git commit
- git push
- git merge
- git rebase
- git reset --hard
- git clean -fd
- force push
- rewrite history
- delete unrelated user changes

Preserve existing user changes.

Do not overwrite unrelated modifications.


======================================================================
ORIGINAL FEATURE REQUEST
======================================================================

The ORIGINAL FEATURE REQUEST is the user's most recent clear feature
or task request in the current Claude Code conversation.

Preserve all relevant:

- requirements
- constraints
- examples
- expected behavior
- acceptance criteria
- compatibility requirements
- implementation restrictions

Do NOT invent requirements.

Do NOT silently remove requirements.

If no clear feature request exists:

STOP.

Ask the user to provide the feature request before implementation.

Write the ORIGINAL FEATURE REQUEST verbatim once to
.review/round-1/spec.md. Later rounds link to that immutable text and
record only decisions or acceptance changes. Each agent receives the
spec path and must read it; do not paste the same request into every
dispatch prompt. Do not paraphrase or silently change the original.

When PHASE 0 produced an approved design or a root-cause note, add one
line per file under the verbatim request:

APPROVED DESIGN: .review/round-1/design.md
ROOT CAUSE: .review/round-1/rootcause.md

The user approved the design, so its requirements bind like the
request. It never replaces the verbatim request.


======================================================================
CHANGE SIZE CLASSIFICATION
======================================================================

Adapted from the ECC orch-pipeline size classifier.

Score the change on three size signals. Take the HIGHEST tier any signal
reaches. Then assess risk separately.

| Tier     | Files touched        | New dependency / contract        | Design ambiguity          |
| -------- | -------------------- | -------------------------------- | ------------------------- |
| trivial  | 1, a few lines       | none                             | none, the change is obvious |
| small    | 1 file / 1 function  | none                             | clear once the code is read |
| standard | 2-5 files            | maybe a new internal module      | one real choice to make   |
| large    | many / cross-cutting | new external dep, public API, spec doc | multiple open questions |

High-risk triggers are authentication/authorization, Temporal workflows,
retry/idempotency, persistence or migration, public API/contract,
cross-bounded-context flow, external integration, and security-sensitive
input. A trigger makes the REVIEW TIER high even if the code diff is small.

State the tier in one line so the user can override it:

CHANGE SIZE: <tier> (<deciding signal>)
REVIEW TIER: normal | high (<risk evidence>)

The size tier decides planning depth:

- trivial / small:  no br-planner; coordinator writes a brief plan
- standard / large: br-planner in FULL mode

Review selection is based on the review tier:

- normal: one independent peer reviewer (CODEX), plus only a specialist
  whose area the diff actually touches. A trivial change with no review
  trigger uses CODEX alone.
- high: CODEX and ANTIGRAVITY independently, plus relevant specialists.

The br-validator always owns the shared validation gate. No omitted
reviewer or specialist counts as PASS; mark it N/A with the selection
reason. Re-classify after a fix if the affected scope changes.

Record the choice in .review/round-<N>/spec.md before dispatch.


======================================================================
SUBAGENT DISPATCH RULES
======================================================================

Launch br-* subagents with the Agent tool, using the agent type name
(br-planner, br-builder, ...).

Every dispatch prompt contains only:

- the path to .review/round-1/spec.md and the current round's spec
- the round number N
- the base ref (for example stg) and what the revision includes:
  committed changes, uncommitted changes, untracked files
- the review snapshot ID from the current round's spec when reviewing
- the report path under .review/round-<N>/
- the role-specific inputs named in the agent's contract

Use a FRESH review context for an independent reviewer on a new round.
Do not resend the original request or unchanged project documentation
inside the prompt. A builder may continue with a concise issue handoff
when continuity helps the fix.

Parallel:

- all br-review-* specialists, in the same turn as the CODEX and
  ANTIGRAVITY dispatch
- br-verifier instances, at most 6 per turn; queue the rest

Sequential:

- br-builder and br-test-writer never run at the same time; they edit
  the same worktree

Every subagent writes its full report to its file and returns only a
summary. Read the full report only when the summary is not enough.

Record each subagent's role, round, agent id and report path for the
final report.

If a read-only br-* subagent modifies a repository file outside
.review/:

STOP.

Inspect the modification. Do NOT silently accept it.

Report layout:

.review/round-<N>/
  spec.md                 shared context given to every reviewer
  snapshot.md             immutable revision identity for this round
  design.md               PHASE 0 brainstorming, approved (round 1 only)
  rootcause.md            PHASE 0 systematic-debugging (round 1 only)
  plan.md                 br-planner (round 1 only)
  build-<tag>.md          br-builder
  tests-<tag>.md          br-test-writer
  validation.md           br-validator (latest run of the round)
  ocr-scope.md            coordinator, from ocr delegate preview/rule
  claude-<area>.md        br-review-<area>
  verify-<cluster>.md     br-verifier
  issues.md               coordinator: consolidated issues table

Before each review fan-out, run:

python3 ~/.claude/workflows/build-review-snapshot.py <base-ref>

Record its snapshot ID and path count in snapshot.md. The script hashes
the base ref, HEAD, and repository file content (tracked plus untracked
non-ignored files). It excludes .review/ and graphify-out/ review
artifacts. Reviewers run the same command before reading code and
again before submitting a verdict, and compare the ID in snapshot.md.
The coordinator verifies it once more before accepting all verdicts.
If it changes, discard the affected round's verdicts and start a new
round on a stable revision. Do not force a commit to create a snapshot.


======================================================================
PHASE 0 — INTAKE (superpowers)
======================================================================

The coordinator runs this phase itself: it is a conversation with the
user plus read-only investigation. It edits no repository file outside
.review/. If the superpowers plugin is unavailable, follow the steps
below without it and record `SUPERPOWERS UNAVAILABLE` in spec.md.

Pick ONE path.

BUG (a defect, failing test or unexpected behaviour is reported):

1. Load superpowers:systematic-debugging and run its phases 1 to 3:
   root-cause investigation, pattern analysis, one hypothesis tested at
   a time. Do not fix anything: the fix belongs to br-test-writer and
   br-builder in PHASE 2.
2. Investigate read-only. Diagnostic code or logging goes only into a
   copy (rsync -a --exclude .git ./ /tmp/br-intake-$$/), deleted
   afterwards.
3. Write .review/round-1/rootcause.md: symptom, root cause with
   file:line evidence, the reproduction (input, state, expected vs
   actual) and the hypothesis test that confirmed it.
4. No root cause after phase 3: say so and ask the user. Do not guess a
   fix.

UNCLEAR (design ambiguity of "one real choice" or more, or a standard /
large change with an open question about behaviour):

1. Load superpowers:brainstorming and follow it with the user.
2. Write the design to .review/round-1/design.md, not
   docs/superpowers/, and do not commit it. Its header quotes the
   ORIGINAL FEATURE REQUEST verbatim and ends with
   `APPROVED: <YYYY-MM-DD>` once the user approves.
3. HARD GATE: no br-planner dispatch and no code before the user
   approves the design.
4. When brainstorming hands off, continue with PHASE 1 of this
   workflow, not superpowers:writing-plans.

A design.md that quotes THIS request and carries APPROVED is reused:
skip brainstorming.

CLEAR (everything else): skip PHASE 0. The user can also skip it
("làm luôn", "just do it").

After PHASE 0, re-check the size tier; brainstorming often moves it.


======================================================================
PHASE 1 — ANALYSIS (br-planner)
======================================================================

The feature must be understood before code changes.

(trivial / small) tier: skip br-planner. The coordinator writes a three-line plan
(files, behaviour, validation commands) into .review/round-1/plan.md.
Small tier adds a fourth line, the RED test: name, assertion, command
and expected failure. Trivial tier may write `NO TEST: <reason>`.

standard / large tier: dispatch br-planner in FULL mode, with
design.md when PHASE 0 produced one.

When dispatched, br-planner returns in .review/round-1/plan.md:

- affected modules and execution flows
- similar implementations to reuse
- the relevant items of the checklist below
- GLOBAL CONSTRAINTS: project-wide rules from spec.md, design.md,
  CLAUDE.md and AGENTS.md, one line each
- REVIEW FOCUS: up to five inputs or failure modes the request implies
  but no test covers yet, most likely first, each assigned a test in
  the task that owns the code
- TASKS in the superpowers:writing-plans shape: Files, Interfaces
  (exact Go signatures consumed and produced), RED tests (name,
  assertions, command, expected failure), GREEN (signature and file),
  DONE command. No commit step.
- the repository-defined validation commands, with their source
- a self-review against spec.md and design.md
- open questions that belong to the user

Ask the user the open questions before Phase 2.

standard / large tier: show the user the TASKS titles, REVIEW FOCUS and
any open question, and wait for approval of the plan before Phase 2.

Use the validation command list from the plan for every br-validator
dispatch.

The planner analyzes, where relevant:

1. relevant modules
2. affected packages
3. affected execution flows
4. existing architecture
5. similar implementations
6. relevant tests
7. API contracts
8. persistence/database behavior
9. external integrations
10. configuration impact
11. backward compatibility
12. error paths
13. edge cases
14. security implications
15. concurrency implications
16. retry behavior
17. duplicate-event behavior
18. idempotency requirements
19. resource lifecycle
20. observability/logging impact

For Go code, explicitly consider when relevant:

- context cancellation
- goroutine lifecycle
- channel lifecycle
- race conditions
- nil handling
- error propagation
- error wrapping
- defer behavior
- Close() behavior
- HTTP timeouts
- retry behavior
- database transactions
- duplicate processing
- webhook idempotency

The coordinator checks that the plan covers the ORIGINAL FEATURE
REQUEST before coding starts.


======================================================================
PHASE 2 — IMPLEMENTATION, TEST FIRST (br-test-writer, then br-builder)
======================================================================

Tests come before production code (superpowers:test-driven-development).
br-test-writer and br-builder still never run at the same time.

small / standard tier:

1. Dispatch br-test-writer in RED mode with the plan. It writes the RED
   tests of every task in one dispatch and confirms each fails for the
   reason the plan states. It writes no production code.

2. Dispatch br-builder in GREEN mode with the plan and the RED test
   list from the br-test-writer report. It makes them pass without
   editing them.

3. If br-builder reports TEST DISPUTED, dispatch br-test-writer in RED
   mode with the dispute and its evidence, then br-builder in GREEN
   mode again. br-builder never changes a RED test.

large tier: run steps 1 and 2 per task, in plan order, so each task
builds on green code. Run the task's DONE command before the next task.

bug (PHASE 0 BUG path): br-test-writer in REGRESSION mode with the
reproduction from rootcause.md (RED), then br-builder in FIX-ISSUE mode
(GREEN). NOT REPRODUCED sends the case back to PHASE 0.

trivial tier keeps the old order: br-builder in IMPLEMENT mode, then
br-test-writer in FEATURE mode only when the plan names a test. If
br-test-writer reports IMPLEMENTATION DEFECT, dispatch br-builder in
FIX-BUILD mode with that report, then re-run the affected tests.

The work implements the ORIGINAL FEATURE REQUEST.

Follow:

- AGENTS.md
- CLAUDE.md
- existing architecture
- existing naming conventions
- existing error-handling conventions
- existing test conventions

Requirements:

- minimize unrelated changes
- avoid unnecessary refactoring
- preserve backward compatibility where required
- implement appropriate error handling
- avoid unnecessary dependencies
- add/update relevant tests
- keep implementation focused on the requested feature

Do NOT modify unrelated production behavior simply because it could
be improved.

Do NOT perform speculative cleanup unrelated to the feature.


======================================================================
PHASE 3 — INITIAL VALIDATION (br-validator)
======================================================================

Before external review, the implementation must be validated.

Dispatch br-validator with the validation command list and the list of
known pre-existing failures. It is the sole owner of the full shared
build, vet, lint and test suite for this revision. Store commands,
results and the snapshot ID in validation.md before review begins.

If VALIDATION: FAIL:

1. dispatch br-builder in FIX-BUILD mode with
   .review/round-<N>/validation.md
2. dispatch br-validator again
3. repeat until VALIDATION: PASS, subject to the auto-fix limit below

In FIX-BUILD mode br-builder follows superpowers:systematic-debugging:
root cause before any change, and BLOCKED after three failed attempts
on the same failure. A BLOCKED failure goes to the user, not to a
fourth patch.

The validation command list covers the relevant repository-defined:

- unit tests
- integration tests
- lint
- static analysis
- type analysis
- build/compile

For a Go repository this may include repository-defined equivalents of:

go test
go vet
golangci-lint
go build

but DO NOT blindly assume these commands.

Prefer commands defined by:

- AGENTS.md
- Makefile
- CI
- scripts
- project documentation

Fix obvious implementation failures (through br-builder) before
starting reviewers.

Do NOT send knowingly broken code to reviewers unless the failure itself
requires independent investigation. Give reviewers the validator's
command/result summary at dispatch; it contains test evidence, not
another reviewer's findings. Reviewers run focused reproduction tests only
when needed. They do not repeat the full shared suite by default.


======================================================================
PHASE 4 — OPEN CODE REVIEW / DELEGATION MODE
======================================================================

OpenCodeReview is used as a deterministic review-planning layer.

IMPORTANT:

Do NOT require OCR to have its own LLM provider.

Prefer OpenCodeReview DELEGATION MODE.

OCR is responsible for deterministic review preparation such as:

- changed-file selection
- file filtering
- review rule resolution
- review scope preparation

The br-review-* specialist subagents perform the actual reasoning.

This avoids requiring separate OCR LLM credentials.


----------------------------------------------------------------------
OCR AVAILABILITY
----------------------------------------------------------------------

Verify:

ocr --version

Then verify Delegation Mode:

ocr delegate preview

If Delegation Mode succeeds:

OCR DELEGATION STATUS: AVAILABLE

Do NOT run normal:

ocr review

unless an OCR LLM provider has explicitly been configured.


----------------------------------------------------------------------
OCR DELEGATION PREVIEW
----------------------------------------------------------------------

Run:

ocr delegate preview

Use the result to determine:

- files requiring review
- review units
- applicable review rules
- review scope

When necessary retrieve rules using:

ocr delegate rule <file...>

Write the review units and the resolved rules to:

.review/round-<N>/ocr-scope.md

If the OCR CLI cannot run delegation mode, write instead:

OCR STATUS: CLI UNAVAILABLE

scope: git diff <base>...HEAD + git diff + untracked files


----------------------------------------------------------------------
SECURITY TRIGGER
----------------------------------------------------------------------

From the ECC orch-pipeline security-review trigger, plus one repository
trigger.

The diff touches a SECURITY TRIGGER when it touches any of:

- authentication or authorization
- user-input handling
- database queries
- file-system paths
- external API calls
- cryptography
- secrets / credentials
- a public route without JWT (for example a webhook)


----------------------------------------------------------------------
OCR SPECIALIST SELECTION
----------------------------------------------------------------------

The OCR stage is performed by br-review-* specialists, one subagent per
area:

| Specialist            | Runs when                                          | IDs         |
| --------------------- | -------------------------------------------------- | ----------- |
| br-review-go          | high review tier and Go logic changed              | OCR-GO-NN   |
| br-review-reliability | retry, concurrency, Temporal, or lifecycle changed | OCR-REL-NN  |
| br-review-security    | the diff touches a SECURITY TRIGGER                | OCR-SEC-NN  |
| br-review-data        | models, repositories, queries, migrations or config structs/tags changed | OCR-DATA-NN |

A specialist that does not run is reported as:

OCR-<AREA>: N/A (<reason>)

Every specialist receives:

- .review/round-1/spec.md containing the original request
- .review/round-<N>/spec.md (the same shared context CODEX and
  ANTIGRAVITY receive)
- .review/round-<N>/ocr-scope.md
- the base ref and what the revision includes
- its report path: .review/round-<N>/claude-<area>.md

Selected specialists start in Phase 5, in the same fan-out as the
selected Orca peer reviewers.

Each specialist ends with exactly one line:

OCR-<AREA> VERDICT: PASS

or

OCR-<AREA> VERDICT: FAIL


----------------------------------------------------------------------
IMPORTANT REVIEW INDEPENDENCE
----------------------------------------------------------------------

Do NOT provide OCR specialist findings to CODEX.

Do NOT provide OCR specialist findings to ANTIGRAVITY.

Preserve them until every selected peer reviewer completes.


----------------------------------------------------------------------
OCR DELEGATION VERDICT
----------------------------------------------------------------------

OCR VERDICT: PASS

only if at least one specialist was dispatched and every dispatched
br-review-* specialist returned PASS.

OCR VERDICT: FAIL

if any dispatched specialist returned FAIL.

If none was selected, report OCR VERDICT: N/A (no specialist trigger).
OCR preview remains a deterministic scope check, not a required
independent PASS gate for a normal-risk change.

If the OCR CLI itself cannot execute delegation mode, the specialists
still run on the git diff scope, and the OCR result is reported as:

OCR STATUS: CLI UNAVAILABLE
OCR VERDICT: PASS | FAIL (from the specialists)

Do NOT classify configuration of an OCR-managed LLM as required
when Delegation Mode is available.


======================================================================
PHASE 5 — PARALLEL PEER REVIEW USING /orchestration
======================================================================

Use /orchestration to start the selected peer-review tasks. CODEX is
selected for every change; ANTIGRAVITY is selected for high-risk changes.

In the SAME coordinator turn, use the Agent tool to start the selected
br-review-* specialists (Phase 4), all in one message.

Start ALL selected reviewers before waiting for any reviewer.

Required topology:

                       COORDINATOR
                            |
          /orchestration    |    Agent tool
                  +---------+---------+-------------------+
                  |                   |                   |
                  v                   v                   v
               CODEX                 AGY         br-review-* x N
            Review + Test        Review + Test   OCR specialists


DO NOT execute sequentially:

CODEX
  |
wait
  |
ANTIGRAVITY


DO NOT execute sequentially:

ANTIGRAVITY
  |
wait
  |
CODEX


All reviewer tasks, Orca and subagent, must be started before entering
the fan-in/wait phase.


======================================================================
REVIEWER #1 — CODEX
======================================================================

Create an Orca orchestration child task for CODEX.

Give CODEX:

- ORIGINAL FEATURE REQUEST
- current repository/worktree
- current code revision
- relevant project instructions
- instruction to read:

  ~/.claude/reviewers/codex-review.md

CODEX must:

- inspect the assigned review scope (full diff for round 1/high risk,
  delta plus affected flow for later normal-risk rounds)
- inspect surrounding code
- inspect relevant tests
- independently reason about correctness
- inspect shared validation evidence and run focused tests only to
  reproduce or disprove a concrete finding
- independently check regression risks
- independently produce findings

CODEX MUST NOT receive:

- OCR findings
- ANTIGRAVITY findings

CODEX MUST NOT intentionally modify production code.


======================================================================
REVIEWER #2 — ANTIGRAVITY / AGY
======================================================================

Antigravity must be a REAL AGY reviewer process.
Launch it only when the review tier is high. Otherwise record
ANTIGRAVITY: N/A (normal review tier).

Read:

~/.claude/reviewers/antigravity-review.md


----------------------------------------------------------------------
ANTIGRAVITY LAUNCH
----------------------------------------------------------------------

Preferred Antigravity executable:

agy

Required permission mode:

--dangerously-skip-permissions

Therefore the effective launch configuration must use:

agy --dangerously-skip-permissions


----------------------------------------------------------------------
NO WRAPPER SCRIPT
----------------------------------------------------------------------

DO NOT:

- create run-agy.sh
- create AGY wrapper shell scripts
- redirect AGY into a hidden background shell process
- simulate AGY with a generic shell reviewer
- launch detached AGY processes
- hide AGY stdout/stderr in temporary files

The user must be able to inspect the actual Antigravity reviewer.


----------------------------------------------------------------------
ORCA NATIVE AGENT
----------------------------------------------------------------------

Prefer Orca's native Antigravity agent integration when it works
correctly with the CURRENT Orca version.

Use the current Orca orchestration instructions.

Do NOT hard-code obsolete worker-start syntax.

The resulting reviewer must be the actual Antigravity/AGY agent.


----------------------------------------------------------------------
ANTIGRAVITY FALLBACK
----------------------------------------------------------------------

Antigravity may have Orca readiness/injection/lifecycle issues.

If native supervised Antigravity orchestration fails:

1. inspect the existing worker first
2. determine whether AGY is actually running
3. do NOT create duplicate AGY processes
4. if recovery is required, use an Orca-managed terminal
5. launch the REAL command:

   agy --dangerously-skip-permissions

6. wait until the real AGY interface is ready
7. send the independent reviewer task
8. keep the terminal inspectable

Even in fallback mode, Antigravity must:

- review the SAME code revision as CODEX
- receive the SAME ORIGINAL FEATURE REQUEST
- read:

  ~/.claude/reviewers/antigravity-review.md

- remain independent from CODEX
- NOT receive OCR findings
- NOT modify production code


======================================================================
ANTIGRAVITY STARTUP VALIDATION
======================================================================

Terminal creation does NOT prove AGY started successfully.

Verify that:

- the AGY process exists
- the real Antigravity CLI/TUI is running
- the reviewer can receive input
- the reviewer actually begins the requested review

A terminal that only shows something similar to:

=== ANTIGRAVITY REVIEWER STARTING ===

without the actual AGY process becoming usable is NOT considered
successfully started.

Do not wait forever on a failed startup.

Inspect the worker/task/terminal using the CURRENT Orca diagnostics.


======================================================================
PHASE 6 — REVIEWER OBSERVABILITY
======================================================================

Reviewer execution must remain observable.

Do NOT intentionally hide reviewer tasks.

Do NOT immediately close reviewer workers or terminals.

Preserve all available Orca identifiers.

When available record:

- reviewer name
- task ID
- dispatch ID
- worker ID
- terminal handle
- current status


Immediately after selected peer reviewers have been started, report:

REVIEW ROUND <N> STARTED


CODEX

Status:
RUNNING

Task:
<task_id if available>

Dispatch:
<dispatch_id if available>

Worker:
<worker_id if available>

Terminal:
<terminal_handle if available>


ANTIGRAVITY

Status:
RUNNING | N/A (<selection reason>)

Task:
<task_id if available>

Dispatch:
<dispatch_id if available>

Worker:
<worker_id if available>

Terminal:
<terminal_handle if available>


CLAUDE SPECIALISTS

OCR-GO           RUNNING | N/A (<reason>)
OCR-REL          RUNNING | N/A (<reason>)
OCR-SEC          RUNNING | N/A (<reason>)
OCR-DATA         RUNNING | N/A (<reason>)


Do NOT invent unavailable identifiers.

If an identifier is unavailable, report:

unavailable


The user must be able to inspect reviewer progress using the CURRENT
Orca orchestration/terminal capabilities.

Use the version-matched Orca skill documentation for:

- task inspection
- worker inspection
- worker output reading
- terminal output reading
- terminal switching

Do NOT assume stale CLI syntax.


======================================================================
PHASE 7 — FAN-OUT / FAN-IN RULE
======================================================================

The workflow has a strict synchronization barrier.

First:

START CODEX

AND, only for high review tier, START ANTIGRAVITY

AND START EVERY SELECTED br-review-* SPECIALIST


Then:

WAIT.


Required state before consolidation:

CODEX = COMPLETED

AND every other SELECTED reviewer/specialist = COMPLETED

AND the review snapshot ID still matches


Do NOT start fixes after only some reviewers complete.

Do NOT let the faster reviewer influence the slower reviewer.

Do NOT expose completed reviewer findings to the still-running reviewer.


======================================================================
PHASE 8 — COLLECT REVIEW RESULTS
======================================================================

After ALL selected reviewers complete, collect:

1. OCR structured result: every br-review-* summary and its
   .review/round-<N>/claude-<area>.md
2. CODEX final report
3. ANTIGRAVITY final report when selected, otherwise N/A


Expected CODEX verdict:

CODEX VERDICT: PASS

or

CODEX VERDICT: FAIL


Expected Antigravity verdict when selected:

ANTIGRAVITY VERDICT: PASS

or

ANTIGRAVITY VERDICT: FAIL


Expected OCR verdict, computed from the selected specialists (Phase 4):

OCR VERDICT: PASS

or

OCR VERDICT: FAIL

or OCR VERDICT: N/A when no specialist was selected


Only now may the coordinator compare findings across reviewers.


======================================================================
PHASE 9 — CONSOLIDATE FINDINGS
======================================================================

The coordinator receives the selected independent review sources:

1. CODEX
2. ANTIGRAVITY when selected
3. selected br-review-* specialists

Steps:

1. Cluster the findings into candidate issues: same file or code
   region, or the same suspected root cause. A finding may stand alone.
2. Resolve a clear finding against code and tests directly, recording
   evidence. Dispatch a br-verifier only for disputed, ambiguous or
   high-severity findings (at most 6 per turn). Give it the source
   findings with reviewer IDs, spec and snapshot ID. Report to
   .review/round-<N>/verify-<cluster>.md.
3. Build .review/round-<N>/issues.md from the evidence and any verifier
   results. Never dismiss a finding merely to reduce reviewer count.

The coordinator or br-verifier classifies each source finding as:

VALID

INVALID

NEEDS_HUMAN

The coordinator then marks DUPLICATE findings: every source finding
that shares a root cause with another is mapped to one canonical issue.

For every finding the final classification is one of:

VALID

INVALID

DUPLICATE

NEEDS_INVESTIGATION (verifier evidence was inconclusive: dispatch a
fresh br-verifier with the open question, or ask the user)


Do NOT use majority voting.

A finding reported by only ONE reviewer may still be valid.

A finding reported by ALL reviewers may still be invalid.

Resolve findings using evidence.


======================================================================
EVIDENCE PRIORITY
======================================================================

Use:

1. ORIGINAL FEATURE REQUEST
2. acceptance criteria
3. source code
4. repository documentation
5. API contracts
6. reproducible tests
7. observable runtime behavior
8. external integration contracts where applicable

Do not fix code merely because an AI reviewer suggested it.


======================================================================
DEDUPLICATION
======================================================================

Different reviewers may describe the SAME underlying defect.

Example:

OCR-REL-04:

Potential duplicate processing in webhook handler.


CODEX-02:

Repeated webhook notification can create multiple tickets.


ANTIGRAVITY-05:

Concurrent duplicate notifications are not idempotent.


The coordinator should consolidate:

ISSUE-01

Sources:

- OCR-REL-04
- CODEX-02
- ANTIGRAVITY-05

Root cause:

Missing idempotency protection during webhook processing.


Implement ONE root-cause fix.

Do NOT implement three separate fixes for the same root cause.


======================================================================
VALID FINDINGS
======================================================================

For each VALID finding:

1. understand the problem                  (br-verifier)
2. reproduce when appropriate              (br-test-writer, red test)
3. identify the root cause                 (br-verifier)
4. design the smallest correct fix         (br-builder)
5. implement the root-cause fix            (br-builder)
6. add/update regression tests             (br-test-writer)
7. validate the fix                        (br-builder focused tests,
                                            then br-validator)


======================================================================
INVALID FINDINGS
======================================================================

For INVALID findings:

- do NOT modify correct production code
- record the reason for rejection
- preserve supporting evidence

Example:

REJECTED FINDING:

CODEX-03

Reason:

The caller guarantees non-nil input through the validated constructor.

Evidence:

<relevant code/test>


======================================================================
DUPLICATE FINDINGS
======================================================================

For DUPLICATE findings:

- map them to the canonical consolidated issue
- preserve source reviewer IDs
- fix the root cause only once


======================================================================
NEEDS INVESTIGATION
======================================================================

For NEEDS_INVESTIGATION, a fresh br-verifier gets the open question
and:

1. inspects relevant implementation
2. inspects callers/callees
3. reproduces if possible
4. runs focused tests
5. creates temporary diagnostic tests in a /tmp copy if useful
6. determines whether the finding is valid

For NEEDS_HUMAN, ask the user the exact question the verifier stated.

Only modify production code if the issue is confirmed.


======================================================================
PHASE 10 — FIX (br-test-writer, then br-builder)
======================================================================

Only br-builder intentionally modifies production code.

Group VALID findings by root cause. Handle each independent root-cause
group in priority order (highest severity and dependencies first).
Create one fix brief and the minimum meaningful regression tests for
each group. Multiple reports of one root cause are one fix, not one
test-and-builder dispatch per reviewer finding:

1. Dispatch br-test-writer in REGRESSION mode with the root-cause group
   from .review/round-<N>/issues.md and its evidence.

   - RED: the new test fails for the reason in the issue. Continue.
   - NOT REPRODUCED: the test passes. Send the issue back to a fresh
     br-verifier with the test as evidence. Do not fix until the issue
     is confirmed again.
   - NO TEST POSSIBLE (for example config or documentation only):
     record the reason in issues.md and continue without a red test.

2. Dispatch br-builder in FIX-ISSUE mode with the group, evidence and
   red test names.
   The red test must turn GREEN. br-builder must not edit that test.

3. Run focused tests, then handle the next independent group. Run the
   full shared validation once after the batch of confirmed fixes.

If an issue needs a decision that belongs to the user (scope, product
behaviour, credentials, infrastructure), ask with AskUserQuestion and
continue once they answer.

For confirmed issues:

- fix root causes
- avoid symptom-only patches
- add/update regression tests
- preserve existing behavior unless change is required
- avoid unrelated refactoring

Do NOT:

- weaken tests to obtain PASS
- delete failing tests to obtain PASS
- disable lint to obtain PASS
- disable static analysis to obtain PASS
- suppress legitimate errors without fixing them


======================================================================
PHASE 11 — POST-FIX VALIDATION
======================================================================

After the batch of br-builder and br-test-writer changes, dispatch
br-validator once
with the validation command list. It runs the relevant
repository-defined:

- unit tests
- integration tests
- lint
- static analysis
- type analysis
- build/compile

Fix implementation-caused validation failures before re-review
(br-builder in FIX-BUILD mode, then br-validator again).


======================================================================
PHASE 12 — INVALIDATE PREVIOUS REVIEW RESULTS
======================================================================

ANY intentional change to the reviewed revision (production code by
br-builder, tests by br-test-writer) invalidates:

- previous OCR result, including every br-review-* verdict
- previous CODEX verdict
- previous ANTIGRAVITY verdict

Previous PASS results MUST NOT be presented as approval of the new
snapshot. Keep them as historical evidence. The new round must obtain
the selected gates on the new snapshot.


======================================================================
PHASE 13 — RE-REVIEW
======================================================================

After code or test changes, capture a new snapshot ID and re-assess
the risk. Run OCR preview for the new snapshot when a specialist is
selected. For normal review tier, CODEX reviews the delta
since the last snapshot, the affected execution flow, and the status
of prior confirmed issues. Select a specialist only if the delta
touches its trigger. For high review tier, CODEX and ANTIGRAVITY run
fresh independent full reviews, with selected specialists. Start all
selected reviewers in one fan-out.


Required topology:

                         UPDATED CODE
                              |
                              v
                  snapshot + scope check
                              |
                              v
              selected Orca reviewers + Agent tool
                              |
                  +-----------+-----------+-------------------+
                  |                       |                   |
                  v                       v                   v
               CODEX              AGY if high       selected br-review-*
            fresh review          fresh review          fresh review
                  |                       |                   |
                  +-----------+-----------+-------------------+
                              |
                              v
                         WAIT FOR ALL


All selected review sources must evaluate the SAME updated snapshot.

Reviewer independence rules apply again.

Do NOT provide the new OCR specialist findings to CODEX or ANTIGRAVITY
before their reviews finish.

Do NOT provide CODEX or ANTIGRAVITY findings to the specialists.

Do NOT provide CODEX findings to ANTIGRAVITY.

Do NOT provide ANTIGRAVITY findings to CODEX.


======================================================================
REVIEW ROUND NUMBERING
======================================================================

Use:

REVIEW ROUND 1

for the first external review.


After the first fix cycle:

REVIEW ROUND 2


After the second fix cycle:

REVIEW ROUND 3


The default automatic budget is two fix cycles, therefore at most
three review rounds. After round 3, report unresolved findings and
evidence. Continue only when the user explicitly requests another
cycle; never label an incomplete round PASS.


======================================================================
PASS CONDITION
======================================================================

FINAL PASS requires the SAME verified snapshot ID to satisfy ALL
selected gates:

- VALIDATION: PASS from br-validator
- CODEX VERDICT: PASS
- ANTIGRAVITY VERDICT: PASS when high review tier; otherwise N/A
- OCR VERDICT: PASS when specialists were selected; otherwise N/A
- no unresolved valid finding or changed snapshot

N/A means the gate was deliberately omitted under the recorded risk
policy. A selected reviewer that failed to start or finish is UNKNOWN,
not N/A or PASS. Any selected FAIL or UNKNOWN prevents FINAL PASS.


======================================================================
IMPORTANT OCR EXCEPTION
======================================================================

If the OCR CLI is unavailable because of an environment/tooling/
configuration problem rather than a code-review failure:

Do not skip selected br-review-* specialists. They run on the git diff
scope instead of the OCR review units. If no specialist was selected,
OCR stays N/A.

Report:

OCR STATUS: CLI UNAVAILABLE

OCR VERDICT: PASS | FAIL | N/A (from selection and specialists)

Continue selected CODEX and ANTIGRAVITY review as usual.

Final result must explicitly state:

FINAL VERDICT: PASS WITH OCR UNAVAILABLE

only if:

- every selected br-review-* specialist PASS (or none selected)
- CODEX PASS
- ANTIGRAVITY PASS when selected
- br-validator PASS
- OCR CLI failure is confirmed to be tooling/environmental and at
  least one specialist was selected
- there are no unresolved code findings

If a br-review-* subagent itself cannot run (agent type missing,
subagent crash), that is NOT an OCR PASS: re-dispatch it, or stop and
tell the user.

Never confuse tool failure with review PASS.


======================================================================
FIX CYCLE LIMIT
======================================================================

The default limit is TWO automatic fix cycles after the initial
implementation. Count a batch of related root-cause fixes as one
cycle. The user may explicitly authorize more cycles; record the new
budget in the current spec.


Initial implementation
    |
Review Round 1
    |
Fix Cycle 1
    |
Review Round 2
    |
   ...
    |
Fix Cycle 2
    |
Review Round 3   ->   PASS or report remaining findings


Stop automatic fixing when the budget is exhausted. Report what was
fixed, what remains, the validation state, the current snapshot ID and
the exact next action. Do not silently extend the budget.

The loop ends only when:

- FINAL PASS is reached,
- the automatic cycle budget is exhausted,
- an external decision is required, or
- the user explicitly tells you to stop.

If a remaining valid finding can only be fixed with a decision that
belongs to the user (scope, product behaviour, credentials,
infrastructure), ask the user and continue once they answer. Do not
stop silently.

Report NEEDS HUMAN REVIEW whenever valid findings remain after the
automatic budget or a required decision cannot be inferred. This is a
non-PASS outcome, not a request to rerun every reviewer automatically.


======================================================================
DISAGREEMENT HANDLING
======================================================================

Do NOT use reviewer voting.

Examples:

CODEX PASS
ANTIGRAVITY FAIL

does NOT mean majority PASS.


OCR + CODEX PASS
ANTIGRAVITY FAIL

does NOT automatically mean PASS.


Resolve disagreements using:

- source code
- requirements
- documentation
- tests
- reproducible behavior
- external contracts

If disagreement cannot be resolved confidently:

STOP and request human review.


======================================================================
ANTIGRAVITY PERMISSION SAFETY
======================================================================

AGY may run with:

--dangerously-skip-permissions

This grants broad execution capability.

Therefore Antigravity reviewer instructions MUST explicitly prohibit:

- modifying production code
- git commit
- git push
- git merge
- git rebase
- git reset --hard
- force push
- destructive repository operations
- modifying production infrastructure
- exposing secrets
- deleting unrelated files

If Antigravity unexpectedly modifies production code:

STOP.

Inspect the modification.

Do NOT silently accept it.

Restore or reconcile only after determining exactly what changed.


======================================================================
REVIEWER TEST ISOLATION
======================================================================

CODEX and ANTIGRAVITY must not interfere with each other.

Prefer:

- read-only production-code review
- existing repository tests
- non-mutating validation commands

If a reviewer needs temporary diagnostic tests:

- isolate temporary work where possible
- do not allow reviewer test artifacts to affect the other reviewer
- do not treat reviewer-created production changes as implementation
- clean temporary artifacts safely after results are captured

The same applies to br-review-* specialists and br-verifier: they
write diagnostic tests only in a copy under /tmp, never in the
repository.

Only br-builder owns final implementation changes, and br-test-writer
owns final test changes.


======================================================================
RUNTIME ARTIFACTS
======================================================================

Runtime review artifacts such as:

.review/ocr-result.json

.review/round-<N>/ (subagent reports, see SUBAGENT DISPATCH RULES)

must not be treated as production changes.

Prefer keeping:

.review/

out of version control.

Do not commit review runtime output.


======================================================================
OBSERVABILITY RETENTION
======================================================================

Do NOT close reviewer tasks/terminals immediately after completion.

Keep reviewer output inspectable until:

1. every selected peer reviewer finishes
2. reports are collected
3. the coordinator consolidates findings

After consolidation, completed reviewer workers may be released according
to the current Orca orchestration lifecycle.

Do not destroy output required for debugging the workflow.


======================================================================
FINAL REPORT
======================================================================

Before writing the verdict, apply superpowers:verification-before-completion:
run python3 ~/.claude/workflows/build-review-snapshot.py <base-ref> once
more. Its ID must equal the SNAPSHOT ID of validation.md and of every
selected verdict. A mismatch, or a claim with no command output behind
it in .review/, is not PASS.

When the workflow ends, report using this structure:


FINAL VERDICT:

PASS

or

PASS WITH OCR UNAVAILABLE

or

NEEDS HUMAN REVIEW


----------------------------------------------------------------------
FEATURE
----------------------------------------------------------------------

<ORIGINAL FEATURE REQUEST summary>


----------------------------------------------------------------------
INTAKE
----------------------------------------------------------------------

PHASE 0: BUG (rootcause.md) | UNCLEAR (design.md, APPROVED <date>) |
SKIPPED (<clear request, or the user skipped it>)


----------------------------------------------------------------------
CHANGE SIZE
----------------------------------------------------------------------

<tier> (<deciding signal>), final round

REVIEW TIER: normal | high (<trigger and selected gates>)

SNAPSHOT ID: <final reviewed revision hash>


----------------------------------------------------------------------
IMPLEMENTATION
----------------------------------------------------------------------

<implementation summary>


----------------------------------------------------------------------
FILES CHANGED
----------------------------------------------------------------------

<production files changed by br-builder>

<test files changed by br-test-writer>


----------------------------------------------------------------------
REVIEW ROUNDS
----------------------------------------------------------------------

<number of review rounds>

AUTO-FIX CYCLES: <used> / <authorized budget>


----------------------------------------------------------------------
OPEN CODE REVIEW
----------------------------------------------------------------------

CLI status:

AVAILABLE | CLI UNAVAILABLE | NOT RUN (<reason>)

OCR verdict: PASS | FAIL | N/A (<reason>)

Claude specialists (final round):

OCR-GO     PASS | FAIL | N/A (<reason>)
OCR-REL    PASS | FAIL | N/A (<reason>)
OCR-SEC    PASS | FAIL | N/A (<reason>)
OCR-DATA   PASS | FAIL | N/A (<reason>)

Findings:

<summary>

Result:

.review/ocr-result.json

.review/round-<N>/claude-<area>.md


----------------------------------------------------------------------
CODEX
----------------------------------------------------------------------

Final verdict:

PASS | FAIL | UNKNOWN

Findings:

<summary>


----------------------------------------------------------------------
ANTIGRAVITY
----------------------------------------------------------------------

Final verdict:

PASS | FAIL | N/A (<reason>)

Findings:

<summary>


----------------------------------------------------------------------
CONSOLIDATED ISSUES
----------------------------------------------------------------------

For each issue:

ISSUE-<ID>

Sources:

- OCR-<AREA>-...
- CODEX-...
- ANTIGRAVITY-...

Root cause:

<root cause>

Verified by:

.review/round-<N>/verify-<cluster>.md

Regression test:

<test name, or NO TEST POSSIBLE: reason>

Resolution:

<resolution>


----------------------------------------------------------------------
FIXED
----------------------------------------------------------------------

<confirmed issues fixed by br-builder, with their regression tests>


----------------------------------------------------------------------
DUPLICATE FINDINGS
----------------------------------------------------------------------

<duplicate mappings>


----------------------------------------------------------------------
REJECTED FINDINGS
----------------------------------------------------------------------

For each rejected finding:

Finding:

<reviewer finding>

Reason:

<why invalid>

Evidence:

<evidence>


----------------------------------------------------------------------
VALIDATION
----------------------------------------------------------------------

For each command:

Command:

<command>

Result:

PASS | FAIL | SKIPPED (<reason>)

Important output:

<summary>


----------------------------------------------------------------------
REMAINING RISKS
----------------------------------------------------------------------

<remaining risks or NONE>


----------------------------------------------------------------------
REVIEWER OBSERVABILITY
----------------------------------------------------------------------

Record final available task/dispatch/worker/terminal identifiers
for the final review round when available.


----------------------------------------------------------------------
SUBAGENT RUNS
----------------------------------------------------------------------

For each br-* subagent dispatched, in order:

Round | Role | Agent id | Report | Result

Example:

1 | br-planner         | <agent_id> | .review/round-1/plan.md          | FULL plan
1 | br-review-go       | <agent_id> | .review/round-1/claude-go.md     | FAIL (2)
1 | br-verifier        | <agent_id> | .review/round-1/verify-C1.md     | VALID 1, INVALID 1
1 | br-test-writer     | <agent_id> | .review/round-1/tests-ISSUE-01.md | RED


----------------------------------------------------------------------
FINAL HANDOFF
----------------------------------------------------------------------

For PASS: Ready for HUMAN DIFF REVIEW.
For NEEDS HUMAN REVIEW: list remaining issues and the decision or
action needed before another cycle. Never claim the diff is ready.

Do NOT commit.

Do NOT push.

Wait for the human to inspect the final diff.


======================================================================
INVOCATION
======================================================================

Start the workflow from a session opened AFTER ~/.claude/agents/br-*.md
exist, with a prompt such as:

Use /orchestration to execute:

~/.claude/workflows/build-review.md

Use my most recent feature request as the ORIGINAL FEATURE REQUEST.

Claude Code: Coordinator only — delegate to br-* subagents.

Run PHASE 0 (superpowers brainstorming or systematic-debugging) when the
request needs it. Add "làm luôn" to skip it.

Select reviewers by the risk policy. Run CODEX and, for high-risk
changes, ANTIGRAVITY as independent Orca reviewers alongside selected
br-review-* specialists, in ONE parallel fan-out.

(When selected, Antigravity remains a real Orca antigravity agent,
agy --dangerously-skip-permissions, no wrapper script, visible terminal.)
