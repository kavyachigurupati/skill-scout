# skill-scout

> Reads your Claude Code sessions and finds what should be automated.

Every day you work in Claude Code, patterns build up that you never act on — repeated lookups, recurring friction, manual steps that should be scripts or agents. `skill-scout` surfaces those patterns and tells you what to build next.

A second module, **recall**, stores the context behind your work: decisions made, bugs fixed, designs considered. It's the paper trail that makes Scout's findings make sense.

---

## Setup

```bash
# 1. Clone the repo
git clone https://github.com/YOUR_USERNAME/skill-scout.git
cd skill-scout

# 2. Install dependencies
pip install anthropic pyyaml python-dateutil

# 3. Set your config
cp config.example.yaml config.yaml
# Edit config.yaml — set your Obsidian vault path and project name mappings

# 4. Run at end of day
python run.py
```

---

## Docs

- [`docs/PRD.md`](docs/PRD.md) — full product requirements, Scout spec, recall templates
- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — system diagram and data flow

---

## Repo structure

```
skill-scout/
├── run.py                  ← entry point
├── config.yaml             ← vault path + project mappings (git-ignored)
├── config.example.yaml     ← copy this to config.yaml
├── ingest.py               ← reads .jsonl session files
├── scout.py                ← scans raw chats for automation candidates
├── classify.py             ← intent classification via Claude API
├── summarize.py            ← fills recall templates via Claude API
├── write.py                ← writes to Obsidian
├── templates/              ← markdown templates per intent
└── docs/                   ← PRD and architecture
```
