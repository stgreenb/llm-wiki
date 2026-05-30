## Why

**Fork**: https://github.com/stgreenb/llm-wiki (forked from MehmetGoekce/llm-wiki)

The upstream llm-wiki only supports Claude Code as a wiki maintainer. Users who work with OpenCode (an alternative AI coding agent) cannot use the wiki. This fork extends llm-wiki so both agents can read, write, and maintain the same wiki from the same project — letting users switch between agents freely.

## What Changes

- Extend `setup.sh` to detect which agents are installed (claude, opencode, both) and scaffold appropriate configs
- Create `opencode.json` with wiki commands (`wiki-ingest`, `wiki-query`, `wiki-lint`, `wiki-status`) that reference the shared `wiki.md` workflow file
- Create `.opencode/commands/wiki-*.md` command files for OpenCode
- Add L1 memory support for OpenCode via `AGENTS.md` (auto-loaded per session)
- Create `.claude/commands/` directory scaffold for Claude Code (unchanged from upstream)
- Add `llm-wiki.yml` configuration with agent detection fields
- Add `memory/` directory for Claude Code L1 memory
- Document the dual-agent setup in `AGENTS.md` and update `README.md`

**No breaking changes** — all existing Claude Code functionality is preserved.

## Capabilities

### New Capabilities

- `multi-agent-setup`: Extended setup.sh that detects installed agents and scaffolds Claude Code, OpenCode, or both
- `opencode-integration`: OpenCode command definitions, AGENTS.md wiki instructions, and command wiring for all wiki operations
- `wiki-memory-l1`: Agent-aware L1 memory layer — Claude Code uses `memory/` directory, OpenCode uses AGENTS.md + optional `.opencode/instructions/`

### Modified Capabilities

None — no existing specs to modify.

## Impact

- `setup.sh` — extended with agent detection, dual-scaffold logic, and config generation
- `wiki.md` — unchanged (shared source of truth for workflows)
- New files: `opencode.json`, `.opencode/commands/wiki-*.md`, `.claude/commands/wiki.md`
- New files: `AGENTS.md` (wiki-aware L1 instructions for OpenCode), `memory/` directory for Claude Code
- `llm-wiki.yml` — new optional `agents` field to specify which agent(s) are in use
- `docs/` — updated with multi-agent setup documentation
