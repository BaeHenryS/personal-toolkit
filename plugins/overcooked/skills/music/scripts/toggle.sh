#!/bin/bash
MUSIC_PID_FILE="$HOME/.claude/.overcooked-music-pid"
MUSIC_LOOP="${CLAUDE_PLUGIN_ROOT}/skills/music/scripts/music-loop.sh"

# Check if music is playing
if [ -f "$MUSIC_PID_FILE" ]; then
    PID=$(cat "$MUSIC_PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
        # Music playing - stop it
        pkill -P "$PID" 2>/dev/null
        kill "$PID" 2>/dev/null
        rm "$MUSIC_PID_FILE"
        echo "Music: STOPPED"
        exit 0
    fi
fi

# Music not playing - start it
nohup "$MUSIC_LOOP" > /dev/null 2>&1 &
echo $! > "$MUSIC_PID_FILE"
echo "Music: PLAYING"
