# build-review

Workflow **Build → Codex + Antigravity → Auto Fix** cho Claude Code.

Claude Code chỉ làm coordinator. Các subagent `br-*` lập kế hoạch, viết test trước (RED), code cho test pass (GREEN), chạy validation. Sau đó Codex, Antigravity (khi rủi ro cao) và các specialist OCR review độc lập trong cùng một lượt song song. Coordinator gom finding, `br-verifier` xác minh từng finding, rồi tự fix theo root cause (tối đa 2 vòng). Kết thúc ở bước người review diff. Workflow **không bao giờ commit / push**.

```
feature ─► PHASE 0 (brainstorming | systematic-debugging)
        ─► br-planner ─► br-test-writer (RED) ─► br-builder (GREEN) ─► br-validator
        ─► ocr delegate preview
        ─► CODEX ‖ AGY (high risk) ‖ br-review-go/reliability/security/data/lean
        ─► br-verifier ─► fix (RED → GREEN) ─► re-review ─► HUMAN DIFF REVIEW
```

Chi tiết từng phase: [workflows/build-review.md](workflows/build-review.md).

> Hiện tối ưu cho **repo Go**: `br-test-writer` viết `*_test.go`, `br-review-go` soát Go/Temporal, `br-review-data` soát MongoDB driver / GORM-MySQL.

## Yêu cầu

| Thành phần | Dùng ở | Cài |
|---|---|---|
| Claude Code | coordinator + subagent `br-*` | https://claude.com/claude-code |
| Plugin `superpowers@claude-plugins-official` | PHASE 0, test-first, verification | `/plugin install superpowers@claude-plugins-official` |
| Plugin `ecc@ecc` | checklist tham khảo cho `br-*` | `/plugin marketplace add https://github.com/affaan-m/ECC.git` rồi `/plugin install ecc@ecc` |
| Plugin `ponytail@ponytail` | quy tắc lean cho `br-planner`, `br-builder`, `br-review-lean` (xem [Ponytail](#ponytail-lean)) | `/plugin marketplace add DietrichGebert/ponytail` rồi (prompt riêng) `/plugin install ponytail@ponytail`; để trống Webhook URL |
| Orca (`orca` CLI + skill `orchestration`, `orca-cli` trong `~/.claude/skills/`) | chạy Codex / AGY như reviewer độc lập | app Orca |
| Codex CLI (`codex`) | reviewer #1, mọi thay đổi | `brew install codex` hoặc `npm i -g @openai/codex` |
| Antigravity CLI (`agy`) | reviewer #2, chỉ review tier high | Antigravity |
| OpenCodeReview (`ocr`) | chuẩn bị review scope (delegation mode, không cần LLM key) | `npm i -g @alibaba-group/open-code-review` |
| `git`, `python3` | script snapshot | |

`install.sh` tự kiểm tra các thành phần trên và in cảnh báo nếu thiếu (vẫn cài). Thiếu `ocr` thì workflow vẫn chạy và báo `OCR STATUS: CLI UNAVAILABLE`. Thiếu Codex, Orca hoặc subagent `br-*` thì không đạt được `FINAL PASS`.

## Cài đặt

```bash
git clone git@github.com:ndxbinh1922001/claude-build-review.git
cd claude-build-review
./install.sh --dry-run          # xem trước sẽ thêm / ghi đè file nào
./install.sh                    # cài
./install.sh --with-rule        # cài thêm rule định tuyến (xem bên dưới)
```

Sau khi cài, **mở session Claude Code mới**: agent chỉ được nạp lúc session khởi động.

File được copy vào `${CLAUDE_CONFIG_DIR:-~/.claude}`:

| Trong repo | Đích |
|---|---|
| `agents/br-*.md` (10 subagent) | `~/.claude/agents/` |
| `workflows/build-review.md`, `workflows/build-review-snapshot.py` | `~/.claude/workflows/` |
| `reviewers/*.md` (brief cho Codex / AGY / OCR) | `~/.claude/reviewers/` |
| `rules/dev-workflow.md` (chỉ với `--with-rule`) | `~/.claude/rules/` |

File đã tồn tại mà khác nội dung sẽ được backup vào `~/.claude/backups/build-review-<timestamp>/` trước khi ghi đè. File giống hệt thì bỏ qua.

`install.sh` cũng tạo `~/.config/ponytail/config.json` với `{"defaultMode": "off"}` nếu file chưa có. File đã có mà không đặt `off` thì chỉ cảnh báo, không ghi đè.

### Ponytail (lean)

[ponytail](https://github.com/DietrichGebert/ponytail) chỉ là tài liệu tham khảo. Hook của nó luôn tắt (`defaultMode: off`), nên coordinator, Codex và AGY không bị ảnh hưởng.

| Bước | Ponytail làm gì |
|---|---|
| Build | `br-planner` và `br-builder` đọc `skills/ponytail/SKILL.md` (solution ladder). Plan có thêm dòng `LADDER` cho mỗi type/func mới và mục `NOT BUILT` để người dùng duyệt. Builder báo thêm `SHORTCUTS`. Contract `br-*` thắng khi mâu thuẫn: ponytail không viết test, không cắt requirement, không coi port/adapter hay VO mà CLAUDE.md bắt buộc là yagni. |
| Review | Specialist `br-review-lean` (OCR-LEAN) dùng checklist của `ponytail-review`, chạy khi size tier là standard/large. Brief của Codex và AGY giữ nguyên. |
| Auto Fix | Finding `ADVISORY` chỉ được báo cáo: không verifier, không tốn fix cycle, không chặn `FINAL PASS`. Finding `RULE-VIOLATION` (vi phạm rule tường minh trong CLAUDE.md/AGENTS.md) đi luồng verify → fix bình thường. |

### Rule định tuyến `--with-rule`

`rules/dev-workflow.md` là rule global, áp cho **mọi project**: khi nào dùng brainstorming / systematic-debugging / TDD, khi nào chạy build-review, và cấm Claude tự commit / push / merge. Chỉ cài nếu bạn muốn theo đúng quy trình đó. Nếu đã có `~/.claude/rules/dev-workflow.md` của riêng bạn, bản cũ sẽ được backup.

## Sử dụng

Trong repo cần làm, mô tả feature / bug cho Claude Code như bình thường, sau đó:

```
Use /orchestration to execute:

~/.claude/workflows/build-review.md

Use my most recent feature request as the ORIGINAL FEATURE REQUEST.
```

Có cài `--with-rule` thì chỉ cần nói "chạy build-review". Thêm "làm luôn" để bỏ PHASE 0.

Toàn bộ report nằm ở `.review/round-<N>/` trong repo. Nên ignore thư mục này:

```bash
echo .review/ >> .git/info/exclude
```

## Cập nhật / gỡ

```bash
git pull && ./install.sh               # cập nhật
./install.sh --uninstall [--with-rule] # gỡ (file bị xoá vẫn được backup)
```

## Lưu ý an toàn

- AGY chạy với `--dangerously-skip-permissions`. Brief của reviewer cấm sửa code, commit, push, reset, nhưng hãy chạy trên worktree không có thay đổi quan trọng chưa lưu.
- Workflow không commit, push, merge hay rebase. Bạn tự xem diff và tự commit.

## Đóng góp

Sửa trong repo này rồi mở PR, đừng sửa thẳng trong `~/.claude`: lần `./install.sh` sau sẽ ghi đè (bản cũ vẫn được backup).
