# llm-wiki-agents - Multi-LLM Knowledge Management

This fork extends llm-wiki to support multiple AI agents (Claude Code and OpenCode) as knowledge maintainers.

> L1 rules below are sourced from `templates/l1/` — shared templates that keep both agents in sync.

## L1/L2 Architecture

- **L1**: Auto-loaded memory (rules, gotchas, credentials) — loaded every session
- **L2**: Wiki knowledge (projects, workflows, research) — queried on-demand via wiki

Routing rule: "Would a mistake without this knowledge be dangerous/embarrassing? → L1. Merely inconvenient? → L2."

Credentials MUST stay in L1 (wiki is git-tracked!). See Security Boundary below.

## Multi-Agent Differences from Upstream

- **Claude Code**: Uses `.claude/commands/wiki.md` + `memory/` directory
- **OpenCode**: Uses `AGENTS.md` instructions + opencode.json for commands

Both agents use the same `llm-wiki.yml` configuration and schema.

## Configuration

Read `llm-wiki.yml` FIRST to determine tool (logseq/obsidian), paths, and namespaces.

## Tool-Specific Format

| | Logseq | Obsidian |
|---|--------|----------|
| Properties | `property:: value` (inline) | YAML frontmatter |
| File names | `Wiki___Tech___Strapi.md` | `Wiki/Tech/Strapi.md` |
| Hierarchy | Indentation + tab | Heading levels |
| Every line | `- ` prefix required | Standard markdown |

## Wiki Paths

- `Wiki/Schema.md` — Contract for all pages
- `Wiki/Dashboard.md` — Health metrics
- `Wiki/<Namespace>.md` — Hub pages for each namespace
- Pages created under configured namespaces

## Commands

Run with: `opencode run wiki-<operation> "args"`

| Command | Description |
|---------|-------------|
| `wiki-ingest` | Ingest source (URL/file/text) into wiki |
| `wiki-query` | Search wiki, synthesize answer |
| `wiki-lint` | Health check: orphans, stale, broken refs |
| `wiki-status` | Wiki metrics and health overview |
| `wiki-ingest-bg` | Heavy ingest in sub-agent (preserves conversation) |

## Security Boundary

- Credentials, passwords, API tokens → **NEVER in wiki pages** (git-tracked!)
- Sensitive L1 rules go in `.opencode/instructions/` (git-excluded)
- Lint flags: `token::`, `password::`, `secret::`, `api-key::`, long base64 strings

## Sensitive Gotchas

Place sensitive rules (credentials, tokens, private config) in `.opencode/instructions/`. This directory is git-ignored. Files placed there are auto-loaded as L1 context on session start.
