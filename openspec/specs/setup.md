# Spec: setup.sh — Interactive Installer

## Description

The setup script is the entry point for new users. It guides them through an
interactive 11-step process to configure their wiki, create initial pages (Schema,
Dashboard, Hub pages), generate the config file, and optionally install the /wiki
skill for Claude Code. It requires only bash, python3, and git.

---

## Requirements

### Prerequisites

- REQ-700: The system MUST require bash (any version supporting `read -p`).
- REQ-701: The system MUST require python3. If python3 is not available, the
  system SHALL display an error and exit.
- REQ-702: The system MUST require git for the optional git init step.
  If git is not available, git-related steps SHALL be skipped with a warning.
- REQ-703: The system MUST NOT require any package manager (npm, pip, etc.)
  or any installed libraries beyond the standard library.

### Agent Detection

- REQ-704: The system SHALL detect which AI coding agents are installed by
  checking for the `claude` and `opencode` commands on PATH, with
  `npx opencode --version` as a fallback.
- REQ-705: Detection diagnostics SHALL be emitted per agent:
  `Found <name> at <path> v<version>` or `<name>: not found, skipping`.
- REQ-706: Diagnostics SHALL be written to stderr (`>&2`) so status
  variables remain clean.
- REQ-707: When both agents are detected, the system SHALL prompt the user
  to choose which agents to configure: Claude Code only, OpenCode only, or Both.
- REQ-708: When neither agent is detected, the system SHALL print a warning
  and exit with instructions to install at least one agent.
- REQ-709: Per-agent scaffold paths:
  - Claude Code: `.claude/commands/wiki.md` (copied from repo's `wiki.md`),
    `memory/` directory for L1 storage
  - OpenCode: `opencode.json` with wiki command definitions,
    `.opencode/commands/wiki-*.md` command files
- REQ-710: The system SHALL include an optional `agents` field in
  `llm-wiki.yml` listing which agents are configured.

### Step 1: Tool Selection

- REQ-720: The system SHALL prompt the user to choose between Logseq (1) and
  Obsidian (2).
- REQ-721: If the user enters a value other than 1 or 2, the system SHALL
  display an error and exit.
- REQ-722: The tool choice determines ALL downstream behavior: file naming,
  property syntax, directory structure, template selection.

### Step 2: Wiki Path

- REQ-730: The system SHALL prompt for the wiki/vault root path with a
  tool-specific default (`~/Documents/Logseq` or `~/Documents/ObsidianVault`).
- REQ-731: The system SHALL expand `~` to `$HOME` in the provided path.
- REQ-732: If the path does not exist, the system SHALL ask "Create it? [y/n]".
  On "y": create with `mkdir -p`. On "n": exit with error.

### Step 3: Pages Directory

- REQ-740: For Logseq, `pages_dir` SHALL be set to `pages`.
  For Obsidian, `pages_dir` SHALL be set to empty string.
- REQ-741: If the pages directory does not exist, the system SHALL create it
  with `mkdir -p`.

### Step 4: Namespaces

- REQ-750: The system SHALL offer a default namespace list:
  Business, Tech, Content, Projects, People, Learning, Reference.
- REQ-751: The user MAY enter a custom space-separated list or press Enter
  to accept defaults.
- REQ-752: Namespace names SHOULD be single words in Title Case. The system
  does not validate this (user responsibility).

### Step 5: Memory Path

- REQ-760: The system SHALL prompt for the Claude Code memory directory path.
- REQ-761: The user MAY skip this step. If skipped, `memory_path` is empty
  in the generated config.
- REQ-762: The system SHALL expand `~` to `$HOME` in the provided path.
- REQ-763: The system does NOT validate that the memory path exists (it may
  be created later by Claude Code).

### Step 6: Git Init

- REQ-770: If the wiki directory does not have a `.git` directory, the system
  SHALL ask "Initialize git? [y/n]".
- REQ-771: On "y": run `git init`, create tool-specific `.gitignore`.
- REQ-772: Logseq `.gitignore` SHALL include: `logseq/bak/`, `logseq/.recycle/`,
  `.DS_Store`, `.logseq/`.
- REQ-773: Obsidian `.gitignore` SHALL include: `.obsidian/workspace.json`,
  `.obsidian/workspace-mobile.json`, `.DS_Store`, `.trash/`.
- REQ-774: On "n": skip git initialization entirely.
- REQ-775: If `.git` already exists, skip this step silently.

### Step 7: Template Validation

- REQ-780: The system SHALL locate the template directory at
  `$SCRIPT_DIR/templates/$TOOL/`.
- REQ-781: If the template directory does not exist, the system SHALL display
  an error and exit.

### Step 8: Page Creation (Python Template Rendering)

- REQ-790: The system SHALL use python3 to render templates with variable
  substitution.
- REQ-791: Template variables: `{{DATE}}` (today, YYYY-MM-DD),
  `{{NAMESPACES}}` (comma-separated list), `{{NAMESPACE}}` (single name),
  `{{NAMESPACE_LINKS}}` (formatted link list).
- REQ-792: The system SHALL create these pages:
  - Schema page (from `Schema.md` template)
  - Dashboard page (from `Dashboard.md` template)
  - One Hub page per namespace (from `Hub.md` template)
- REQ-793: For Logseq: all pages created flat in `pages/` directory with
  triple-underscore naming (`Wiki___Schema.md`, `Wiki___Tech.md`, etc.).
- REQ-794: For Obsidian: Schema and Dashboard in `Wiki/` directory.
  Hub pages in `Wiki/<Namespace>/_index.md` with directory creation.
- REQ-795: The system SHALL create parent directories as needed (`mkdir -p`).
- REQ-796: The system SHALL NOT overwrite existing pages. If a page already
  exists, the system SHOULD skip it with a warning.

### Step 9: Config File Generation

- REQ-800: The system SHALL create `llm-wiki.yml` in the wiki root directory.
- REQ-801: The config SHALL include all required keys: tool, wiki_path,
  pages_dir, namespaces. And memory_path if provided.
- REQ-802: The config SHALL include a header comment with generation date.
- REQ-803: The config SHALL include an optional `agents` field listing which
  agents are configured.

### Step 10: Skill Installation

- REQ-810: The system SHALL ask if the user wants to install the /wiki skill
  for Claude Code.
- REQ-811: The user MAY enter a project path or "skip" to decline.
- REQ-812: If installing: copy `wiki.md` to `$project/.claude/commands/wiki.md`,
  creating the directory if needed.
- REQ-813: The system SHALL patch the `<CONFIG_PATH>` placeholder in the
  copied skill file with the actual config file path using `sed`.
- REQ-814: The sed command MUST be platform-aware: macOS uses `sed -i ''`,
  Linux uses `sed -i`.

### Step 11: Agent Scaffold

- REQ-820: The system SHALL scaffold per-agent configuration based on the
  user's selection.
- REQ-821: Claude Code scaffold: copy `wiki.md` to `.claude/commands/wiki.md`,
  create `memory/` directory with `.gitignore`.
- REQ-822: OpenCode scaffold: create `opencode.json` with wiki command
  definitions, create `.opencode/commands/wiki-*.md` command files.
- REQ-823: When both agents selected, both scaffolds SHALL complete without
  file conflicts.

### Step 12: Initial Git Commit

- REQ-830: If git was initialized (Step 6) or `.git` already existed, the
  system SHALL create an initial commit with all created files.
- REQ-831: The commit message SHALL include: tool name, namespace count,
  and a link to the GitHub repository.
- REQ-832: Git errors during commit SHALL be suppressed (the commit is
  best-effort, not critical).

### Final Summary

- REQ-840: The system SHALL display a summary showing: wiki path, config
  file path, and 3 suggested next steps.
- REQ-841: The next steps SHALL include: open wiki in tool, try first ingest,
  run status command.

---

## Scenarios

### Scenario 1: Happy path — Logseq, new directory, defaults

```
GIVEN python3 and git are available
WHEN the user runs ./setup.sh and:
    - Selects "1" (Logseq)
    - Enters "~/Documents/TestWiki" (does not exist)
    - Confirms "y" to create directory
    - Presses Enter for default namespaces
    - Enters "~/.claude/projects/test/memory/" for memory path
    - Confirms "y" for git init
    - Enters "~/myproject" for skill installation
THEN the system SHALL:
    - Create ~/Documents/TestWiki/pages/
    - Create 9 pages: Schema, Dashboard, 7 hub pages (one per default namespace)
    - Create llm-wiki.yml with all settings
    - Initialize git with .gitignore
    - Copy wiki.md to ~/myproject/.claude/commands/wiki.md with patched config path
    - Create initial git commit
    - Display summary with next steps
```

### Scenario 2: Happy path — Obsidian, existing vault

```
GIVEN ~/Documents/ObsidianVault/ already exists with .obsidian/ directory
WHEN the user runs ./setup.sh and:
    - Selects "2" (Obsidian)
    - Enters "~/Documents/ObsidianVault"
    - Presses Enter for default namespaces
    - Skips memory path
    - git already initialized (.git exists)
    - Skips skill installation
THEN the system SHALL:
    - Create Wiki/ directory inside the vault
    - Create Schema.md and Dashboard.md in Wiki/
    - Create 7 namespace directories with _index.md hub pages
    - Create llm-wiki.yml (no memory_path)
    - Skip git init (already exists)
    - Create git commit with new files
    - Display summary
```

### Scenario 3: Directory does not exist — user declines creation

```
GIVEN the user enters wiki path "/nonexistent/path"
AND the path does not exist
WHEN the system asks "Create it? [y/n]"
AND the user enters "n"
THEN the system SHALL display an error message
AND exit with code 1
AND no files SHALL be created anywhere
```

### Scenario 4: Invalid tool selection

```
WHEN the user enters "3" for tool selection
THEN the system SHALL display: "Invalid choice"
AND exit with code 1
```

### Scenario 5: python3 not available

```
GIVEN python3 is not installed or not in PATH
WHEN setup.sh reaches the template rendering step
THEN the system SHALL fail with a python3-related error
AND no wiki pages SHALL be created
```

### Scenario 6: Template directory missing

```
GIVEN the templates/logseq/ directory does not exist
    (e.g., setup.sh run from wrong location)
WHEN setup.sh reaches template validation
THEN the system SHALL display an error about missing templates
AND exit with code 1
```

### Scenario 7: Skill installation skipped

```
WHEN the user enters "skip" for the skill installation prompt
THEN the system SHALL NOT copy wiki.md anywhere
AND SHALL NOT modify any files outside the wiki directory
AND SHALL continue to the git commit step
```

### Scenario 8: Custom namespaces

```
WHEN the user enters "Engineering Sales Support" for namespaces
THEN the system SHALL create 3 hub pages:
    - Wiki___Engineering.md (Logseq) or Wiki/Engineering/_index.md (Obsidian)
    - Wiki___Sales.md or Wiki/Sales/_index.md
    - Wiki___Support.md or Wiki/Support/_index.md
AND the Schema page SHALL list these 3 namespaces
AND llm-wiki.yml SHALL contain these 3 namespaces
```

### Scenario 9: Git init skipped

```
GIVEN the wiki directory has no .git/
WHEN the system asks "Initialize git? [y/n]"
AND the user enters "n"
THEN no .git directory SHALL be created
AND no .gitignore SHALL be created
AND the final commit step SHALL be skipped
```

### Scenario 10: Existing pages not overwritten

```
GIVEN ~/Documents/Logseq/pages/Wiki___Schema.md already exists
    from a previous setup run
WHEN setup.sh runs template rendering
THEN the existing Schema page SHOULD NOT be overwritten
AND the system SHOULD display: "Wiki___Schema.md already exists, skipping"
```

---

## Acceptance Criteria

- [ ] Only requires bash, python3, git (no package managers, no libraries)
- [ ] Tool selection (1/2) determines all downstream behavior
- [ ] Tilde expansion works in all path inputs
- [ ] Missing directories created with user confirmation
- [ ] Default namespaces offered, custom list accepted
- [ ] Template rendering creates Schema, Dashboard, and all Hub pages
- [ ] Logseq: flat files with triple-underscore naming
- [ ] Obsidian: directory hierarchy with _index.md hub files
- [ ] Config file generated with all required keys
- [ ] Skill installation optional, sed platform-aware
- [ ] Git init optional, tool-specific .gitignore
- [ ] Existing pages not silently overwritten
- [ ] Clear error messages for all failure modes
- [ ] Final summary with actionable next steps

---

## Dependencies

- Templates must exist: `templates/logseq/{Schema,Hub,Dashboard}.md` and
  `templates/obsidian/{Schema,Hub,Dashboard}.md`
- specs/config.md defines the format of the generated `llm-wiki.yml`
- specs/schema.md defines what the generated Schema page contains
