#!/bin/bash
# Toggle extended sounds (Warning + Fire) on/off
# Only effective in iTerm2 with overcooked mode enabled
TOGGLE_FILE="$HOME/.claude/.overcooked-extended-enabled"

if [ -f "$TOGGLE_FILE" ]; then
    rm "$TOGGLE_FILE"
    echo "Burning Mode: DISABLED"
else
    touch "$TOGGLE_FILE"
    echo "Burning Mode: ENABLED (Warning + Fire sounds active)"
fi
