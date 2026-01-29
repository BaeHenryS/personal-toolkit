---
name: devlog
description: Summarize the current coding session. Shows learnings and accomplishments in terminal, appends to today's Obsidian daily note under "## Notes > ### Progress > #### Project Name". Use when user says /devlog or wants to log what they did.
---

# Dev Log - Session Summary

Log your coding session progress to Obsidian daily notes, organized by project.

## Configuration

Read `~/.claude/settings.json` and extract `env.OBSIDIAN_VAULT`.

If `OBSIDIAN_VAULT` is not set, display: "Vault not configured. Run /vault first."

Read vault structure from `<vault_path>/vault-config.yaml`.

**Paths used from vault-config.yaml:**
- `daily_notes` → Daily Notes folder
- `projects` → Projects folder
- `processed_coding` → Export location for coding sessions

**Section format:** `## Notes` → `### Progress` → `#### Project Name`

## Execution Steps

### Step 1: Check Daily Note Exists

First, read `<vault_path>/vault-config.yaml` to get the `daily_notes` folder name.

Then check if today's daily note exists:
```
<vault_path>/<daily_notes>/YYYY-MM-DD.md
```

Use today's date in YYYY-MM-DD format.

**If the file does NOT exist:**
- Display this message to the user: "Today's daily note doesn't exist yet. Please create it in Obsidian first, then run /devlog again."
- Stop execution. Do not proceed further.

**If the file exists:** Continue to Step 2.

### Step 2: Determine Project

Identify which project this session belongs to:

1. List all `.md` files in the Projects folder (`<vault_path>/<projects>` from vault-config.yaml)
2. Match the current session to a project using:
   - Current working directory name (e.g., `thought-organizer` → "Thought Organizer Agent")
   - Session context (what was worked on)
   - Read project markdown files if needed for clarity
3. Extract the project title from the markdown file's `# Title` heading
4. Use the exact title for the section header (e.g., `#### Thought Organizer Agent`)

**If no matching project found:** Use "General" as the project name.

### Step 3: Export Chat History

Export session for future reference using folder-based structure:

Note: If the scratchpad is not there or you cannot find the current project, then raise an error and DO NOT CONTINUE

1. **Get current session info from scratchpad path:**
   - The scratchpad path is provided in your system prompt, e.g.:
     `/private/tmp/claude/{project-path}/{session-id}/scratchpad`
   - Extract the session ID (the UUID before `/scratchpad`)
   - Extract the project path (the segment after `/private/tmp/claude/` and before the session ID)
   - Construct transcript path: `~/.claude/projects/{project-path}/{session-id}.jsonl`
   - Example: scratchpad `/private/tmp/claude/-Users-foo-project/abc123/scratchpad`
     → transcript `~/.claude/projects/-Users-foo-project/abc123.jsonl`
   - **Verify the transcript is current:**
     1. Check the file exists: `ls -la <transcript-path>`
     2. Read the last few lines: `tail -3 <transcript-path>`
     3. Confirm it contains recent messages from this conversation
     4. If the file doesn't exist or content doesn't match, stop and inform the user

2. **Detect previous transcripts (recursive with LLM verification):**

   **CRITICAL: Only count REAL continuation references, not casual mentions.**

   A transcript reference is ONLY valid if it appears in a **continuation message** - either:
   - **Plan-mode exit**: User message starting with "Implement the following plan:"
   - **Compaction summary**: User message starting with "This session is being continued from a previous conversation"

   Both end with "read the full transcript at:" followed by the path.

   **DO NOT count:**
   - References in tool_result outputs (content is an array, not a string)
   - References in subagent results (appear inside tool_result arrays)
   - Assistant messages mentioning paths (type is "assistant")
   - Any other casual mention of transcript paths

   **JSONL Structure Reference:**
   Each line is a JSON object with fields:
   - `type`: "user", "assistant", "system", "progress"
   - `message.content`: either a **string** (direct message) or **array** (tool results)

   **Step A: Find candidate lines**

   ```bash
   grep -n "read the full transcript at:" <transcript.jsonl>
   ```

   **Step B: Verify each candidate using JSON structure**

   For each candidate line, examine the JSON:

   1. Parse the line as JSON
   2. Check: `type == "user"`
   3. Check: `message.content` is a **string** (NOT an array)
   4. Check: Content contains either:
      - `"Implement the following plan:"` (plan-mode)
      - `"This session is being continued"` (compaction)
   5. If all checks pass → VALID continuation
   6. Extract path: `grep -o "read the full transcript at: [^\"\\]*\.jsonl"`

   **Example verification:**
   ```
   Line 2: {"type":"user","message":{"content":"Implement the following plan:...read the full transcript at: /path/to/abc.jsonl"}}
     ✓ type == "user"
     ✓ message.content is a string
     ✓ Contains "Implement the following plan:"
     → VALID plan-mode continuation → abc.jsonl

   Line 356: {"type":"user","message":{"content":[{"type":"tool_result",...}]}}
     ✓ type == "user"
     ✗ message.content is an ARRAY (tool_result)
     → SKIP (false positive from grep output)
   ```

   **Optional jq-based validation:**
   ```bash
   grep "read the full transcript at:" "$TRANSCRIPT_PATH" | \
     while IFS= read -r line; do
       valid=$(echo "$line" | jq -r '
         if .type == "user" and
            (.message.content | type == "string") and
            ((.message.content | contains("Implement the following plan:")) or
             (.message.content | contains("This session is being continued")))
         then "VALID"
         else "SKIP"
         end
       ' 2>/dev/null)

       if [ "$valid" = "VALID" ]; then
         echo "$line" | jq -r '.message.content' | \
           grep -o "read the full transcript at: [^\"\\]*\.jsonl"
       fi
     done
   ```

   **Step C: Recursive discovery**

   For each valid transcript found, repeat Steps A-B until no new transcripts are discovered.

   **Step D: Determine chronological order using reference topology**

   DO NOT use file modification times - they are unreliable.
   Use the reference chain: transcripts that are referenced but don't reference others come FIRST.

   **Example from a real session:**
   ```
   Discovery:
   - 830e4d0f (current) has plan implementation referencing de2864e0
   - de2864e0 has plan implementations referencing 2bb50f3b AND c9c826aa
   - c9c826aa has plan implementation referencing 2bb50f3b
   - 2bb50f3b has no plan implementation references (ROOT)

   Reference topology:
   - 2bb50f3b: referenced by c9c826aa and de2864e0, references nothing → ROOT
   - c9c826aa: referenced by de2864e0, references 2bb50f3b → SECOND
   - de2864e0: referenced by current, references both above → THIRD
   - 830e4d0f: references de2864e0 → CURRENT (last)

   Final order: 2bb50f3b → c9c826aa → de2864e0 → 830e4d0f
   ```

   **Verification output:** After discovery, list all found transcripts showing:
   - Line number where reference was found
   - Type (plan-mode or compaction)
   - The LLM's verification reasoning (type check, content type check, pattern match)

   **Handling compaction:** If the conversation context has been compacted (summarized), the
   continuation reference may not be visible in the current context. In this case:
   1. ALWAYS search the current JSONL file (derived from scratchpad path) directly
   2. The JSONL file preserves all messages even after compaction
   3. Search for BOTH continuation patterns (plan-mode AND compaction)

3. **Generate task slug:**
   - Extract short task description from plan or conversation
   - Convert to lowercase kebab-case (e.g., "Fix clippings heading duplication" → "clippings-fix")
   - Keep slugs concise (2-4 words max)

4. **Create session folder:**
   - Folder name: `{YYYY-MM-DD}-{project-slug}-{task-slug}/`
   - Example: `2026-01-22-thought-organizer-clippings-fix/`
   - If folder exists (same session, running devlog again), update files in place

5. **Copy transcripts:**
   - If no previous transcripts: copy current as `session.jsonl`
   - If previous transcripts found: copy all in chronological order (oldest first)
     - Name by position: `session-1.jsonl`, `session-2.jsonl`, etc. (simplest, always works)
     - Current session is always last (highest number)
     - Example: 4 sessions → `session-1.jsonl`, `session-2.jsonl`, `session-3.jsonl`, `session-4.jsonl`

6. **Detect and copy plan files:**
   - Read ALL transcripts in the chain (including current)
   - Search for pattern `"slug":"[^"]*"` to extract ALL unique plan slugs
   - For each unique slug:
     - Construct path: `~/.claude/plans/<slug>.md`
     - If file exists, copy to export folder
   - Naming convention:
     - Single plan: `plan.md`
     - Multiple plans: `plan-1.md`, `plan-2.md` (in chronological order)
   - Skip gracefully if no plan slugs found or files don't exist
   - **Extract title**: Read first `#` heading from each plan file
   - **Note on shared slugs**: Multiple sessions often share the SAME plan slug (the plan file
     gets overwritten each time). This means you may only have 1 plan file even with multiple
     sessions. This is expected - the final plan file contains the most recent plan content.

7. **Create metadata.json:**
```json
{
  "date": "2026-01-22",
  "project": "Thought Organizer Agent",
  "project_slug": "thought-organizer",
  "task": "Fix clippings heading duplication",
  "task_slug": "clippings-fix",
  "phases": [
    {"name": "planning", "file": "planning.jsonl", "session_id": "aaa"},
    {"name": "implementation-1", "file": "implementation-1.jsonl", "session_id": "bbb"},
    {"name": "implementation-2", "file": "implementation-2.jsonl", "session_id": "ccc"},
    {"name": "implementation-3", "file": "implementation-3.jsonl", "session_id": "ddd"}
  ],
  "plan_files": [
    {
      "slug": "virtual-strolling-bee",
      "file": "plan-1.md",
      "title": "Plan: Add Plan File Export to Devlog",
      "phase": "planning"
    },
    {
      "slug": "streamed-hopping-sunbeam",
      "file": "plan-2.md",
      "title": "Plan: Implement Two-Phase Pipeline",
      "phase": "implementation-1"
    }
  ],
  "files_modified": ["src/clipper.py"],
  "outcome": "completed"
}
```
   - For single-phase sessions, use `[{"name": "session", "file": "session.jsonl", "session_id": "xxx"}]`
   - Phases array must list transcripts in chronological order (oldest → newest)
   - The recursive chain discovery ensures no transcripts are missed
   - `plan_files` array: include only if plan files were exported
     - `title`: extracted from first `#` heading in the plan file
     - `phase`: the phase name whose transcript contains this slug
     - Order reflects when each planning phase occurred (earliest first)

8. **Write summary.md** based on conversation context:
   - Frontmatter: date, project, task, link to metadata.json
   - Summary: 2-3 sentences of key accomplishments
   - Key changes: bullet list of major edits/features
   - Files modified: list of paths

**Export location:** `<vault_path>/<processed_coding>/` (from vault-config.yaml)

**Folder structure:**
```
Processed/Coding/{YYYY-MM-DD}-{project-slug}-{task-slug}/
  ├── metadata.json          # Machine-readable metadata
  ├── *.jsonl                # One or more transcript files (session.jsonl, planning.jsonl, implementation-1.jsonl, etc.)
  ├── plan.md                # Single plan (or plan-1.md, plan-2.md for multiple)
  └── summary.md             # Human-readable summary
```

**Example with multiple plans:**
```
Processed/Coding/2026-01-22-thought-organizer-feature/
  ├── metadata.json
  ├── planning.jsonl
  ├── implementation-1.jsonl
  ├── implementation-2.jsonl
  ├── plan-1.md
  ├── plan-2.md
  └── summary.md
```

**summary.md format:**
```markdown
---
date: 2026-01-22
project: Thought Organizer Agent
task: Fix clippings heading duplication
metadata: "[[metadata.json]]"
---

# Coding Session: Thought Organizer Agent

## Summary
[2-3 sentence summary of what was accomplished]

## Plans
- [[plan-1.md|Add Plan File Export]] (planning phase)
- [[plan-2.md|Two-Phase Pipeline]] (implementation-1 phase)

## Key Changes
- [Major change 1]
- [Major change 2]

## Files Modified
- `path/to/file1.py`
- `path/to/file2.md`
```

**Plans section notes:**
- Only include `## Plans` section if plan files were exported
- Use wikilink with plan title as display text
- Include phase association in parentheses

Store the folder wikilink (e.g., `[[2026-01-22-thought-organizer-clippings-fix/summary|Session Log]]`) for use in Step 6.

### Step 4: Analyze Chat History

Review the current conversation to identify:
1. **Learnings**: Technical insights, concepts discovered, patterns understood
2. **Accomplishments**: Code written, bugs fixed, features implemented, tasks completed

### Step 5: Display Terminal Output

Output BOTH sections to the terminal:

```
## What I Learned
- [Learning 1]
- [Learning 2]

## What I Shipped
- [Accomplishment 1]
- [Accomplishment 2]
```

Keep bullet points concise (one line each).

### Step 6: Append to Daily Note

Read the current daily note and append to the project's section under `## Notes` → `### Progress`.

**Constraints:**
- Write ONLY accomplishments (not learnings)
- Maximum 1 bullet point
- Keep descriptions minimal and concise
- Include wikilink to session log: `([[{folder}/summary|Session Log]])`
- Use checkbox format:
  - `- [v]` for completed items
  - `- [ ]` for in-progress/incomplete items

**Locating/Creating Sections:**
1. Find the `## Notes` section
2. Look for `### Progress` under `## Notes`
   - If it doesn't exist, create it
3. Look for `#### Project Name` under `### Progress` (case-insensitive match)
   - If the project section exists: append new items below existing content
   - If it doesn't exist: create it under `### Progress`

**Format to write:**
```markdown
## Notes

### Progress

#### Thought Organizer Agent
- [v] Implemented X feature ([[2026-01-11-thought-organizer-feature-name/summary|Session Log]])

#### Video Generation Pipeline
- [v] Added audio sync feature ([[2026-01-11-video-pipeline-audio-sync/summary|Session Log]])
```

### Step 7: Confirm

After appending, confirm to the user that their progress has been logged.

## Important Rules

1. **Never create the daily note file** - User must create it first
2. **Always use today's date** - Regardless of when work started
3. **Max 1 item** - Prioritize the single most significant accomplishment
4. **Minimal descriptions** - Keep each item to one short line
5. **Checkbox status matters** - Use `[v]` for done, `[ ]` for incomplete
