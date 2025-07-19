#!/bin/bash

# Claude CLI 包裝腳本 - 自動偵測並通知

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# 執行 claude 並監控輸出
claude "$@" | "$SCRIPT_DIR/claude-monitor.sh"