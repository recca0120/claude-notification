#!/bin/bash

# Claude Notification Hooks Setup Script
# Sets up Claude Code hooks for the notification system

set -e

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Determine if we're running from installed location or development
if [ -d "$SCRIPT_DIR/../lib" ]; then
    # Installed in .local/bin, lib is at ../lib
    LIB_DIR="$SCRIPT_DIR/../lib"
    SCRIPTS_DIR="$SCRIPT_DIR/../scripts"
elif [ -d "$SCRIPT_DIR/lib" ]; then
    # Running from project root
    LIB_DIR="$SCRIPT_DIR/lib"
    SCRIPTS_DIR="$SCRIPT_DIR/scripts"
else
    echo "Error: Cannot find lib directory" >&2
    exit 1
fi

# Source i18n for multilingual support
source "$LIB_DIR/i18n.sh"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Claude settings path
CLAUDE_DIR="$HOME/.claude"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

# Display functions
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

prompt() {
    echo -e "${BLUE}[?]${NC} $1"
}

# Check if jq is installed
check_jq() {
    if ! command -v jq &> /dev/null; then
        error "jq is required but not installed. Run: brew install jq"
    fi
}

# Create Claude directory if it doesn't exist
ensure_claude_dir() {
    if [ ! -d "$CLAUDE_DIR" ]; then
        info "Creating Claude directory: $CLAUDE_DIR"
        mkdir -p "$CLAUDE_DIR"
    fi
}

# Backup existing settings
backup_settings() {
    if [ -f "$SETTINGS_FILE" ]; then
        BACKUP_FILE="$SETTINGS_FILE.backup.$(date +%Y%m%d_%H%M%S)"
        info "Backing up existing settings to: $BACKUP_FILE"
        cp "$SETTINGS_FILE" "$BACKUP_FILE"
    fi
}

# Get the absolute path to the hook processor script
get_hook_processor_path() {
    local processor_path="$SCRIPTS_DIR/claude-hook-processor.sh"
    if [ ! -f "$processor_path" ]; then
        error "Hook processor script not found: $processor_path"
    fi
    echo "$processor_path"
}

# Create or update settings file
setup_hooks() {
    local hook_processor_path=$(get_hook_processor_path)
    
    info "Setting up Claude Code hooks..."
    
    # Initialize settings structure if file doesn't exist
    if [ ! -f "$SETTINGS_FILE" ]; then
        echo '{}' > "$SETTINGS_FILE"
    fi
    
    # Read existing settings
    local settings=$(cat "$SETTINGS_FILE")
    
    # Check if running in interactive mode or if choice is pre-set
    if [ -n "${SETUP_CHOICE:-}" ]; then
        # Use environment variable if set (for testing)
        choice="$SETUP_CHOICE"
        info "Using pre-configured choice: $choice"
    elif [ -t 0 ]; then
        # Ask user which hooks to enable
        echo
        prompt "Which hooks would you like to enable?"
        echo "1) Essential hooks (UserPromptSubmit, Stop) - Recommended"
        echo "2) PostToolUse hook only (file change monitoring)"
        echo "3) All hooks (complete monitoring)"
        echo "4) Skip hook setup"
        
        read -p "Enter choice (1-4): " choice
    else
        info "Running in non-interactive mode, setting up essential hooks"
        choice=1
    fi
    
    case "$choice" in
        1)
            info "Setting up essential notification hooks..."
            # Merge hooks instead of overwriting
            settings=$(echo "$settings" | jq --arg cmd "$hook_processor_path" '
                # Initialize hooks object if it does not exist
                .hooks //= {} |
                # Merge UserPromptSubmit hooks
                .hooks.UserPromptSubmit = (
                    (.hooks.UserPromptSubmit // []) + [{
                        "matcher": ".*",
                        "hooks": [{
                            "type": "command",
                            "command": $cmd
                        }]
                    }] | unique_by(.matcher)
                ) |
                # Merge Stop hooks
                .hooks.Stop = (
                    (.hooks.Stop // []) + [{
                        "matcher": ".*",
                        "hooks": [{
                            "type": "command",
                            "command": $cmd
                        }]
                    }] | unique_by(.matcher)
                )
            ')
            ;;
        2)
            info "Setting up PostToolUse hook..."
            # Merge hooks instead of overwriting
            settings=$(echo "$settings" | jq --arg cmd "$hook_processor_path" '
                # Initialize hooks object if it does not exist
                .hooks //= {} |
                # Merge PostToolUse hooks
                .hooks.PostToolUse = (
                    (.hooks.PostToolUse // []) + [{
                        "matcher": "(Bash|Edit|Write|MultiEdit)",
                        "hooks": [{
                            "type": "command",
                            "command": $cmd
                        }]
                    }] | unique_by(.matcher)
                )
            ')
            ;;
        3)
            info "Setting up all hooks..."
            # Merge all hooks instead of overwriting
            settings=$(echo "$settings" | jq --arg cmd "$hook_processor_path" '
                # Initialize hooks object if it does not exist
                .hooks //= {} |
                # Merge UserPromptSubmit hooks
                .hooks.UserPromptSubmit = (
                    (.hooks.UserPromptSubmit // []) + [{
                        "matcher": ".*",
                        "hooks": [{
                            "type": "command",
                            "command": $cmd
                        }]
                    }] | unique_by(.matcher)
                ) |
                # Merge Stop hooks
                .hooks.Stop = (
                    (.hooks.Stop // []) + [{
                        "matcher": ".*",
                        "hooks": [{
                            "type": "command",
                            "command": $cmd
                        }]
                    }] | unique_by(.matcher)
                ) |
                # Merge SubagentStop hooks
                .hooks.SubagentStop = (
                    (.hooks.SubagentStop // []) + [{
                        "matcher": ".*",
                        "hooks": [{
                            "type": "command",
                            "command": $cmd
                        }]
                    }] | unique_by(.matcher)
                ) |
                # Merge PreToolUse hooks
                .hooks.PreToolUse = (
                    (.hooks.PreToolUse // []) + [{
                        "matcher": ".*",
                        "hooks": [{
                            "type": "command",
                            "command": $cmd
                        }]
                    }] | unique_by(.matcher)
                ) |
                # Merge PostToolUse hooks
                .hooks.PostToolUse = (
                    (.hooks.PostToolUse // []) + [{
                        "matcher": "(Bash|Edit|Write|MultiEdit)",
                        "hooks": [{
                            "type": "command",
                            "command": $cmd
                        }]
                    }] | unique_by(.matcher)
                )
            ')
            ;;
        4)
            warn "Skipping hook setup"
            return
            ;;
        *)
            error "Invalid choice"
            ;;
    esac
    
    # Write updated settings
    echo "$settings" | jq '.' > "$SETTINGS_FILE"
    info "Hooks configured successfully!"
}

# Verify hook setup
verify_hooks() {
    info "Verifying hook setup..."
    
    if [ ! -f "$SETTINGS_FILE" ]; then
        warn "Settings file not found"
        return 1
    fi
    
    echo
    info "Current hook configuration:"
    jq '.hooks' "$SETTINGS_FILE" 2>/dev/null || echo "{}"
    
    echo
    info "Hook processor script: $(get_hook_processor_path)"
    
    # Check if hook processor is executable
    if [ ! -x "$(get_hook_processor_path)" ]; then
        warn "Hook processor is not executable. Fixing..."
        chmod +x "$(get_hook_processor_path)"
    fi
    
    return 0
}

# Display usage instructions
show_usage() {
    echo
    echo -e "${GREEN}Hook setup complete!${NC}"
    echo "========================"
    echo
    echo "The Claude notification system is now integrated with Claude Code."
    echo
    echo "How it works:"
    echo "- UserPromptSubmit: Detects when user interrupts or provides input"
    echo "- Stop: Detects when Claude completes execution"
    echo "- PostToolUse: Monitors file changes and command executions (optional)"
    echo
    echo "The hooks will automatically trigger notifications for:"
    echo "1. When Claude needs user input or is interrupted"
    echo "2. When Claude completes a task"
    echo "3. File modifications (if PostToolUse is enabled)"
    echo
    echo "To test the integration:"
    echo "1. Open Claude Code"
    echo "2. Ask Claude to perform a task"
    echo "3. You should receive notifications when:"
    echo "   - Claude needs your input"
    echo "   - Claude completes the task"
    echo
    echo "To modify hook settings, edit: $SETTINGS_FILE"
    echo
}

# Main execution
main() {
    echo -e "${GREEN}Claude Notification Hooks Setup${NC}"
    echo "=============================="
    echo
    
    check_jq
    ensure_claude_dir
    backup_settings
    setup_hooks
    
    if verify_hooks; then
        show_usage
    else
        error "Hook setup verification failed"
    fi
}

# Run main function
main "$@"