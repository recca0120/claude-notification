#!/usr/bin/env bats

# Test suite for configuration reading functionality

setup() {
    export SCRIPT_DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" && pwd )"
    export PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
    export CONFIG_READER="$PROJECT_ROOT/lib/config-reader.sh"
    export CONFIG_FILE="$PROJECT_ROOT/config.json"
}

@test "config-reader.sh exists" {
    [ -f "$CONFIG_READER" ]
}

@test "can read notification enabled setting" {
    source "$CONFIG_READER"
    run get_config_value "notification.enabled"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "can read sound enabled setting" {
    source "$CONFIG_READER"
    run get_config_value "notification.sound.enabled"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "can read sound file path" {
    source "$CONFIG_READER"
    run get_config_value "notification.sound.file"
    [ "$status" -eq 0 ]
    [ "$output" = "/System/Library/Sounds/Glass.aiff" ]
}

@test "can read speech enabled setting" {
    source "$CONFIG_READER"
    run get_config_value "notification.speech.enabled"
    [ "$status" -eq 0 ]
    [ "$output" = "false" ]
}

@test "can read speech voice" {
    source "$CONFIG_READER"
    run get_config_value "notification.speech.voice"
    [ "$status" -eq 0 ]
    [ "$output" = "Samantha" ]
}

@test "can read trigger keywords array" {
    source "$CONFIG_READER"
    run get_config_array "triggers.keywords"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "該怎麼做" ]]
}