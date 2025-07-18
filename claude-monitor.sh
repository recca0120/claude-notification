#!/bin/bash

# Claude Monitor Script
# Monitors Claude output and sends notifications when questions are detected

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source libraries
source "$SCRIPT_DIR/lib/config-reader.sh"
source "$SCRIPT_DIR/lib/i18n.sh"
source "$SCRIPT_DIR/lib/keyword-detector.sh"

echo "$(get_text "monitor.started")"
echo "$(get_text "monitor.info")"
echo "$(get_text "monitor.exit")"
echo "-----------------------------------"

# Start monitoring
monitor_for_keywords