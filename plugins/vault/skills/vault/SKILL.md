---
name: vault
description: Show or update Obsidian vault configuration and permissions
argument-hint: "[path | personal | company | permissions <safe|full>]"
disable-model-invocation: true
---

# Vault Configuration & Permissions

Manage Obsidian vault paths and configure Claude Code permissions for vault skills.

## Critical Rule

**`OBSIDIAN_VAULT` env and `config/config.yaml` must ALWAYS point to the same vault.**

When updating either, update both.

## Current Status

Read `~/.claude/settings.json` and display:
- Active vault: `env.OBSIDIAN_VAULT`
- Personal vault: `env.PERSONAL_VAULT`
- Company vault: `env.COMPANY_VAULT`

## Arguments

$ARGUMENTS

## Execution

### If no arguments: Show status only

Display the current status above. If active vault is configured, also read and display the structure from `<vault_path>/vault-config.yaml`.

### If `company`: Switch to company vault

1. Read `COMPANY_VAULT` from `~/.claude/settings.json`
2. Update `~/.claude/settings.json`:
   - Set `env.OBSIDIAN_VAULT` to the company vault path
3. Update thought-organizer config (if cwd contains `config/config.yaml`):
   - Set `vault.path` to the company vault path
4. Report success

### If `personal`: Switch to personal vault

1. Read `PERSONAL_VAULT` from `~/.claude/settings.json`
2. Update `~/.claude/settings.json`:
   - Set `env.OBSIDIAN_VAULT` to the personal vault path
3. Update thought-organizer config (if cwd contains `config/config.yaml`):
   - Set `vault.path` to the personal vault path
4. Report success

### If path argument provided: Set personal vault path

1. **Validate the path**
   - Expand `~` if present
   - Verify path exists and is a directory
   - Check for `.obsidian/` folder (confirms it's an Obsidian vault)
   - Check for `vault-config.yaml` - if missing, offer to create with defaults

2. **Update `~/.claude/settings.json`**
   - Set `env.PERSONAL_VAULT` to the new path
   - Set `env.OBSIDIAN_VAULT` to the new path (make it active)
   - Preserve all other settings

3. **Update thought-organizer config (if cwd contains `config/config.yaml`)**
   - Set `vault.path` to the new path

4. **Report success**

### If `--set-company path`: Set company vault path

1. Validate path exists
2. Update `~/.claude/settings.json` with `env.COMPANY_VAULT`
3. Do NOT change active vault (OBSIDIAN_VAULT) unless `--company` also passed
4. Report success

### If `permissions safe`: Configure read-only permissions

Configure minimal permissions for vault skills (read-only vault access).

#### Step 1: Read Vault Locations

Read `~/.claude/settings.json` and extract:
- `env.OBSIDIAN_VAULT` → personal vault (required)
- `env.COMPANY_VAULT` → company vault (optional)

If OBSIDIAN_VAULT is not set, stop and tell the user to run `/vault` first to configure their vault path.

#### Step 2: Read Vault Structures

For the personal vault, read `$OBSIDIAN_VAULT/vault-config.yaml` to get folder names.

If vault-config.yaml doesn't exist, use these defaults:
```yaml
daily_notes: "Daily Notes"
projects: "Projects"
notes: "Notes"
references: "References"
clippings: "Clippings"
processed: "Processed"
processed_coding: "Processed/Coding"
prototypes: "Processed/Prototypes"
style_guide: "style-guide.md"
```

#### Step 3: Generate Safe Mode Permissions

**Personal vault - Read only:**
(Use `//` prefix for absolute paths - NOT single `/`)
```
Read(//$OBSIDIAN_VAULT/**)
```

**Company vault - Read only (if configured):**
```
Read(//$COMPANY_VAULT/**)
```

**Claude data (for devlog):**
```
Read(~/.claude/projects/**/*.jsonl)
Read(~/.claude/plans/**)
```

**Bash commands - minimal set:**
```
Bash(ls:*)
Bash(git status:*)
Bash(git diff:*)
Bash(git log:*)
```

#### Step 4: Update Settings

1. Read current `~/.claude/settings.json`
2. Get existing `permissions.allow` array (or create empty array if none)
3. **Remove any existing vault-related permissions** before adding new ones (to ensure clean mode switches)
4. Add the new permission rules based on selected mode
5. Preserve all other settings (model, hooks, env, plugins, etc.)
6. Write the updated settings.json with proper JSON formatting

**Important:** Use actual resolved paths in the permissions (not environment variables), since permissions are resolved at settings load time.

#### Step 5: Report

```
Vault Permissions Configured (SAFE MODE)

Personal Vault: $OBSIDIAN_VAULT
  - Read-only access

Company Vault: $COMPANY_VAULT (or "Not configured")
  - Read-only access

Claude Data:
  - Read access to session transcripts and plans

Bash Commands:
  - ls (directory listing)
  - git status/diff/log (read-only git operations)

Total permissions added: X

Note: Read-only access. Use `/vault permissions full` for write access.

IMPORTANT: Restart Claude Code for permissions to take effect.
```

### If `permissions full`: Configure full read/write permissions

Configure full read/write/edit permissions for vault skills.

#### Step 1-2: Same as safe mode

Read vault locations and structures.

#### Step 3: Generate Full Mode Permissions

**Personal vault - full Read/Write/Edit access:**
(Use `//` prefix for absolute paths - NOT single `/`)
```
Read(//$OBSIDIAN_VAULT/**)
Edit(//$OBSIDIAN_VAULT/**)
Write(//$OBSIDIAN_VAULT/**)
```

**Company vault - full Read/Write/Edit access (if configured):**
```
Read(//$COMPANY_VAULT/**)
Edit(//$COMPANY_VAULT/**)
Write(//$COMPANY_VAULT/**)
```

**Claude data (for devlog):**
```
Read(~/.claude/projects/**/*.jsonl)
Read(~/.claude/plans/**)
```

**Bash commands for vault operations:**
(Use `command:*` format - the colon creates a word boundary for prefix matching)
```
Bash(grep:*)
Bash(ls:*)
Bash(mkdir:*)
Bash(cp:*)
Bash(head:*)
Bash(tail:*)
Bash(cat:*)
Bash(sort:*)
Bash(wc:*)
Bash(echo:*)
Bash(git status:*)
Bash(git diff:*)
Bash(git add:*)
Bash(git commit:*)
Bash(git log:*)
```

#### Step 4: Update Settings

Same as safe mode.

#### Step 5: Report

```
Vault Permissions Configured (FULL MODE)

Personal Vault: $OBSIDIAN_VAULT
  - Full Read/Write/Edit access

Company Vault: $COMPANY_VAULT (or "Not configured")
  - Full Read/Write/Edit access

Claude Data:
  - Read access to session transcripts and plans

Bash Commands:
  - grep, ls, mkdir, cp (file operations)
  - head, tail, cat, sort, wc (file reading)
  - echo (output)
  - git status/diff/add/commit/log (git operations)

Total permissions added: X

Note: Full write access enabled. Use `/vault permissions safe` to restrict to read-only.

IMPORTANT: Restart Claude Code for permissions to take effect.
```

## Path Prefix Rules

- `//path` = Absolute path from filesystem root (use this for vault paths)
- `~/path` = Path from home directory
- `/path` = Path relative to settings file (NOT absolute!)

## Default vault-config.yaml

If creating a new vault-config.yaml, use:

```yaml
# Vault Structure Configuration
daily_notes: "Daily Notes"
projects: "Projects"
notes: "Notes"
references: "References"
clippings: "Clippings"
processed: "Processed"
processed_coding: "Processed/Coding"
prototypes: "Processed/Prototypes"
style_guide: "style-guide.md"
```

## Verification

After the user restarts Claude Code, they can verify by:

### Safe Mode Verification
1. `ls` should work without permission prompts
2. `git status` should work without permission prompts
3. `cat`, `grep`, `mkdir` should prompt for permission (not pre-approved)
4. Editing vault files should prompt for permission (not pre-approved)

### Full Mode Verification
1. Running `/vault:devlog` - should complete without permission prompts
2. Running `/vault:stylize Notes/` - should complete without permission prompts
