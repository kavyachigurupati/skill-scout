# skill-scout — Product Requirements Document

> Reads your Claude Code sessions and finds what should be automated.

---

## What this is

Every day you work in Claude Code, patterns build up that you never act on. You look up the same docs twice. You fix the same class of bug. You set up the same boilerplate. You have a conversation that should have been a script or an MCP. None of it gets captured, so none of it gets automated.

`skill-scout` runs at the end of your day and does two things:

**Scout** — the core. Reads your raw sessions and asks: *is there something here worth automating?* Flags each candidate with a suggested automation type and effort estimate. Output lands in your Obsidian vault for you to review and decide on.

**Recall** — the supporting layer. Classifies each session by intent, fills a structured template, and appends it to the right project file in Obsidian. Decisions, bug fixes, design choices — stored with the context that made them make sense. The paper trail behind Scout's findings.

---

## Problem

You spend hours in Claude Code — making decisions, fixing bugs, designing systems, researching tools. That context disappears when the session ends.

Over time you:
- Repeat manual work that should have been scripted the first time
- Miss that you've hit the same error three times across different projects
- Look up the same docs again because you never captured what you found
- Forget the reasoning behind decisions when you return to them weeks later
- Have no visibility into where your time actually goes

---

## Goals

**Primary — Scout**
- Surface automation opportunities from raw sessions: scripts, agents, MCPs, hooks, templates
- Flag each candidate with enough context to act on it, not just notice it
- Output lands in Obsidian, ready to review

**Secondary — Recall**
- Capture decisions, bugs, design, and research into structured Obsidian notes
- Organised by project and intent, not buried by date
- One command at end of day, zero ongoing effort

---

## Non-goals (v1)

- No UI, no dashboard, no web app
- No automatic scheduling — manual trigger only
- No real-time or per-session processing
- Scout flags candidates only — it does not build the automations
- Recall entries are structured captures, not polished documents

---

## Scout

Reads **raw `.jsonl` chats** directly — not summaries. Summaries have already lost the texture that makes patterns visible: the failed attempts, the friction, the thing that came up again. Scout needs the original.

### What Scout looks for

| Signal in the raw chat | Automation candidate |
|---|---|
| Same task done manually 2+ times | Script or reusable template |
| Repeated docs / tool lookup | MCP server or browser agent |
| Same class of error recurring | Linter rule or pre-check agent |
| Workflow that could run unattended | Scheduled job or autonomous agent |
| Context setup that's always the same | Claude Code hook or shell alias |
| Question asked to Claude with a fixed answer | Prompt template or knowledge file |

### Scout output

One note per candidate written to `Scout/` in your Obsidian vault:
- What was observed (with session reference)
- Which sessions this appeared in
- Suggested automation type: script / MCP / agent / hook / template
- Effort estimate: low / medium / high
- Suggested next step

You review these in Obsidian and decide what to act on.

---

## Recall

Each session is classified by intent and a structured template is filled. This is the paper trail — context for your decisions, a record of what you built and what slowed you down.

### Intents

**Decision**
- What was the choice between?
- Why I chose this path
- What I ruled out and why
- Assumptions I'm making
- When to revisit this

**Bug fix**
- What the symptom was
- What I thought it was (first guess)
- What it actually was
- How it got fixed
- Time wasted / what caused the waste
- How to spot this faster next time

**Design**
- Problem being solved
- Options considered
- Trade-offs
- What shaped the final direction
- Open questions

**Research**
- What I was trying to understand
- Key discoveries
- Tools / docs / resources found
- What surprised me
- Pros / cons / gotchas
- Would I use this again?

**Implementation**
- What was built
- What saved time
- What slowed me down
- Anything reusable here?

**Other**
- What happened
- Worth revisiting?

---

## Obsidian Vault Structure

```
~/skill-scout/
├── Scout/
│   └── {candidate-slug}.md      ← one file per automation opportunity flagged
├── Projects/
│   └── {project-name}/
│       ├── decisions.md
│       ├── bug-fixes.md
│       ├── design.md
│       ├── research.md
│       └── implementation.md
└── Daily Log/
    └── 2026-04-06.md            ← lightweight index of what was added today
```

`Scout/` is listed first because it is the primary output. Each recall intent file gets entries appended — newest at top, each with date and session title.

---

## Repo Structure

```
skill-scout/
├── run.py                  ← entry point — run this at end of day
├── config.yaml             ← vault path, project name mappings (git-ignored)
├── config.example.yaml     ← copy this to config.yaml
├── ingest.py               ← reads .jsonl files since last run
├── scout.py                ← Claude API: scan raw chats for automation candidates
├── classify.py             ← Claude API: label intent per session
├── summarize.py            ← Claude API: fill recall template
├── write.py                ← write entries to Obsidian
├── templates/
│   ├── decision.md
│   ├── bug_fix.md
│   ├── design.md
│   ├── research.md
│   ├── implementation.md
│   └── scout_candidate.md
└── docs/
    ├── PRD.md              ← this file
    └── ARCHITECTURE.md     ← system diagram and data flow
```

---

## Tech

- **Language:** Python 3.11+
- **Dependencies:** `anthropic`, `pyyaml`, `python-dateutil`
- **One thing to configure:** vault path and project name mappings in `config.yaml`

---

## Build Order

Build recall first — simpler, validates ingest + API + write works end-to-end. Then build Scout on top of the same ingest layer.

1. `ingest.py` — read and parse `.jsonl` files, verify output before any API calls
2. `classify.py` + `summarize.py` — intent classification and template filling
3. `write.py` — write to Obsidian files, create if missing
4. `run.py` — wire recall end-to-end and confirm it works
5. `scout.py` — Scout as a second independent pass over the same raw sessions

---

## Open Questions (before building)

1. What is your Obsidian vault path?
2. What are your active project names?
3. What are your Claude Code project folder names under `~/.claude/projects/`?
