#!/usr/bin/env bash
# SessionStart hook: give every new CLI session its own prompt-bar colour.
# Works by feeding Claude Code an initial user message that is the /color
# slash command, which the prompt pipeline dispatches before the first turn.
set -u
input=$(cat)

source_kind=$(printf '%s' "$input" | jq -r '.source // ""')
case "$source_kind" in
  startup|clear) ;;                       # fresh conversation -> new colour
  *) printf '{}\n'; exit 0 ;;             # resume/compact -> keep the old one
esac

COLORS=(red blue green yellow purple orange pink cyan)
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/claude-session-color"
mkdir -p "$(dirname "$STATE")"

# Round-robin so two sessions started back to back never match.
n=$(cat "$STATE" 2>/dev/null || echo 0)
case "$n" in ''|*[!0-9]*) n=0 ;; esac
color=${COLORS[$((n % ${#COLORS[@]}))]}
echo $(( (n + 1) % 1000 )) > "$STATE"

jq -nc --arg cmd "/color $color" \
  '{hookSpecificOutput:{hookEventName:"SessionStart",initialUserMessage:$cmd}}'
