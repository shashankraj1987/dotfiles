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

[ -d "$PROJECTS_ROOT" ] || { echo "Projects root does not exist: $PROJECTS_ROOT" >&2; exit 1; }
mkdir -p "$(dirname "$MANIFEST")"
temp_file="$(mktemp)"
trap 'rm -f "$temp_file"' EXIT
printf '# Portable Git workspace manifest.\n# path<TAB>remote URL<TAB>branch\n' > "$temp_file"

while IFS= read -r -d '' git_dir; do
    project="${git_dir%/.git}"
    relative="${project#"$PROJECTS_ROOT"/}"
    remote="$(git -C "$project" remote get-url origin 2>/dev/null || true)"
    branch="$(git -C "$project" branch --show-current 2>/dev/null || true)"

    [ -n "$remote" ] || { echo "SKIP  $project (no origin remote)"; continue; }
    case "$relative$remote$branch" in
        *$'\t'*|*$'\n'*) echo "SKIP  $project (tab/newline in manifest value)" >&2; continue ;;
    esac
    if printf '%s' "$remote" | grep -Eq '^https?://[^/@:]+:[^/@]+@'; then
        echo "REFUSE $project has credentials embedded in its remote URL." >&2
        exit 1
    fi

    printf '%s\t%s\t%s\n' "$relative" "$remote" "$branch" >> "$temp_file"
    if [ -n "$(git -C "$project" status --porcelain 2>/dev/null)" ]; then
        echo "WARN  $relative has uncommitted files; the manifest cannot transfer them."
    else
        echo "ADD   $relative"
    fi
done < <(find "$PROJECTS_ROOT" -type d -name .git -print0 | sort -z)

mv "$temp_file" "$MANIFEST"
trap - EXIT
echo "Project manifest written to config/projects/projects.tsv. Review it before committing."
