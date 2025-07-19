#!/usr/bin/env bats

# Test for claude-hook-processor.sh - focusing on Stop event notifications

setup() {
    export SCRIPT_DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" && pwd )"
    export PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
    export HOOK_PROCESSOR="$PROJECT_ROOT/scripts/claude-hook-processor.sh"
    
    # Use mock claude-notify
    export CLAUDE_NOTIFY="$SCRIPT_DIR/mocks/claude-notify"
    export MOCK_OUTPUT="$BATS_TMPDIR/mock-notify-output"
    
    # Create test config
    export CONFIG_PATH="$BATS_TMPDIR/test-config.json"
    cat > "$CONFIG_PATH" << 'EOF'
{
    "notification": {
        "enabled": true,
        "sound": {
            "enabled": true,
            "file": "/System/Library/Sounds/Glass.aiff"
        }
    },
    "system": {
        "language": "zh"
    }
}
EOF
}

teardown() {
    rm -f "$CONFIG_PATH" "$MOCK_OUTPUT"
}


@test "Stop event with file modification workflow" {
    # Create a complete file modification conversation
    local transcript_file="$BATS_TMPDIR/file-mod-transcript.jsonl"
    cat > "$transcript_file" << 'EOF'
{"role": "user", "content": "請更新 README.md 檔案，加入安裝說明"}
{"role": "assistant", "content": "我會幫您更新 README.md 檔案，加入詳細的安裝說明。"}
{"role": "tool_use", "content": "使用 Read 工具讀取 README.md"}
{"role": "tool_result", "content": "成功讀取 README.md 內容"}
{"role": "assistant", "content": "現在我會在適當的位置加入安裝說明。"}
{"role": "tool_use", "content": "使用 Edit 工具修改 README.md"}
{"role": "tool_result", "content": "README.md 已成功更新"}
{"role": "assistant", "content": "✓ 已更新 README.md：\n  - 新增了詳細的安裝步驟\n  - 包含系統需求說明\n  - 加入了疑難排解章節"}
EOF
    
    # Stop event with transcript
    local stop_event=$(jq -n \
        --arg transcript "$transcript_file" \
        --arg session "file-mod-session" \
        --arg cwd "/test/project" \
        '{
            "hook_event_name": "Stop",
            "session_id": $session,
            "transcript_path": $transcript,
            "cwd": $cwd
        }')
    
    rm -f "$MOCK_OUTPUT"
    echo "$stop_event" | "$HOOK_PROCESSOR"
    sleep 2.5
    
    # Verify notification contains work summary
    [ -f "$MOCK_OUTPUT" ]
    grep -q "已更新 README.md" "$MOCK_OUTPUT"
    
    rm -f "$transcript_file"
}

@test "Stop event when task has no completion summary" {
    # Create conversation without clear completion marker
    local transcript_file="$BATS_TMPDIR/no-summary-transcript.jsonl"
    cat > "$transcript_file" << 'EOF'
{"role": "user", "content": "系統有什麼問題嗎？"}
{"role": "assistant", "content": "讓我檢查一下系統狀態。"}
{"role": "tool_use", "content": "使用 Bash 工具執行 echo 'System check'"}
{"role": "tool_result", "content": "System check"}
{"role": "assistant", "content": "系統運作正常，沒有發現任何問題。"}
EOF
    
    local stop_event=$(jq -n \
        --arg transcript "$transcript_file" \
        --arg session "check-session" \
        --arg cwd "/test/my-app" \
        '{
            "hook_event_name": "Stop",
            "session_id": $session,
            "transcript_path": $transcript,
            "cwd": $cwd
        }')
    
    rm -f "$MOCK_OUTPUT"
    echo "$stop_event" | "$HOOK_PROCESSOR"
    sleep 2.5
    
    # Should use default message when no completion summary found
    [ -f "$MOCK_OUTPUT" ]
    grep -q "my-app" "$MOCK_OUTPUT"
    grep -q "任務已完成，您可以回來查看結果了" "$MOCK_OUTPUT"
    
    rm -f "$transcript_file"
}

@test "Stop event handles interrupted conversation gracefully" {
    # Create an interrupted conversation (user stopped Claude mid-task)
    local transcript_file="$BATS_TMPDIR/interrupted-transcript.jsonl"
    cat > "$transcript_file" << 'EOF'
{"role": "user", "content": "請幫我重構整個專案"}
{"role": "assistant", "content": "我會幫您重構整個專案。這是一個較大的任務，讓我開始分析程式結構。"}
{"role": "tool_use", "content": "使用 Glob 工具搜尋 **/*.js"}
{"role": "tool_result", "content": "找到 25 個 JavaScript 檔案"}
{"role": "assistant", "content": "我找到了 25 個 JavaScript 檔案。現在開始逐一檢查..."}
{"role": "user", "content": "[使用者中斷]"}
EOF
    
    local stop_event=$(jq -n \
        --arg transcript "$transcript_file" \
        --arg session "interrupted-task" \
        --arg cwd "/test/project" \
        '{
            "hook_event_name": "Stop",
            "session_id": $session,
            "transcript_path": $transcript,
            "cwd": $cwd
        }')
    
    rm -f "$MOCK_OUTPUT"
    echo "$stop_event" | "$HOOK_PROCESSOR"
    sleep 2.5
    
    # Should still send notification even for interrupted tasks
    [ -f "$MOCK_OUTPUT" ]
    grep -q "project" "$MOCK_OUTPUT"
    
    rm -f "$transcript_file"
}

@test "Stop event with error during task execution" {
    # Create conversation where Claude encountered an error
    local transcript_file="$BATS_TMPDIR/error-transcript.jsonl"
    cat > "$transcript_file" << 'EOF'
{"role": "user", "content": "請執行測試"}
{"role": "assistant", "content": "我會執行專案的測試套件。"}
{"role": "tool_use", "content": "使用 Bash 工具執行 npm test"}
{"role": "tool_result", "content": "Error: 5 tests failed"}
{"role": "assistant", "content": "測試執行完成，但有 5 個測試失敗。以下是失敗的測試：\n1. Stop event test\n2. Notification queue test\n..."}
EOF
    
    local stop_event=$(jq -n \
        --arg transcript "$transcript_file" \
        --arg session "test-session" \
        --arg cwd "/test/project" \
        '{
            "hook_event_name": "Stop",
            "session_id": $session,
            "transcript_path": $transcript,
            "cwd": $cwd
        }')
    
    rm -f "$MOCK_OUTPUT"
    echo "$stop_event" | "$HOOK_PROCESSOR"
    sleep 2.5
    
    # Should send notification even when task had errors
    [ -f "$MOCK_OUTPUT" ]
    grep -q "project" "$MOCK_OUTPUT"
    
    rm -f "$transcript_file"
}

@test "Stop event after running tests and capturing conversation" {
    # Create conversation from this actual session
    local transcript_file="$BATS_TMPDIR/capture-test-transcript.jsonl"
    cat > "$transcript_file" << 'EOF'
{"role": "user", "content": "再執行一次測試，把這次補捉到的對話記錄來測Stop時要通知使用者"}
{"role": "assistant", "content": "我來執行測試並準備捕捉這次的對話記錄。"}
{"role": "tool_use", "content": "使用 TodoWrite 工具更新任務清單"}
{"role": "tool_result", "content": "Todos have been modified successfully."}
{"role": "tool_use", "content": "使用 Bash 工具執行 bats tests/claude-hook-processor.bats"}
{"role": "tool_result", "content": "1..5\nok 1 Stop event triggers notification after complete task execution\nok 2 Stop event with file modification workflow\nok 3 Stop event when task has no completion summary\nok 4 Stop event handles interrupted conversation gracefully\nok 5 Stop event with error during task execution"}
{"role": "assistant", "content": "測試都通過了。現在我會建立一個新的測試案例，使用這次對話的內容來測試 Stop 事件通知。"}
{"role": "tool_use", "content": "使用 Edit 工具新增測試案例"}
{"role": "tool_result", "content": "The file has been updated."}
{"role": "assistant", "content": "✓ 已完成測試執行並新增測試案例：\n  - 執行了所有 5 個測試，全部通過\n  - 建立了新的測試案例，使用本次對話內容\n  - 測試驗證 Stop 事件會正確發送通知給使用者"}
EOF
    
    local stop_event=$(jq -n \
        --arg transcript "$transcript_file" \
        --arg session "capture-session-001" \
        --arg cwd "/test/notification-project" \
        '{
            "hook_event_name": "Stop",
            "session_id": $session,
            "transcript_path": $transcript,
            "cwd": $cwd
        }')
    
    rm -f "$MOCK_OUTPUT"
    echo "$stop_event" | "$HOOK_PROCESSOR"
    sleep 2.5
    
    # Verify notification was sent
    [ -f "$MOCK_OUTPUT" ]
    grep -q "notification-project" "$MOCK_OUTPUT"
    
    # Verify it contains the completion summary
    grep -q "已完成測試執行並新增測試案例" "$MOCK_OUTPUT"
    
    rm -f "$transcript_file"
}

@test "Stop event after git operations with permission prompt" {
    # Create conversation with git operations requiring user confirmation
    local transcript_file="$BATS_TMPDIR/git-permission-transcript.jsonl"
    cat > "$transcript_file" << 'EOF'
{"role": "user", "content": "push"}
{"role": "assistant", "content": "我來幫您推送變更到遠端儲存庫。"}
{"role": "tool_use", "content": "使用 TodoWrite 工具更新任務清單"}
{"role": "tool_result", "content": "Todos have been modified successfully."}
{"role": "tool_use", "content": "使用 Bash 工具執行 git status"}
{"role": "tool_result", "content": "On branch main\nYour branch is ahead of 'origin/main' by 5 commits.\n  (use \"git push\" to publish your local commits)\n\nChanges to be committed:\n  (use \"git restore --staged <file>...\" to unstage)\n\tdeleted:    tests/fixtures/notification.json\n..."}
{"role": "assistant", "content": "我需要先將所有變更加入 git，然後提交並推送。"}
{"role": "tool_use", "content": "使用 Task 工具執行 git 操作"}
{"role": "tool_result", "content": "[使用者需要確認] 是否允許執行 git add 和 git commit 操作？"}
{"role": "assistant", "content": "正在等待您確認是否可以執行 git 操作..."}
{"role": "user", "content": "[使用者確認] 可以執行"}
{"role": "tool_result", "content": "## Summary\n\nI've successfully completed the following tasks:\n\n1. **Added all modified files to git staging** ✓\n2. **Created a commit with the changes** ✓\n   - Commit hash: `7e296f2`\n   - Commit message: \"feat: Add transcript analyzer and hook event capture tools\"\n3. **Push to remote repository** ❌\n   - The push failed due to permission issues (403 error)"}
{"role": "assistant", "content": "✓ 已完成 git 操作：\n  - 成功將所有檔案加入暫存區\n  - 建立提交 (7e296f2): feat: Add transcript analyzer and hook event capture tools\n  - 推送失敗：需要設定 GitHub 認證 (SSH key 或 Personal Access Token)"}
EOF
    
    local stop_event=$(jq -n \
        --arg transcript "$transcript_file" \
        --arg session "git-ops-session" \
        --arg cwd "/test/git-project" \
        '{
            "hook_event_name": "Stop",
            "session_id": $session,
            "transcript_path": $transcript,
            "cwd": $cwd
        }')
    
    rm -f "$MOCK_OUTPUT"
    echo "$stop_event" | "$HOOK_PROCESSOR"
    sleep 2.5
    
    # Verify notification was sent
    [ -f "$MOCK_OUTPUT" ]
    grep -q "git-project" "$MOCK_OUTPUT"
    
    # Verify it contains the git operation summary
    grep -q "已完成 git 操作" "$MOCK_OUTPUT"
    
    rm -f "$transcript_file"
}

@test "Notification event sends notification when user confirmation needed" {
    # Create conversation transcript where Claude needs user confirmation
    local transcript_file="$BATS_TMPDIR/notification-transcript.jsonl"
    cat > "$transcript_file" << 'EOF'
{"role": "user", "content": "先執行建立空白檔案，再以這個對話，建立一個收到 Notification 的時候要通知使用者的測試"}
{"role": "assistant", "content": "我會先建立一個空白檔案，然後使用這次的對話內容來建立 Notification 事件的測試。"}
{"role": "tool_use", "content": "使用 TodoWrite 工具更新任務清單"}
{"role": "tool_result", "content": "Todos have been modified successfully."}
{"role": "tool_use", "content": "使用 Write 工具建立 empty-file.txt"}
{"role": "tool_result", "content": "File created successfully at: /Users/recca0120/PycharmProjects/claude-notification/empty-file.txt"}
{"role": "assistant", "content": "已建立空白檔案 empty-file.txt"}
{"role": "notification", "content": "需要您的權限來執行下一步操作：修改系統設定檔案。是否允許？"}
EOF
    
    # Notification event when Claude needs user permission
    local notification_event=$(jq -n \
        --arg transcript "$transcript_file" \
        --arg session "notification-test-001" \
        --arg cwd "/test/notification-project" \
        --arg message "需要您的權限來執行下一步操作：修改系統設定檔案。是否允許？" \
        '{
            "hook_event_name": "Notification",
            "session_id": $session,
            "transcript_path": $transcript,
            "cwd": $cwd,
            "notification": {
                "type": "permission_request",
                "message": $message
            }
        }')
    
    rm -f "$MOCK_OUTPUT"
    echo "$notification_event" | "$HOOK_PROCESSOR"
    
    # Notification event should trigger immediate notification
    [ -f "$MOCK_OUTPUT" ]
    grep -q "notification-project" "$MOCK_OUTPUT"
    grep -q "需要您的確認" "$MOCK_OUTPUT"
    grep -q "需要您的權限來執行下一步操作" "$MOCK_OUTPUT"
    
    rm -f "$transcript_file"
}

