#!/bin/bash

# Script to capture hook events for test fixtures
# This intercepts hook events and saves them to fixtures directory
# Each session is saved in its own directory for better organization

# Debug: Log script execution
echo "[Capture Debug] Script started at $(date)" >> /tmp/capture-debug.log

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
FIXTURES_DIR="$SCRIPT_DIR/tests/fixtures/hook-events"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Read input from stdin
input=$(cat)

# Debug: Log received input
echo "[Capture Debug] Received input: ${input:0:100}..." >> /tmp/capture-debug.log

# Extract session_id and event name
session_id=$(echo "$input" | jq -r '.session_id // "unknown"')
event_name=$(echo "$input" | jq -r '.hook_event_name // "unknown"')

# Debug: Log extracted values
echo "[Capture Debug] Session: $session_id, Event: $event_name" >> /tmp/capture-debug.log

# Create session-specific directory
session_dir="$FIXTURES_DIR/$session_id"
mkdir -p "$session_dir"

# Save the event with timestamp and event name
output_file="$session_dir/${TIMESTAMP}_${event_name}.json"
echo "$input" | jq '.' > "$output_file"

echo "[Capture] Session: $session_id, Event: $event_name -> $output_file" >&2

# Also save transcript if available
transcript_path=$(echo "$input" | jq -r '.transcript_path // empty')
if [ -n "$transcript_path" ] && [ -f "$transcript_path" ]; then
    transcript_file="$session_dir/${TIMESTAMP}_${event_name}_transcript.jsonl"
    cp "$transcript_path" "$transcript_file"
    echo "[Capture] Transcript saved to: $transcript_file" >&2
fi

# Keep a log of all events in the session
log_file="$session_dir/events.log"
echo "[$TIMESTAMP] $event_name" >> "$log_file"

# Pass through to the real hook processor
"$SCRIPT_DIR/scripts/claude-hook-processor.sh" <<< "$input"