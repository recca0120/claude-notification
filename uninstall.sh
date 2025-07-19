#!/bin/bash

# Claude Notify Uninstall Script
# Removes Claude notification system from your machine

set -e

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$SCRIPT_DIR"

# Source i18n for multilingual support
source "$PROJECT_ROOT/lib/i18n.sh" 2>/dev/null || true

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default paths (can be overridden for testing)
INSTALL_BASE="${INSTALL_BASE:-$HOME/.local/bin/claude-notifier}"
CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/claude-notification}"
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"

# Display functions
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

prompt() {
    echo -e "${BLUE}[?]${NC} $1"
}

# Remove installed files
remove_installed_files() {
    info "Removing installed files from $INSTALL_BASE..."
    
    # Remove entire installation directory
    if [ -d "$INSTALL_BASE" ]; then
        rm -rf "$INSTALL_BASE"
        info "Removed installation directory: $INSTALL_BASE"
    else
        warn "Installation directory not found: $INSTALL_BASE"
    fi
}

# Remove configuration files
remove_config_files() {
    if [ -d "$CONFIG_DIR" ]; then
        warn "Configuration directory found: $CONFIG_DIR"
        read -p "Remove configuration files? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$CONFIG_DIR"
            info "Removed configuration directory"
        else
            info "Configuration files preserved"
        fi
    fi
}

# Clean Claude hooks settings
clean_claude_hooks() {
    if [ -f "$CLAUDE_DIR/settings.json" ]; then
        warn "Claude settings found: $CLAUDE_DIR/settings.json"
        read -p "Remove Claude notification hooks from settings? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # Create backup
            cp "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/settings.json.uninstall.$(date +%Y%m%d_%H%M%S)"
            
            # Remove hooks that point to our scripts
            if command -v jq &> /dev/null; then
                local hook_path="$INSTALL_BASE/scripts/claude-hook-processor.sh"
                jq --arg path "$hook_path" '
                    .hooks |= with_entries(
                        .value |= map(select(.hooks[0].command != $path))
                    ) |
                    .hooks |= with_entries(select(.value | length > 0))
                ' "$CLAUDE_DIR/settings.json" > "$CLAUDE_DIR/settings.json.tmp"
                mv "$CLAUDE_DIR/settings.json.tmp" "$CLAUDE_DIR/settings.json"
                info "Cleaned Claude hooks settings"
            else
                warn "jq not found. Please manually remove hooks from $CLAUDE_DIR/settings.json"
            fi
        fi
    fi
}

# Remove from PATH
clean_path() {
    info "Checking shell configuration..."
    
    local shell_configs=("$HOME/.zshrc" "$HOME/.bashrc")
    
    for rc_file in "${shell_configs[@]}"; do
        if [ -f "$rc_file" ] && grep -q "$INSTALL_BASE/bin" "$rc_file"; then
            warn "Found PATH entry in $rc_file"
            read -p "Remove PATH entry? (y/N) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                # Remove Claude Notify PATH lines
                if [[ "$OSTYPE" == "darwin"* ]]; then
                    sed -i '' "/# Claude Notify/,+1d" "$rc_file"
                else
                    sed -i "/# Claude Notify/,+1d" "$rc_file"
                fi
                info "Removed PATH entry from $rc_file"
            fi
        fi
    done
}

# Show uninstall summary
show_summary() {
    echo
    echo -e "${GREEN}解除安裝完成 / Uninstall complete${NC}"
    echo "======================================"
    echo
    echo "The following actions were performed:"
    echo "- Removed installation directory: $INSTALL_BASE"
    [ ! -d "$CONFIG_DIR" ] && echo "- Removed configuration files"
    echo
    echo "Thank you for using Claude Notification System!"
    echo
}

# Main uninstall function
main() {
    echo -e "${RED}Claude Notification System Uninstaller${NC}"
    echo "====================================="
    echo
    warn "This will remove Claude Notification System from your computer."
    echo
    
    read -p "Continue with uninstall? (y/N) " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "Uninstall cancelled"
        exit 0
    fi
    
    echo
    
    # Perform uninstall steps
    remove_installed_files
    remove_config_files
    clean_claude_hooks
    clean_path
    
    show_summary
}

# Run main function
main "$@"