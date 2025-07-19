#!/usr/bin/env bats

# Test suite for config management commands

setup() {
    export SCRIPT_DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" && pwd )"
    export PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
    export CLAUDE_NOTIFY="$PROJECT_ROOT/claude-notify"
    export TEST_CONFIG="$BATS_TMPDIR/test-config.json"
    
    # Create a test config
    cat > "$TEST_CONFIG" <<EOF
{
  "notification": {
    "enabled": true,
    "sound": {
      "enabled": false,
      "file": "/System/Library/Sounds/Glass.aiff"
    },
    "speech": {
      "enabled": false,
      "voice": "Samantha",
      "rate": 200
    }
  },
  "triggers": {
    "keywords": ["test"]
  }
}
EOF
}

teardown() {
    rm -f "$TEST_CONFIG"
}

@test "claude-notify executable exists" {
    [ -f "$CLAUDE_NOTIFY" ]
    [ -x "$CLAUDE_NOTIFY" ]
}

@test "config get command" {
    run "$CLAUDE_NOTIFY" config get notification.enabled --config "$TEST_CONFIG"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "config set command" {
    run "$CLAUDE_NOTIFY" config set notification.sound.enabled true --config "$TEST_CONFIG"
    [ "$status" -eq 0 ]
    
    # Verify the change
    run "$CLAUDE_NOTIFY" config get notification.sound.enabled --config "$TEST_CONFIG"
    [ "$output" = "true" ]
}

@test "config list command" {
    run "$CLAUDE_NOTIFY" config list --config "$TEST_CONFIG"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "notification.enabled: true" ]]
}

@test "config add keyword" {
    run "$CLAUDE_NOTIFY" config add-keyword "新關鍵字" --config "$TEST_CONFIG"
    [ "$status" -eq 0 ]
    
    # Verify keyword was added
    run "$CLAUDE_NOTIFY" config get triggers.keywords --config "$TEST_CONFIG"
    [[ "$output" =~ "新關鍵字" ]]
}

@test "config remove keyword" {
    # First add a keyword
    "$CLAUDE_NOTIFY" config add-keyword "要刪除的" --config "$TEST_CONFIG"
    
    # Then remove it
    run "$CLAUDE_NOTIFY" config remove-keyword "要刪除的" --config "$TEST_CONFIG"
    [ "$status" -eq 0 ]
}

@test "config reset to defaults" {
    # Change a value
    "$CLAUDE_NOTIFY" config set notification.sound.enabled true --config "$TEST_CONFIG"
    
    # Reset
    run "$CLAUDE_NOTIFY" config reset --config "$TEST_CONFIG"
    [ "$status" -eq 0 ]
    
    # Verify reset
    run "$CLAUDE_NOTIFY" config get notification.sound.enabled --config "$TEST_CONFIG"
    [ "$output" = "true" ]  # Default value
}

@test "help command" {
    run "$CLAUDE_NOTIFY" --help
    [ "$status" -eq 0 ]
    # Check for either Chinese or English usage text
    [[ "$output" =~ "Usage" ]] || [[ "$output" =~ "使用方式" ]]
}

@test "version command" {
    run "$CLAUDE_NOTIFY" --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "claude-notify" ]]
}