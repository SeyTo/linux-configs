#!/bin/bash
# Read JSON data that Claude Code sends to stdin
input=$(cat)

# Extract fields using jq
MODEL=$(echo "$input" | jq -r '.model.display_name')
DIR=$(echo "$input" | jq -r '.workspace.current_dir')
# The "// 0" provides a fallback if the field is null
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)

# Rate limit usage (5-hour / 7-day). Optional fields; only render if present.
NOW=$(date +%s)

FIVE_PCT=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
FIVE_RESET=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
RATE_SEG=""
if [ -n "$FIVE_PCT" ]; then
  FIVE_PCT_R=$(printf '%.0f' "$FIVE_PCT")
  FIVE_LEFT=$((FIVE_RESET - NOW))
  [ "$FIVE_LEFT" -lt 0 ] && FIVE_LEFT=0
  FIVE_H=$((FIVE_LEFT / 3600))
  FIVE_M=$(((FIVE_LEFT % 3600) / 60))
  RATE_SEG="${RATE_SEG} | ${FIVE_PCT_R}% (rst ${FIVE_H}h${FIVE_M}m)"
fi

WEEK_PCT=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
WEEK_RESET=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')
if [ -n "$WEEK_PCT" ]; then
  WEEK_PCT_R=$(printf '%.0f' "$WEEK_PCT")
  WEEK_LEFT=$((WEEK_RESET - NOW))
  [ "$WEEK_LEFT" -lt 0 ] && WEEK_LEFT=0
  WEEK_D=$((WEEK_LEFT / 86400))
  WEEK_H=$(((WEEK_LEFT % 86400) / 3600))
  RATE_SEG="${RATE_SEG} | ${WEEK_PCT_R}% (rst ${WEEK_D}d${WEEK_H}h)"
fi

# Output the status line - ${DIR##*/} extracts just the folder name
echo "kush: [$MODEL] 📁 ${DIR##*/} | ${PCT}% context${RATE_SEG}"
