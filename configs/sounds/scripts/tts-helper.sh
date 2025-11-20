#!/bin/bash
# Helper script for generating TTS with time references

# Function to generate time-aware greeting
generate_greeting() {
    local hour=$(date +%H)
    local minute=$(date +%M)
    
    if [ "$hour" -ge 5 ] && [ "$hour" -lt 12 ]; then
        echo "Good morning, Matthew. All systems operational. The time is $hour $minute."
    elif [ "$hour" -ge 12 ] && [ "$hour" -lt 18 ]; then
        echo "Good afternoon, Matthew. All systems operational. The time is $hour $minute."
    else
        echo "Good evening, Matthew. All systems operational. The time is $hour $minute."
    fi
}

# Function to generate time-specific message
generate_time_message() {
    local hour=$(date +%H)
    local minute=$(date +%M)
    local period=""
    
    if [ "$hour" -ge 5 ] && [ "$hour" -lt 12 ]; then
        period="morning"
    elif [ "$hour" -ge 12 ] && [ "$hour" -lt 18 ]; then
        period="afternoon"
    else
        period="evening"
    fi
    
    echo "Current time: $hour $minute. This is the $period."
}

# Generate current greeting
generate_greeting

# Generate time message
generate_time_message
