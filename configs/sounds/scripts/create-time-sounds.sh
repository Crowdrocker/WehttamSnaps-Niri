#!/bin/bash
# J.A.R.V.I.S. Time-Based Sound Creation Script
# Creates scripts to generate time-aware TTS audio

echo "🕐 J.A.R.V.I.S. Time Sound Creation Guide"
echo "========================================="
echo ""

# Create time-aware greeting script
cat > time-greeting-generator.sh << 'EOF'
#!/bin/bash
# Generate time-aware J.A.R.V.I.S. greetings

# Get current hour
HOUR=$(date +%H)

# Determine greeting based on time
if [ "$HOUR" -ge 5 ] && [ "$HOUR" -lt 12 ]; then
    # Morning (5 AM - 11:59 AM)
    PERIOD="morning"
    GREETING="Good morning, Matthew. All systems operational."
elif [ "$HOUR" -ge 12 ] && [ "$HOUR" -lt 18 ]; then
    # Afternoon (12 PM - 5:59 PM)
    PERIOD="afternoon"
    GREETING="Good afternoon, Matthew. All systems operational."
else
    # Evening (6 PM - 4:59 AM)
    PERIOD="evening"
    GREETING="Good evening, Matthew. All systems operational."
fi

echo "Current time: $(date +%H:%M)"
echo "Time period: $PERIOD"
echo "Greeting: $GREETING"
echo ""

# Save greeting to file
echo "$GREETING" > current-greeting.txt
echo "✓ Greeting saved to current-greeting.txt"
EOF

chmod +x time-greeting-generator.sh

echo "✓ Created time-greeting-generator.sh"
echo ""

# Create TTS generation helper
cat > tts-helper.sh << 'EOF'
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
EOF

chmod +x tts-helper.sh

echo "✓ Created tts-helper.sh"
echo ""

# Create specific TTS phrases for 101soundboards.com
cat > tts-phrases.txt << 'EOF'
=== J.A.R.V.I.S. Time-Aware Phrases ===

For 101soundboards.com, use voice: 73296-jarvis-v1-paul-bettany-tts-computer-ai-voice

=== TIME-BASED GREETINGS ===

MORNING (5 AM - 11:59 AM):
"Good morning, Matthew. All systems operational."

AFTERNOON (12 PM - 5:59 PM):
"Good afternoon, Matthew. All systems operational."

EVENING (6 PM - 4:59 AM):
"Good evening, Matthew. All systems operational."

=== ALTERNATIVE TIME REFERENCES ===

"Allow me to introduce myself, I am JARVIS, a virtual artificial intelligence. All systems are ready for gaming and work."

"Current time: 9 AM. All systems operational."

"Current time: 3 PM. All systems operational."

"Current time: 9 PM. All systems operational."

=== DYNAMIC TIME PHRASES ===

"The time is now 8 AM. All systems ready for a productive day."

"The time is now 2 PM. Systems running optimally."

"The time is now 8 PM. Evening mode activated."

=== SYSTEM STATUS WITH TIME ===

"System check complete. Current time: 7 AM. All systems nominal."

"System check complete. Current time: 1 PM. All systems nominal."

"System check complete. Current time: 10 PM. All systems nominal."
EOF

echo "✓ Created tts-phrases.txt with time-aware phrases"
echo ""

# Create advanced time script with more options
cat > advanced-time-greetings.sh << 'EOF'
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
EOF

chmod +x advanced-time-greetings.sh

echo "✓ Created advanced-time-greetings.sh"
echo ""

# Create usage instructions
cat > TIME-TTS-USAGE.md << 'EOF'
# Time-Aware TTS Usage Guide

## Using 101soundboards.com

1. Go to: https://www.101soundboards.com/
2. Search for: `73296-jarvis-v1-paul-bettany-tts-computer-ai-voice`
3. Use the voice generator
4. Type your time-aware phrase
5. Download as MP3
6. Name appropriately

## Time-Aware Phrases to Create

### Basic Time Periods
1. **Morning (5 AM - 11:59 AM)**:
   - "Good morning, Matthew. All systems operational."

2. **Afternoon (12 PM - 5:59 PM)**:
   - "Good afternoon, Matthew. All systems operational."

3. **Evening (6 PM - 4:59 AM)**:
   - "Good evening, Matthew. All systems operational."

### Alternative Options
4. **Generic startup**:
   - "Allow me to introduce myself, I am JARVIS, a virtual artificial intelligence. All systems are ready for gaming and work."

5. **System check with time**:
   - "System check complete. Current time: 9 AM. All systems nominal."
   - "System check complete. Current time: 3 PM. All systems nominal."
   - "System check complete. Current time: 9 PM. All systems nominal."

## How to Use

1. Run the script to see current suggestions:
   ```bash
   ./time-greeting-generator.sh
   ```

2. Run the advanced script for more options:
   ```bash
   ./advanced-time-greetings.sh
   ```

3. Copy the phrases you like to 101soundboards.com
4. Save as MP3 files with appropriate names:
   - `morning.mp3`
   - `afternoon.mp3`
   - `evening.mp3`
   - `startup.mp3` (for generic)

## Pro Tips

- Use 12-hour format for more natural speech
- Keep phrases short and clear
- Test different voice speeds
- Download multiple variations
- Name files descriptively

## Integration

The JARVIS scripts will automatically detect the time and play the appropriate sound based on:
- 5 AM - 11:59 AM: Morning greeting
- 12 PM - 5:59 PM: Afternoon greeting  
- 6 PM - 4:59 AM: Evening greeting

EOF

echo "✓ Created TIME-TTS-USAGE.md with detailed instructions"
echo ""
echo "🕐 Time-aware TTS setup complete!"
echo ""
echo "Next steps:"
echo "1. Run ./time-greeting-generator.sh to see current suggestions"
echo "2. Run ./advanced-time-greetings.sh for more options"
echo "3. Go to 101soundboards.com and create your MP3 files"
echo "4. Save them as morning.mp3, afternoon.mp3, evening.mp3"
echo "5. Place in ~/.config/jarvis/sounds/ after installation"