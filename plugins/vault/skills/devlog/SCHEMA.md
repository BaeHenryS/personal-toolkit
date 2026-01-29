# Devlog Metadata Schema Reference

Current version: **0.3**

## Schema Versions

### 0.3 (Current)
Added git commit tracking.

**New fields:**
- `git.start_commit` - Parent of first commit in session (null if first commit is repo root)
- `git.end_commit` - Last commit made in session
- `git.commits` - Array of all commit hashes in chronological order
- `git.commit_range` - Git range string for `git diff` / `git log`

**Note:** `git` is `null` if no commits were made or working directory is not a git repo.

### 0.2
Added plan files and subagent tracking.

**Fields:**
- `plan_files` - Array of exported plan files with slug, filename, title, and phase
- `subagents` - Array of subagent info with agent_id, slug, session_id, session_num

### 0.1
Initial schema.

**Fields:**
- `schema_version` - Version string
- `date` - Session date (YYYY-MM-DD)
- `project` - Project display name
- `project_slug` - Project slug for filenames
- `task` - Task description
- `task_slug` - Task slug for filenames
- `phases` - Array of session phases with name, file, session_id
- `files_modified` - Array of modified file paths
- `outcome` - Session outcome (completed, in_progress, etc.)

## Example (0.3)

```json
{
  "schema_version": "0.3",
  "date": "2026-01-28",
  "project": "Thought Organizer Agent",
  "project_slug": "thought-organizer",
  "task": "Add git commit tracking",
  "task_slug": "git-tracking",
  "phases": [
    {"name": "session", "file": "session.jsonl", "session_id": "abc123"}
  ],
  "plan_files": [
    {
      "slug": "virtual-strolling-bee",
      "file": "plan.md",
      "title": "Plan: Add Git Commit Tracking",
      "phase": "session"
    }
  ],
  "subagents": [],
  "git": {
    "start_commit": "9b75d4a",
    "end_commit": "def5678",
    "commits": ["abc1234", "def5678"],
    "commit_range": "9b75d4a..def5678"
  },
  "files_modified": ["~/.claude/skills/devlog/SKILL.md"],
  "outcome": "completed"
}
```
