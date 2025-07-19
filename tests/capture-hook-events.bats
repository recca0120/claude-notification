#!/usr/bin/env bats

# Test for capture-hook-events.sh - captures hook events for test fixtures

setup() {
    export SCRIPT_DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" && pwd )"
    export PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
    export CAPTURE_SCRIPT="$PROJECT_ROOT/capture-hook-events.sh"
    export FIXTURES_DIR="$BATS_TMPDIR/test-fixtures/hook-events"
    
    # Override fixtures directory for testing
    export FIXTURES_DIR_OVERRIDE="$FIXTURES_DIR"
    
    # Create mock hook processor
    export MOCK_PROCESSOR="$BATS_TMPDIR/mock-hook-processor.sh"
    cat > "$MOCK_PROCESSOR" << 'EOF'
#!/bin/bash
# Mock hook processor that logs calls
echo "Mock processor called" >> "$BATS_TMPDIR/mock-processor.log"
cat > "$BATS_TMPDIR/mock-processor-input.json"
EOF
    chmod +x "$MOCK_PROCESSOR"
    
    # Create test capture script with overrides
    export TEST_CAPTURE="$BATS_TMPDIR/test-capture.sh"
    # Use proper escaping for sed replacement
    sed "s|^\(FIXTURES_DIR=\).*|\1\"$FIXTURES_DIR\"|; s|\"\$SCRIPT_DIR/scripts/claude-hook-processor.sh\"|\"$MOCK_PROCESSOR\"|" "$CAPTURE_SCRIPT" > "$TEST_CAPTURE"
    chmod +x "$TEST_CAPTURE"
}

teardown() {
    rm -rf "$FIXTURES_DIR" "$MOCK_PROCESSOR" "$TEST_CAPTURE" "$BATS_TMPDIR/mock-processor.log" "$BATS_TMPDIR/mock-processor-input.json"
}

@test "Capture creates session-specific directory" {
    local test_input=$(jq -n '{
        "hook_event_name": "Stop",
        "session_id": "test-session-123",
        "cwd": "/test/project"
    }')
    
    echo "$test_input" | "$TEST_CAPTURE"
    
    # Verify session directory was created
    [ -d "$FIXTURES_DIR/test-session-123" ]
}

@test "Capture saves event with timestamp and event name" {
    local test_input=$(jq -n '{
        "hook_event_name": "UserPromptSubmit",
        "session_id": "test-session-456",
        "prompt": "Test prompt"
    }')
    
    echo "$test_input" | "$TEST_CAPTURE"
    
    # Verify event file was created
    local files=("$FIXTURES_DIR/test-session-456"/*_UserPromptSubmit.json)
    [ -f "${files[0]}" ]
    
    # Verify content is correct
    local saved_content=$(cat "${files[0]}")
    echo "$saved_content" | jq -e '.session_id == "test-session-456"'
    echo "$saved_content" | jq -e '.hook_event_name == "UserPromptSubmit"'
    echo "$saved_content" | jq -e '.prompt == "Test prompt"'
}

@test "Capture saves transcript when available" {
    # Create a test transcript
    local transcript_file="$BATS_TMPDIR/test-transcript.jsonl"
    cat > "$transcript_file" << 'EOF'
{"role": "user", "content": "Test question"}
{"role": "assistant", "content": "Test answer"}
EOF
    
    local test_input=$(jq -n \
        --arg transcript "$transcript_file" \
        '{
            "hook_event_name": "Stop",
            "session_id": "session-with-transcript",
            "transcript_path": $transcript
        }')
    
    echo "$test_input" | "$TEST_CAPTURE"
    
    # Verify transcript was saved
    local transcript_files=("$FIXTURES_DIR/session-with-transcript"/*_Stop_transcript.jsonl)
    [ -f "${transcript_files[0]}" ]
    
    # Verify content matches
    diff "$transcript_file" "${transcript_files[0]}"
}

@test "Capture creates event log for session" {
    local session_id="log-test-session"
    
    # Send multiple events
    echo '{"hook_event_name": "UserPromptSubmit", "session_id": "'$session_id'"}' | "$TEST_CAPTURE"
    sleep 1
    echo '{"hook_event_name": "PreToolUse", "session_id": "'$session_id'"}' | "$TEST_CAPTURE"
    sleep 1
    echo '{"hook_event_name": "Stop", "session_id": "'$session_id'"}' | "$TEST_CAPTURE"
    
    # Verify log file exists
    local log_file="$FIXTURES_DIR/$session_id/events.log"
    [ -f "$log_file" ]
    
    # Verify log contains all events
    grep -q "UserPromptSubmit" "$log_file"
    grep -q "PreToolUse" "$log_file"
    grep -q "Stop" "$log_file"
    
    # Verify chronological order
    [ $(wc -l < "$log_file") -eq 3 ]
}

@test "Capture passes input to real hook processor" {
    local test_input=$(jq -n '{
        "hook_event_name": "PostToolUse",
        "session_id": "passthrough-test",
        "tool_name": "Bash"
    }')
    
    echo "$test_input" | "$TEST_CAPTURE"
    
    # Verify mock processor was called
    [ -f "$BATS_TMPDIR/mock-processor.log" ]
    grep -q "Mock processor called" "$BATS_TMPDIR/mock-processor.log"
    
    # Verify input was passed correctly
    [ -f "$BATS_TMPDIR/mock-processor-input.json" ]
    local passed_input=$(cat "$BATS_TMPDIR/mock-processor-input.json")
    echo "$passed_input" | jq -e '.session_id == "passthrough-test"'
    echo "$passed_input" | jq -e '.tool_name == "Bash"'
}

@test "Capture handles missing session_id gracefully" {
    local test_input=$(jq -n '{
        "hook_event_name": "Stop"
    }')
    
    echo "$test_input" | "$TEST_CAPTURE"
    
    # Should create directory with "unknown" session
    [ -d "$FIXTURES_DIR/unknown" ]
}

@test "Capture outputs debug messages to stderr" {
    local test_input=$(jq -n '{
        "hook_event_name": "Stop",
        "session_id": "debug-test"
    }')
    
    # Capture stderr output
    local output=$(echo "$test_input" | "$TEST_CAPTURE" 2>&1 >/dev/null)
    
    # Debug: show actual output
    echo "Debug output: $output" >&2
    
    # Verify debug output contains expected messages
    echo "$output" | grep -q "\[Capture\] Session: debug-test"
    echo "$output" | grep -q "Event: Stop"
}