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
