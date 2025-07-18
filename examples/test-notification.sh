#!/bin/bash

# 測試通知系統的範例腳本

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "測試 Claude 通知系統"
echo "==================="

# 測試 1: 基本通知
echo -e "\n1. 測試基本通知..."
"$PROJECT_ROOT/claude-notify.sh" "測試通知" "這是一個測試訊息"
sleep 2

# 測試 2: 帶聲音的通知
echo -e "\n2. 測試帶聲音的通知..."
"$PROJECT_ROOT/claude-notify.sh" "聲音測試" "這個通知會有聲音" --sound
sleep 2

# 測試 3: 帶語音的通知
echo -e "\n3. 測試帶語音的通知..."
"$PROJECT_ROOT/claude-notify.sh" "語音測試" "這個通知會朗讀內容" --speak
sleep 3

# 測試 4: 關鍵字檢測
echo -e "\n4. 測試關鍵字檢測..."
echo "請問該怎麼做？" | "$PROJECT_ROOT/claude-monitor.sh" &
MONITOR_PID=$!
sleep 2
kill $MONITOR_PID 2>/dev/null

echo -e "\n測試完成！"