#!/bin/bash
# Check if iTerm2 is set up for burning mode (macOS only)

# Check if macOS
if [[ "$(uname)" != "Darwin" ]]; then
    echo "NOT_MACOS"
    exit 0
fi

# Find iTerm2 directory (with or without space in path)
if [ -d "$HOME/Library/ApplicationSupport/iTerm2" ]; then
    ITERM2_BASE="$HOME/Library/ApplicationSupport/iTerm2"
elif [ -d "$HOME/Library/Application Support/iTerm2" ]; then
    ITERM2_BASE="$HOME/Library/Application Support/iTerm2"
else
    echo "NOT_INSTALLED"
    exit 0
fi

# Check if AutoLaunch script exists
if [ -f "$ITERM2_BASE/Scripts/AutoLaunch/claude_sound_stopper.py" ]; then
    echo "INSTALLED"
else
    echo "NOT_INSTALLED"
fi
