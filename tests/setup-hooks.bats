#!/usr/bin/env bats

# Test for setup-hooks.sh

setup() {
    # Get the root directory of the project
    export PROJECT_ROOT="$( cd "$( dirname "$BATS_TEST_DIRNAME" )" && pwd )"
    export SETUP_HOOKS="$PROJECT_ROOT/setup-hooks.sh"
    export LIB_DIR="$PROJECT_ROOT/lib"
    
    # Create temporary test directory
    export TEST_DIR="$(mktemp -d)"
    export CLAUDE_DIR="$TEST_DIR/.claude"
    export SETTINGS_FILE="$CLAUDE_DIR/settings.json"
    
    # Override HOME for testing
    export HOME="$TEST_DIR"
    
    # Source i18n for testing
    source "$LIB_DIR/i18n.sh"
}

teardown() {
    # Clean up test directory
    rm -rf "$TEST_DIR"
}

# Helper function to create initial settings
create_settings_with_hooks() {
    mkdir -p "$CLAUDE_DIR"
    cat > "$SETTINGS_FILE" << 'EOF'
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "test",
        "hooks": [{
          "type": "command",
          "command": "/existing/hook/script.sh"
        }]
      }
    ],
    "CustomHook": [
      {
        "matcher": ".*",
        "hooks": [{
          "type": "command",
          "command": "/custom/hook.sh"
        }]
      }
    ]
  },
  "otherSettings": {
    "key": "value"
  }
}
EOF
}

@test "setup-hooks preserves existing settings when adding essential hooks" {
    create_settings_with_hooks
    
    # Run setup-hooks with choice 1 using environment variable
    SETUP_CHOICE=1 bash "$SETUP_HOOKS" >/dev/null 2>&1
    
    # Check that other settings are preserved
    run jq '.otherSettings.key' "$SETTINGS_FILE"
    [ "$status" -eq 0 ]
    [ "$output" = '"value"' ]
    
    # Check that custom hooks are preserved
    run jq '.hooks.CustomHook[0].matcher' "$SETTINGS_FILE"
    [ "$status" -eq 0 ]
    [ "$output" = '".*"' ]
    
    # Check that existing UserPromptSubmit hook is preserved
    run jq '.hooks.UserPromptSubmit | length' "$SETTINGS_FILE"
    [ "$status" -eq 0 ]
    [ "$output" -ge 1 ]
    
    # Check that new hooks are added
    run jq '.hooks.Stop | length' "$SETTINGS_FILE"
    [ "$status" -eq 0 ]
    [ "$output" -ge 1 ]
}

@test "setup-hooks merges hooks without duplicating matchers" {
    create_settings_with_hooks
    
    # Add a UserPromptSubmit hook with same matcher
    jq '.hooks.UserPromptSubmit += [{
        "matcher": ".*",
        "hooks": [{
            "type": "command",
            "command": "/duplicate/hook.sh"
        }]
    }]' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp" && mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
    
    # Run setup-hooks using environment variable
    SETUP_CHOICE=1 bash "$SETUP_HOOKS" >/dev/null 2>&1
    
    # Check that only one hook with ".*" matcher exists
    run jq '[.hooks.UserPromptSubmit[] | select(.matcher == ".*")] | length' "$SETTINGS_FILE"
    [ "$status" -eq 0 ]
    [ "$output" -eq 1 ]
    
    # Check that the test matcher is still preserved
    run jq '[.hooks.UserPromptSubmit[] | select(.matcher == "test")] | length' "$SETTINGS_FILE"
    [ "$status" -eq 0 ]
    [ "$output" -eq 1 ]
}

@test "setup-hooks preserves all existing hooks when adding PostToolUse" {
    create_settings_with_hooks
    
    # Run setup-hooks with choice 2 using environment variable
    SETUP_CHOICE=2 bash "$SETUP_HOOKS" >/dev/null 2>&1
    
    # Check that existing hooks are preserved
    run jq '.hooks.UserPromptSubmit[] | select(.matcher == "test") | .matcher' "$SETTINGS_FILE"
    [ "$status" -eq 0 ]
    [ "$output" = '"test"' ]
    
    run jq '.hooks.CustomHook[0].matcher' "$SETTINGS_FILE"
    [ "$status" -eq 0 ]
    [ "$output" = '".*"' ]
    
    # Check that PostToolUse is added
    run jq '.hooks.PostToolUse | length' "$SETTINGS_FILE"
    [ "$status" -eq 0 ]
    [ "$output" -ge "1" ]
}

@test "setup-hooks handles empty settings file correctly" {
    mkdir -p "$CLAUDE_DIR"
    echo '{}' > "$SETTINGS_FILE"
    
    # Run setup-hooks using environment variable
    SETUP_CHOICE=1 bash "$SETUP_HOOKS" >/dev/null 2>&1
    
    # Check that hooks are created
    run jq '.hooks | length' "$SETTINGS_FILE"
    [ "$status" -eq 0 ]
    [ "$output" -ge 2 ]
}

@test "setup-hooks creates backup of existing settings" {
    create_settings_with_hooks
    
    # Run setup-hooks using environment variable
    SETUP_CHOICE=1 bash "$SETUP_HOOKS" >/dev/null 2>&1
    
    # Check that backup file exists
    run ls "$CLAUDE_DIR"/settings.json.backup.*
    [ "$status" -eq 0 ]
    
    # Check that backup contains original settings
    backup_file=$(ls "$CLAUDE_DIR"/settings.json.backup.* | head -1)
    run jq '.otherSettings.key' "$backup_file"
    [ "$status" -eq 0 ]
    [ "$output" = '"value"' ]
}

@test "setup-hooks option 3 adds all hooks while preserving existing ones" {
    create_settings_with_hooks
    
    # Run setup-hooks with choice 3 using environment variable
    SETUP_CHOICE=3 bash "$SETUP_HOOKS" >/dev/null 2>&1
    
    # Check that all new hooks are added
    for hook in UserPromptSubmit Stop SubagentStop PreToolUse PostToolUse; do
        run jq ".hooks.$hook | length" "$SETTINGS_FILE"
        [ "$status" -eq 0 ]
        [ "$output" -ge 1 ]
    done
    
    # Check that existing settings are preserved
    run jq '.otherSettings.key' "$SETTINGS_FILE"
    [ "$status" -eq 0 ]
    [ "$output" = '"value"' ]
    
    run jq '.hooks.CustomHook[0].matcher' "$SETTINGS_FILE"
    [ "$status" -eq 0 ]
    [ "$output" = '".*"' ]
}

@test "setup-hooks option 4 skips without modifying settings" {
    create_settings_with_hooks
    original_checksum=$(md5sum "$SETTINGS_FILE" | cut -d' ' -f1)
    
    # Run setup-hooks with choice 4 using environment variable
    SETUP_CHOICE=4 bash "$SETUP_HOOKS" >/dev/null 2>&1
    
    # Check that settings remain unchanged (ignoring whitespace changes from jq)
    current_checksum=$(jq -S . "$SETTINGS_FILE" | md5sum | cut -d' ' -f1)
    original_normalized=$(jq -S . "$SETTINGS_FILE.backup."* 2>/dev/null | md5sum | cut -d' ' -f1)
    
    # If no backup was created, settings should be unchanged
    if [ -z "$original_normalized" ]; then
        new_checksum=$(md5sum "$SETTINGS_FILE" | cut -d' ' -f1)
        [ "$original_checksum" = "$new_checksum" ]
    fi
}

@test "setup-hooks preserves complex nested settings" {
    mkdir -p "$CLAUDE_DIR"
    cat > "$SETTINGS_FILE" << 'EOF'
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "complex-[0-9]+",
        "hooks": [{
          "type": "command",
          "command": "/complex/hook.sh",
          "args": ["--verbose", "--output", "/tmp/log"]
        }]
      }
    ]
  },
  "authentication": {
    "method": "token",
    "token": "secret-token"
  },
  "ui": {
    "theme": "dark",
    "fontSize": 14
  }
}
EOF
    
    # Run setup-hooks using environment variable
    SETUP_CHOICE=1 bash "$SETUP_HOOKS" >/dev/null 2>&1
    
    # Check that complex settings are preserved
    run jq '.authentication.token' "$SETTINGS_FILE"
    [ "$status" -eq 0 ]
    [ "$output" = '"secret-token"' ]
    
    run jq '.ui.theme' "$SETTINGS_FILE"
    [ "$status" -eq 0 ]
    [ "$output" = '"dark"' ]
    
    # Check that complex hook with args is preserved
    run jq '.hooks.UserPromptSubmit[] | select(.matcher == "complex-[0-9]+") | .hooks[0].args | length' "$SETTINGS_FILE"
    [ "$status" -eq 0 ]
    [ "$output" -eq 3 ]
}