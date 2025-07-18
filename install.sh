#!/bin/bash

# Claude Notify 安裝腳本

set -e

# 顏色定義
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 預設安裝路徑
INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"
CONFIG_DIR="$HOME/.config/claude-notification"
REPO_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# 顯示訊息
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# 檢查依賴
check_dependencies() {
    info "檢查依賴項目..."
    
    # 檢查 Homebrew
    if ! command -v brew &> /dev/null; then
        error "需要安裝 Homebrew。請前往 https://brew.sh 安裝"
    fi
    
    # 檢查/安裝 terminal-notifier
    if ! command -v terminal-notifier &> /dev/null; then
        info "安裝 terminal-notifier..."
        brew install terminal-notifier
    else
        info "terminal-notifier 已安裝"
    fi
    
    # 檢查/安裝 jq
    if ! command -v jq &> /dev/null; then
        info "安裝 jq..."
        brew install jq
    else
        info "jq 已安裝"
    fi
}

# 建立目錄
create_directories() {
    info "建立必要目錄..."
    
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$CONFIG_DIR"
}

# 複製檔案
install_files() {
    info "安裝程式檔案..."
    
    # 複製主程式
    cp -f "$REPO_DIR/claude-notify" "$INSTALL_DIR/"
    chmod +x "$INSTALL_DIR/claude-notify"
    
    # 建立符號連結到其他腳本
    ln -sf "$REPO_DIR/claude-notify.sh" "$INSTALL_DIR/claude-notify.sh"
    ln -sf "$REPO_DIR/claude-monitor.sh" "$INSTALL_DIR/claude-monitor.sh"
    
    # 複製函式庫
    cp -rf "$REPO_DIR/lib" "$INSTALL_DIR/"
    
    # 複製設定檔（如果不存在）
    if [ ! -f "$CONFIG_DIR/config.json" ]; then
        cp "$REPO_DIR/config.json" "$CONFIG_DIR/"
        info "已建立設定檔: $CONFIG_DIR/config.json"
    else
        warn "設定檔已存在，跳過複製"
    fi
}

# 設定 PATH
setup_path() {
    info "設定 PATH..."
    
    # 檢查使用的 shell
    SHELL_NAME=$(basename "$SHELL")
    
    case "$SHELL_NAME" in
        zsh)
            RC_FILE="$HOME/.zshrc"
            ;;
        bash)
            RC_FILE="$HOME/.bashrc"
            ;;
        *)
            warn "未知的 shell: $SHELL_NAME"
            RC_FILE=""
            ;;
    esac
    
    if [ -n "$RC_FILE" ]; then
        # 檢查 PATH 是否已包含安裝目錄
        if ! grep -q "$INSTALL_DIR" "$RC_FILE" 2>/dev/null; then
            echo "" >> "$RC_FILE"
            echo "# Claude Notify" >> "$RC_FILE"
            echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> "$RC_FILE"
            info "已將 $INSTALL_DIR 加入 PATH"
            warn "請執行 'source $RC_FILE' 或重新開啟終端機"
        else
            info "PATH 已包含安裝目錄"
        fi
    fi
}

# 互動式設定
interactive_setup() {
    echo -e "\n${GREEN}Claude Notify 設定精靈${NC}"
    echo "========================"
    
    # 詢問是否啟用聲音
    read -p "預設啟用聲音提示？[Y/n] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        "$INSTALL_DIR/claude-notify" config set notification.sound.enabled true
    fi
    
    # 詢問是否啟用語音
    read -p "預設啟用語音播報？[y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        "$INSTALL_DIR/claude-notify" config set notification.speech.enabled true
    fi
    
    # 測試通知
    read -p "要測試通知功能嗎？[Y/n] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        "$INSTALL_DIR/claude-notify" "安裝成功" "Claude Notify 已準備就緒！"
    fi
}

# 顯示完成訊息
show_completion() {
    echo
    echo -e "${GREEN}安裝完成！${NC}"
    echo "========================"
    echo "claude-notify 已安裝到: $INSTALL_DIR"
    echo "設定檔位置: $CONFIG_DIR/config.json"
    echo
    echo "使用方式:"
    echo "  claude-notify --help    # 顯示說明"
    echo "  claude-notify config list # 列出設定"
    echo "  claude-notify monitor   # 啟動監控"
    echo
    echo "與 Claude CLI 整合:"
    echo "  claude | claude-notify monitor"
    echo
}

# 主程式
main() {
    echo -e "${GREEN}Claude Notify 安裝程式${NC}"
    echo "======================="
    echo
    
    check_dependencies
    create_directories
    install_files
    setup_path
    
    # 詢問是否進行互動式設定
    read -p "要進行互動式設定嗎？[Y/n] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        interactive_setup
    fi
    
    show_completion
}

# 執行主程式
main "$@"