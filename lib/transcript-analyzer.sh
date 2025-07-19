#!/bin/bash

# Transcript Analyzer
# Analyzes Claude's conversation transcript to detect when user attention is needed

# Function to analyze the latest messages in transcript
analyze_transcript() {
    local transcript_path="$1"
    local session_id="$2"
    
    # Check if transcript file exists
    if [ ! -f "$transcript_path" ]; then
        return 1
    fi
    
    # Get the last few messages from Claude (look for assistant role)
    local recent_messages=$(tail -20 "$transcript_path" 2>/dev/null | jq -r 'select(.role == "assistant") | .content' 2>/dev/null | tail -5)
    
    # Keywords that indicate Claude needs user decision/permission
    local decision_keywords=(
        "permission.*denied"
        "request.*rejected"
        "blocked.*tool"
        "need.*permission"
        "require.*approval"
        "allow.*tool"
        "authorize"
        "confirm.*use"
        "Would you like me to"
        "Should I"
        "May I"
        "Can I"
        "要使用.*工具"
        "需要.*授權"
        "是否允許"
        "請確認"
    )
    
    # Check if any recent message contains decision keywords
    for keyword in "${decision_keywords[@]}"; do
        if echo "$recent_messages" | grep -iE "$keyword" >/dev/null 2>&1; then
            echo "$recent_messages" | grep -iE "$keyword" | tail -1
            return 0
        fi
    done
    
    return 1
}

# Export function for use in other scripts
export -f analyze_transcript