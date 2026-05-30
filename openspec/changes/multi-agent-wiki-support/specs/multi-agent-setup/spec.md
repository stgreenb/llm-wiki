## ADDED Requirements

### Requirement: setup.sh detects installed agents
The setup.sh script SHALL detect which AI coding agents are installed on the system by checking for the `claude` and `opencode` commands, plus `npx opencode --version` as a fallback.

#### Scenario: Only Claude Code installed (via PATH)
- **WHEN** `claude` is found on PATH and `opencode` is not
- **THEN** setup.sh SHALL scaffold only the Claude Code configuration
- **AND** setup.sh SHALL emit `Found claude at <path>` with version

#### Scenario: Only OpenCode installed (via PATH)
- **WHEN** `opencode` is found on PATH and `claude` is not
- **THEN** setup.sh SHALL scaffold only the OpenCode configuration
- **AND** setup.sh SHALL emit `Found opencode at <path>` with version

#### Scenario: Only OpenCode installed (via npx)
- **WHEN** `opencode` is not on PATH but `npx opencode --version` succeeds
- **THEN** setup.sh SHALL detect opencode as available
- **AND** setup.sh SHALL emit `Found opencode via npx` with version

#### Scenario: Both agents installed
- **WHEN** both `claude` and `opencode` are found (via PATH or npx)
- **THEN** setup.sh SHALL prompt the user to choose which agents to configure (claude, opencode, or both)

#### Scenario: Neither agent installed
- **WHEN** neither `claude`, `opencode`, nor `npx opencode` is found
- **THEN** setup.sh SHALL print a warning and exit with instructions to install at least one agent

#### Scenario: Detection diagnostics emitted
- **WHEN** setup.sh completes agent detection
- **THEN** it SHALL print a line per checked agent: `Found <name> at <path> v<version>` or `<name>: not found, skipping`

### Requirement: setup.sh scaffolds per-agent configs
For each selected agent, setup.sh SHALL create the appropriate configuration files and directory structure.

#### Scenario: Claude Code scaffold
- **WHEN** Claude Code is selected
- **THEN** setup.sh SHALL create `.claude/commands/wiki.md` by copying the repo's `wiki.md`, patching in the config file path
- **AND** setup.sh SHALL create a `memory/` directory for L1 storage

#### Scenario: OpenCode scaffold
- **WHEN** OpenCode is selected
- **THEN** setup.sh SHALL create `opencode.json` at the wiki root with wiki command definitions
- **AND** setup.sh SHALL create `.opencode/commands/wiki-ingest.md`, `wiki-query.md`, `wiki-lint.md`, `wiki-status.md` command files

#### Scenario: Both agents scaffolded
- **WHEN** both Claude Code and OpenCode are selected
- **THEN** setup.sh SHALL perform both scaffold operations without conflict

### Requirement: llm-wiki.yml agents field
The llm-wiki.yml configuration SHALL include an optional `agents` field listing which agents are configured.

#### Scenario: Agents field generated
- **WHEN** setup.sh completes
- **THEN** llm-wiki.yml SHALL contain `agents:` with the list of configured agent names (e.g., `agents: [claude, opencode]`)
