#!/usr/bin/env bats

# Test suite for claude-notify.sh using bats

setup() {
    # Setup test environment
    export SCRIPT_DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" && pwd )"
    export PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
    export CLAUDE_NOTIFY="$PROJECT_ROOT/claude-notify.sh"
    export CONFIG_FILE="$PROJECT_ROOT/config.json"
}

@test "claude-notify.sh exists and is executable" {
    [ -f "$CLAUDE_NOTIFY" ]
    [ -x "$CLAUDE_NOTIFY" ]
}

@test "fails when no arguments provided" {
    run "$CLAUDE_NOTIFY"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Usage:" ]]
}

@test "fails when only title provided" {
    run "$CLAUDE_NOTIFY" "Test Title"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Usage:" ]]
}

@test "succeeds with title and message" {
    run "$CLAUDE_NOTIFY" "Test Title" "Test Message"
    [ "$status" -eq 0 ]
}

@test "config.json exists" {
    [ -f "$CONFIG_FILE" ]
}

@test "config.json is valid JSON" {
    run jq '.' < "$CONFIG_FILE"
    [ "$status" -eq 0 ]
}

@test "notification with sound flag" {
    run "$CLAUDE_NOTIFY" "Test Title" "Test Message" --sound
    [ "$status" -eq 0 ]
}

@test "notification with speak flag" {
    run "$CLAUDE_NOTIFY" "Test Title" "Test Message" --speak
    [ "$status" -eq 0 ]
}

@test "notification with both sound and speak flags" {
    run "$CLAUDE_NOTIFY" "Test Title" "Test Message" --sound --speak
    [ "$status" -eq 0 ]
}

@test "terminal-notifier is available" {
    run which terminal-notifier
    [ "$status" -eq 0 ]
}

@test "afplay is available for sound" {
    run which afplay
    [ "$status" -eq 0 ]
}

@test "say command is available for text-to-speech" {
    run which say
    [ "$status" -eq 0 ]
}

@test "reads sound setting from config when no --sound flag" {
    # Create temp config with sound enabled
    export CONFIG_FILE="$BATS_TMPDIR/test-config.json"
    cat > "$CONFIG_FILE" <<EOF
{
  "notification": {
    "enabled": true,
    "sound": {
      "enabled": true,
      "file": "/System/Library/Sounds/Glass.aiff"
    },
    "speech": {
      "enabled": false
    }
  }
}
EOF
    run "$CLAUDE_NOTIFY" "Test" "Message" --config "$CONFIG_FILE"
    [ "$status" -eq 0 ]
}

@test "reads speech setting from config when no --speak flag" {
    # Create temp config with speech enabled
    export CONFIG_FILE="$BATS_TMPDIR/test-config.json"
    cat > "$CONFIG_FILE" <<EOF
{
  "notification": {
    "enabled": true,
    "sound": {
      "enabled": false
    },
    "speech": {
      "enabled": true,
      "voice": "Samantha"
    }
  }
}
EOF
    run "$CLAUDE_NOTIFY" "Test" "Message" --config "$CONFIG_FILE"
    [ "$status" -eq 0 ]
}