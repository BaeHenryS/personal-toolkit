#!/usr/bin/env python3
"""
AutoLaunch script to stop Claude notification sounds on any iTerm2 interaction.

Monitors focus changes and keystrokes. When user interacts with any terminal,
kills notification sounds from the custombell hooks and plays a pickup sound.

Resource usage: Minimal - uses async event listeners (waits for events, no polling).
"""

import asyncio
import subprocess
import os
import random
import iterm2

# Path pattern to match notification sounds
SOUND_PATTERN = "afplay.*overcooked.*sounds"
PID_FILE = os.path.expanduser("~/.claude/.overcooked-notify-pids")
SOUNDS_DIR = os.path.expanduser("~/.claude/.overcooked-sounds-dir")

# Pickup sounds to play on successful kill
PICKUP_SOUNDS = [
    "Item_PickUp_01.wav",
    "Item_PickUp_02.wav",
    "Item_PickUp_03.wav",
    "Item_PickUp_04.wav",
    "Item_PickUp_05.wav",
]


def get_sounds_dir():
    """Get the sounds directory from the marker file or use default."""
    if os.path.exists(SOUNDS_DIR):
        with open(SOUNDS_DIR, 'r') as f:
            return f.read().strip()
    # Fallback to old location
    return os.path.expanduser("~/.claude/hooks/overcooked/sounds")


def play_pickup_sound():
    """Play a random pickup sound."""
    try:
        sounds_dir = get_sounds_dir()
        sound_file = os.path.join(sounds_dir, random.choice(PICKUP_SOUNDS))
        if os.path.exists(sound_file):
            subprocess.Popen(["afplay", sound_file])
    except Exception as e:
        print(f"Error playing pickup sound: {e}")


def kill_notification_sounds():
    """Kill any running notification sounds from Claude hooks.

    Returns True if sounds were killed, False otherwise.
    """
    killed = False
    try:
        # Check if there are any sounds to kill
        result = subprocess.run(
            ["pgrep", "-f", SOUND_PATTERN],
            capture_output=True,
            text=True
        )
        print(f"pgrep result: returncode={result.returncode}, stdout='{result.stdout.strip()}'")
        if result.returncode == 0:
            # There are sounds running, kill them
            subprocess.run(["pkill", "-f", SOUND_PATTERN], capture_output=True)
            killed = True
            print("Killed sounds via pkill")

        # Also check and kill PIDs from the PID file
        if os.path.exists(PID_FILE):
            with open(PID_FILE, 'r') as f:
                pids = f.read().strip()
            print(f"PID file contents: '{pids}'")
            if pids:
                for pid in pids.split('\n'):
                    pid = pid.strip()
                    if pid:
                        # Kill process and children
                        subprocess.run(["pkill", "-P", pid], capture_output=True)
                        subprocess.run(["kill", pid], capture_output=True)
                        killed = True
                        print(f"Killed PID {pid}")
                # Clear the PID file
                open(PID_FILE, 'w').close()
    except Exception as e:
        print(f"Error killing sounds: {e}")

    print(f"kill_notification_sounds returning: {killed}")
    return killed


def stop_sounds_and_play_pickup():
    """Kill notification sounds and play pickup if successful."""
    if kill_notification_sounds():
        play_pickup_sound()


async def monitor_focus(connection):
    """Monitor focus changes and kill sounds on any iTerm2 focus event."""
    print("Starting focus monitor...")
    async with iterm2.FocusMonitor(connection) as monitor:
        while True:
            update = await monitor.async_get_next_update()

            # Kill sounds on any focus change to iTerm2
            if update.application_active or update.window_changed or \
               update.selected_tab_changed or update.active_session_changed:
                stop_sounds_and_play_pickup()


async def monitor_keystrokes(connection):
    """Monitor keystrokes and kill sounds on any keypress."""
    print("Starting keystroke monitor...")
    async with iterm2.KeystrokeMonitor(connection) as monitor:
        while True:
            await monitor.async_get()
            stop_sounds_and_play_pickup()


async def main(connection):
    print("Claude Sound Stopper starting...")
    print("Kills notification sounds on any iTerm2 focus or keystroke")
    print("Plays pickup sound on successful kill")

    # Run both monitors concurrently
    await asyncio.gather(
        monitor_focus(connection),
        monitor_keystrokes(connection)
    )


iterm2.run_forever(main)
