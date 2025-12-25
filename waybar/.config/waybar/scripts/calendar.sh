#!/bin/bash

# Fetch agenda in TSV format for reliable parsing (from now to end of day)
RAW_DATA=$(gcalcli agenda now 11:59pm --details all --nocolor --tsv 2>/dev/null)

# Current time minus 10 minutes (show in-progress events for first 10 min)
CUTOFF_SECS=$(($(date +%s) - 600))

# Find the first event that started less than 10 min ago or hasn't started
EVENT=""
while IFS= read -r line; do
    START_TIME=$(echo "$line" | cut -f3)
    EVENT_SECS=$(date -d "today $START_TIME" +%s 2>/dev/null)
    if [ -n "$EVENT_SECS" ] && [ "$EVENT_SECS" -gt "$CUTOFF_SECS" ]; then
        EVENT="$line"
        break
    fi
done < <(echo "$RAW_DATA" | tail -n +2)

# If no upcoming event found, output empty JSON
if [ -z "$EVENT" ]; then
    echo '{"text":"","tooltip":"No upcoming events"}'
    exit 0
fi

# Parse TSV columns (1-indexed):
# 3: start_time, 7: hangout_link, 9: conference_uri, 10: title
TIME=$(echo "$EVENT" | cut -f3)
TITLE=$(echo "$EVENT" | cut -f10)
HANGOUT_LINK=$(echo "$EVENT" | cut -f7)
CONFERENCE_LINK=$(echo "$EVENT" | cut -f9)

# Count remaining events today
EVENT_COUNT=$(echo "$RAW_DATA" | tail -n +2 | wc -l)

# Determine prefix and text based on event timing
NOW_SECS=$(date +%s)
EVENT_SECS=$(date -d "today $TIME" +%s 2>/dev/null)
ONE_HOUR=$((NOW_SECS + 3600))

if [ "$EVENT_SECS" -le "$NOW_SECS" ]; then
    DISPLAY_TEXT="now: $TITLE  "
elif [ "$EVENT_SECS" -gt "$ONE_HOUR" ]; then
    DISPLAY_TEXT="today: $EVENT_COUNT  "
else
    DISPLAY_TEXT="next: $TITLE $TIME  "
fi

# Prefer conference link, fallback to hangout link
LINK="${CONFERENCE_LINK:-$HANGOUT_LINK}"

# Create JSON using jq (compact output for waybar)
jq -cn \
  --arg text "$DISPLAY_TEXT" \
  --arg tooltip "Event: $TITLE\nTime: $TIME\nLink: $LINK" \
  --arg link "$LINK" \
  '{text: $text, tooltip: $tooltip, alt: $link}'
