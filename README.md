# Claude Notification System

[![Tests](https://github.com/recca0120/claude-notification/actions/workflows/test.yml/badge.svg)](https://github.com/recca0120/claude-notification/actions/workflows/test.yml)

[中文](#中文) | [English](#english)

---

## 中文

為 Claude Code 提供智能通知系統的 macOS 工具。當 Claude 需要您的注意時自動發送通知。

### 功能特點

- 🔔 系統通知顯示（使用 macOS 內建 osascript）
- 🔊 可選的聲音提示
- 🗣️ 可選的語音播報
- 🚨 智能事件偵測（需要決定、完成、權限請求）
- 📦 訊息堆疊防止通知轟炸
- 📝 從對話記錄提取工作總結
- ⚙️ 可自訂設定
- 🌐 支援中英文介面
- 🧪 完整的測試覆蓋

### 通知時機

系統會在以下情況自動發送通知：
1. **執行完成** - Claude 完成任務執行（會顯示完成的工作總結）
2. **需要決定** - Claude 詢問您要選擇或確認事項
3. **權限請求** - Claude 需要您授權使用某個工具
4. **等待輸入** - 透過關鍵字偵測判斷 Claude 在等待您的回應

### 安裝需求

- macOS (使用內建的 osascript 發送通知)
- Homebrew
- jq (用於讀取 JSON 設定)

### 安裝步驟

```bash
# 自動安裝
./install.sh

# 或手動安裝依賴
brew install jq
```

### 解除安裝

```bash
# 執行解除安裝腳本
./uninstall.sh

# 這將會：
# - 移除已安裝的執行檔
# - 詢問是否刪除設定檔
# - 清理 Claude Code hooks 設定
# - 移除 PATH 設定
```

### 使用方式

#### 直接發送通知

```bash
# 基本通知
./claude-notify "標題" "訊息內容"

# 帶聲音的通知
./claude-notify "標題" "訊息內容" --sound

# 帶語音的通知
./claude-notify "標題" "訊息內容" --speak

# 同時有聲音和語音
./claude-notify "標題" "訊息內容" --sound --speak
```

#### 設定管理

```bash
# 列出所有設定
./claude-notify config list

# 取得設定值
./claude-notify config get notification.sound.enabled

# 設定值
./claude-notify config set notification.sound.enabled true

# 新增關鍵字
./claude-notify config add-keyword "新關鍵字"

# 移除關鍵字  
./claude-notify config remove-keyword "關鍵字"

# 重設為預設值
./claude-notify config reset

# 設定語言 (zh/en/auto)
./claude-notify config set system.language zh
```

#### 監控 Claude 輸出

```bash
# 在終端機中使用管道監控
claude | ./claude-notify monitor

# 或直接執行監控腳本並手動輸入測試
./claude-notify monitor
```

### 設定檔

編輯 `config.json` 來自訂設定：

```json
{
  "notification": {
    "enabled": true,
    "sound": {
      "enabled": true,
      "file": "/System/Library/Sounds/Glass.aiff"
    },
    "speech": {
      "enabled": false,
      "voice": "Samantha",
      "rate": 200
    }
  },
  "triggers": {
    "keywords": [
      "該怎麼做",
      "怎麼做",
      "如何",
      "請問",
      "您想",
      "要選擇"
    ]
  },
  "system": {
    "language": "auto"
  },
  "logging": {
    "enabled": false,
    "file": "/tmp/claude-hook-debug.log",
    "level": "info"
  }
}
```

### Claude Code Hooks 整合

與 Claude Code 整合以接收即時通知。

#### 自動設定 (推薦)

使用提供的設定腳本：

```bash
# 執行 hooks 設定腳本
./setup-hooks.sh

# 或在安裝時會詢問是否設定 hooks
./install.sh
```

#### 手動設定

如果需要手動設定，編輯 `~/.claude/settings.json`：

```bash
# 1. 基本設定（推薦）- 按照官方文件順序
{
  "hooks": {
    "Notification": [{
      "matcher": ".*",
      "hooks": [{
        "type": "command",
        "command": "/path/to/claude-hook-processor.sh"
      }]
    }],
    "UserPromptSubmit": [{
      "matcher": ".*",
      "hooks": [{
        "type": "command",
        "command": "/path/to/claude-hook-processor.sh"
      }]
    }],
    "Stop": [{
      "matcher": ".*",
      "hooks": [{
        "type": "command",
        "command": "/path/to/claude-hook-processor.sh"
      }]
    }]
  }
}

# 2. 或加入檔案變更監控
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "(Bash|Edit|Write|MultiEdit)",
        "hooks": [
          {
            "type": "command",
            "command": "/path/to/claude-hook-processor.sh"
          }
        ]
      }
    ]
  }
}
```

### 測試

```bash
# 執行所有測試
bats tests/*.bats

# 執行範例測試
./examples/test-notification.sh

# 測試模式（不會真的發送通知）
./claude-notify "測試標題" "測試訊息" --test
```

測試執行時不會發送真正的通知、播放聲音或語音。

### 專案結構

```
claude-notification/
├── claude-notify        # 主要執行檔
├── scripts/              # Shell 腳本
│   ├── claude-notify.sh  # 主要通知腳本
│   ├── claude-monitor.sh # 監控腳本
│   └── claude-hook-processor.sh # Hook 處理器
├── lib/                  # 函式庫
│   ├── config-reader.sh  # 設定讀取器
│   ├── keyword-detector.sh # 關鍵字偵測器
│   ├── notification-queue.sh # 通知佇列
│   └── i18n.sh          # 國際化支援
├── tests/                # 測試檔案
│   ├── mocks/            # 測試用 mock 腳本
│   │   └── claude-notify
│   ├── fixtures/         # 測試資料
│   ├── claude-notify.bats
│   ├── claude-hook-processor.bats
│   ├── config-reader.bats
│   ├── config-manager.bats
│   ├── keyword-detector.bats
│   ├── notification-queue.bats
│   ├── setup-hooks.bats
│   └── uninstall.bats
├── install.sh            # 安裝腳本
├── uninstall.sh          # 解除安裝腳本
├── setup-hooks.sh        # Hook 設定腳本
├── config.json           # 設定檔
└── README.md             # 說明文件
```

---

## English

A smart notification system for Claude Code on macOS. Automatically alerts you when Claude needs your attention.

### Features

- 🔔 System notifications (using macOS built-in osascript)
- 🔊 Optional sound alerts
- 🗣️ Optional text-to-speech
- 🚨 Smart event detection (decisions needed, completion, permission requests)
- 📦 Message queuing to prevent notification spam
- 📝 Extracts work summaries from conversation logs
- ⚙️ Customizable settings
- 🌐 Bilingual interface (Chinese/English)
- 🧪 Comprehensive test coverage

### When You'll Get Notifications

The system automatically sends notifications when:
1. **Task Complete** - Claude finishes executing tasks (shows work summary)
2. **Decision Needed** - Claude asks you to choose or confirm something
3. **Permission Request** - Claude needs authorization to use a tool
4. **Waiting for Input** - Detected through keywords that Claude is waiting for your response

### Requirements

- macOS (uses built-in osascript for notifications)
- Homebrew
- jq (for JSON parsing)

### Installation

```bash
# Automatic installation
./install.sh

# Or install dependencies manually
brew install jq
```

### Uninstallation

```bash
# Run uninstall script
./uninstall.sh

# This will:
# - Remove installed executables
# - Ask whether to delete config files
# - Clean up Claude Code hooks settings
# - Remove PATH entries
```

### Usage

#### Send Notifications

```bash
# Basic notification
./claude-notify "Title" "Message content"

# With sound alert
./claude-notify "Title" "Message content" --sound

# With text-to-speech
./claude-notify "Title" "Message content" --speak

# With both sound and speech
./claude-notify "Title" "Message content" --sound --speak
```

#### Configuration Management

```bash
# List all settings
./claude-notify config list

# Get a setting value
./claude-notify config get notification.sound.enabled

# Set a value
./claude-notify config set notification.sound.enabled true

# Add a keyword
./claude-notify config add-keyword "new keyword"

# Remove a keyword
./claude-notify config remove-keyword "keyword"

# Reset to defaults
./claude-notify config reset

# Set language (zh/en/auto)
./claude-notify config set system.language en
```

#### Monitor Claude Output

```bash
# Monitor using pipe in terminal
claude | ./claude-notify monitor

# Or run monitor directly for testing
./claude-notify monitor
```

### Configuration File

Edit `config.json` to customize settings:

```json
{
  "notification": {
    "enabled": true,
    "sound": {
      "enabled": true,
      "file": "/System/Library/Sounds/Glass.aiff"
    },
    "speech": {
      "enabled": false,
      "voice": "Samantha",
      "rate": 200
    }
  },
  "triggers": {
    "keywords": [
      "how to",
      "what should",
      "which",
      "please",
      "would you like"
    ]
  },
  "system": {
    "language": "auto"
  },
  "logging": {
    "enabled": false,
    "file": "/tmp/claude-hook-debug.log",
    "level": "info"
  }
}
```

### Claude Code Hooks Integration

Integrate with Claude Code for real-time notifications.

#### Automatic Setup (Recommended)

Use the provided setup script:

```bash
# Run the hooks setup script
./setup-hooks.sh

# Or it will be offered during installation
./install.sh
```

#### Manual Setup

If you need to manually configure, edit `~/.claude/settings.json`:

```bash
# 1. Basic setup (recommended) - Following official documentation order
{
  "hooks": {
    "Notification": [{
      "matcher": ".*",
      "hooks": [{
        "type": "command",
        "command": "/path/to/claude-hook-processor.sh"
      }]
    }],
    "UserPromptSubmit": [{
      "matcher": ".*",
      "hooks": [{
        "type": "command",
        "command": "/path/to/claude-hook-processor.sh"
      }]
    }],
    "Stop": [{
      "matcher": ".*",
      "hooks": [{
        "type": "command",
        "command": "/path/to/claude-hook-processor.sh"
      }]
    }]
  }
}

# 2. Or use PostToolUse hook
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "(Bash|Edit|Write|MultiEdit)",
        "hooks": [
          {
            "type": "command",
            "command": "/path/to/claude-hook-processor.sh"
          }
        ]
      }
    ]
  }
}
```

### Testing

```bash
# Run all tests
bats tests/*.bats

# Run example test
./examples/test-notification.sh

# Test mode (no actual notifications sent)
./claude-notify "Test Title" "Test Message" --test
```

Tests run without sending actual notifications, playing sounds, or speaking.

### Project Structure

```
claude-notification/
├── claude-notify        # Main executable
├── scripts/              # Shell scripts
│   ├── claude-notify.sh  # Main notification script
│   ├── claude-monitor.sh # Monitor script
│   └── claude-hook-processor.sh # Hook processor
├── lib/                  # Libraries
│   ├── config-reader.sh  # Config reader
│   ├── keyword-detector.sh # Keyword detector
│   ├── notification-queue.sh # Notification queue
│   └── i18n.sh          # Internationalization
├── tests/                # Test files
│   ├── mocks/            # Test mock scripts
│   │   └── claude-notify
│   ├── fixtures/         # Test data
│   ├── claude-notify.bats
│   ├── claude-hook-processor.bats
│   ├── config-reader.bats
│   ├── config-manager.bats
│   ├── keyword-detector.bats
│   ├── notification-queue.bats
│   ├── setup-hooks.bats
│   └── uninstall.bats
├── install.sh            # Installation script
├── uninstall.sh          # Uninstallation script
├── setup-hooks.sh        # Hook setup script
├── config.json           # Configuration file
└── README.md             # Documentation
```

### Development

This project follows TDD (Test-Driven Development) principles. See `CLAUDE.md` for details.

### License

MIT