#!/usr/bin/env bats

# Test file for uninstall.sh

setup() {
    export UNINSTALL_SCRIPT="$BATS_TEST_DIRNAME/../uninstall.sh"
    export TEST_INSTALL_DIR="$BATS_TMPDIR/test-install"
    export TEST_CONFIG_DIR="$BATS_TMPDIR/test-config"
    export TEST_CLAUDE_DIR="$BATS_TMPDIR/test-claude"
    
    # Create test directories and files
    mkdir -p "$TEST_INSTALL_DIR"
    mkdir -p "$TEST_CONFIG_DIR"
    mkdir -p "$TEST_CLAUDE_DIR"
    
    # Simulate installed files
    touch "$TEST_INSTALL_DIR/claude-notify"
    touch "$TEST_INSTALL_DIR/claude-notify.sh"
    touch "$TEST_INSTALL_DIR/claude-monitor.sh"
    touch "$TEST_INSTALL_DIR/claude-hook-processor.sh"
    touch "$TEST_INSTALL_DIR/setup-hooks.sh"
    mkdir -p "$TEST_INSTALL_DIR/lib"
    touch "$TEST_INSTALL_DIR/lib/test.sh"
    
    # Simulate config files
    echo '{"test": true}' > "$TEST_CONFIG_DIR/config.json"
    
    # Simulate Claude settings
    echo '{"hooks": {}}' > "$TEST_CLAUDE_DIR/settings.json"
    echo '{"hooks": {}}' > "$TEST_CLAUDE_DIR/settings.json.backup.20240101"
}

teardown() {
    rm -rf "$TEST_INSTALL_DIR" "$TEST_CONFIG_DIR" "$TEST_CLAUDE_DIR"
}

@test "uninstall.sh exists and is executable" {
    [ -f "$UNINSTALL_SCRIPT" ]
    [ -x "$UNINSTALL_SCRIPT" ]
}

@test "removes installed files from bin directory" {
    # Simulate uninstall with test directories
    INSTALL_DIR="$TEST_INSTALL_DIR" CONFIG_DIR="$TEST_CONFIG_DIR" run bash -c "
        export INSTALL_DIR='$TEST_INSTALL_DIR'
        export CONFIG_DIR='$TEST_CONFIG_DIR'
        echo 'y' | '$UNINSTALL_SCRIPT'
    "
    
    # Check files are removed
    [ ! -f "$TEST_INSTALL_DIR/claude-notify" ]
    [ ! -f "$TEST_INSTALL_DIR/claude-notify.sh" ]
    [ ! -f "$TEST_INSTALL_DIR/claude-monitor.sh" ]
    [ ! -d "$TEST_INSTALL_DIR/lib" ]
}

@test "prompts before removing config files" {
    # Test with 'n' response to keep config
    # Hide Claude dir to avoid extra prompts
    INSTALL_DIR="$TEST_INSTALL_DIR" CONFIG_DIR="$TEST_CONFIG_DIR" CLAUDE_DIR="/non/existent" run bash -c "
        export INSTALL_DIR='$TEST_INSTALL_DIR'
        export CONFIG_DIR='$TEST_CONFIG_DIR'
        export CLAUDE_DIR='/non/existent'
        printf 'y\nn\n' | '$UNINSTALL_SCRIPT'
    "
    
    # Config should still exist
    [ -f "$TEST_CONFIG_DIR/config.json" ]
}

@test "removes config files when confirmed" {
    # Test with 'y' response to remove config
    # Hide Claude dir and shell configs to avoid extra prompts
    INSTALL_DIR="$TEST_INSTALL_DIR" CONFIG_DIR="$TEST_CONFIG_DIR" CLAUDE_DIR="/non/existent" HOME="/non/existent" run bash -c "
        export INSTALL_DIR='$TEST_INSTALL_DIR'
        export CONFIG_DIR='$TEST_CONFIG_DIR'
        export CLAUDE_DIR='/non/existent'
        export HOME='/non/existent'
        printf 'yy' | '$UNINSTALL_SCRIPT'
    "
    
    # Config directory should be removed
    [ ! -d "$TEST_CONFIG_DIR" ] || [ ! -f "$TEST_CONFIG_DIR/config.json" ]
}

@test "offers to clean Claude hooks settings" {
    # Test hook cleanup
    INSTALL_DIR="$TEST_INSTALL_DIR" CLAUDE_DIR="$TEST_CLAUDE_DIR" run bash -c "
        export INSTALL_DIR='$TEST_INSTALL_DIR'
        export CLAUDE_DIR='$TEST_CLAUDE_DIR'
        echo -e 'y\ny\ny' | '$UNINSTALL_SCRIPT'
    "
    
    # Should run without error
    [ "$status" -eq 0 ]
}

@test "cancels uninstall when user declines" {
    # Test cancellation
    INSTALL_DIR="$TEST_INSTALL_DIR" run bash -c "
        export INSTALL_DIR='$TEST_INSTALL_DIR'
        echo 'n' | '$UNINSTALL_SCRIPT'
    "
    
    # Files should still exist
    [ -f "$TEST_INSTALL_DIR/claude-notify" ]
}

@test "handles missing directories gracefully" {
    # Test with non-existent directories
    run bash -c "
        export INSTALL_DIR='/non/existent/path'
        export CONFIG_DIR='/non/existent/config'
        echo 'y' | '$UNINSTALL_SCRIPT'
    "
    
    # Should not fail
    [ "$status" -eq 0 ]
}

@test "displays uninstall summary" {
    INSTALL_DIR="$TEST_INSTALL_DIR" run bash -c "
        export INSTALL_DIR='$TEST_INSTALL_DIR'
        echo -e 'y\ny\ny' | '$UNINSTALL_SCRIPT'
    "
    
    # Should show completion message
    [[ "$output" =~ "完成" ]] || [[ "$output" =~ "complete" ]]
}