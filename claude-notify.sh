#!/bin/bash

# Claude Notification Script
# Sends notifications when Claude asks questions

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source config reader
source "$SCRIPT_DIR/lib/config-reader.sh"

# Default values
TITLE="$1"
MESSAGE="$2"
SOUND_ENABLED=false
SPEAK_ENABLED=false
SOUND_FILE="/System/Library/Sounds/Glass.aiff"
CUSTOM_CONFIG=""

# Parse command line arguments
shift 2  # Remove title and message from arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --sound)
            SOUND_ENABLED=true
            shift
            ;;
        --speak)
            SPEAK_ENABLED=true
            shift
            ;;
        --config)
            CUSTOM_CONFIG="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

# Override CONFIG_FILE if custom config provided
if [ -n "$CUSTOM_CONFIG" ]; then
    export CONFIG_FILE="$CUSTOM_CONFIG"
fi

# Read settings from config if not overridden by command line
if [ "$SOUND_ENABLED" = "false" ]; then
    CONFIG_SOUND=$(get_config_value "notification.sound.enabled")
    if [ "$CONFIG_SOUND" = "true" ]; then
        SOUND_ENABLED=true
        SOUND_FILE=$(get_config_value "notification.sound.file" || echo "$SOUND_FILE")
    fi
fi

if [ "$SPEAK_ENABLED" = "false" ]; then
    CONFIG_SPEAK=$(get_config_value "notification.speech.enabled")
    if [ "$CONFIG_SPEAK" = "true" ]; then
        SPEAK_ENABLED=true
    fi
fi

# Validate required parameters
if [ -z "$TITLE" ] || [ -z "$MESSAGE" ]; then
    echo "Usage: $0 <title> <message> [--sound] [--speak]"
    exit 1
fi

# Send notification using terminal-notifier
terminal-notifier -title "$TITLE" -message "$MESSAGE" -sender com.anthropic.claude

# Play sound if enabled
if [ "$SOUND_ENABLED" = true ]; then
    afplay "$SOUND_FILE" &
fi

# Speak message if enabled
if [ "$SPEAK_ENABLED" = true ]; then
    say "$MESSAGE" &
fi

exit 0