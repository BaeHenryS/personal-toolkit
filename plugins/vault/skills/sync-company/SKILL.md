---
name: sync-company
description: Sync notes from personal vault to a shared team knowledge base. Takes content specified after the command, formats it per the target KB's style guide, and writes to daily notes (with attribution) and optionally a dedicated note.
---

# Sync to Shared Knowledge Base

Transfer content from your personal notes to a shared team knowledge base.

---

## Configuration

Read `~/.claude/settings.json` and extract:
- `env.PERSONAL_VAULT` → source vault (personal)
- `env.COMPANY_VAULT` → target vault (company)

If either is not set, display: "Vaults not configured. Run /vault first."

**Source vault (personal):**
- Path from `env.PERSONAL_VAULT`
- Structure from `<personal_vault_path>/vault-config.yaml`

**Target vault (company):**
- Path from `env.COMPANY_VAULT`
- Structure from `<company_vault_path>/vault-config.yaml` (if exists)

**Author settings (user-specific):**
```yaml
author_name: "Henry"
author_wikilink: "[[Henry]]"  # Links to author's profile in KB
```

---

## Usage

```
/sync-company <description of content to transfer>
```

**Examples:**
```
/sync-company The idea about embedder agents parsing spec sheets with vision
/sync-company My thoughts on customer error classification from today's notes
/sync-company Transfer the agent verbosity notes to a dedicated note
```

---

## Execution Steps

### Step 1: Read Target KB Style Guide

Read the style guide at the target KB root:
```
$COMPANY_VAULT/style-guide.md
```

Apply its formatting rules. Key conventions:
- Filenames: kebab-case
- Frontmatter: include `categories`, `created`, `author`
- Attribution in daily notes: `[{author_name}]` section notation
- Wikilinks for cross-references

### Step 2: Find Source Content

Based on the user's description, locate the content in the personal vault:

1. **Check today's daily note**: `$PERSONAL_VAULT/<daily_notes>/YYYY-MM-DD.md` (daily_notes from vault-config.yaml)
2. **Search recent daily notes** if not found today
3. **Check Notes/, Projects/, etc.** if referencing an existing note (paths from vault-config.yaml)

**If content cannot be found**: Ask the user to clarify or provide the content directly.

### Step 3: Determine Destination Type

Decide where the content should go in the target KB:

| Content Type | Daily Note | Dedicated Note | Location |
|--------------|------------|----------------|----------|
| Quick thought/idea | Yes | No | Daily note only |
| Substantial idea/concept | Yes | Yes | `Notes/` |
| Project/tasks | Yes | Yes | `Projects/` |
| Reference/tool | Yes | Yes | `References/` |

**Guidelines:**
- Quick, informal thoughts → daily note only
- Substantial ideas worth referencing later → dedicated note + mention in daily
- User says "transfer to a note" or "dedicated note" → always create dedicated note

### Step 4: Locate or Create Daily Note

Check if today's daily note exists at:
1. `$COMPANY_VAULT/<daily_notes>/YYYY-MM-DD.md` (daily_notes from company vault-config.yaml if exists)
2. If folder doesn't exist, fall back to `$COMPANY_VAULT/YYYY-MM-DD.md`

**If daily note doesn't exist**, create it:
```markdown
# YYYY-MM-DD

## Notes

[{author_name}]
```

**If it exists**, find or create the `[{author_name}]` section under `## Notes`.

### Step 5: Format and Write Content

#### Daily Note Entry

Append under the author's section:

```markdown
[{author_name}]
- <transferred content>
```

If a dedicated note was created, add a wikilink reference:
```markdown
- Added [[note-name]] - brief description
```

#### Dedicated Note (when applicable)

```markdown
---
categories:
  - "[[CategoryName]]"
created: YYYY-MM-DD
author: {author_name}
---

# Title

<transferred content>

---
See also: {author_wikilink}
```

### Step 6: Confirm

Report to user:
- What was transferred
- File path(s) written
- Wikilink to use for referencing: `[[note-name]]`

---

## Attribution Strategy

Attribution should be subtle and Obsidian-native:

| Location | Method | Example |
|----------|--------|---------|
| Daily note | Section header | `[Henry]` |
| Frontmatter | Author field | `author: Henry` |
| Note footer | See also link | `See also: [[Henry]]` |

The `[[Henry]]` wikilink serves dual purpose:
- Indicates who contributed the note
- Links to the author's profile page in the KB
- Enables backlinks to find all notes by that person

---

## Example Workflows

### Quick Thought

**Input:** `/sync-company The embedder agent idea from today's notes`

→ Reads personal daily note, finds the embedder agent content
→ Appends to company daily note:
```markdown
[Henry]
- Embedder agent should support PDF and image inputs for spec sheet parsing
```

### Substantial Idea

**Input:** `/sync-company Transfer my customer error classification notes to a dedicated note`

→ Finds content in personal vault
→ Creates `Notes/customer-error-classification.md`:
```markdown
---
categories:
  - "[[Ideas]]"
created: 2026-01-20
author: Henry
---

# Customer Error Classification

<transferred content>

---
See also: [[Henry]]
```

→ Also appends to daily note:
```markdown
[Henry]
- Added [[customer-error-classification]] - approach for categorizing customer errors
```

---

## Rules

1. **Always read the target KB's style guide first** - it defines the conventions
2. **Find source content first** - this is a transfer tool, not a creation tool
3. **Preserve original meaning** - clean up formatting, don't rewrite content
4. **Use wikilinks for attribution** - subtle, useful, enables backlinks
5. **Ask if unclear** - don't guess at ambiguous content or intent
