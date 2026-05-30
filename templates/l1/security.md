## Security Boundary

- Credentials, passwords, API tokens, SSH keys → **NEVER in wiki pages** (git-tracked!)
- L1 only: `memory/` (Claude) or `.opencode/instructions/` (OpenCode) — both git-excluded
- Pattern detection: `token::`, `password::`, `secret::`, `api-key::`, long base64 strings
- Lint flags any of these patterns found in Wiki/ pages
