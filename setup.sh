#!/bin/bash
set -eo pipefail

# Detect script location BEFORE any cd operations
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ----- Prerequisites -----
check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo -e "\033[0;31mRequired: '$1' is not installed.\033[0m"
        echo "Please install $1 and try again."
        exit 1
    fi
}

check_command python3
check_command git

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'
BOLD='\033[1m'

echo ""
echo -e "${CYAN}${BOLD}llm-wiki setup${NC}"
echo -e "${CYAN}Multi-agent wiki: Claude Code + OpenCode${NC}"
echo ""

# ===== AGENT DETECTION =====
echo -e "${BOLD}Detecting AI coding agents...${NC}"

detect_agent() {
    local name="$1"
    local cmd="$2"
    local fallback="$3"
    local path=""
    local version=""

    if command -v "$cmd" &> /dev/null; then
        path="$(command -v "$cmd")"
        version="$($cmd --version 2>/dev/null | head -1 || echo "unknown")"
        echo -e "  ${GREEN}Found $name at $path v$version${NC}" >&2
        echo "found"
    elif [ -n "$fallback" ] && eval "$fallback" &>/dev/null; then
        version="$(eval "$fallback" | head -1 || echo "unknown")"
        echo -e "  ${GREEN}Found $name via npx v$version${NC}" >&2
        echo "found"
    else
        echo -e "  ${YELLOW}$name: not found, skipping${NC}" >&2
        echo "not_found"
    fi
}

CLAUDE_STATUS=$(detect_agent "claude" "claude" "")
OPENCODE_STATUS=$(detect_agent "opencode" "opencode" "npx opencode --version 2>/dev/null")

SELECTED_AGENTS=()

if [ "$CLAUDE_STATUS" = "not_found" ] && [ "$OPENCODE_STATUS" = "not_found" ]; then
    echo ""
    echo -e "${RED}No AI coding agents detected.${NC}"
    echo "Install at least one agent to use llm-wiki:"
    echo "  Claude Code: https://docs.anthropic.com/en/docs/claude-code"
    echo "  OpenCode:    https://opencode.ai"
    exit 1
fi

if [ "$CLAUDE_STATUS" = "found" ] && [ "$OPENCODE_STATUS" = "found" ]; then
    echo ""
    echo -e "${BOLD}Both Claude Code and OpenCode detected.${NC}"
    echo "Choose which agents to configure:"
    echo "  1) Claude Code only"
    echo "  2) OpenCode only"
    echo "  3) Both"
    read -p "Enter choice [1/2/3]: " agent_choice
    case $agent_choice in
        1) SELECTED_AGENTS=("claude") ;;
        2) SELECTED_AGENTS=("opencode") ;;
        3) SELECTED_AGENTS=("claude" "opencode") ;;
        *) echo -e "${RED}Invalid choice. Defaulting to both.${NC}"
           SELECTED_AGENTS=("claude" "opencode") ;;
    esac
elif [ "$CLAUDE_STATUS" = "found" ]; then
    SELECTED_AGENTS=("claude")
    echo -e "  ${GREEN}→ Configuring Claude Code only${NC}"
else
    SELECTED_AGENTS=("opencode")
    echo -e "  ${GREEN}→ Configuring OpenCode only${NC}"
fi
echo ""

# ===== STEP 1: Tool selection =====
echo -e "${BOLD}Which note-taking tool do you use?${NC}"
echo "  1) Logseq"
echo "  2) Obsidian"
read -p "Enter choice [1/2]: " tool_choice

case $tool_choice in
    1) TOOL="logseq" ;;
    2) TOOL="obsidian" ;;
    *) echo -e "${RED}Invalid choice. Exiting.${NC}"; exit 1 ;;
esac
echo -e "${GREEN}Selected: $TOOL${NC}"
echo ""

# ===== STEP 2: Wiki path =====
if [ "$TOOL" = "logseq" ]; then
    DEFAULT_PATH="$HOME/Documents/Logseq"
else
    DEFAULT_PATH="$HOME/Documents/ObsidianVault"
fi

echo -e "${BOLD}Where is your $TOOL graph/vault?${NC}"
read -p "Path [$DEFAULT_PATH]: " wiki_path
wiki_path="${wiki_path:-$DEFAULT_PATH}"

# Expand ~ to $HOME
wiki_path="${wiki_path/#\~/$HOME}"

if [ ! -d "$wiki_path" ]; then
    echo -e "${YELLOW}Directory does not exist. Create it? [y/n]${NC}"
    read -p "" create_dir
    if [ "$create_dir" = "y" ] || [ "$create_dir" = "Y" ]; then
        mkdir -p "$wiki_path"
        echo -e "${GREEN}Created: $wiki_path${NC}"
    else
        echo -e "${RED}Exiting. Please create the directory first.${NC}"
        exit 1
    fi
fi
echo ""

# ===== STEP 3: Pages directory =====
if [ "$TOOL" = "logseq" ]; then
    PAGES_DIR="pages"
else
    PAGES_DIR=""
fi

pages_path="$wiki_path/$PAGES_DIR"
if [ -n "$PAGES_DIR" ] && [ ! -d "$pages_path" ]; then
    mkdir -p "$pages_path"
fi

# ===== STEP 4: Namespaces =====
DEFAULT_NS="Business Tech Content Projects People Learning Reference"
echo -e "${BOLD}Which namespaces do you want?${NC}"
echo -e "Default: ${CYAN}$DEFAULT_NS${NC}"
read -p "Enter space-separated list (or press Enter for default): " custom_ns
NAMESPACES="${custom_ns:-$DEFAULT_NS}"

for ns in $NAMESPACES; do
    if [[ ! "$ns" =~ ^[A-Za-z][A-Za-z0-9-]*$ ]]; then
        echo -e "${RED}Invalid namespace name: '$ns'${NC}"
        echo "Namespace names must start with a letter and contain only letters, numbers, and hyphens."
        exit 1
    fi
done

echo -e "${GREEN}Namespaces: $NAMESPACES${NC}"
echo ""

# ===== STEP 5: Memory path =====
echo -e "${BOLD}Where is your Claude Code memory directory?${NC}"
echo -e "(Usually: ~/.claude/projects/<project>/memory/)"
read -p "Path [skip]: " memory_path
memory_path="${memory_path/#\~/$HOME}"
echo ""

# ===== STEP 6: Git init =====
if [ ! -d "$wiki_path/.git" ]; then
    echo -e "${BOLD}Initialize git in $wiki_path?${NC} [y/n]"
    read -p "" init_git
    if [ "$init_git" = "y" ] || [ "$init_git" = "Y" ]; then
        cd "$wiki_path"
        git init

        if [ "$TOOL" = "logseq" ]; then
            cat > .gitignore << 'GITIGNORE'
logseq/bak/
logseq/.recycle/
.DS_Store
.logseq/
GITIGNORE
        else
            cat > .gitignore << 'GITIGNORE'
.obsidian/workspace.json
.obsidian/workspace-mobile.json
.DS_Store
.trash/
GITIGNORE
        fi

        # Add memory/ and .opencode/instructions/ to gitignore if agents use them
        if [[ " ${SELECTED_AGENTS[*]} " =~ "claude" ]]; then
            echo "" >> .gitignore
            echo "# Claude Code L1 memory" >> .gitignore
            echo "memory/" >> .gitignore
        fi
        if [[ " ${SELECTED_AGENTS[*]} " =~ "opencode" ]]; then
            echo "" >> .gitignore
            echo "# OpenCode L1 gotchas (sensitive rules)" >> .gitignore
            echo ".opencode/instructions/" >> .gitignore
        fi

        echo -e "${GREEN}Git initialized with .gitignore${NC}"
    fi
fi
echo ""

# ===== STEP 7: Set template directory =====
TEMPLATE_DIR="$SCRIPT_DIR/templates/$TOOL"

if [ ! -d "$TEMPLATE_DIR" ]; then
    echo -e "${RED}Templates not found at $TEMPLATE_DIR${NC}"
    echo "Make sure you're running this from the llm-wiki repository."
    exit 1
fi

# ===== STEP 8: Create wiki pages via Python =====
echo -e "${BOLD}Creating wiki pages...${NC}"

TODAY=$(date +%Y-%m-%d)

python3 << PYEOF
import os

tool = "$TOOL"
pages_path = "$pages_path"
wiki_path = "$wiki_path"
template_dir = "$TEMPLATE_DIR"
namespaces = "$NAMESPACES".split()
today = "$TODAY"

def read_template(name):
    with open(os.path.join(template_dir, name)) as f:
        return f.read()

def write_file(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    if os.path.exists(path):
        print(f"  Skipped (already exists): {os.path.basename(path)}")
        return False
    with open(path, 'w') as f:
        f.write(content)
    return True

if tool == "logseq":
    ns_list = ", ".join(f"Wiki/{ns}" for ns in namespaces)
    schema = read_template("Schema.md")
    schema = schema.replace("{{NAMESPACES}}", ns_list)
    schema = schema.replace("{{DATE}}", today)
    if write_file(os.path.join(pages_path, "Wiki___Schema.md"), schema):
        print(f"  Created: Wiki/Schema")

    ns_links = "\n".join(f"\t- [[Wiki/{ns}]]" for ns in namespaces)
    dashboard = read_template("Dashboard.md")
    dashboard = dashboard.replace("{{NAMESPACE_LINKS}}", ns_links)
    dashboard = dashboard.replace("{{DATE}}", today)
    if write_file(os.path.join(pages_path, "Wiki___Dashboard.md"), dashboard):
        print(f"  Created: Wiki/Dashboard")

    hub_tpl = read_template("Hub.md")
    for ns in namespaces:
        hub = hub_tpl.replace("{{NAMESPACE}}", ns).replace("{{DATE}}", today)
        if write_file(os.path.join(pages_path, f"Wiki___{ns}.md"), hub):
            print(f"  Created: Wiki/{ns}")

else:
    wiki_dir = os.path.join(wiki_path, "Wiki")
    os.makedirs(wiki_dir, exist_ok=True)

    ns_list = ", ".join(f"Wiki/{ns}" for ns in namespaces)
    schema = read_template("Schema.md")
    schema = schema.replace("{{NAMESPACES}}", ns_list)
    schema = schema.replace("{{DATE}}", today)
    if write_file(os.path.join(wiki_dir, "Schema.md"), schema):
        print(f"  Created: Wiki/Schema.md")

    ns_links = "\n".join(f"- [[Wiki/{ns}]]" for ns in namespaces)
    dashboard = read_template("Dashboard.md")
    dashboard = dashboard.replace("{{NAMESPACE_LINKS}}", ns_links)
    dashboard = dashboard.replace("{{DATE}}", today)
    if write_file(os.path.join(wiki_dir, "Dashboard.md"), dashboard):
        print(f"  Created: Wiki/Dashboard.md")

    hub_tpl = read_template("Hub.md")
    for ns in namespaces:
        ns_dir = os.path.join(wiki_dir, ns)
        os.makedirs(ns_dir, exist_ok=True)
        hub = hub_tpl.replace("{{NAMESPACE}}", ns).replace("{{DATE}}", today)
        if write_file(os.path.join(ns_dir, "_index.md"), hub):
            print(f"  Created: Wiki/{ns}/_index.md")

PYEOF

# ===== STEP 9: Create llm-wiki.yml =====
CONFIG_FILE="$wiki_path/llm-wiki.yml"

build_agents_yaml() {
    local agents=""
    for agent in "${SELECTED_AGENTS[@]}"; do
        if [ -z "$agents" ]; then
            agents="  - $agent"
        else
            agents="$agents\n  - $agent"
        fi
    done
    echo -e "$agents"
}

AGENTS_YAML=$(build_agents_yaml)

write_config() {
    cat > "$CONFIG_FILE" << YAML
# llm-wiki configuration
# Generated by setup.sh on $(date +%Y-%m-%d)

tool: $TOOL
wiki_path: $wiki_path
pages_dir: $PAGES_DIR
memory_path: ${memory_path:-""}

namespaces:
$(for ns in $NAMESPACES; do echo "  - $ns"; done)

agents:
$(for agent in "${SELECTED_AGENTS[@]}"; do echo "  - $agent"; done)
YAML
    echo -e "  ${GREEN}Created: llm-wiki.yml${NC}"
}

if [ -f "$CONFIG_FILE" ]; then
    echo -e "${YELLOW}llm-wiki.yml already exists. Overwrite? [y/n]${NC}"
    read -p "" overwrite_config
    if [ "$overwrite_config" = "y" ] || [ "$overwrite_config" = "Y" ]; then
        write_config
    else
        echo -e "  Keeping existing config."
    fi
else
    write_config
fi

# ===== STEP 10: Claude Code scaffold =====
if [[ " ${SELECTED_AGENTS[*]} " =~ "claude" ]]; then
    echo ""
    echo -e "${BOLD}Install /wiki skill for Claude Code?${NC}"
    echo "This copies wiki.md to your project's .claude/commands/ directory."
    read -p "Project path (or 'skip'): " project_path

    if [ "$project_path" != "skip" ] && [ -n "$project_path" ]; then
        project_path="${project_path/#\~/$HOME}"
        COMMANDS_DIR="$project_path/.claude/commands"
        mkdir -p "$COMMANDS_DIR"
        cp "$SCRIPT_DIR/wiki.md" "$COMMANDS_DIR/wiki.md"

        if [ "$(uname)" = "Darwin" ]; then
            sed -i '' "s|<CONFIG_PATH>|$CONFIG_FILE|g" "$COMMANDS_DIR/wiki.md"
        else
            sed -i "s|<CONFIG_PATH>|$CONFIG_FILE|g" "$COMMANDS_DIR/wiki.md"
        fi
        echo -e "${GREEN}Installed /wiki skill to $COMMANDS_DIR/wiki.md${NC}"

        # Create memory/ directory for L1 storage
        MEMORY_DIR="$project_path/memory"
        mkdir -p "$MEMORY_DIR"
        if [ ! -f "$MEMORY_DIR/.gitignore" ]; then
            cat > "$MEMORY_DIR/.gitignore" << 'GITIGNORE'
# L1 memory files - git-excluded by default
*
!.gitignore
GITIGNORE
            echo -e "${GREEN}Created memory/ directory for Claude L1 storage${NC}"
        fi
    fi
fi

# ===== STEP 11: OpenCode scaffold =====
if [[ " ${SELECTED_AGENTS[*]} " =~ "opencode" ]]; then
    echo ""
    echo -e "${BOLD}Install wiki commands for OpenCode?${NC}"
    echo "This creates opencode.json and .opencode/commands/wiki-*.md files."
    read -p "Project root path (or 'skip'): " oc_project_path

    if [ "$oc_project_path" != "skip" ] && [ -n "$oc_project_path" ]; then
        oc_project_path="${oc_project_path/#\~/$HOME}"

        # Create opencode.json
        OC_CONFIG="$oc_project_path/opencode.json"
        if [ -f "$OC_CONFIG" ]; then
            echo -e "${YELLOW}opencode.json already exists. Merge wiki commands? [y/n]${NC}"
            read -p "" merge_oc
            if [ "$merge_oc" = "y" ] || [ "$merge_oc" = "Y" ]; then
                # Simple merge: read existing, add commands, write back
                python3 -c "
import json, sys
config_path = '$OC_CONFIG'
wiki_commands = {
    'wiki-ingest': {'template': 'Read @wiki.md and execute the ingest workflow.\nSource: \$0', 'description': 'Ingest a source (URL/file/text) into the wiki'},
    'wiki-query': {'template': 'Read @wiki.md and execute the query workflow.\nQuestion: \$0', 'description': 'Search the wiki and synthesize an answer'},
    'wiki-lint': {'template': 'Read @wiki.md and execute the lint workflow.\nArgs: \$0', 'description': 'Health check: orphans, stale, broken refs, credential leaks'},
    'wiki-status': {'template': 'Read @wiki.md and execute the status workflow.', 'description': 'Wiki metrics and health overview'},
    'wiki-ingest-bg': {'template': 'Read @wiki.md and execute the ingest workflow.\nSource: \$0', 'description': 'Heavy ingest in sub-agent (preserves conversation)', 'subtask': True}
}
try:
    with open(config_path) as f:
        config = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    config = {}
if 'command' not in config:
    config['command'] = {}
config['command'].update(wiki_commands)
with open(config_path, 'w') as f:
    json.dump(config, f, indent=2)
print('Merged wiki commands into opencode.json')
"
            fi
        else
            cat > "$OC_CONFIG" << 'JSON'
{
  "command": {
    "wiki-ingest": {
      "template": "Read @wiki.md and execute the ingest workflow.\nSource: $0",
      "description": "Ingest a source (URL/file/text) into the wiki"
    },
    "wiki-query": {
      "template": "Read @wiki.md and execute the query workflow.\nQuestion: $0",
      "description": "Search the wiki and synthesize an answer"
    },
    "wiki-lint": {
      "template": "Read @wiki.md and execute the lint workflow.\nArgs: $0",
      "description": "Health check: orphans, stale, broken refs, credential leaks"
    },
    "wiki-status": {
      "template": "Read @wiki.md and execute the status workflow.",
      "description": "Wiki metrics and health overview"
    },
    "wiki-ingest-bg": {
      "template": "Read @wiki.md and execute the ingest workflow.\nSource: $0",
      "description": "Heavy ingest in sub-agent (preserves conversation)",
      "subtask": true
    }
  }
}
JSON
            echo -e "${GREEN}Created: opencode.json${NC}"
        fi

        # Create .opencode/commands/ directory and command files
        OC_COMMANDS_DIR="$oc_project_path/.opencode/commands"
        mkdir -p "$OC_COMMANDS_DIR"

        for cmd_file in wiki-ingest.md wiki-query.md wiki-lint.md wiki-status.md; do
            cmd_path="$OC_COMMANDS_DIR/$cmd_file"
            if [ ! -f "$cmd_path" ]; then
                case "$cmd_file" in
                    wiki-ingest.md)
                        cat > "$cmd_path" << 'CMD'
---
description: Ingest a source into the wiki — processes URLs, files, or text and updates 5-15 wiki pages
---
CMD
                        ;;
                    wiki-query.md)
                        cat > "$cmd_path" << 'CMD'
---
description: Search the wiki and synthesize an answer with source attribution
---
CMD
                        ;;
                    wiki-lint.md)
                        cat > "$cmd_path" << 'CMD'
---
description: Run health checks on the wiki — orphans, stale pages, broken refs, credential leaks
---
CMD
                        ;;
                    wiki-status.md)
                        cat > "$cmd_path" << 'CMD'
---
description: Show wiki metrics — page count, health, recent changes
---
CMD
                        ;;
                esac
                echo -e "${GREEN}Created: .opencode/commands/$cmd_file${NC}"
            fi
        done

        # Create .opencode/instructions/ for sensitive gotchas
        OC_INSTRUCTIONS_DIR="$oc_project_path/.opencode/instructions"
        mkdir -p "$OC_INSTRUCTIONS_DIR"
        if [ ! -f "$OC_INSTRUCTIONS_DIR/.gitignore" ]; then
            cat > "$OC_INSTRUCTIONS_DIR/.gitignore" << 'GITIGNORE'
# Sensitive L1 rules - git-excluded
*
!.gitignore
GITIGNORE
            echo -e "${GREEN}Created .opencode/instructions/ for sensitive L1 rules${NC}"
        fi
    fi
fi

# ===== STEP 12: L1 templates for both agents =====
L1_TEMPLATE_DIR="$SCRIPT_DIR/templates/l1"
if [ -d "$L1_TEMPLATE_DIR" ]; then
    echo ""
    echo -e "${BOLD}Scaffold L1 memory for selected agents?${NC} [y/n]"
    read -p "" scaffold_l1

    if [ "$scaffold_l1" = "y" ] || [ "$scaffold_l1" = "Y" ]; then
        # Claude Code: copy templates/l1/ -> memory/
        if [[ " ${SELECTED_AGENTS[*]} " =~ "claude" ]] && [ -n "$project_path" ] && [ "$project_path" != "skip" ]; then
            MEMORY_DIR="$project_path/memory"
            mkdir -p "$MEMORY_DIR"
            for l1_file in "$L1_TEMPLATE_DIR"/*.md; do
                fname=$(basename "$l1_file")
                cp "$l1_file" "$MEMORY_DIR/$fname"
                echo -e "${GREEN}Copied templates/l1/$fname → memory/$fname${NC}"
            done
            echo -e "  ${CYAN}Tip: Reference memory/ files in CLAUDE.md for auto-loading${NC}"
        fi

        # OpenCode: templates/l1/ content is already in AGENTS.md, done at repo level
        if [[ " ${SELECTED_AGENTS[*]} " =~ "opencode" ]]; then
            echo -e "  ${CYAN}L1 templates sourced from templates/l1/ — AGENTS.md references these rules${NC}"
        fi
    fi
fi

# ===== STEP 13: Initial commit =====
if [ -d "$wiki_path/.git" ]; then
    echo ""
    cd "$wiki_path"
    git add -A
    git commit -m "wiki: initial setup via llm-wiki

Schema, Dashboard, and hub pages for $(echo $NAMESPACES | wc -w | tr -d ' ') namespaces.
Tool: $TOOL
Agents: ${SELECTED_AGENTS[*]}

Generated by https://github.com/stgreenb/llm-wiki" 2>/dev/null || true
    echo -e "${GREEN}Initial commit created.${NC}"
fi

# ===== DONE =====
echo ""
echo -e "${CYAN}${BOLD}Setup complete!${NC}"
echo ""
echo -e "Your wiki is at: ${BOLD}$wiki_path${NC}"
echo -e "Config file:     ${BOLD}$CONFIG_FILE${NC}"
echo -e "Configured for:  ${BOLD}${SELECTED_AGENTS[*]}${NC}"
echo ""

if [[ " ${SELECTED_AGENTS[*]} " =~ "claude" ]]; then
    echo -e "Claude Code:"
    echo -e "  /wiki ingest \"your first source\""
    echo -e "  /wiki status"
    echo ""
fi

if [[ " ${SELECTED_AGENTS[*]} " =~ "opencode" ]]; then
    echo -e "OpenCode:"
    echo -e "  opencode run wiki-ingest \"your first source\""
    echo -e "  opencode run wiki-status"
    echo ""
fi

echo -e "Documentation: ${CYAN}https://github.com/stgreenb/llm-wiki${NC}"
