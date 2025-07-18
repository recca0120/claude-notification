#!/bin/bash

# Internationalization support for Claude Notify

# Get system language
get_system_language() {
    local lang="${LANG:-en_US.UTF-8}"
    
    # Check config override
    local config_lang=$(get_config_value "system.language" 2>/dev/null)
    
    if [ "$config_lang" != "auto" ] && [ -n "$config_lang" ]; then
        echo "$config_lang"
    elif [[ "$lang" =~ ^zh ]]; then
        echo "zh"
    else
        echo "en"
    fi
}

# Get localized text
get_text() {
    local key="$1"
    local lang=$(get_system_language)
    
    case "$lang" in
        zh)
            get_text_zh "$key"
            ;;
        *)
            get_text_en "$key"
            ;;
    esac
}

# Chinese texts
get_text_zh() {
    local key="$1"
    
    case "$key" in
        # Main help
        "help.title") echo "Claude Notify v$VERSION - macOS 通知系統" ;;
        "help.usage") echo "使用方式:" ;;
        "help.notify_options") echo "通知選項:" ;;
        "help.config_commands") echo "設定命令:" ;;
        "help.monitoring") echo "監控:" ;;
        "help.examples") echo "範例:" ;;
        
        # Options
        "help.opt.sound") echo "啟用聲音提示" ;;
        "help.opt.speak") echo "啟用語音播報" ;;
        "help.opt.config") echo "使用指定的設定檔" ;;
        
        # Config commands
        "help.cmd.get") echo "取得設定值" ;;
        "help.cmd.set") echo "設定值" ;;
        "help.cmd.list") echo "列出所有設定" ;;
        "help.cmd.add_keyword") echo "新增關鍵字" ;;
        "help.cmd.remove_keyword") echo "移除關鍵字" ;;
        "help.cmd.reset") echo "重設為預設值" ;;
        "help.cmd.monitor") echo "啟動關鍵字監控" ;;
        
        # Messages
        "msg.config_updated") echo "已更新:" ;;
        "msg.keyword_added") echo "已新增關鍵字:" ;;
        "msg.keyword_removed") echo "已移除關鍵字:" ;;
        "msg.config_reset") echo "設定已重設為預設值" ;;
        "msg.current_config") echo "當前設定" ;;
        
        # Errors
        "error.no_key") echo "錯誤：請提供設定鍵" ;;
        "error.no_key_value") echo "錯誤：請提供設定鍵和值" ;;
        "error.no_keyword") echo "錯誤：請提供關鍵字" ;;
        "error.update_failed") echo "錯誤：無法更新設定" ;;
        "error.unknown_config") echo "未知的設定命令:" ;;
        
        # Monitor
        "monitor.started") echo "Claude 通知監控已啟動" ;;
        "monitor.info") echo "當 Claude 詢問問題時，您將收到通知" ;;
        "monitor.exit") echo "按 Ctrl+C 結束監控" ;;
        "monitor.notification_title") echo "Claude 需要您的回應" ;;
        
        # Install
        "install.title") echo "Claude Notify 安裝程式" ;;
        "install.checking_deps") echo "檢查依賴項目..." ;;
        "install.creating_dirs") echo "建立必要目錄..." ;;
        "install.installing") echo "安裝程式檔案..." ;;
        "install.config_created") echo "已建立設定檔:" ;;
        "install.config_exists") echo "設定檔已存在，跳過複製" ;;
        "install.setup_wizard") echo "Claude Notify 設定精靈" ;;
        "install.enable_sound") echo "預設啟用聲音提示？[Y/n]" ;;
        "install.enable_speech") echo "預設啟用語音播報？[y/N]" ;;
        "install.test_notify") echo "要測試通知功能嗎？[Y/n]" ;;
        "install.interactive") echo "要進行互動式設定嗎？[Y/n]" ;;
        "install.complete") echo "安裝完成！" ;;
        "install.success_title") echo "安裝成功" ;;
        "install.success_msg") echo "Claude Notify 已準備就緒！" ;;
        
        *) echo "$key" ;;
    esac
}

# English texts
get_text_en() {
    local key="$1"
    
    case "$key" in
        # Main help
        "help.title") echo "Claude Notify v$VERSION - macOS Notification System" ;;
        "help.usage") echo "Usage:" ;;
        "help.notify_options") echo "Notification Options:" ;;
        "help.config_commands") echo "Config Commands:" ;;
        "help.monitoring") echo "Monitoring:" ;;
        "help.examples") echo "Examples:" ;;
        
        # Options
        "help.opt.sound") echo "Enable sound alert" ;;
        "help.opt.speak") echo "Enable text-to-speech" ;;
        "help.opt.config") echo "Use specified config file" ;;
        
        # Config commands
        "help.cmd.get") echo "Get config value" ;;
        "help.cmd.set") echo "Set config value" ;;
        "help.cmd.list") echo "List all settings" ;;
        "help.cmd.add_keyword") echo "Add keyword" ;;
        "help.cmd.remove_keyword") echo "Remove keyword" ;;
        "help.cmd.reset") echo "Reset to defaults" ;;
        "help.cmd.monitor") echo "Start keyword monitoring" ;;
        
        # Messages
        "msg.config_updated") echo "Updated:" ;;
        "msg.keyword_added") echo "Keyword added:" ;;
        "msg.keyword_removed") echo "Keyword removed:" ;;
        "msg.config_reset") echo "Config reset to defaults" ;;
        "msg.current_config") echo "Current configuration" ;;
        
        # Errors
        "error.no_key") echo "Error: Please provide a config key" ;;
        "error.no_key_value") echo "Error: Please provide key and value" ;;
        "error.no_keyword") echo "Error: Please provide a keyword" ;;
        "error.update_failed") echo "Error: Failed to update config" ;;
        "error.unknown_config") echo "Unknown config command:" ;;
        
        # Monitor
        "monitor.started") echo "Claude notification monitor started" ;;
        "monitor.info") echo "You'll be notified when Claude asks questions" ;;
        "monitor.exit") echo "Press Ctrl+C to exit" ;;
        "monitor.notification_title") echo "Claude needs your response" ;;
        
        # Install
        "install.title") echo "Claude Notify Installer" ;;
        "install.checking_deps") echo "Checking dependencies..." ;;
        "install.creating_dirs") echo "Creating directories..." ;;
        "install.installing") echo "Installing program files..." ;;
        "install.config_created") echo "Config file created:" ;;
        "install.config_exists") echo "Config file exists, skipping" ;;
        "install.setup_wizard") echo "Claude Notify Setup Wizard" ;;
        "install.enable_sound") echo "Enable sound alerts by default? [Y/n]" ;;
        "install.enable_speech") echo "Enable text-to-speech by default? [y/N]" ;;
        "install.test_notify") echo "Test notification? [Y/n]" ;;
        "install.interactive") echo "Run interactive setup? [Y/n]" ;;
        "install.complete") echo "Installation complete!" ;;
        "install.success_title") echo "Installation Successful" ;;
        "install.success_msg") echo "Claude Notify is ready!" ;;
        
        *) echo "$key" ;;
    esac
}