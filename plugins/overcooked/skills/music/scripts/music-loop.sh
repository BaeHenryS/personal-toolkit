#!/bin/bash
MUSIC_DIR="${CLAUDE_PLUGIN_ROOT}/skills/music/sounds"
MUSIC_FILES=("$MUSIC_DIR"/*.wav)

if [ ${#MUSIC_FILES[@]} -eq 0 ] || [ ! -f "${MUSIC_FILES[0]}" ]; then
    exit 0
fi

while true; do
    TRACK="${MUSIC_FILES[$RANDOM % ${#MUSIC_FILES[@]}]}"
    afplay "$TRACK"
    sleep 3
done
