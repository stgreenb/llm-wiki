## 1. Extend setup.sh for Agent Detection

- [x] 1.1 Add agent detection logic: check `command -v claude`, `command -v opencode`, and `npx opencode --version` as fallback
- [x] 1.2 Handle all four detection scenarios: claude-only, opencode-only, both, neither
- [x] 1.3 Emit detection diagnostics per agent: "Found X at <path> v<version>" or "X: not found, skipping"
- [x] 1.4 Add interactive prompt when both agents detected (let user choose which to scaffold)

## 2. Claude Code Scaffold Path

- [x] 2.1 Copy wiki.md → .claude/commands/wiki.md with config path patching (preserve upstream behavior)
- [x] 2.2 Create `memory/` directory with .gitignore for L1 storage
- [x] 2.3 Add `agents: [claude]` to generated llm-wiki.yml

## 3. OpenCode Scaffold Path

- [x] 3.1 Create `opencode.json` with wiki-ingest, wiki-query, wiki-lint, wiki-status commands referencing `@wiki.md`
- [x] 3.2 Create `.opencode/commands/wiki-ingest.md` command file
- [x] 3.3 Create `.opencode/commands/wiki-query.md` command file
- [x] 3.4 Create `.opencode/commands/wiki-lint.md` command file
- [x] 3.5 Create `.opencode/commands/wiki-status.md` command file
- [x] 3.6 Create `wiki-ingest-bg` command variant with `"subtask": true` for heavy jobs
- [x] 3.7 Add `agents: [opencode]` to generated llm-wiki.yml

## 4. Dual-Agent Scaffold Path

- [x] 4.1 Run both Claude Code and OpenCode scaffold without file conflicts
- [x] 4.2 Add `agents: [claude, opencode]` to generated llm-wiki.yml

## 5. L1 Memory Layer for Both Agents

- [x] 5.1 Create shared L1 templates in `templates/l1/routing.md` and `templates/l1/security.md`
- [x] 5.2 Write AGENTS.md sourcing L1 content from shared templates: L1/L2 routing rule, credential security boundary, tool-specific format table (Logseq/Obsidian), wiki path conventions
- [x] 5.3 Create `.opencode/instructions/` directory with .gitignore for sensitive gotchas
- [x] 5.4 Add AGENTS.md reference to `.opencode/instructions/` for git-excluded L1 content
- [x] 5.5 Ensure lint workflow flags L1/L2 duplicates (verbatim match) for both agents
- [x] 5.6 Wire memory/ files (Claude) to source from templates/l1/ during scaffold

## 6. Documentation

- [x] 6.1 Update README.md with multi-agent setup instructions, command syntax differences, and switching guide
- [x] 6.2 Update `config.example.yml` with agents field example and document detection behavior
- [x] 6.3 Add line budget warning comment to wiki.md (target: <300 lines)
