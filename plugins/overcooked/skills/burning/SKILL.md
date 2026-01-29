---
name: burning
description: Toggle extended Warning + Fire sounds (iTerm2/macOS only)
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/skills/burning/scripts/*)
---

# Burning Mode (Extended Sounds)

Extended sounds (Warning + Fire) only work in iTerm2 on macOS.

## First, check iTerm2 setup

Check if the iTerm2 AutoLaunch script is installed:
```bash
${CLAUDE_PLUGIN_ROOT}/skills/burning/scripts/check-iterm2.sh
```

If output is "NOT_INSTALLED":
1. Ask user: "Burning mode requires iTerm2 setup. Install the AutoLaunch script? (This enables pickup sounds when you interact with the terminal)"
2. If yes, run: `${CLAUDE_PLUGIN_ROOT}/skills/burning/scripts/install-iterm2.sh`
3. Tell user: "Restart iTerm2 or enable Python API: iTerm2 → Scripts → Manage → Enable Python API"

If output is "NOT_MACOS":
1. Tell user: "Burning mode is only available on macOS with iTerm2."
2. Do not proceed.

## Then toggle burning mode

Run:
```bash
${CLAUDE_PLUGIN_ROOT}/skills/burning/scripts/toggle-burning.sh
```

Output:
- If ENABLED: "Burning Mode: ENABLED (Warning + Fire sounds active)"
- If DISABLED: "Burning Mode: DISABLED"
