---
name: recall-lint
description: Health-checks the ~/Recall wiki — finds orphan projects, stale state files, missing index entries, and broken cross-links. Use when asked to "lint recall", "check the wiki health", "find stale notes", "clean up recall", or "what projects have gone quiet".
allowed-tools: Read, Grep, Bash(find:*), Bash(date:*), Bash(wc:*), Bash(awk:*), Bash(sort:*)
---

You health-check the ~/Recall wiki and report issues. Read only — you never write, modify, or delete files.

## Rules

- Read only — never write, never delete
- Report all findings even if the wiki is clean
- Always print the full health report at the end

## Status reporting

At every step, print what you are doing:

- `✓` for healthy
- `⚠ WARNING:` for non-fatal issues (stale, missing metadata, orphan)
- `✗ ERROR:` for broken or missing required files

Always print the full health report at the end even if no issues are found.

## Error handling

**Missing ~/Recall/index.md:** Caught in Step 1 — stops immediately with error.

**Unreadable state file mid-run:** If a `{project}-state.md` exists but cannot be read:

- Print: `  ⚠ WARNING: Could not read {project}-state.md — skipping staleness and cross-link checks for this project`
- Continue to the next project — never abort a full run for one bad file

**Unexpected errors:** If any read operation fails in a way not covered by a specific step:

- Print: `✗ ERROR: Unexpected failure in Step {N} — {reason}`
- Continue — never silently swallow an error

## Step 1 — Read index.md

Print: `→ Reading ~/Recall/index.md...`

Read `~/Recall/index.md`. This is the source of truth for which projects exist.

- If missing → print `✗ ERROR: ~/Recall/index.md not found — has /recall been run?` and stop.
- Extract all project names listed under `## Projects`.
- Print `  Found {n} projects in index.`

## Step 2 — Check project folders

Print: `→ Checking project folders...`

For each project in index.md, verify:

- `~/Recall/Projects/{project-name}/` folder exists
- `{project-name}-log.md` exists
- `{project-name}-state.md` exists

Print per project:

- `  ✓ {project}` — all three exist
- `  ⚠ WARNING: {project} — folder missing`
- `  ⚠ WARNING: {project} — log file missing`
- `  ⚠ WARNING: {project} — state file missing`

Also scan `~/Recall/Projects/` for folders NOT listed in index.md:

- `  ⚠ WARNING: {project} — folder exists but not in index.md (orphan)`

## Step 3 — Check for stale projects

Print: `→ Checking for stale projects...`

Read the `last-updated` field from each state file's YAML frontmatter. Compare to today's date.

- Updated within 30 days → `  ✓ {project} — active (last updated {date})`
- Updated 30–90 days ago → `  ⚠ WARNING: {project} — stale (last updated {date})`
- Updated > 90 days ago → `  ⚠ WARNING: {project} — very stale (last updated {date}) — consider marking complete`
- No frontmatter or no `last-updated` field → `  ⚠ WARNING: {project} — no last-updated metadata (state file may predate frontmatter support)`

## Step 4 — Check cross-links

Print: `→ Checking cross-links...`

For each state file, read the `related` field from the YAML frontmatter. For each listed related project:

- If it exists in index.md → `  ✓ {project} → {related} (link valid)`
- If it does not exist in index.md → `  ⚠ WARNING: {project} references {related} but {related} is not in index.md`

## Step 5 — Check Scout directory

Print: `→ Checking ~/Recall/Scout/...`

- If `Scout/` doesn't exist → `  ⚠ WARNING: No Scout directory — /scout has not been run yet`
- If exists → count `.md` files, print `  ✓ {n} scout candidates on file`

Read `~/Recall/.scout_processed` if it exists:

- Print `  Last scout: {timestamp}`
- If > 7 days ago → `  ⚠ WARNING: Scout hasn't run in {n} days — consider running /scout`
- If missing → `  ⚠ WARNING: No .scout_processed file — scout has never run`

## Step 6 — Check global log

Print: `→ Checking ~/Recall/log.md...`

- If missing → `  ⚠ WARNING: ~/Recall/log.md not found — global log not being written (may need a fresh /recall run)`
- If exists → count `## [` heading lines (each is one session entry), print `  ✓ {n} session entries in global log`

## Step 7 — Print health report

Always print this block:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
recall-lint complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Projects    : {n} in index — {n} healthy, {n} with issues
Stale       : {list of stale projects, or "none"}
Very stale  : {list, or "none"}
Orphans     : {list of orphan folders, or "none"}
Broken links: {list of broken cross-links, or "none"}
Scout       : last ran {date} | {n} candidates on file
Global log  : {n} entries | {healthy or missing}
Warnings    : {n total}
Errors      : {n total}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
