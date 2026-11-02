#!/bin/bash
# Apply this repo's herdr-board pipeline to a board. Idempotent: run it again after
# editing columns/*.md to push the new prompts, or on a new machine to rebuild the
# pipeline from scratch.
#
#   ./setup-board.sh                 # the currently selected board
#   ./setup-board.sh 2               # a board id
#   ./setup-board.sh /path/to/repo   # a project's board by scope path
#
# Columns, in order, and the gates between them:
#   Todo        manual - a human writes the task and picks the agent
#   Plan        auto   - plans only, asks questions, then waits for approval here
#   Doing       auto   - implements on branch card-<id>, hands off to Dev Review
#   Dev Review  auto   - commits, pushes, opens the PR, then waits here
#   Done        manual - a human lands it after the PR is approved
set -euo pipefail
cd "$(dirname "$0")"

BOARD=()
if [ $# -gt 0 ]; then
  # A path needs its project/board to exist first; `board board open` is an
  # idempotent get-or-create. A bare id or name is used as-is.
  case "$1" in
    /*) board board open "$1" --json >/dev/null ;;
  esac
  BOARD=(--board "$1")
fi

ensure() { # ensure <name> <position>
  board column show "$1" "${BOARD[@]}" --json >/dev/null 2>&1 \
    || board column create "${BOARD[@]}" --name "$1" --position "$2" --json >/dev/null
}
ensure Todo 0
ensure Plan 1
ensure Doing 2
ensure "Dev Review" 3
ensure Done 4

board column edit Todo "${BOARD[@]}" --trigger manual \
  --clear-prompt --clear-on-success --clear-on-fail --clear-timeout --json >/dev/null

board column edit Plan "${BOARD[@]}" --trigger auto \
  --prompt "$(cat columns/plan.md)" \
  --clear-on-success --on-fail Todo --clear-timeout --json >/dev/null

board column edit Doing "${BOARD[@]}" --trigger auto \
  --prompt "$(cat columns/doing.md)" \
  --on-success "Dev Review" --on-fail Todo --clear-timeout --json >/dev/null

board column edit "Dev Review" "${BOARD[@]}" --trigger auto \
  --prompt "$(cat columns/dev-review.md)" \
  --clear-on-success --on-fail Doing --clear-timeout --json >/dev/null

board column edit Done "${BOARD[@]}" --trigger manual \
  --clear-prompt --clear-on-success --clear-on-fail --clear-timeout --json >/dev/null

echo "pipeline applied:"
board column list "${BOARD[@]}"
