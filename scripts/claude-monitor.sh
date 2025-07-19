#!/bin/bash

# Claude Monitor Script
# Monitors Claude output and sends notifications when questions are detected

# Get script directory
MONITOR_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$MONITOR_SCRIPT_DIR/.." && pwd )"

# Source libraries
source "$PROJECT_ROOT/lib/config-reader.sh"
source "$PROJECT_ROOT/lib/i18n.sh"
source "$PROJECT_ROOT/lib/keyword-detector.sh"

# Check if silent mode
if [[ "$1" != "--silent" ]]; then
    echo "$(get_text "monitor.started")"
    echo "$(get_text "monitor.info")"
    echo "$(get_text "monitor.exit")"
    echo "-----------------------------------"
fi

# Start monitoring with any passed arguments
monitor_for_keywords "$@"