#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECTS_ROOT="${DOTFILES_PROJECTS_ROOT:-$HOME/git_apps}"
MANIFEST="$REPO_ROOT/config/projects/projects.tsv"

while [ "$#" -gt 0 ]; do
    case "$1" in
        --root)
            [ "$#" -ge 2 ] || { echo "--root requires a directory" >&2; exit 1; }
            PROJECTS_ROOT="$2"
            shift
            ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
    shift
done

[ -f "$MANIFEST" ] || exit 0
mkdir -p "$PROJECTS_ROOT"

while IFS=$'\t' read -r relative remote branch; do
    [ -n "$relative" ] || continue
    case "$relative" in \#*) continue ;; esac
    case "$relative" in
        /*|../*|*/../*|*/..) echo "REFUSE unsafe project path in manifest: $relative" >&2; exit 1 ;;
    esac
    target="$PROJECTS_ROOT/$relative"
    if [ -e "$target" ]; then
        echo "SKIP  $target (exists)"
        continue
    fi
    mkdir -p "$(dirname "$target")"
    echo "CLONE $remote -> $target"
    git clone "$remote" "$target"
    if [ -n "${branch:-}" ] && git -C "$target" show-ref --verify --quiet "refs/remotes/origin/$branch"; then
        git -C "$target" checkout "$branch"
    fi
done < "$MANIFEST"
