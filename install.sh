#!/usr/bin/env bash
# Install the build-review workflow into the Claude Code config directory.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
BACKUP_DIR="$TARGET/backups/build-review-$(date +%Y%m%d-%H%M%S)"

DRY_RUN=0
WITH_RULE=0
UNINSTALL=0
WARNINGS=0

usage() {
  cat <<'EOF'
Usage: ./install.sh [--dry-run] [--with-rule] [--uninstall]

Copies the build-review workflow into ${CLAUDE_CONFIG_DIR:-~/.claude}:
  agents/br-*.md
  workflows/build-review.md, workflows/build-review-snapshot.py
  reviewers/*.md

and creates ${XDG_CONFIG_HOME:-~/.config}/ponytail/config.json with
"defaultMode": "off" when it is missing (ponytail stays reference-only).

Options:
  --with-rule   also install rules/dev-workflow.md (routing rule, applies to every project)
  --dry-run     print what would change and change nothing
  --uninstall   remove the files this script installs (backed up first)
  -h, --help    show this help

A file that already exists with different content is backed up to
<config>/backups/build-review-<timestamp>/ before it is replaced or removed.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --with-rule) WITH_RULE=1 ;;
    --uninstall) UNINSTALL=1 ;;
    -h | --help) usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

# Repository-relative paths of every file this script manages, one per line.
managed_files() {
  (cd "$REPO_DIR" && find agents workflows reviewers -type f \( -name '*.md' -o -name '*.py' \) | LC_ALL=C sort)
  if [ "$WITH_RULE" -eq 1 ]; then
    echo rules/dev-workflow.md
  fi
}

run() {
  if [ "$DRY_RUN" -eq 0 ]; then
    "$@"
  fi
}

backup() {
  run mkdir -p "$BACKUP_DIR/$(dirname "$1")"
  run cp -p "$TARGET/$1" "$BACKUP_DIR/$1"
}

warn() {
  echo "warning: $*" >&2
  WARNINGS=$((WARNINGS + 1))
}

warn_cmd() {
  command -v "$1" >/dev/null 2>&1 || warn "'$1' not found in PATH ($2)"
}

warn_plugin() {
  local registry="$TARGET/plugins/installed_plugins.json"
  if [ ! -f "$registry" ] || ! grep -q "\"$1\"" "$registry"; then
    warn "plugin $1 is not installed ($2)"
  fi
}

warn_skill() {
  [ -e "$TARGET/skills/$1" ] || warn "skill '$1' not found in $TARGET/skills ($2)"
}

check_prereqs() {
  warn_cmd git "required by the snapshot script"
  warn_cmd python3 "required by the snapshot script"
  warn_cmd codex "CODEX reviewer"
  warn_cmd agy "ANTIGRAVITY reviewer, high review tier only"
  warn_cmd orca "runs CODEX and ANTIGRAVITY as Orca reviewers"
  warn_cmd ocr "OpenCodeReview: npm i -g @alibaba-group/open-code-review"
  warn_plugin superpowers@claude-plugins-official "PHASE 0 intake and test-first discipline"
  warn_plugin ecc@ecc "reference checklists for the br-* agents"
  warn_plugin ponytail@ponytail "lean rules for br-planner, br-builder and br-review-lean"
  warn_skill orchestration "Orca multi-agent coordination"
  warn_skill orca-cli "Orca terminal and worktree control"
}

install_files() {
  local rel src dst added=0 updated=0 unchanged=0
  while IFS= read -r rel; do
    src="$REPO_DIR/$rel"
    dst="$TARGET/$rel"
    if [ -f "$dst" ] && cmp -s "$src" "$dst"; then
      unchanged=$((unchanged + 1))
      continue
    fi
    if [ -e "$dst" ]; then
      echo "update  $rel (old copy -> $BACKUP_DIR/$rel)"
      backup "$rel"
      updated=$((updated + 1))
    else
      echo "add     $rel"
      added=$((added + 1))
    fi
    run mkdir -p "$(dirname "$dst")"
    run cp "$src" "$dst"
  done < <(managed_files)
  echo "added $added, updated $updated, unchanged $unchanged in $TARGET"
}

# ponytail's hooks would inject its persona into the coordinator and every
# subagent; the workflow reads its SKILL.md files explicitly instead.
ensure_ponytail_off() {
  local cfg="${XDG_CONFIG_HOME:-$HOME/.config}/ponytail/config.json"
  if [ -n "${PONYTAIL_DEFAULT_MODE-}" ] && [ "$PONYTAIL_DEFAULT_MODE" != off ]; then
    warn "PONYTAIL_DEFAULT_MODE=$PONYTAIL_DEFAULT_MODE overrides $cfg: ponytail hooks stay on"
  fi
  if [ ! -e "$cfg" ]; then
    echo "add     $cfg (defaultMode off)"
    run mkdir -p "$(dirname "$cfg")"
    if [ "$DRY_RUN" -eq 0 ]; then
      printf '{"defaultMode": "off"}\n' > "$cfg"
    fi
  elif ! grep -Eq '"defaultMode"[[:space:]]*:[[:space:]]*"off"' "$cfg"; then
    warn "$cfg does not set \"defaultMode\": \"off\": ponytail hooks will steer every session and subagent"
  fi
}

uninstall_files() {
  local rel removed=0
  while IFS= read -r rel; do
    [ -e "$TARGET/$rel" ] || continue
    echo "remove  $rel (copy -> $BACKUP_DIR/$rel)"
    backup "$rel"
    run rm -f "$TARGET/$rel"
    removed=$((removed + 1))
  done < <(managed_files)
  echo "removed $removed from $TARGET"
}

[ "$DRY_RUN" -eq 1 ] && echo "dry run: nothing is written"

if [ "$UNINSTALL" -eq 1 ]; then
  uninstall_files
  exit 0
fi

check_prereqs
install_files
ensure_ponytail_off
[ "$WARNINGS" -gt 0 ] && echo "$WARNINGS prerequisite warning(s): the workflow degrades or stops at the phases above until they are installed."
echo "Open a NEW Claude Code session so it loads the br-* agents."
