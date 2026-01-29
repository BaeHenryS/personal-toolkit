---
name: scribe
description: Research and note-taking skill that explores codebases, performs web research, compiles findings, and writes notes to Obsidian. Use when user says /scribe, wants to "research and take notes", "explore the codebase and document", "learn about X and save notes", "update my notes on X", "edit [[note]] with new info", or wants Claude to investigate a topic and compile findings into Obsidian notes (create or update).
---

# Scribe - Research and Note-Taking

Research topics through codebase exploration and web research, then compile findings into Obsidian notes with user approval.

---

## Usage

### Mode 1: Create New Note
```
/scribe "<topic or question>"
```

**Examples:**
```
/scribe "How does authentication work in this codebase?"
/scribe "What are best practices for JWT tokens?"
/scribe "Compare our API patterns to industry standards"
```

### Mode 2: Edit Existing Note
```
/scribe --edit <note> "<instructions>"
```

**Note reference formats:**
- Wikilink: `--edit [[claude-code-guide]]`
- Path: `--edit Notes/api-patterns.md`

**Examples:**
```
/scribe --edit [[claude-code-guide]] "add current implementation details"
/scribe --edit Notes/api-patterns.md "update with new endpoints"
```

---

## Configuration

Read `~/.claude/settings.json` and extract `env.OBSIDIAN_VAULT`.

If `OBSIDIAN_VAULT` is not set, display: "Vault not configured. Run /vault first."

Read vault structure from `<vault_path>/vault-config.yaml`.

**Paths used from vault-config.yaml:**
- `daily_notes` → Daily Notes folder
- `notes` → Notes folder for standalone notes

---

## Execution Workflow

```
/scribe [--edit <note>] "<topic or instructions>"
    │
    ▼
┌─────────────────────────────────────────┐
│ Phase 0: Mode Detection                 │
└─────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────┐
│ Phase 1: Research                       │
└─────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────┐
│ Phase 2: Draft                          │
└─────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────┐
│ Phase 3: Iterate (loop until approved)  │
└─────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────┐
│ Phase 4: Commit                         │
└─────────────────────────────────────────┘
```

---

## Phase 0: Mode Detection

Determine CREATE or EDIT mode based on arguments.

### CREATE Mode
- No `--edit` flag present
- Will create a new note from scratch
- Proceed to Phase 1 with full research scope

### EDIT Mode
- `--edit` flag with note reference
- Read the existing note first to understand current content
- Identify what needs to be added or updated
- Proceed to Phase 1 with focused research scope (gaps/updates only)

**Resolving note references:**
1. Wikilink `[[note-name]]` → Search for matching `.md` file in vault
2. Path `Notes/file.md` → Use path directly relative to vault root

---

## Phase 1: Research

Research the topic using appropriate agents. **Not all agents are needed for every question.**

### Agent Selection

| Agent | Purpose | When to Use |
|-------|---------|-------------|
| `Explore` | Codebase exploration | Questions about code, architecture, implementation |
| `web-research-specialist` | Web research | External docs, debugging, best practices, comparisons |
| *(none)* | Vault-only | Just synthesizing existing vault notes |

### Selection Examples

- "How does auth work in this codebase?" → **Explore only**
- "What are best practices for JWT tokens?" → **web-research-specialist only**
- "Update my auth notes with current implementation" → **Explore** + existing note
- "Compare our approach to industry standards" → **Explore + web-research-specialist**
- "Summarize my project notes" → **No agents** (vault-only synthesis)

### Invoking Agents

Use the Task tool with appropriate `subagent_type`:

**For codebase exploration:**
```
Task tool:
  subagent_type: "Explore"
  description: "Explore [topic]"
  prompt: "Research how [specific topic] works in this codebase. Look for:
    - Key files and components
    - Implementation patterns
    - Important functions/classes
    Return findings with file paths and line numbers."
```

**For web research:**
```
Task tool:
  subagent_type: "web-research-specialist"
  description: "Research [topic]"
  prompt: "Research [topic]. Find:
    - Best practices
    - Common patterns
    - Relevant documentation
    Return findings with source links."
```

**Run agents in parallel when both are needed.**

### For EDIT Mode

Focus research on gaps and updates:
- What's missing from the current note?
- What has changed since the note was written?
- What new information is relevant?

---

## Phase 2: Draft

Present the draft to the user for review.

### CREATE Mode - Draft Format

```markdown
## Draft: [Topic Title]

[Compiled content from research]

---

**Proposed location:** Notes/YYYY-MM-DD-topic-slug.md
```

### EDIT Mode - Draft Format

Show proposed changes clearly:

```markdown
## Proposed Changes to [[note-name]]

### Additions
[New content to add]

### Modifications
[Content to change, with before/after if significant]

### Unchanged
[Sections that will remain as-is]
```

---

## Phase 3: Iterate

Loop until the user approves the draft.

### Feedback Loop

1. Present draft (Phase 2)
2. Wait for user feedback
3. If feedback received:
   - Incorporate changes
   - Re-present updated draft
   - Return to step 2
4. If approved ("looks good", "approved", "ship it", etc.):
   - Proceed to Phase 4

### Approval Indicators

Watch for phrases like:
- "looks good"
- "approved"
- "ship it"
- "yes"
- "go ahead"
- "write it"
- "commit"

### Feedback Response

When user provides feedback:
- Acknowledge the specific feedback
- Make requested changes
- Present updated draft
- Highlight what changed

---

## Phase 4: Commit

Write the approved content to the vault.

### EDIT Mode

Update the existing note in place:
1. Read current note content
2. Apply approved changes
3. Write updated content back to the same file path
4. Confirm completion with file path

### CREATE Mode

Ask user where to write:

**Option A: Standalone Note in Notes/**

Path: `<vault_path>/<notes>/YYYY-MM-DD-topic-slug.md`

Format:
```markdown
---
categories:
  - "[[Learning]]"
created: YYYY-MM-DD
source: scribe
project: {project-name}
---

# Topic Title

[Approved content]
```

**Option B: Daily Note Section**

Append under `## Notes` → `### Scribe`:

```markdown
## Notes

### Scribe

#### Topic Title
- Key finding 1
- Key finding 2
- See: [[YYYY-MM-DD-topic-slug]] (if standalone also created)
```

### Ask User Preference

Before writing in CREATE mode:

```
Where should I save this note?
1. Notes/ folder as standalone note (Notes/YYYY-MM-DD-topic-slug.md)
2. Today's daily note under ## Notes > ### Scribe
3. Both (standalone note + summary in daily note)
```

### Confirm Completion

After writing:
```
Note saved to: Notes/YYYY-MM-DD-topic-slug.md
Wikilink: [[YYYY-MM-DD-topic-slug]]
```

---

## Output Formats

### Standalone Note Frontmatter

```yaml
---
categories:
  - "[[Learning]]"
created: YYYY-MM-DD
source: scribe
project: {project-name}
---
```

**Fields:**
- `categories`: Always include `[[Learning]]` for scribed notes
- `created`: Date note was created (YYYY-MM-DD)
- `source`: Always `scribe` to indicate origin
- `project`: Current project name (from working directory or context), omit if not applicable

### Daily Note Format

```markdown
## Notes

### Scribe

#### Topic Title
- Key finding 1
- Key finding 2
- See: [[YYYY-MM-DD-topic-slug]]
```

### File Naming

Standalone notes: `YYYY-MM-DD-topic-slug.md`

**Slug rules:**
- Lowercase
- Hyphen-separated (kebab-case)
- 2-4 words describing the topic
- Remove articles (a, an, the)

**Examples:**
- "How does authentication work?" → `2026-01-25-authentication-flow.md`
- "JWT best practices" → `2026-01-25-jwt-best-practices.md`

---

## Rules

1. **Always research before drafting** - Don't guess at content
2. **Present draft before writing** - Never write without user approval
3. **Keep iteration open** - User can refine as much as needed
4. **Preserve existing content in EDIT mode** - Don't remove unless asked
5. **Use appropriate agents** - Don't invoke agents that aren't needed
6. **Ask if unclear** - Don't assume topic scope or output location
7. **Include source references** - Link to files, line numbers, or web sources when possible
