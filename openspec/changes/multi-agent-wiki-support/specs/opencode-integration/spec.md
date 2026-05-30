## ADDED Requirements

### Requirement: OpenCode wiki commands defined in opencode.json
The `opencode.json` configuration file SHALL define four wiki commands: `wiki-ingest`, `wiki-query`, `wiki-lint`, and `wiki-status`.

#### Scenario: Command registration
- **WHEN** OpenCode loads the project
- **THEN** opencode.json SHALL be read and the four wiki commands SHALL be available

### Requirement: OpenCode wiki commands reference wiki.md
Each OpenCode wiki command SHALL use the `@wiki.md` file reference to inject the shared workflow instructions into the prompt.

#### Scenario: Ingest command uses @wiki.md
- **WHEN** user runs `wiki-ingest "source text"`
- **THEN** the prompt SHALL include the full content of `wiki.md` via `@wiki.md`
- **AND** the prompt SHALL pass the source text as `$ARGUMENTS`

#### Scenario: Query command uses @wiki.md
- **WHEN** user runs `wiki-query "question"`
- **THEN** the prompt SHALL include `@wiki.md` and pass the question as `$ARGUMENTS`

#### Scenario: Lint command uses @wiki.md
- **WHEN** user runs `wiki-lint` or `wiki-lint --fix`
- **THEN** the prompt SHALL include `@wiki.md` and pass any flags as `$ARGUMENTS`

#### Scenario: Status command uses @wiki.md
- **WHEN** user runs `wiki-status`
- **THEN** the prompt SHALL include `@wiki.md`

### Requirement: OpenCode commands default to main conversation context
Wiki commands SHALL NOT use sub-agent routing (`agent: smarter` or `subtask: true`) by default. The commands execute in the main conversation context to preserve conversation history.

#### Scenario: Default is main-context
- **WHEN** a wiki command is invoked without flags
- **THEN** the agent executing it SHALL be the current conversation agent (not a spawned sub-agent)

### Requirement: Heavy operations can opt into sub-agent mode
For large ingest jobs, an escape hatch SHALL exist to run wiki operations in a clean sub-agent context, preventing context window pollution.

#### Scenario: wiki-ingest-bg command uses sub-agent
- **WHEN** user runs `wiki-ingest-bg "large source document"`
- **THEN** the command SHALL execute in a separate sub-agent context via `"subtask": true`
- **AND** the main conversation context SHALL be preserved

#### Scenario: Per-command subtask override
- **WHEN** opencode.json has `"subtask": true` for a wiki command
- **THEN** that command SHALL always spawn a clean sub-agent, regardless of operation size

### Requirement: AGENTS.md provides wiki instructions for OpenCode
The `AGENTS.md` file SHALL contain wiki-aware L1 instructions that OpenCode reads at project start, including the L1/L2 architecture, routing rules, and tool-specific format guidance.

#### Scenario: OpenCode reads AGENTS.md at startup
- **WHEN** OpenCode starts in the project directory
- **THEN** the agent SHALL have wiki context from AGENTS.md available without a wiki query

#### Scenario: Security rules in AGENTS.md
- **WHEN** OpenCode processes wiki content
- **THEN** the credential leak rules defined in AGENTS.md SHALL be respected (no tokens, passwords, or secrets in wiki pages)

### Requirement: Command files exist for each operation
A `.opencode/commands/wiki-<operation>.md` file SHALL exist for each wiki operation, with YAML frontmatter describing the command.

#### Scenario: Command file structure
- **WHEN** OpenCode loads `.opencode/commands/`
- **THEN** four markdown files SHALL be found: `wiki-ingest.md`, `wiki-query.md`, `wiki-lint.md`, `wiki-status.md`
- **AND** each SHALL have a `description` field in its frontmatter
