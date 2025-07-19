#!/usr/bin/env bats

# Test file for notification-queue.sh

setup() {
    export QUEUE_LIB="$BATS_TEST_DIRNAME/../lib/notification-queue.sh"
    source "$QUEUE_LIB"
    
    # Use test-specific queue directory
    export QUEUE_DIR="$BATS_TMPDIR/test-queue"
    export QUEUE_FILE="$QUEUE_DIR/queue.txt"
    export LOCK_FILE="$QUEUE_DIR/queue.lock"
    
    # Clean up before each test
    rm -rf "$QUEUE_DIR"
}

teardown() {
    rm -rf "$QUEUE_DIR"
}

@test "notification-queue.sh exists" {
    [ -f "$QUEUE_LIB" ]
}

@test "ensure_queue_dir creates directory" {
    [ ! -d "$QUEUE_DIR" ]
    ensure_queue_dir
    [ -d "$QUEUE_DIR" ]
}

@test "add_to_queue adds notification" {
    add_to_queue "Test Title" "Test Message"
    [ -f "$QUEUE_FILE" ]
    
    local content=$(cat "$QUEUE_FILE")
    [[ "$content" =~ "Test Title" ]]
    [[ "$content" =~ "Test Message" ]]
}

@test "get_queue retrieves and clears notifications" {
    add_to_queue "Title 1" "Message 1"
    add_to_queue "Title 2" "Message 2"
    
    local queue=$(get_queue)
    [[ "$queue" =~ "Title 1" ]]
    [[ "$queue" =~ "Title 2" ]]
    
    # Queue should be empty after retrieval
    [ ! -s "$QUEUE_FILE" ] || [ ! -f "$QUEUE_FILE" ]
}

@test "process_queue returns single notification as-is" {
    add_to_queue "Single Title" "Single Message"
    
    local result=$(process_queue "TestProject")
    [[ "$result" =~ "single|Single Title|Single Message" ]]
}

@test "process_queue consolidates multiple notifications" {
    add_to_queue "Title 1" "Message 1"
    add_to_queue "Title 2" "Message 2"
    add_to_queue "Title 3" "Message 3"
    
    local result=$(process_queue "TestProject")
    [[ "$result" =~ "consolidated" ]]
    [[ "$result" =~ "有 3 個通知" ]]
}

@test "should_queue returns true for rapid notifications" {
    # First notification should not queue
    run should_queue
    [ "$status" -eq 1 ]
    
    # Immediate second notification should queue
    run should_queue
    [ "$status" -eq 0 ]
}

@test "queue respects MAX_QUEUE_SIZE" {
    # Add more than MAX_QUEUE_SIZE notifications
    for i in {1..15}; do
        add_to_queue "Title $i" "Message $i"
    done
    
    local queue=$(get_queue)
    local count=$(echo "$queue" | wc -l | tr -d ' ')
    
    # Should only keep last MAX_QUEUE_SIZE items
    [ "$count" -le "$MAX_QUEUE_SIZE" ]
}

@test "lock mechanism prevents concurrent access" {
    acquire_lock
    
    # Second acquire should fail
    local result
    if acquire_lock 1; then
        result="acquired"
    else
        result="failed"
    fi
    
    [ "$result" = "failed" ]
    
    release_lock
    
    # Now should succeed
    acquire_lock
    release_lock
}

@test "cleanup_queue removes old files" {
    ensure_queue_dir
    
    # Create an old file
    touch -t 202301010000 "$QUEUE_DIR/old_file"
    
    cleanup_queue
    
    # Old file should be removed
    [ ! -f "$QUEUE_DIR/old_file" ]
}