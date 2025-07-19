#!/bin/bash

# Script to setup Claude Code hooks for capturing test fixtures

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CAPTURE_SCRIPT="$SCRIPT_DIR/capture-hook-events.sh"

echo "Setting up Claude Code hooks for fixture capture mode..."

# Create temporary settings for capture mode
cat > /tmp/claude-capture-settings.json << EOF
{
  "hooks": {
    "Stop": [{
      "matcher": ".*",
      "hooks": [{
        "type": "command",
        "command": "$CAPTURE_SCRIPT"
      }]
    }],
    "UserPromptSubmit": [{
      "matcher": ".*",
      "hooks": [{
        "type": "command",
        "command": "$CAPTURE_SCRIPT"
      }]
    }],
    "PreToolUse": [{
      "matcher": ".*",
      "hooks": [{
        "type": "command",
        "command": "$CAPTURE_SCRIPT"
      }]
    }],
    "PostToolUse": [{
      "matcher": ".*",
      "hooks": [{
        "type": "command",
        "command": "$CAPTURE_SCRIPT"
      }]
    }]
  }
}
EOF

echo ""
echo "Capture mode settings created at: /tmp/claude-capture-settings.json"
echo ""
echo "To enable capture mode, update your Claude Code settings:"
echo "cp /tmp/claude-capture-settings.json ~/.claude/settings.json"
echo ""
echo "To restore normal mode, run:"
echo "./setup-hooks.sh"
echo ""
echo "Captured events will be saved to: tests/fixtures/hook-events/"