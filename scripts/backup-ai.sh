#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AI_ROOT="$REPO_ROOT/config/ai"
TOOLS="codex,claude,copilot,gemini,opencode"
INCLUDE_MEMORIES=false

while [ "$#" -gt 0 ]; do
    case "$1" in
        --tools)
            [ "$#" -ge 2 ] || { echo "--tools requires a comma-separated value" >&2; exit 1; }
            TOOLS="$2"
            shift
            ;;
        --include-memories) INCLUDE_MEMORIES=true ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
    shift
done

selected() {
    case ",$TOOLS," in
        *,"$1",*) return 0 ;;
        *) return 1 ;;
    esac
}

assert_no_secrets() {
    local source="$1"
    if grep -Eiq '(api[_-]?key|access[_-]?token|refresh[_-]?token|client[_-]?secret|password|authorization)["[:space:]]*[:=][[:space:]]*"?[^"[:space:]}]{8,}' "$source"; then
        echo "REFUSE $source appears to contain a credential; sanitize it manually." >&2
        exit 1
    fi
}

write_template() {
    local source="$1" target="$2"
    [ -f "$source" ] || return 0
    assert_no_secrets "$source"
    mkdir -p "$(dirname "$target")"
    sed "s#${HOME//\\/\\\\}#@HOME@#g" "$source" > "$target"
    echo "COPY  $source -> ${target#"$REPO_ROOT"/}"
}

copy_file() {
    local source="$1" target="$2"
    [ -f "$source" ] || return 0
    assert_no_secrets "$source"
    mkdir -p "$(dirname "$target")"
    cp -p "$source" "$target"
    echo "COPY  $source -> ${target#"$REPO_ROOT"/}"
}

copy_tree() {
    local source="$1" target="$2"
    [ -d "$source" ] || return 0
    while IFS= read -r -d '' file; do
        case "$file" in
            */.system/*|*/cache/*|*/logs/*|*/sessions/*|*/projects/*|*.sqlite|*.sqlite-shm|*.sqlite-wal) continue ;;
        esac
        copy_file "$file" "$target/${file#"$source"/}"
    done < <(find "$source" -type f -print0)
}

backup_codex_config() {
    local source="$HOME/.codex/config.toml" target="$AI_ROOT/codex/config.toml.tmpl" temp_file
    [ -f "$source" ] || return 0
    assert_no_secrets "$source"
    temp_file="$(mktemp)"
    awk '
        /^\[/ {
            omit = 0
            if ($0 ~ /^\[marketplaces[.]/) omit = 1
            if ($0 ~ /^\[mcp_servers[.]node_repl/) omit = 1
            if ($0 ~ /^\[shell_environment_policy[.]set\]/) omit = 1
            if ($0 ~ /^\[projects[.]/) omit = 1
        }
        !omit { print }
    ' "$source" > "$temp_file"
    mkdir -p "$(dirname "$target")"
    sed "s#${HOME//\\/\\\\}#@HOME@#g" "$temp_file" > "$target"
    rm -f "$temp_file"
    echo "COPY  $source -> ${target#"$REPO_ROOT"/} (machine-generated sections removed)"
}

if selected codex; then
    backup_codex_config
    copy_file "$HOME/.codex/AGENTS.md" "$AI_ROOT/codex/common/AGENTS.md"
    copy_tree "$HOME/.codex/rules" "$AI_ROOT/codex/linux/rules"
    if [ -d "$HOME/.codex/skills" ]; then
        copy_tree "$HOME/.codex/skills" "$AI_ROOT/codex/common/skills"
    fi
    if $INCLUDE_MEMORIES; then
        copy_tree "$HOME/.codex/memories" "$AI_ROOT/codex/common/memories"
    fi
fi

if selected claude; then
    write_template "$HOME/.claude/settings.json" "$AI_ROOT/claude/settings.json.tmpl"
    for part in CLAUDE.md; do copy_file "$HOME/.claude/$part" "$AI_ROOT/claude/$part"; done
    for part in agents commands hooks skills; do copy_tree "$HOME/.claude/$part" "$AI_ROOT/claude/$part"; done
fi

if selected copilot; then
    write_template "$HOME/.copilot/settings.json" "$AI_ROOT/copilot/settings.json.tmpl"
fi

if selected gemini; then
    write_template "$HOME/.gemini/settings.json" "$AI_ROOT/gemini/settings.json.tmpl"
    copy_file "$HOME/.gemini/GEMINI.md" "$AI_ROOT/gemini/GEMINI.md"
    copy_tree "$HOME/.gemini/commands" "$AI_ROOT/gemini/commands"
fi

if selected opencode; then
    opencode_root="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
    write_template "$opencode_root/opencode.jsonc" "$AI_ROOT/opencode/opencode.jsonc.tmpl"
fi

echo "AI settings backup complete. Review 'git diff -- config/ai' before committing."
