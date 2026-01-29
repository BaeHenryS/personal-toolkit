#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -n "$PLUGIN_ROOT" ]; then
    MUSIC_DIR="${PLUGIN_ROOT}/skills/music/sounds"
else
    MUSIC_DIR="$SCRIPT_DIR/../sounds"
fi
MUSIC_FILES=("$MUSIC_DIR"/*.wav)

if [ ${#MUSIC_FILES[@]} -eq 0 ] || [ ! -f "${MUSIC_FILES[0]}" ]; then
    exit 0
fi

while true; do
    TRACK="${MUSIC_FILES[$RANDOM % ${#MUSIC_FILES[@]}]}"
    afplay "$TRACK"
    sleep 3
done
