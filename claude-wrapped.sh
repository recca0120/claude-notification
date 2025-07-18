#!/bin/bash

# Claude CLI 包裝腳本 - 自動偵測並通知

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# 執行 claude 並監控輸出
claude "$@" | tee >(
    while IFS= read -r line; do
        # 將輸出傳給監控器
        echo "$line" | "$SCRIPT_DIR/lib/keyword-detector.sh"
    done
)