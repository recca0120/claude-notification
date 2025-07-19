#!/bin/bash

# Notification Queue Manager
# Manages notification queuing and deduplication

QUEUE_DIR="${TMPDIR:-/tmp}/claude-notifications"
QUEUE_FILE="$QUEUE_DIR/queue.txt"
LOCK_FILE="$QUEUE_DIR/queue.lock"
MAX_QUEUE_SIZE=10
QUEUE_TIMEOUT=5  # seconds

# Ensure queue directory exists
ensure_queue_dir() {
    mkdir -p "$QUEUE_DIR"
}

# Acquire lock with timeout
acquire_lock() {
    local timeout="${1:-5}"
    local count=0
    
    while [ -f "$LOCK_FILE" ] && [ $count -lt $timeout ]; do
        sleep 0.1
        count=$((count + 1))
    done
    
    if [ $count -ge $timeout ]; then
        return 1
    fi
    
    ensure_queue_dir
    echo $$ > "$LOCK_FILE"
    return 0
}

# Release lock
release_lock() {
    rm -f "$LOCK_FILE"
}

# Add notification to queue
add_to_queue() {
    local title="$1"
    local message="$2"
    local timestamp=$(date +%s)
    
    ensure_queue_dir
    
    if acquire_lock; then
        # Add to queue with timestamp
        echo "${timestamp}|${title}|${message}" >> "$QUEUE_FILE"
        
        # Trim queue if too large
        if [ -f "$QUEUE_FILE" ]; then
            tail -n $MAX_QUEUE_SIZE "$QUEUE_FILE" > "$QUEUE_FILE.tmp"
            mv "$QUEUE_FILE.tmp" "$QUEUE_FILE"
        fi
        
        release_lock
        return 0
    else
        return 1
    fi
}

# Get queued notifications
get_queue() {
    ensure_queue_dir
    
    if [ ! -f "$QUEUE_FILE" ]; then
        return 1
    fi
    
    if acquire_lock; then
        if [ -f "$QUEUE_FILE" ]; then
            cat "$QUEUE_FILE"
            > "$QUEUE_FILE"  # Clear queue after reading
        fi
        release_lock
        return 0
    else
        return 1
    fi
}

# Process queue and send consolidated notification
process_queue() {
    local notifications=$(get_queue)
    
    if [ -z "$notifications" ]; then
        return 1
    fi
    
    local count=$(echo "$notifications" | wc -l | tr -d ' ')
    local project_name="$1"
    
    if [ "$count" -eq 1 ]; then
        # Single notification, send as-is
        local title=$(echo "$notifications" | cut -d'|' -f2)
        local message=$(echo "$notifications" | cut -d'|' -f3)
        echo "single|$title|$message"
    else
        # Multiple notifications, consolidate
        local title="[$project_name] 有 $count 個通知"
        local messages=""
        
        # Extract last few messages
        echo "$notifications" | tail -n 3 | while IFS='|' read -r timestamp title message; do
            messages="${messages}• ${message:0:50}...\n"
        done
        
        echo "consolidated|$title|$messages"
    fi
}

# Check if should queue or send immediately
should_queue() {
    local last_notification_file="$QUEUE_DIR/last_notification"
    local current_time=$(date +%s)
    local threshold=2  # seconds
    
    ensure_queue_dir
    
    if [ -f "$last_notification_file" ]; then
        local last_time=$(cat "$last_notification_file")
        local diff=$((current_time - last_time))
        
        if [ $diff -lt $threshold ]; then
            return 0  # Should queue
        fi
    fi
    
    echo "$current_time" > "$last_notification_file"
    return 1  # Send immediately
}

# Clean up old queue files
cleanup_queue() {
    if [ -d "$QUEUE_DIR" ]; then
        find "$QUEUE_DIR" -type f -mtime +1 -delete 2>/dev/null || true
    fi
}