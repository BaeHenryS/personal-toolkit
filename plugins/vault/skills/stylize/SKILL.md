---
name: stylize
description: Format and organize Obsidian notes according to the vault's style guide. Use when the user asks to stylize, format, or clean up notes in Notes/, Projects/, or specific files. Supports custom instructions for ordering/styling. Does NOT apply to Daily Notes.
---

# Stylize Skill

Format and organize Obsidian notes according to the vault's style guide with spell/grammar corrections.

## Configuration

Read `~/.claude/settings.json` and extract `env.OBSIDIAN_VAULT`.

If `OBSIDIAN_VAULT` is not set, display: "Vault not configured. Run /vault first."

Read vault structure from `<vault_path>/vault-config.yaml`.

## Usage

```
/stylize <path> [--instructions "custom instructions"]
```

**Arguments:**
- `<path>` - File or folder to stylize (relative to vault root)
  - `Notes/` - All notes in Notes folder
  - `Projects/` - All notes in Projects folder
  - `Notes/my-note.md` - Specific note
- `--instructions "..."` - Custom instructions for ordering/styling (optional)

**Examples:**
```
/stylize Notes/
/stylize Projects/my-project.md
/stylize Notes/ --instructions "order sections alphabetically"
/stylize Projects/ --instructions "put Next Steps section at the top"
```

## Workflow

When this skill is invoked:

### 1. Read the Style Guide

Read the vault's style guide at the vault root:
```
<vault_path>/style-guide.md
```

The style guide defines:
- Folder structure and placement rules
- Naming conventions (kebab-case, YYYY-MM-DD dates, plural tags)
- Frontmatter properties (categories required)
- Rating system (1-7 scale)
- Linking conventions (wikilinks, source attribution)
- Content structure templates
- Writing style rules

### 2. Use Obsidian Syntax Skills

Reference the appropriate Obsidian skills for proper syntax:

**Markdown content** - `obsidian-markdown` skill:
- Wikilinks: `[[note-name]]`, `[[note-name|display text]]`
- Callouts: `> [!note]`, `> [!warning]`
- Frontmatter/properties
- Embeds, tags, block references

**Base embeds** - `obsidian-bases` skill (when notes embed `.base` files):
- Embed syntax: `![[MyBase.base]]` or `![[MyBase.base#View Name]]`
- Base file structure (YAML with filters, formulas, views)

**Canvas embeds** - `json-canvas` skill (when notes embed `.canvas` files):
- Embed syntax: `![[MyCanvas.canvas]]`
- Canvas file structure (JSON with nodes, edges, groups)

### 3. Apply Formatting

For each note in the target path:

**Spell/Grammar:**
- Fix spelling errors
- Fix grammar issues
- Preserve original meaning and voice

**Structure:**
- Ensure proper frontmatter with required `categories` property
- Add/fix headings structure
- Use bullet points where appropriate
- Remove excessive blank lines
- Clean up formatting inconsistencies

**Linking:**
- Add `[[wikilinks]]` to related notes (first mention only)
- Ensure source attribution if from daily note: `*From: [[YYYY-MM-DD]]*`
- Add "See also" section for related notes

**Style Guide Compliance:**
- Use kebab-case filenames
- Use YYYY-MM-DD date format
- Use plural tags/categories
- Follow content templates for note type (Notes, References, Projects)

### 4. Apply Custom Instructions

If `--instructions` provided, apply them after standard formatting:
- Section ordering
- Content grouping
- Special formatting requests

### 5. Preserve Content

**DO:**
- Preserve all original content and meaning
- Keep the author's voice
- Make minimal necessary changes

**DON'T:**
- Add boilerplate ("This note is about...")
- Add meta-commentary
- Expand or pad content
- Over-format with excessive bold/italics

## Restrictions

- **DO NOT** stylize files in `Daily Notes/` - these are journal entries
- Only process `.md` files
- Skip files that are already well-formatted (no changes needed)

## Output

After stylizing:
1. Show which files were changed
2. For each changed file, briefly note what was fixed (spelling, frontmatter, structure, etc.)
3. Write the changes to the files
