#!/bin/bash

# Keyword detection for Claude notifications
# Checks if message contains trigger keywords from config

# Source the config reader and i18n
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/config-reader.sh"
source "$SCRIPT_DIR/i18n.sh"

# Function to check if text contains any configured keywords
check_for_keywords() {
    local text="$1"
    local keywords
    
    # Get keywords from config
    keywords=$(get_config_array "triggers.keywords")
    
    if [ -z "$keywords" ]; then
        return 1
    fi
    
    # Check each keyword
    while IFS= read -r keyword; do
        if [[ "$text" == *"$keyword"* ]]; then
            return 0
        fi
    done <<< "$keywords"
    
    return 1
}

# Function to monitor input and trigger notifications
monitor_for_keywords() {
    local line
    local silent_mode=false
    
    # Check for silent mode flag
    if [[ "$1" == "--silent" ]]; then
        silent_mode=true
    fi
    
    while IFS= read -r line; do
        # Pass through the input only if not in silent mode
        if [[ "$silent_mode" == "false" ]]; then
            echo "$line"
        fi
        
        if check_for_keywords "$line"; then
            # Extract a preview of the message
            local preview="${line:0:100}"
            if [ ${#line} -gt 100 ]; then
                preview="${preview}..."
            fi
            
            # Send notification
            local title=$(get_text "monitor.notification_title")
            "$SCRIPT_DIR/../claude-notify.sh" "$title" "$preview" &
        fi
    done
}