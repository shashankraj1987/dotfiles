#!/usr/bin/env bash
set -euo pipefail

FORCE=false
TOOLS="codex,claude,copilot,gemini,opencode"

while [ "$#" -gt 0 ]; do
    case "$1" in
        --force) FORCE=true ;;
        --tools)
            [ "$#" -ge 2 ] || { echo "--tools requires a comma-separated value" >&2; exit 1; }
            TOOLS="$2"
            shift
            ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
    shift
done

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AI_ROOT="$REPO_ROOT/config/ai"
STAMP="$(date +%Y%m%d-%H%M%S)"

selected() {
    case ",$TOOLS," in
        *,"$1",*) return 0 ;;
        *) return 1 ;;
    esac
}

install_file() {
    local source="$1" target="$2" template="${3:-false}"
    [ -f "$source" ] || return 0
    mkdir -p "$(dirname "$target")"

    if [ -e "$target" ]; then
        if ! $FORCE; then
            echo "SKIP  $target (exists; use --force to replace)"
            return 0
        fi
        cp -p "$target" "$target.dotfiles-backup-$STAMP"
        echo "SAVE  $target.dotfiles-backup-$STAMP"
    fi

    if [ "$template" = true ]; then
        sed "s#@HOME@#${HOME//\\/\\\\}#g" "$source" > "$target"
    else
        cp -p "$source" "$target"
    fi
    echo "WRITE $target"
}

install_tree() {
    local source="$1" target="$2"
    [ -d "$source" ] || return 0
    mkdir -p "$target"
    while IFS= read -r -d '' file; do
        install_file "$file" "$target/${file#"$source"/}"
    done < <(find "$source" -type f -print0)
}

if selected codex; then
    install_file "$AI_ROOT/codex/config.toml.tmpl" "$HOME/.codex/config.toml" true
    install_tree "$AI_ROOT/codex/common/rules" "$HOME/.codex/rules"
    install_tree "$AI_ROOT/codex/common/skills" "$HOME/.codex/skills"
    install_tree "$AI_ROOT/codex/linux/rules" "$HOME/.codex/rules"
fi

if selected claude; then
    install_file "$AI_ROOT/claude/settings.json.tmpl" "$HOME/.claude/settings.json" true
    for part in CLAUDE.md agents commands hooks skills; do
        if [ -d "$AI_ROOT/claude/$part" ]; then
            install_tree "$AI_ROOT/claude/$part" "$HOME/.claude/$part"
        else
            install_file "$AI_ROOT/claude/$part" "$HOME/.claude/$part"
        fi
    done
fi

if selected copilot; then
    install_file "$AI_ROOT/copilot/settings.json.tmpl" "$HOME/.copilot/settings.json" true
fi

if selected gemini; then
    install_file "$AI_ROOT/gemini/settings.json.tmpl" "$HOME/.gemini/settings.json" true
    install_file "$AI_ROOT/gemini/GEMINI.md" "$HOME/.gemini/GEMINI.md"
    install_tree "$AI_ROOT/gemini/commands" "$HOME/.gemini/commands"
fi

if selected opencode; then
    opencode_root="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
    install_file "$AI_ROOT/opencode/opencode.jsonc.tmpl" "$opencode_root/opencode.jsonc" true
fi

echo "AI settings restore complete. Sign in to each tool separately; credentials are not restored."
