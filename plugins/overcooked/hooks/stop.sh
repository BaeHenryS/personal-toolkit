#!/bin/bash
# Simple stop notification - just ImCooked, no extended sounds

SOUNDS_DIR="${CLAUDE_PLUGIN_ROOT}/skills/toggle/sounds"
OVERCOOKED_FILE="$HOME/.claude/.overcooked-enabled"

# Exit if overcooked mode is disabled
if [ ! -f "$OVERCOOKED_FILE" ]; then
    exit 0
fi

afplay "$SOUNDS_DIR/ImCooked.wav" &

exit 0
