# llm-wiki-agents

[![License: MIT](https://img.shields.io/github/license/MehmetGoekce/llm-wiki)](LICENSE)

**Fork** of [MehmetGoekce/llm-wiki](https://github.com/MehmetGoekce/llm-wiki) that extends upstream to support both **Claude Code** and **OpenCode** as wiki maintainers from a single shared wiki directory.

Upstream maps Karpathy's [LLM Wiki concept](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) to real tools (Logseq or Obsidian) using a two-layer cache architecture (L1/L2). This fork preserves all of that and adds multi-agent support on top.

## Quick Start

```bash
git clone https://github.com/stgreenb/llm-wiki.git
cd llm-wiki
./setup.sh
```

`setup.sh` does three things:

1. **Detects installed agents** (Claude Code, OpenCode, or both) and scaffolds per-agent configs
2. **Configures your wiki** (Logseq or Obsidian) with path setup and namespace creation
3. **Creates the wiki structure** — Schema, Dashboard, and hub pages

### Command Differences

| Agent | Ingest | Query | Lint | Status |
|-------|--------|-------|------|--------|
| **Claude Code** | `/wiki ingest <src>` | `/wiki query <q>` | `/wiki lint` | `/wiki status` |
| **OpenCode** | `opencode run wiki-ingest <src>` | `opencode run wiki-query <q>` | `opencode run wiki-lint` | `opencode run wiki-status` |

## Switching Agents

Both agents share the same `Wiki/` directory, `llm-wiki.yml` config, and `wiki.md` workflow instructions. Switch freely — no reconfiguration needed. Run `setup.sh` when setting up a new project to scaffold the other agent's config.

## What This Fork Adds

| Feature | Upstream | This Fork |
|---------|----------|-----------|
| Supported agents | Claude Code only | Claude Code + OpenCode |
| Agent detection | None — assumes Claude | Auto-detects `claude`, `opencode`, `npx opencode` — handles all 4 scenarios |
| setup.sh scaffolds | `.claude/commands/wiki.md` | Claude path + OpenCode path (`opencode.json`, `.opencode/commands/wiki-*.md`) |
| Dual-agent config | Not supported | Interactive prompt when both detected, choose one or both |
| L1 memory | `memory/` directory (Claude) | `memory/` + `AGENTS.md` + `.opencode/instructions/` — both sourced from shared `templates/l1/` |
| Workflow instructions | `wiki.md` (Claude-only) | Same `wiki.md` — shared source of truth, no duplication |
| OpenCode commands | N/A | 5 commands: `wiki-ingest`, `wiki-query`, `wiki-lint`, `wiki-status`, `wiki-ingest-bg` |

## Architecture

The core workflow is in [wiki.md](wiki.md) — the shared source of truth for both agents. L1 rules live in `templates/l1/` and get wired per-agent during setup.

## Upstream

Forked from [MehmetGoekce/llm-wiki](https://github.com/MehmetGoekce/llm-wiki). All upstream Claude Code functionality is preserved — this is a pure extension, no breaking changes.
