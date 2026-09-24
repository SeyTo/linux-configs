#!/usr/bin/env bash
# UserPromptSubmit hook: name the session after its first real question,
# the same way /rename does (hookSpecificOutput.sessionTitle -> nameSource "hook").
set -u
input=$(cat)

# Claude Code passes the current title; if one exists this is not the first
# question (or the user already renamed by hand) -- leave it alone.
existing=$(printf '%s' "$input" | jq -r '.session_title // ""')
[ -n "$existing" ] && { printf '{}\n'; exit 0; }

prompt=$(printf '%s' "$input" | jq -r '.prompt // ""')

# Skip slash commands, so opening with /resume or /model does not become the name.
case "$prompt" in
  /*|'') printf '{}\n'; exit 0 ;;
esac

title=$(printf '%s' "$prompt" \
  | tr '\n' ' ' \
  | tr -cs 'A-Za-z0-9' ' ' \
  | awk '{ for (i = 1; i <= NF && i <= 7; i++) printf "%s%s", (i > 1 ? "-" : ""), tolower($i) }' \
  | cut -c1-48)

[ -z "$title" ] && { printf '{}\n'; exit 0; }

jq -nc --arg t "$title" \
  '{hookSpecificOutput:{hookEventName:"UserPromptSubmit",sessionTitle:$t}}'
