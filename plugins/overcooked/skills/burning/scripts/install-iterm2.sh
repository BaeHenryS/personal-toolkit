#!/bin/bash
# Install claude_sound_stopper.py to iTerm2 AutoLaunch (macOS only)

if [[ "$(uname)" != "Darwin" ]]; then
    echo "Error: iTerm2 is only available on macOS"
    exit 1
fi

# Find iTerm2 directory
if [ -d "$HOME/Library/ApplicationSupport/iTerm2" ]; then
    ITERM2_BASE="$HOME/Library/ApplicationSupport/iTerm2"
elif [ -d "$HOME/Library/Application Support/iTerm2" ]; then
    ITERM2_BASE="$HOME/Library/Application Support/iTerm2"
else
    echo "Error: iTerm2 not found. Please install iTerm2 first."
    exit 1
fi

SOURCE="${CLAUDE_PLUGIN_ROOT}/skills/burning/iterm2/claude_sound_stopper.py"
TARGET="$ITERM2_BASE/Scripts/AutoLaunch/claude_sound_stopper.py"

mkdir -p "$(dirname "$TARGET")"

if [ "$1" = "--copy" ]; then
    cp "$SOURCE" "$TARGET"
    echo "Copied claude_sound_stopper.py to iTerm2 AutoLaunch"
else
    ln -sf "$SOURCE" "$TARGET"
    echo "Symlinked claude_sound_stopper.py to iTerm2 AutoLaunch"
    echo "(Use --copy if symlink doesn't work)"
fi
