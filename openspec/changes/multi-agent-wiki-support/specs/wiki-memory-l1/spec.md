## ADDED Requirements

### Requirement: Claude Code L1 memory uses memory/ directory
When Claude Code is configured, the L1 memory directory `memory/` SHALL exist and be referenced in the Claude Code project instructions.

#### Scenario: memory directory created
- **WHEN** setup.sh runs with Claude Code selected
- **THEN** a `memory/` directory SHALL be created at the wiki project root
- **AND** it SHALL be excluded from git tracking

#### Scenario: Memory files loadable
- **WHEN** Claude Code starts a session
- **THEN** files in `memory/` SHALL be auto-loaded as L1 context

### Requirement: OpenCode L1 memory uses AGENTS.md
When OpenCode is configured, the `AGENTS.md` file SHALL contain wiki rules, routing guidance, and format conventions as L1 knowledge.

#### Scenario: Wiki rules in AGENTS.md
- **WHEN** OpenCode starts a session
- **THEN** `AGENTS.md` SHALL contain the L1/L2 routing rule, credential security boundary, tool-specific format table, and wiki path conventions

#### Scenario: Git-excluded gotchas
- **WHEN** sensitive rules (credentials, tokens) need L1 storage
- **THEN** they SHALL be stored in `.opencode/instructions/` which is gitignored
- **AND** AGENTS.md SHALL reference this directory

### Requirement: L1 content is generated from shared templates
The L1 content for both agents SHALL be generated from shared templates in `templates/l1/` so that updating a rule once updates both agents.

#### Scenario: Shared templates prevent drift
- **WHEN** setup.sh creates L1 content for any agent
- **THEN** it SHALL source the L1 routing rule, credential policy, and conventions from `templates/l1/`
- **AND** both AGENTS.md (OpenCode) and memory/ files (Claude Code) SHALL contain the same rule text

#### Scenario: Template directory structure
- **WHEN** setup.sh runs
- **THEN** `templates/l1/` SHALL exist with at minimum: `routing.md` (L1/L2 boundary rule) and `security.md` (credential policy)

### Requirement: L1/L2 boundary is agent-independent
The L1/L2 routing rule SHALL be the same regardless of which agent is in use.

#### Scenario: Single routing rule
- **WHEN** either agent encounters new knowledge
- **THEN** the routing rule SHALL be: dangerous/embarrassing mistakes → L1, merely inconvenient → L2
- **AND** credentials SHALL always route to L1 (never git-tracked wiki pages)

#### Scenario: Lint flags L1/L2 duplicates in both agents
- **WHEN** /wiki lint (Claude) or wiki-lint (OpenCode) runs
- **THEN** the lint SHALL flag content that appears verbatim in both L1 and a Wiki/ page
- **AND** the lint SHALL report the page path and suggest removing the duplicate from L1

#### Scenario: Duplicate defined as verbatim match
- **WHEN** a sentence or rule appears with identical text in AGENTS.md and Wiki/Schema.md
- **THEN** the lint SHALL flag this as an L1/L2 duplicate
- **AND** a near-match (e.g., "max 2 SSH calls" vs "max 2-3 SSH calls") SHALL NOT be flagged — only exact string matches
