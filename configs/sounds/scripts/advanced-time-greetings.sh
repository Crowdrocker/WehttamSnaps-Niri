#!/bin/bash
# Advanced time-aware greeting generator

get_time_period() {
    local hour=$(date +%H)
    
    if [ "$hour" -ge 5 ] && [ "$hour" -lt 12 ]; then
        echo "morning"
    elif [ "$hour" -ge 12 ] && [ "$hour" -lt 18 ]; then
        echo "afternoon"
    else
        echo "evening"
    fi
}

get_formal_time() {
    local hour=$(date +%H)
    local minute=$(date +%M)
    
    # Convert to 12-hour format for more natural speech
    if [ "$hour" -eq 0 ]; then
        echo "12 $minute AM"
    elif [ "$hour" -lt 12 ]; then
        echo "$hour $minute AM"
    elif [ "$hour" -eq 12 ]; then
        echo "12 $minute PM"
    else
        echo "$((hour - 12)) $minute PM"
    fi
}

# Generate various time-aware greetings
generate_startup_greeting() {
    local period=$(get_time_period)
    local formal_time=$(get_formal_time)
    
    echo "Good $period, Matthew. All systems operational."
    echo "Good $period, Matthew. The time is $formal_time. All systems are ready."
    echo "Allow me to introduce myself, I am JARVIS, a virtual artificial intelligence. All systems are ready for gaming and work."
    echo "System check complete. Current time: $formal_time. All systems nominal."
}

# Generate time-specific messages
generate_time_messages() {
    local period=$(get_time_period)
    local hour=$(date +%H)
    
    echo "The time is now $(get_formal_time). All systems ready for a productive $period."
    echo "Current time: $(get_formal_time). $period mode activated."
    echo "System time: $(get_formal_time). All systems running optimally."
    
    # Add some personality based on time
    if [ "$hour" -ge 5 ] && [ "$hour" -lt 9 ]; then
        echo "Good morning, Matthew. Early bird gets the worm, and all systems are ready."
    elif [ "$hour" -ge 9 ] && [ "$hour" -lt 17 ]; then
        echo "Good day, Matthew. Prime time for productivity. All systems operational."
    elif [ "$hour" -ge 17 ] && [ "$hour" -lt 22 ]; then
        echo "Good evening, Matthew. Perfect time for gaming. All systems ready."
    else
        echo "Good evening, Matthew. Late night session. All systems operational."
    fi
}

echo "=== STARTUP GREETINGS ==="
generate_startup_greeting

echo ""
echo "=== TIME-SPECIFIC MESSAGES ==="
generate_time_messages
