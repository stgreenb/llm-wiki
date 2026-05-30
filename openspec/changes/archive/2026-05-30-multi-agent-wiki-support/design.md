## Context

The upstream llm-wiki scaffolds a wiki for Claude Code only: `setup.sh` copies `wiki.md` into `.claude/commands/wiki.md` and all workflows assume Claude Code as the LLM agent. The fork must preserve this path while adding equivalent support for OpenCode.

Key constraints:
- The wiki itself (Wiki/ directory, llm-wiki.yml) must be SHARED — both agents read/write the same files
- The workflow instructions in `wiki.md` must remain the SINGLE source of truth — no forking the workflows
- Agent-specific tooling (commands, L1 memory, project instructions) must use each agent's native mechanism
- Zero breaking changes to the Claude Code path

## Goals / Non-Goals

**Goals:**
- setup.sh detects installed agents and scaffolds appropriate configs
- OpenCode users can run wiki-ingest, wiki-query, wiki-lint, wiki-status
- Both agents share the same wiki files, llm-wiki.yml config, and workflow instructions
- L1 memory works for both agents (different mechanisms, same purpose)
- Switch between agents without reconfiguration

**Non-Goals:**
- Create a new scripting language or MCP server — agent-native mechanisms only
- Build a custom sync layer between agents — they share the same files directly
- Support agents beyond Claude Code and OpenCode (future concern)

## Decisions

**Decision 1: Single `wiki.md` with per-agent wiring**
- Claude Code: setup.sh copies `wiki.md` → `.claude/commands/wiki.md` (unchanged upstream behavior)
- OpenCode: `opencode.json` commands + `.opencode/commands/wiki-*.md` files that reference `@wiki.md` inline
- Rationale: Zero duplication of workflow logic. The `wiki.md` content is injected into OpenCode's prompt via the `@filename` command syntax. If workflows need updating, only `wiki.md` changes.

**Decision 2: Agent detection in setup.sh**
- `setup.sh` checks `command -v claude`, `command -v opencode`, and `npx opencode --version 2>/dev/null`
- Falls back gracefully: emits a clear diagnostic per agent ("found opencode at /usr/local/bin/opencode v1.2.3" or "opencode: not found, skipping")
- Scaffolds configs for each detected agent
- Asks user which agents to configure if both are detected
- Logs detected versions for traceability
- Rationale: Covers npx and PATH-based installs. Clear diagnostics prevent silent skips.

**Decision 3: L1 memory divergence**
- Claude Code: `memory/` directory (unchanged — Claude auto-loads from CLAUDE.md reference)
- OpenCode: Wiki rules embedded directly in `AGENTS.md` (auto-loaded every session) + optional `.opencode/instructions/` for gotchas
- Both: Generated from shared templates in `templates/l1/` so updating a routing rule changes both agents
- Rationale: OpenCode has no `memory/` directory equivalent. `AGENTS.md` is its closest parallel — it's read at project start. Gotchas and credentials that shouldn't be in git go to `.opencode/instructions/` which is gitignored. A shared template directory prevents drift between agent-specific L1 files.

**Decision 4: llm-wiki.yml agents field**
- Add optional `agents:` list to llm-wiki.yml (e.g., `agents: [claude, opencode]`)
- setup.sh generates this based on detection
- Future-proof: easy to add new agent types
- Rationale: The config file already exists and is read first by both agents. Adding the agents field here is the natural place.

**Decision 5: OpenCode commands reference wiki.md**
- OpenCode commands use `@wiki.md` to inject the full workflow file
- Example: `wiki-ingest` command template is `Read @wiki.md and execute the ingest workflow.\nSource: $ARGUMENTS`
- Rationale: No command-specific logic duplication. The sub-agent gets the full workflow context. The `$ARGUMENTS` mechanism passes the wiki operation's parameters.

## Risks / Trade-offs

- **[Duplication risk]** AGENTS.md and `.claude/` CLAUDE.md both describe the project — they could drift
  → Mitigation: setup.sh generates both from templates; AGENTS.md is the canonical instruction file

- **[Confusion risk]** Users switching agents might expect identical command syntax
  → Mitigation: OpenCode commands use `wiki-ingest` (hyphenated) vs Claude's `/wiki ingest` (subcommand). Document the difference in README.

- **[Include overhead]** `@wiki.md` includes the full file every command run, consuming context
  → Mitigation: wiki.md is ~200 lines; acceptable for a main-context prompt. Set a 300-line budget in wiki.md — if it exceeds that, formalize skills-based extraction.
  → Escape hatch: define shared skills in `.claude/skills/wiki-*/SKILL.md` (both agents can load them). Not implemented in this change but available if wiki.md grows beyond budget.

- **[Agent drift]** OpenCode may add/change features that alter how commands or skills work
  → Mitigation: Pin minimum OpenCode version in docs; test on upgrade.

- **[Context pollution]** Main-context wiki commands consume conversation window on heavy ingest jobs
  → Mitigation: Default is main-context (simpler, preserves history). Heavy operations can opt into sub-agent via `"subtask": true` on a per-command basis in opencode.json, or via a `wiki-ingest-bg` variant command that spawns a clean sub-agent.
