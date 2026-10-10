#!/bin/bash
set -e

# Function to check if a PID is elevated (UID 0)
is_elevated() {
    local pid=$1
    if [ -f "/proc/$pid/status" ]; then
        local uid=$(awk '/Uid:/ {print $2}' "/proc/$pid/status" 2>/dev/null)
        if [ "$uid" -eq 0 ]; then
            return 0
        fi
    fi
    return 1
}

# Function to find child processes recursively up to 10 layers
find_children() {
    local pid=$1
    local depth=$2
    if [ $depth -gt 15 ]; then
        return
    fi
    local children=$(ps --ppid "$pid" -o pid= | tr -d ' ')
    for child_pid in $children; do
        echo "$child_pid"
        find_children "$child_pid" $((depth+1))
    done
}

# Function to find parent processes until a window PID is found
find_window_pid() {
    local pid=$1
    local window_pids=($(hyprctl clients -j | jq -r '.[] | .pid'))

    # Check if the PID itself is a window PID
    if printf '%s\n' "${window_pids[@]}" | grep -q "^$pid$"; then
        echo "$pid"
        return
    fi

    # Traverse parents until we find a window PID
    local current_pid=$pid
    while [ -f "/proc/$current_pid/status" ]; do
        local parent_pid=$(awk '/PPid:/ {print $2}' "/proc/$current_pid/status" 2>/dev/null)
        if [ -z "$parent_pid" ]; then
            break
        fi
        if printf '%s\n' "${window_pids[@]}" | grep -q "^$parent_pid$"; then
            echo "$parent_pid"
            return
        fi
        current_pid=$parent_pid
    done
}

# Function to find the PID of the start-hyprland process
get_start_hyprland_pid() {
    pgrep -f "start-hyprland" | head -n 1
}

# Function to verify and remove tags from windows that are no longer elevated
verify_elevated_tags() {
    # Get all windows currently tagged as elevated
    local elevated_windows=$(hyprctl clients -j | jq -r '.[] | select(.tags[]? | contains("elevated")) | "\(.pid) \(.address)"')

    # Check if there are any elevated windows
    if [ -z "$elevated_windows" ]; then
        echo "No windows are currently tagged as elevated."
        return 0
    fi

    # Process each elevated window
    while IFS= read -r line; do
        local window_pid=$(echo "$line" | awk '{print $1}')
        local window_address=$(echo "$line" | awk '{print $2}')

        # Find all related processes for this window PID
        local still_elevated=0

        # Check if the window PID itself is elevated
        if is_elevated "$window_pid"; then
            still_elevated=1
        else
            # Check child processes of the window PID
            local children=$(find_children "$window_pid" 1)
            while IFS= read -r child_pid; do
                if is_elevated "$child_pid"; then
                    still_elevated=1
                    break
                fi
            done <<< "$children"
        fi

        # If no related processes are elevated, remove the tag
        if [ "$still_elevated" -eq 0 ]; then
            echo "Window Address: $window_address no longer has elevated processes, removing tag"
            hyprctl dispatch tagwindow -- -elevated address:$window_address
        fi
    done <<< "$elevated_windows"
}

# Main script
while true; do
    echo "Checking for elevated processes under start-hyprland..."

    # Get the PID of start-hyprland
    start_hyprland_pid=$(get_start_hyprland_pid)
    if [ -z "$start_hyprland_pid" ]; then
        echo "Error: start-hyprland process not found. Is Hyprland running?"
        continue
    fi

    echo "Found start-hyprland PID: $start_hyprland_pid"

    # Get all child processes of start-hyprland
    echo "Finding child processes of start-hyprland..."
    child_pids=$(find_children "$start_hyprland_pid" 1)

    # Check each child process for elevation
    while IFS= read -r pid; do
        if is_elevated "$pid"; then
            echo "Found elevated PID: $pid"
            # Find the window PID associated with this elevated process
            window_pid=$(find_window_pid "$pid")
            if [ -n "$window_pid" ]; then
                echo "Found window PID: $window_pid"
                # Get the window address for the window PID
                window_address=$(hyprctl clients -j | jq -r --arg pid "$window_pid" '.[] | select(.pid == ($pid | tonumber)) | .address')
                if [ -n "$window_address" ]; then
                    echo "Tagging window with address: $window_address"
                    hyprctl dispatch tagwindow +elevated address:$window_address
                else
                    echo "No window address found for PID: $window_pid"
                fi
            else
                echo "No window PID found for elevated PID: $pid"
            fi
        fi
    done <<< "$child_pids"

    # Verify and remove tags from windows that are no longer elevated
    verify_elevated_tags
done
