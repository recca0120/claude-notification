# Claude Notification System

[中文](#中文) | [English](#english)

---

## 中文

當 Claude 詢問問題時自動發送通知的 macOS 工具。

### 功能特點

- 🔔 系統通知顯示
- 🔊 可選的聲音提示
- 🗣️ 可選的語音播報
- 🔍 自動偵測關鍵字
- ⚙️ 可自訂設定
- 🌐 支援中英文介面

### 安裝需求

- macOS
- Homebrew
- terminal-notifier (會自動安裝)
- jq (用於讀取 JSON 設定)

### 安裝步驟

```bash
# 自動安裝
./install.sh

# 或手動安裝依賴
brew install terminal-notifier
brew install jq
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
  }
}
```

### 測試

```bash
# 執行所有測試
bats tests/*.bats

# 執行範例測試
./examples/test-notification.sh
```

### 專案結構

```
claude-notification/
├── claude-notify          # 統一命令介面
├── claude-notify.sh       # 主要通知腳本
├── claude-monitor.sh      # 監控腳本
├── config.json           # 設定檔
├── lib/                  # 函式庫
│   ├── config-reader.sh  # 設定讀取器
│   ├── keyword-detector.sh # 關鍵字偵測器
│   └── i18n.sh          # 國際化支援
├── tests/                # 測試檔案
│   ├── claude-notify.bats
│   ├── config-reader.bats
│   ├── config-manager.bats
│   └── keyword-detector.bats
└── examples/             # 範例腳本
    └── test-notification.sh
```

---

## English

A macOS tool that automatically sends notifications when Claude asks questions.

### Features

- 🔔 System notifications
- 🔊 Optional sound alerts
- 🗣️ Optional text-to-speech
- 🔍 Automatic keyword detection
- ⚙️ Customizable settings
- 🌐 Bilingual interface (Chinese/English)

### Requirements

- macOS
- Homebrew
- terminal-notifier (auto-installed)
- jq (for JSON parsing)

### Installation

```bash
# Automatic installation
./install.sh

# Or install dependencies manually
brew install terminal-notifier
brew install jq
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
  }
}
```

### Testing

```bash
# Run all tests
bats tests/*.bats

# Run example test
./examples/test-notification.sh
```

### Project Structure

```
claude-notification/
├── claude-notify          # Unified CLI interface
├── claude-notify.sh       # Main notification script
├── claude-monitor.sh      # Monitor script
├── config.json           # Configuration file
├── lib/                  # Libraries
│   ├── config-reader.sh  # Config reader
│   ├── keyword-detector.sh # Keyword detector
│   └── i18n.sh          # Internationalization
├── tests/                # Test files
│   ├── claude-notify.bats
│   ├── config-reader.bats
│   ├── config-manager.bats
│   └── keyword-detector.bats
└── examples/             # Example scripts
    └── test-notification.sh
```

### Development

This project follows TDD (Test-Driven Development) principles. See `CLAUDE.md` for details.

### License

MIT