#!/usr/bin/env bats

# Test suite for keyword detection functionality

setup() {
    export SCRIPT_DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" && pwd )"
    export PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
    export KEYWORD_DETECTOR="$PROJECT_ROOT/lib/keyword-detector.sh"
    export CONFIG_FILE="$PROJECT_ROOT/config.json"
}

@test "keyword-detector.sh exists" {
    [ -f "$KEYWORD_DETECTOR" ]
}

@test "detects keywords from config" {
    source "$KEYWORD_DETECTOR"
    # Test with various Chinese keywords
    run check_for_keywords "Claude 詢問：這個功能該怎麼做呢？"
    [ "$status" -eq 0 ]
    
    run check_for_keywords "請問這要怎麼做？"
    [ "$status" -eq 0 ]
    
    run check_for_keywords "如何實作這個功能？"
    [ "$status" -eq 0 ]
    
    run check_for_keywords "請問您想要使用哪種方式？"
    [ "$status" -eq 0 ]
    
    run check_for_keywords "您想選擇哪個選項？"
    [ "$status" -eq 0 ]
    
    run check_for_keywords "要選擇哪種實作方式？"
    [ "$status" -eq 0 ]
}

@test "returns false when no keywords found" {
    source "$KEYWORD_DETECTOR"
    run check_for_keywords "這是一般的訊息內容"
    [ "$status" -eq 1 ]
}

@test "monitor_for_keywords function exists" {
    source "$KEYWORD_DETECTOR"
    type -t monitor_for_keywords | grep -q function
}