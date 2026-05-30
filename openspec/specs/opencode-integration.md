# Spec: OpenCode Integration — Wiki Commands and Agent Wiring

## Description

OpenCode requires its own command registration, configuration, and L1 memory
wiring. This spec defines how OpenCode is configured as a wiki maintainer
alongside or instead of Claude Code.

---

## Requirements

### OpenCode Wiki Commands

- REQ-900: An `opencode.json` configuration file SHALL define four wiki
  commands: `wiki-ingest`, `wiki-query`, `wiki-lint`, `wiki-status`.
- REQ-901: Each wiki command SHALL use the `@wiki.md` file reference to
  inject shared workflow instructions into the prompt.
- REQ-902: The wiki-ingest command SHALL pass user-provided source text
  via `$ARGUMENTS`.
- REQ-903: The wiki-query command SHALL pass the user's question via
  `$ARGUMENTS`.
- REQ-904: The wiki-lint command SHALL pass any flags (e.g., `--fix`) via
  `$ARGUMENTS`.
- REQ-905: Wiki commands SHALL execute in the main conversation context
  (not sub-agents) to preserve conversation history by default.

### Sub-Agent Escape Hatch

- REQ-910: A `wiki-ingest-bg` command SHALL exist with `"subtask": true`
  for heavy ingest jobs that would pollute the main context window.
- REQ-911: Per-command `"subtask": true` in opencode.json SHALL cause
  that command to always spawn a clean sub-agent.

### Command Files

- REQ-920: A `.opencode/commands/wiki-<operation>.md` file SHALL exist
  for each wiki operation: `wiki-ingest.md`, `wiki-query.md`,
  `wiki-lint.md`, `wiki-status.md`.
- REQ-921: Each command file SHALL have a `description` field in its
  YAML frontmatter.

### AGENTS.md as OpenCode L1

- REQ-930: The `AGENTS.md` file SHALL contain wiki-aware L1 instructions
  that OpenCode reads at project start.
- REQ-931: AGENTS.md SHALL include: L1/L2 routing rule, credential
  security boundary, tool-specific format table (Logseq/Obsidian),
  and wiki path conventions.
- REQ-932: Sensitive rules (credentials, tokens, API keys) SHALL be
  stored in `.opencode/instructions/` (git-ignored), not in wiki pages
  or AGENTS.md itself.
- REQ-933: AGENTS.md SHALL reference `.opencode/instructions/` as the
  location for git-excluded L1 gotchas.

---

## Scenarios

### Scenario 1: Command registration

```
WHEN OpenCode loads the project
THEN opencode.json SHALL be read
AND the four wiki commands SHALL be available
```

### Scenario 2: Command uses @wiki.md

```
WHEN user runs a wiki command
THEN the prompt SHALL include the full content of wiki.md via @wiki.md
```

### Scenario 3: wiki-ingest-bg uses sub-agent

```
WHEN user runs "wiki-ingest-bg" with a large source document
THEN the command SHALL execute in a separate sub-agent context
AND the main conversation context SHALL be preserved
```

### Scenario 4: AGENTS.md read at startup

```
WHEN OpenCode starts in the project directory
THEN the agent SHALL have wiki context from AGENTS.md available
AND credential rules SHALL be respected
```

---

## Acceptance Criteria

- [ ] opencode.json registers 5 commands (4 wiki + 1 bg variant)
- [ ] Each command references @wiki.md
- [ ] wiki-ingest-bg uses "subtask": true
- [ ] AGENTS.md contains L1 wiki instructions
- [ ] .opencode/instructions/ is gitignored
- [ ] Command files exist with YAML frontmatter descriptions

---

## Dependencies

- `wiki.md` must exist at the project root
- `opencode.json` config format per opencode.ai/docs/config schema
- `templates/l1/` provides shared rules sourced into AGENTS.md
