Read all .jsonl session files from today in ~/.claude/projects/\*_/_.jsonl

Each .jsonl file is one Claude Code session. Each line is a message with a role (human/assistant) and timestamp.

---

## Step 1 — Read and understand each session

For each session file, read the full conversation and determine:

**Intent** — pick the single best fit:

- `decision` — choosing between approaches, tools, or directions
- `bug-fix` — diagnosing and fixing something broken
- `design` — planning architecture, structure, or system design
- `research` — exploring a tool, library, concept, or approach
- `implementation` — building or writing something concrete
- `other` — anything that doesn't fit above

**Project** — infer from the file path or conversation content. The folder name under ~/.claude/projects/ is a mangled version of the project path (e.g. `-Users-kavya-Desktop-my-project` = `my-project`). Use the last meaningful segment as the project name.

---

## Step 2 — Write recall notes to Obsidian

For each session, fill the matching template below and append it to the correct file:
`~/Recall/Projects/{project-name}/{intent}.md`

Create the file and any missing folders if they don't exist. Append — never overwrite.

### Decision template

```
## {title}
**Date:** {date}
**Session:** {session filename}

### What was the choice between?
{extract from conversation}

### Why this path was chosen
{extract from conversation}

### What was ruled out and why
{extract from conversation}

### Assumptions being made
{extract from conversation}

### When to revisit
{extract or note if unclear}

---
```

### Bug fix template

```
## {title}
**Date:** {date}
**Session:** {session filename}

### Symptom
{extract from conversation}

### First guess
{extract from conversation}

### What it actually was
{extract from conversation}

### How it got fixed
{extract from conversation}

### What wasted time
{extract from conversation}

### How to spot this faster next time
{extract from conversation}

---
```

### Design template

```
## {title}
**Date:** {date}
**Session:** {session filename}

### Problem being solved
{extract from conversation}

### Options considered
{extract from conversation}

### Trade-offs
{extract from conversation}

### What shaped the final direction
{extract from conversation}

### Open questions
{extract from conversation}

---
```

### Research template

```
## {title}
**Date:** {date}
**Session:** {session filename}

### What I was trying to understand
{extract from conversation}

### Key discoveries
{extract from conversation}

### Tools / docs / resources found
{extract from conversation}

### What surprised me
{extract from conversation}

### Pros / cons / gotchas
{extract from conversation}

### Would I use this again?
{extract from conversation}

---
```

### Implementation template

```
## {title}
**Date:** {date}
**Session:** {session filename}

### What was built
{extract from conversation}

### What saved time
{extract from conversation}

### What slowed me down
{extract from conversation}

### Anything reusable here?
{extract from conversation}

---
```

### Other template

```
## {title}
**Date:** {date}
**Session:** {session filename}

### What happened
{extract from conversation}

### Worth revisiting?
{extract from conversation}

---
```

---

## Step 3 — Scout for automation candidates

While reading the sessions, look for any of these signals:

| Signal                                    | Candidate type                     |
| ----------------------------------------- | ---------------------------------- |
| Same task done manually more than once    | Script or template                 |
| Repeated lookup of docs, tools, or syntax | MCP server or browser agent        |
| Same class of error appearing again       | Linter rule or pre-check           |
| Workflow that could run unattended        | Scheduled job or agent             |
| Setup or context that's always repeated   | Claude Code hook or alias          |
| Question with a fixed repeatable answer   | Prompt template or CLAUDE.md entry |

For each candidate found, write a note to `~/Recall/Scout/{slug}.md`:

```
# {candidate title}
**Date flagged:** {date}
**Effort:** {low / medium / high}

## What was observed
{describe the pattern, be specific}

## Sessions it appeared in
{list session filenames}

## Suggested automation
{script / MCP / agent / hook / template — and a brief description of what it would do}

## Suggested next step
{one concrete action to start building this}
```

---

## Finally

Print a short summary of what was written:

- How many sessions were processed
- One line per session: filename → intent → project
- How many Scout candidates were found and their titles
