#!/bin/bash

space_info=""
repo_name=""

# Get git repository name
if git rev-parse --is-inside-work-tree &>/dev/null; then
    repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
    if [ -n "$repo_root" ]; then
        repo_name=$(basename "$repo_root")
    fi
fi

# Get workspace info from yabai
if command -v yabai &> /dev/null; then
    term_pid=$$
    while [ "$term_pid" -gt 1 ]; do
        parent_pid=$(ps -o ppid= -p "$term_pid" 2>/dev/null | tr -d ' ')
        [ -z "$parent_pid" ] && break
        parent_name=$(ps -o comm= -p "$parent_pid" 2>/dev/null)
        if [[ "$parent_name" =~ (Terminal|iTerm|Alacritty|kitty|WezTerm|Ghostty) ]]; then
            term_pid=$parent_pid
            break
        fi
        term_pid=$parent_pid
    done

    win_json=$(yabai -m query --windows 2>/dev/null | \
               jq --arg pid "$term_pid" '[.[] | select(.pid == ($pid | tonumber))] | .[0] // empty')

    if [ -n "$win_json" ] && [ "$win_json" != "null" ]; then
        space_idx=$(echo "$win_json" | jq -r '.space')
        if [ -n "$space_idx" ] && [ "$space_idx" != "null" ]; then
            space_label=$(yabai -m query --spaces 2>/dev/null | \
                          jq -r --arg idx "$space_idx" '.[] | select(.index == ($idx | tonumber)) | .label // empty')
            if [ -n "$space_label" ]; then
                space_info="${space_idx}:${space_label}"
            else
                space_info="space ${space_idx}"
            fi
        fi
    fi
fi

# Build subtitle from space and repo
subtitle=""
if [ -n "$space_info" ]; then
    subtitle="$space_info"
fi
if [ -n "$repo_name" ]; then
    if [ -n "$subtitle" ]; then
        subtitle="${subtitle} ${repo_name}"
    else
        subtitle="$repo_name"
    fi
fi

# Send notification
message="$1"

if command -v notify-send &>/dev/null; then
    if [ -n "$subtitle" ]; then
        notify-send -title "Claude Code" -subtitle "$subtitle" \
          -message "$message" -sender com.anthropic.claudefordesktop
    else
        notify-send -title "Claude Code" -message "$message" \
          -sender com.anthropic.claudefordesktop
    fi
else
    # Fallback to osascript (ugly icon, but works)
    if [ -n "$subtitle" ]; then
        osascript -e "display notification \"${message}\" with title \"Claude Code\" subtitle \"${subtitle}\""
    else
        osascript -e "display notification \"${message}\" with title \"Claude Code\""
    fi
fi
