#!/bin/bash

# Claude Notify Installation Script

set -e

# Get script directory and source i18n
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_DIR="$SCRIPT_DIR"
source "$REPO_DIR/lib/config-reader.sh"
source "$REPO_DIR/lib/i18n.sh"

# 顏色定義
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 預設安裝路徑 - 使用獨立資料夾
INSTALL_BASE="${INSTALL_BASE:-$HOME/.local/bin/claude-notifier}"
INSTALL_DIR="$INSTALL_BASE"
CONFIG_DIR="$HOME/.config/claude-notification"

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
    info "$(get_text "install.checking_deps")"
    
    # 檢查 Homebrew
    if ! command -v brew &> /dev/null; then
        error "Need to install Homebrew. Please visit https://brew.sh"
    fi
    
    # Note: terminal-notifier is no longer needed
    # We use macOS built-in osascript for notifications
    
    # 檢查/安裝 jq
    if ! command -v jq &> /dev/null; then
        info "Installing jq..."
        brew install jq
    else
        info "jq already installed"
    fi
}

# 建立目錄
create_directories() {
    info "$(get_text "install.creating_dirs")"
    
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$CONFIG_DIR"
}

# 複製檔案
install_files() {
    info "$(get_text "install.installing")"
    
    # 建立必要的目錄結構
    mkdir -p "$INSTALL_BASE/bin"
    mkdir -p "$INSTALL_BASE/lib"
    mkdir -p "$INSTALL_BASE/scripts"
    
    # 複製主程式
    cp -f "$REPO_DIR/claude-notify" "$INSTALL_BASE/bin/"
    chmod +x "$INSTALL_BASE/bin/claude-notify"
    
    # 複製腳本
    cp -f "$REPO_DIR/scripts/claude-notify.sh" "$INSTALL_BASE/scripts/"
    cp -f "$REPO_DIR/scripts/claude-monitor.sh" "$INSTALL_BASE/scripts/"
    cp -f "$REPO_DIR/scripts/claude-hook-processor.sh" "$INSTALL_BASE/scripts/"
    chmod +x "$INSTALL_BASE/scripts/"*.sh
    
    # 複製函式庫
    cp -rf "$REPO_DIR/lib/"* "$INSTALL_BASE/lib/"
    
    # 複製 setup-hooks.sh 到安裝目錄
    cp -f "$REPO_DIR/setup-hooks.sh" "$INSTALL_BASE/bin/"
    chmod +x "$INSTALL_BASE/bin/setup-hooks.sh"
    
    # 複製設定檔（如果不存在）
    if [ ! -f "$CONFIG_DIR/config.json" ]; then
        cp "$REPO_DIR/config.json" "$CONFIG_DIR/"
        # 同時複製到安裝目錄以供相容性
        cp "$REPO_DIR/config.json" "$INSTALL_BASE/"
        info "$(get_text "install.config_created") $CONFIG_DIR/config.json"
    else
        warn "$(get_text "install.config_exists")"
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
        # 需要將 bin 目錄加入 PATH
        BIN_DIR="$INSTALL_BASE/bin"
        # 檢查 PATH 是否已包含安裝目錄
        if ! grep -q "$BIN_DIR" "$RC_FILE" 2>/dev/null; then
            echo "" >> "$RC_FILE"
            echo "# Claude Notify" >> "$RC_FILE"
            echo "export PATH=\"\$PATH:$BIN_DIR\"" >> "$RC_FILE"
            info "已將 $BIN_DIR 加入 PATH"
            warn "請執行 'source $RC_FILE' 或重新開啟終端機"
        else
            info "PATH 已包含安裝目錄"
        fi
    fi
}

# 互動式設定
interactive_setup() {
    echo -e "\n${GREEN}$(get_text "install.setup_wizard")${NC}"
    echo "========================"
    
    # 詢問是否啟用聲音
    read -p "$(get_text "install.enable_sound") " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        "$INSTALL_BASE/bin/claude-notify" config set notification.sound.enabled true
    fi
    
    # 詢問是否啟用語音
    read -p "$(get_text "install.enable_speech") " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        "$INSTALL_BASE/bin/claude-notify" config set notification.speech.enabled true
    fi
    
    # 測試通知
    read -p "$(get_text "install.test_notify") " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        "$INSTALL_BASE/bin/claude-notify" "$(get_text "install.success_title")" "$(get_text "install.success_msg")"
    fi
    
    # 詢問是否設定 Claude Code hooks
    echo
    read -p "Would you like to set up Claude Code hooks integration? (Y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        "$INSTALL_BASE/bin/setup-hooks.sh"
    fi
}

# 顯示完成訊息
show_completion() {
    echo
    echo -e "${GREEN}$(get_text "install.complete")${NC}"
    echo "========================"
    echo "claude-notify installed to: $INSTALL_BASE"
    echo "Config location: $CONFIG_DIR/config.json"
    echo
    echo "Usage:"
    echo "  claude-notify --help    # Show help"
    echo "  claude-notify config list # List settings"
    echo "  claude-notify monitor   # Start monitoring"
    echo
    echo "Integration with Claude CLI:"
    echo "  claude | claude-notify monitor"
    echo
}

# 主程式
main() {
    echo -e "${GREEN}$(get_text "install.title")${NC}"
    echo "======================="
    echo
    
    check_dependencies
    create_directories
    install_files
    setup_path
    
    # 詢問是否進行互動式設定（檢查是否在互動模式）
    if [ -t 0 ]; then
        read -p "$(get_text "install.interactive") " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            interactive_setup
        fi
    else
        info "Running in non-interactive mode, skipping setup wizard"
    fi
    
    show_completion
}

# 執行主程式
main "$@"