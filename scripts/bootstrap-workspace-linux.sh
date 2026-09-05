#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_WORKSPACE_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"

TEAM=""
WORKSPACE_ROOT="$DEFAULT_WORKSPACE_ROOT"
CONFIG_PATH="$SCRIPT_DIR/../config/repositories.json"
WHAT_IF=false

print_usage() {
    cat <<'EOF'
Usage:
  bash bootstrap-workspace-linux.sh --team <firmware_team|hardware_team|all> [options]

Options:
  --team, -t             Team repository set.
  --workspace-root, -w   Workspace root directory.
  --config, -c           Path to repositories.json.
  --what-if, -n          Print planned actions without changes.
  --help, -h             Show this help message.
EOF
}

fail() {
    echo "Error: $1" >&2
    exit 1
}

normalize_git_url() {
    local url="$1"

    url="${url%/}"
    case "$url" in
        git@github.com:*)
            url="https://github.com/${url#git@github.com:}"
            ;;
        ssh://git@github.com/*)
            url="https://github.com/${url#ssh://git@github.com/}"
            ;;
    esac

    url="${url%.git}"
    printf '%s\n' "$url" | tr '[:upper:]' '[:lower:]'
}

clone_repository() {
    local name="$1"
    local url="$2"
    local directory="$3"
    local target_path="$WORKSPACE_ROOT/$directory"

    if [[ -e "$target_path" ]]; then
        if [[ ! -d "$target_path" ]]; then
            echo "Warning: skipping '$name': '$target_path' exists but is not a directory." >&2
            return
        fi

        local remote_url
        remote_url="$(git -C "$target_path" config --get remote.origin.url 2>/dev/null || true)"
        if [[ -z "$remote_url" ]]; then
            echo "Warning: skipping '$name': '$target_path' is not a Git repository with an 'origin' remote." >&2
            return
        fi

        if [[ "$(normalize_git_url "$remote_url")" == "$(normalize_git_url "$url")" ]]; then
            echo "Already cloned: $name"
            return
        fi

        echo "Warning: skipping '$name': '$target_path' has a different remote: $remote_url" >&2
        return
    fi

    if [[ "$WHAT_IF" == true ]]; then
        echo "Will clone: $name -> $target_path"
        return
    fi

    mkdir -p "$(dirname -- "$target_path")"
    git clone "$url" "$target_path"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --team|-t)
            [[ $# -ge 2 ]] || fail "Option '$1' requires a value."
            TEAM="$2"
            shift 2
            ;;
        --workspace-root|-w)
            [[ $# -ge 2 ]] || fail "Option '$1' requires a value."
            WORKSPACE_ROOT="$2"
            shift 2
            ;;
        --config|-c)
            [[ $# -ge 2 ]] || fail "Option '$1' requires a value."
            CONFIG_PATH="$2"
            shift 2
            ;;
        --what-if|-n)
            WHAT_IF=true
            shift
            ;;
        --help|-h)
            print_usage
            exit 0
            ;;
        *)
            fail "Unknown option '$1'. Use --help for usage information."
            ;;
    esac
done

[[ -n "$TEAM" ]] || fail "Specify a team with --team."
command -v git >/dev/null 2>&1 || fail "Git was not found in PATH."
command -v jq >/dev/null 2>&1 || fail "jq was not found in PATH."
[[ -f "$CONFIG_PATH" ]] || fail "Configuration file was not found: $CONFIG_PATH"
jq -e . "$CONFIG_PATH" >/dev/null || fail "Configuration file contains invalid JSON: $CONFIG_PATH"

if [[ "$TEAM" != "all" ]] && ! jq -e --arg team "$TEAM" \
    '[.repositories[].bootstrap.teams[]] | index($team) != null' "$CONFIG_PATH" >/dev/null; then
    available_teams="$(jq -r '[.repositories[].bootstrap.teams[]] | unique | join(", ")' "$CONFIG_PATH")"
    fail "Unknown team '$TEAM'. Available values: $available_teams, all."
fi

if [[ ! -d "$WORKSPACE_ROOT" ]]; then
    if [[ "$WHAT_IF" == true ]]; then
        echo "Will create workspace root directory: $WORKSPACE_ROOT"
    else
        mkdir -p "$WORKSPACE_ROOT"
    fi
fi

if [[ "$TEAM" == "all" ]]; then
    repositories_filter='.repositories[] | select(.bootstrap.common == true or (.bootstrap.teams | length > 0))'
else
    repositories_filter='.repositories[] | select(.bootstrap.common == true or (.bootstrap.teams | index($team) != null))'
fi

echo "Workspace: $WORKSPACE_ROOT"
echo "Selected team: $TEAM"

while IFS=$'\t' read -r name url directory; do
    clone_repository "$name" "$url" "$directory"
done < <(jq -r --arg team "$TEAM" "$repositories_filter | [.name, .url, .directory] | @tsv" "$CONFIG_PATH")
