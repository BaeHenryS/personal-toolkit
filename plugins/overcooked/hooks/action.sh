#!/bin/bash
# Called when user takes action (submits prompt)
# Stops any running notification sounds and plays putdown

SOUNDS_DIR="${CLAUDE_PLUGIN_ROOT}/skills/toggle/sounds"
OVERCOOKED_FILE="$HOME/.claude/.overcooked-enabled"
PID_FILE="$HOME/.claude/.overcooked-notify-pids"

# Exit if overcooked mode is disabled
if [ ! -f "$OVERCOOKED_FILE" ]; then
    exit 0
fi

# Kill any running notification sounds
if [ -f "$PID_FILE" ]; then
    while read -r pid; do
        # Skip empty lines
        [ -z "$pid" ] && continue
        # Kill the process and its children (for the subshell with afplay)
        pkill -P "$pid" 2>/dev/null || true
        kill "$pid" 2>/dev/null || true
    done < "$PID_FILE"
    > "$PID_FILE"
fi

# Also kill any lingering afplay processes for notification sounds (not music)
pkill -f "afplay.*/skills/toggle/sounds" 2>/dev/null || true

# Play random putdown sound
PUTDOWN_SOUNDS=("Item_PutDown_01.wav" "Item_PutDown_02.wav" "Item_PutDown_03.wav" "Item_PutDown_04.wav" "Item_PutDown_05.wav")
RANDOM_SOUND=${PUTDOWN_SOUNDS[$RANDOM % ${#PUTDOWN_SOUNDS[@]}]}
afplay "$SOUNDS_DIR/$RANDOM_SOUND" &

exit 0
