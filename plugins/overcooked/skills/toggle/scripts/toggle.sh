#!/bin/bash
# Toggle overcooked notification sounds on/off
TOGGLE_FILE="$HOME/.claude/.overcooked-enabled"

if [ -f "$TOGGLE_FILE" ]; then
    rm "$TOGGLE_FILE"
    echo "Overcooked Mode: DISABLED"
else
    touch "$TOGGLE_FILE"
    echo "Overcooked Mode: ENABLED"
fi
