# OPEN CODE REVIEW (OCR)

OpenCodeReview is a specialized deterministic code-review stage.

Its purpose is to review the current code diff with precise file
selection, structured review output, and line-level findings.

It is NOT a replacement for Codex or Antigravity.

==================================================
INPUT
==================================================

Review the current implementation against the ORIGINAL FEATURE REQUEST.

Use the current repository/worktree and current code revision.

==================================================
EXECUTION
==================================================

Run:

ocr review --format json --output .review/ocr-result.json

If reviewing against a base branch is more appropriate, determine
the actual base branch from the current repository and use:

ocr review --from <base> --to <current-branch> \
  --format json \
  --output .review/ocr-result.json

Do not guess the base branch.

==================================================
RULES
==================================================

OCR MUST NOT modify production code.

OCR findings are advisory evidence.

Claude must independently validate each OCR finding before fixing.

==================================================
OUTPUT
==================================================

Preserve:

.review/ocr-result.json

Claude must summarize OCR findings as:

OCR FINDING <ID>

Severity:
<severity if available>

File:
<path>

Location:
<line/range if available>

Problem:
<description>

Evidence:
<evidence>

Recommended fix:
<recommendation>

==================================================
VERDICT
==================================================

OCR VERDICT: PASS

if no actionable findings exist.

OCR VERDICT: FAIL

if one or more actionable findings exist.
