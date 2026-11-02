#!/usr/bin/env bash
# Claude Code hook -> Omarchy desktop notification.
# Wire the same script to several events; it branches on .hook_event_name.
# Clicking a toast focuses the terminal window running that Claude session.
#
# Env toggles:
#   CLAUDE_NOTIFY_WHEN_FOCUSED=1  also notify when the Claude terminal is the active window
#   CLAUDE_NOTIFY_DISABLE=1       silence everything
set -u

[ "${CLAUDE_NOTIFY_DISABLE:-0}" = 1 ] && exit 0
command -v omarchy-notification-send >/dev/null || exit 0

input=$(cat)
field() { printf '%s' "$input" | jq -r "$1 // empty" 2>/dev/null; }

event=$(field .hook_event_name)
session=$(field .session_id)
cwd=$(field .cwd)
project=$(basename "${cwd:-$PWD}")
title=$(field .session_title)
label=${title:-$project}

# Find the Hyprland client (terminal window) that owns this Claude process.
term_pid=""
if command -v hyprctl >/dev/null; then
  client_pids=" $(hyprctl clients -j 2>/dev/null | jq -r '.[].pid' | tr '\n' ' ') "
  pid=$PPID
  while [ -n "$pid" ] && [ "$pid" -gt 1 ]; do
    case $client_pids in *" $pid "*) term_pid=$pid; break ;; esac
    pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
  done
fi

terminal_focused() {
  [ -n "$term_pid" ] || return 1
  [ "$(hyprctl activewindow -j 2>/dev/null | jq -r '.pid')" = "$term_pid" ]
}

# Last assistant text for the Stop toast (field on newer versions, else transcript).
last_message() {
  local msg transcript
  msg=$(field .last_assistant_message)
  if [ -z "$msg" ]; then
    transcript=$(field .transcript_path)
    [ -f "$transcript" ] && msg=$(tail -n 200 "$transcript" |
      jq -rs '[.[] | select(.type == "assistant") | .message.content[]? | select(.type == "text") | .text] | last // empty' 2>/dev/null)
  fi
  printf '%s' "$msg" | tr '\n' ' ' | sed 's/  */ /g' | cut -c1-180
}

glyph="󰚩" urgency=low body="" skip_if_focused=0
case $event in
  Notification)
    body=$(field .message)
    case $(field .notification_type) in
      permission_prompt)  glyph="󰌾" urgency=critical head="Permission needed" ;;
      idle_prompt)        glyph="󰂚" urgency=normal   head="Waiting for your input"; skip_if_focused=1 ;;
      elicitation_dialog) glyph="󰋗" urgency=normal   head="Question for you" ;;
      auth_success)       glyph="󰄬"                  head="Authenticated" ;;
      *)                  glyph="󰂚" urgency=normal   head="Claude needs attention" ;;
    esac ;;
  Stop)
    glyph="󰄬" head="Done"; body=$(last_message); skip_if_focused=1 ;;
  StopFailure)
    glyph="󰀦" urgency=critical head="Turn failed"
    body=$(field '.error // .reason // .message') ;;
  SubagentStop)
    glyph="󰜎" head="Subagent finished"; body=$(field .agent_type); skip_if_focused=1 ;;
  TaskCompleted)
    glyph="󰄬" head="Task completed"; body=$(field '.task_subject // .task.subject // .subject') ;;
  PreCompact)
    glyph="󰀼" head="Compacting context ($(field .trigger))" ;;
  SessionStart)
    glyph="󰐊" head="Session started ($(field .source))"; skip_if_focused=1 ;;
  SessionEnd)
    glyph="󰅖" head="Session ended"; body=$(field .reason) ;;
  *)
    head=${event:-Claude Code} ;;
esac

if [ "$skip_if_focused" = 1 ] && [ "${CLAUDE_NOTIFY_WHEN_FOCUSED:-0}" != 1 ] && terminal_focused; then
  exit 0
fi

# One toast per session, replaced in place instead of stacking.
state_dir="${XDG_RUNTIME_DIR:-/tmp}/claude-notify"
mkdir -p "$state_dir"
id_file="$state_dir/${session:-default}.id"
replace_id=$(cat "$id_file" 2>/dev/null || echo 0)

args=(--app-name "Claude Code" -g "$glyph" -u "$urgency" -r "$replace_id" -p)
[ "$urgency" = critical ] || args+=(-t 8000)
args+=("Claude · $label — $head" "$body")
[ -n "$term_pid" ] && args+=(--exec hyprctl dispatch focuswindow "pid:$term_pid")

new_id=$(omarchy-notification-send "${args[@]}" 2>/dev/null) && printf '%s\n' "$new_id" >"$id_file"
[ "$event" = SessionEnd ] && rm -f "$id_file"
exit 0
