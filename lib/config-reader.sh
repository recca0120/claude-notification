#!/bin/bash

# Configuration reader for claude-notify
# Reads JSON configuration using jq

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="${CONFIG_FILE:-$PROJECT_ROOT/config.json}"

# Function to get a single value from config
get_config_value() {
    local key="$1"
    local value
    
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Error: Config file not found: $CONFIG_FILE" >&2
        return 1
    fi
    
    value=$(jq -r ".$key" "$CONFIG_FILE" 2>/dev/null)
    
    if [ $? -eq 0 ] && [ "$value" != "null" ]; then
        echo "$value"
        return 0
    else
        return 1
    fi
}

# Function to get an array from config
get_config_array() {
    local key="$1"
    local array
    
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Error: Config file not found: $CONFIG_FILE" >&2
        return 1
    fi
    
    array=$(jq -r ".$key[]" "$CONFIG_FILE" 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        echo "$array"
        return 0
    else
        return 1
    fi
}

# Function to check if a value exists in config array
is_in_config_array() {
    local key="$1"
    local search_value="$2"
    local array_values
    
    array_values=$(get_config_array "$key")
    
    if [ $? -eq 0 ]; then
        while IFS= read -r value; do
            if [[ "$search_value" =~ $value ]]; then
                return 0
            fi
        done <<< "$array_values"
    fi
    
    return 1
}