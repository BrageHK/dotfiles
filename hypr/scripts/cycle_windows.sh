#!/bin/bash

# Paths to temporary files
LIST_FILE="/tmp/hyprswitch_window_list.txt"
INDEX_FILE="/tmp/hyprswitch_current_index.txt"

# Action: forward, reverse, or reset
ACTION=$1

# Function to retrieve the list of windows sorted by focusHistoryID ascending
get_window_list() {
    hyprctl clients -j | jq -r 'map(select(.mapped == true)) | sort_by(.focusHistoryID) | .[].address'
}

# Function to reset cycling state
reset_cycling() {
    rm -f "$LIST_FILE" "$INDEX_FILE"
    exit 0
}

# Handle reset action
if [ "$ACTION" == "reset" ]; then
    reset_cycling
fi

# Validate action
if [ "$ACTION" != "forward" ] && [ "$ACTION" != "reverse" ]; then
    exit 1
fi

# If the window list does not exist, create it
if [ ! -f "$LIST_FILE" ]; then
    WINDOW_LIST=$(get_window_list)
    echo "$WINDOW_LIST" > "$LIST_FILE"
else
    # Read window list from file (cached)
    WINDOW_LIST=$(cat "$LIST_FILE")
fi

# Convert window list to an array
WINDOWS=($WINDOW_LIST)
TOTAL_WINDOWS=${#WINDOWS[@]}

# Handle empty window list
if [ "$TOTAL_WINDOWS" -eq 0 ]; then
    reset_cycling
fi

# Get the currently active window's address
CURRENT_WINDOW=$(hyprctl activewindow -j | jq -r '.address')

# Find the index of the current window
CURRENT_INDEX=-1
for i in "${!WINDOWS[@]}"; do
    if [[ "${WINDOWS[$i]}" == "$CURRENT_WINDOW" ]]; then
        CURRENT_INDEX=$i
        break
    fi
done

# If the current window is not found, reset cycling state
if [ "$CURRENT_INDEX" -eq -1 ]; then
    reset_cycling
fi

# Calculate the next index based on action
if [ "$ACTION" == "forward" ]; then
    NEXT_INDEX=$(( (CURRENT_INDEX + 1) % TOTAL_WINDOWS ))
elif [ "$ACTION" == "reverse" ]; then
    NEXT_INDEX=$(( (CURRENT_INDEX - 1 + TOTAL_WINDOWS) % TOTAL_WINDOWS ))
fi

# Focus the next window
NEXT_WINDOW="${WINDOWS[$NEXT_INDEX]}"
hyprctl dispatch focuswindow address:"$NEXT_WINDOW"

# Cache the current index for the next action
echo "$NEXT_INDEX" > "$INDEX_FILE"

exit 0
