#!/bin/bash
# Called on notification (Claude needs attention)

SOUNDS_DIR="${CLAUDE_PLUGIN_ROOT}/skills/toggle/sounds"
OVERCOOKED_FILE="$HOME/.claude/.overcooked-enabled"
EXTENDED_FILE="$HOME/.claude/.overcooked-extended-enabled"
PID_FILE="$HOME/.claude/.overcooked-notify-pids"

# Exit if overcooked mode is disabled
if [ ! -f "$OVERCOOKED_FILE" ]; then
    exit 0
fi

# Clear any old PIDs
> "$PID_FILE"

# Always play ImCooked immediately
afplay "$SOUNDS_DIR/ImCooked.wav" &
echo $! >> "$PID_FILE"

# Extended sounds only in iTerm2, and only if user is NOT already focused on it
FRONTMOST=$(osascript -e 'tell application "System Events" to get name of first process whose frontmost is true' 2>/dev/null)
if [ "$TERM_PROGRAM" = "iTerm.app" ] && [ -f "$EXTENDED_FILE" ] && [ "$FRONTMOST" != "iTerm2" ]; then
    (
        # Wait 3 seconds before extended sounds
        sleep 3

        # Play warning sound
        afplay "$SOUNDS_DIR/CookingWarning_Accelerating_FINAL_v2.wav"

        # Play random fire ignition
        FIRE_SOUNDS=("FireIgnition.wav" "FireIgnition1.wav" "FireIgnition2.wav" "FireIgnition3.wav")
        RANDOM_SOUND=${FIRE_SOUNDS[$RANDOM % ${#FIRE_SOUNDS[@]}]}
        afplay "$SOUNDS_DIR/$RANDOM_SOUND"
    ) &
    echo $! >> "$PID_FILE"
fi

exit 0
