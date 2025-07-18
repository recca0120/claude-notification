#!/bin/bash

# Test script for Claude notification system
# Using TDD approach - write tests first

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Test helper functions
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="$3"
    
    if [ "$expected" = "$actual" ]; then
        echo -e "${GREEN}✓${NC} $message"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} $message"
        echo "  Expected: $expected"
        echo "  Actual: $actual"
        ((TESTS_FAILED++))
    fi
}

assert_exit_code() {
    local expected="$1"
    local actual="$2"
    local message="$3"
    
    if [ "$expected" -eq "$actual" ]; then
        echo -e "${GREEN}✓${NC} $message"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} $message"
        echo "  Expected exit code: $expected"
        echo "  Actual exit code: $actual"
        ((TESTS_FAILED++))
    fi
}

# Test 1: Basic notification display
test_basic_notification() {
    echo "Test 1: Basic notification display"
    
    # Test that the notification script exists
    if [ ! -f "../claude-notify.sh" ]; then
        echo -e "${RED}✗${NC} claude-notify.sh does not exist"
        ((TESTS_FAILED++))
        return
    fi
    
    # Test basic notification
    ../claude-notify.sh "Test Title" "Test Message" 2>/dev/null
    assert_exit_code 0 $? "Should display notification successfully"
}

# Test 2: Notification with sound
test_notification_with_sound() {
    echo -e "\nTest 2: Notification with sound"
    
    # Test notification with sound
    ../claude-notify.sh "Test Title" "Test Message" --sound 2>/dev/null
    assert_exit_code 0 $? "Should play sound with notification"
}

# Test 3: Notification with text-to-speech
test_notification_with_tts() {
    echo -e "\nTest 3: Notification with text-to-speech"
    
    # Test notification with TTS
    ../claude-notify.sh "Test Title" "Test Message" --speak 2>/dev/null
    assert_exit_code 0 $? "Should speak notification message"
}

# Test 4: Configuration file
test_configuration() {
    echo -e "\nTest 4: Configuration file"
    
    # Test reading configuration
    if [ -f "../config.json" ]; then
        echo -e "${GREEN}✓${NC} config.json exists"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} config.json does not exist"
        ((TESTS_FAILED++))
    fi
}

# Run all tests
echo "Running Claude Notification Tests"
echo "================================="

test_basic_notification
test_notification_with_sound
test_notification_with_tts
test_configuration

# Summary
echo -e "\n================================="
echo "Test Summary:"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Failed: $TESTS_FAILED${NC}"

# Exit with appropriate code
if [ $TESTS_FAILED -eq 0 ]; then
    exit 0
else
    exit 1
fi