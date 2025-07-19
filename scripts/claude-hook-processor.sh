#!/bin/bash

# Claude Hook Processor for Notifications
# Processes hook events from Claude Code and triggers notifications

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
source "$PROJECT_ROOT/lib/config-reader.sh"
source "$PROJECT_ROOT/lib/notification-queue.sh"
source "$PROJECT_ROOT/lib/transcript-analyzer.sh"

# Allow overriding claude-notify path for testing
CLAUDE_NOTIFY="${CLAUDE_NOTIFY:-$PROJECT_ROOT/claude-notify}"

# Read JSON input from stdin
input=$(cat)

# Get logging configuration
logging_enabled=$(get_config_value "logging.enabled")
log_file=$(get_config_value "logging.file")
log_level=$(get_config_value "logging.level")

# Use default log file if not specified
if [ -z "$log_file" ]; then
    log_file="/tmp/claude-hook-debug.log"
fi

# Function to log messages
log_message() {
    local level="$1"
    local message="$2"
    
    # Check if logging is enabled
    if [ "$logging_enabled" != "true" ]; then
        return
    fi
    
    # Log based on level (info logs everything, debug only when DEBUG is set)
    case "$level" in
        "debug")
            if [ "${DEBUG:-}" = "true" ] || [ "$log_level" = "debug" ]; then
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" >> "$log_file"
            fi
            ;;
        *)
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" >> "$log_file"
            ;;
    esac
}

# Log the input
log_message "debug" "Input: $input"

# Extract hook event details from Claude Code format
hook_event_name=$(echo "$input" | jq -r '.hook_event_name // empty')
session_id=$(echo "$input" | jq -r '.session_id // empty')
cwd=$(echo "$input" | jq -r '.cwd // empty')

# Log extracted event details
log_message "info" "Event: $hook_event_name, Session: $session_id, CWD: $cwd"

# Extract event-specific fields
case "$hook_event_name" in
    "Stop"|"SubagentStop")
        message=$(echo "$input" | jq -r '.message // empty')
        response=$(echo "$input" | jq -r '.response // empty')
        ;;
    "PreToolUse"|"PostToolUse")
        tool_name=$(echo "$input" | jq -r '.tool_name // empty')
        tool_input=$(echo "$input" | jq '.tool_input // empty')
        tool_output=$(echo "$input" | jq '.tool_output // empty')
        ;;
    "Notification")
        message=$(echo "$input" | jq -r '.message // empty')
        ;;
    "PreCompact")
        # Handle context compaction event
        ;;
esac

# Special handling for blocked tools
blocked=$(echo "$input" | jq -r '.blocked // false')
error_message=$(echo "$input" | jq -r '.message // empty')

# Get project name from cwd or use current directory
if [ -n "$cwd" ]; then
    project_name=$(basename "$cwd")
else
    project_name=$(basename "$(pwd)")
fi

# Check if notifications are enabled
notification_enabled=$(get_config_value "notification.enabled")
if [ "$notification_enabled" = "false" ]; then
    log_message "info" "Notifications disabled, skipping"
    exit 0
fi

# Helper function to send notification
send_notification() {
    local title="$1"
    local message="$2"
    local sound="${3:-false}"
    
    if [ -n "$title" ] && [ -n "$message" ]; then
        # Truncate long messages
        if [ ${#message} -gt 100 ]; then
            message="${message:0:100}..."
        fi
        
        # Check if should queue
        if should_queue; then
            add_to_queue "$title" "$message"
            # Process queue after a delay
            (sleep 2 && process_and_send_queue) &
        else
            # Send immediately
            log_message "info" "Sending notification: $title - $message"
            if [ "$sound" = "true" ]; then
                "$CLAUDE_NOTIFY" "$title" "$message" --sound
            else
                "$CLAUDE_NOTIFY" "$title" "$message"
            fi
        fi
    fi
}

# Process queue and send consolidated notification
process_and_send_queue() {
    local result=$(process_queue "$project_name")
    
    if [ -n "$result" ]; then
        local type=$(echo "$result" | cut -d'|' -f1)
        local title=$(echo "$result" | cut -d'|' -f2)
        local message=$(echo "$result" | cut -d'|' -f3-)
        
        "$CLAUDE_NOTIFY" "$title" "$message" --sound
    fi
}

# Process based on hook event
case "$hook_event_name" in
    "Stop")
        # Claude finished execution - User wants to be notified when done
        title="$project_name"
        
        # Extract transcript path
        transcript_path=$(echo "$input" | jq -r '.transcript_path // empty')
        
        # Try to get the last assistant message from transcript if available
        if [ -n "$transcript_path" ] && [ -f "$transcript_path" ]; then
            # Extract last assistant message that might contain completion summary
            last_msg=$(tac "$transcript_path" 2>/dev/null | while IFS= read -r line; do
                if echo "$line" | jq -e '.role == "assistant"' >/dev/null 2>&1; then
                    content=$(echo "$line" | jq -r '.content // empty')
                    # Check if this looks like a completion summary
                    if echo "$content" | grep -qE "^(⏺|•|✓|已完成|已在|已更新|已新增|已修改|已建立)"; then
                        echo "$content"
                        break
                    fi
                fi
            done)
            
            if [ -n "$last_msg" ]; then
                msg="$last_msg"
                log_message "info" "Found completion summary from transcript"
            else
                msg="${response:-${message:-任務已完成，您可以回來查看結果了}}"
            fi
        else
            msg="${response:-${message:-任務已完成，您可以回來查看結果了}}"
        fi
        
        # Send notification with sound to alert user
        send_notification "$title" "$msg" true
        log_message "info" "Sent completion notification"
        ;;
        
    "SubagentStop")
        # Subagent completed - NO notification needed
        # User only cares about main task completion, not subtasks
        log_message "debug" "Subagent stopped: ${message:-no message}"
        ;;
        
    "PreToolUse")
        # Tool is about to be used - NO notification needed
        log_message "debug" "PreToolUse for ${tool_name}: ${error_message:-no message}"
        ;;
        
    "PostToolUse")
        # Tool was used successfully - optional notification
        # You can enable this if you want notifications for specific tools
        case "$tool_name" in
            "Write"|"Edit"|"MultiEdit")
                # Notify for file modifications
                if [ "$(get_config_value 'notification.file_changes')" = "true" ]; then
                    title="[$project_name] 檔案已修改"
                    file_path=$(echo "$tool_input" | jq -r '.file_path // empty')
                    if [ -n "$file_path" ]; then
                        msg="已修改: $(basename "$file_path")"
                        send_notification "$title" "$msg"
                    fi
                fi
                ;;
        esac
        ;;
        
    "Notification")
        # Process Notification events - Send notification when Claude needs user input
        title="[$project_name] 需要您的確認"
        notification_message=$(echo "$input" | jq -r '.notification.message // .message // empty')
        
        if [ -n "$notification_message" ]; then
            send_notification "$title" "$notification_message" true
            log_message "info" "Sent Notification event notification: $notification_message"
        else
            log_message "debug" "Notification event without message"
        fi
        ;;
        
    "PreCompact")
        # Context compaction - NO notification needed
        # This is internal housekeeping, not relevant to user
        log_message "debug" "Context compaction starting"
        ;;
esac

# Log script completion
log_message "debug" "Hook processor completed for event: $hook_event_name"

# Always exit successfully to avoid blocking Claude
exit 0