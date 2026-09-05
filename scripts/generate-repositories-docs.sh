#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_PATH="$SCRIPT_DIR/../config/repositories.json"
DOCUMENT_PATH="$SCRIPT_DIR/../repositories.md"
CHECK=false

BEGIN_MARKER='<!-- BEGIN GENERATED REPOSITORY CATALOG -->'
END_MARKER='<!-- END GENERATED REPOSITORY CATALOG -->'

print_usage() {
    cat <<'EOF'
Usage:
  bash generate-repositories-docs.sh [options]

Options:
  --config, -c      Path to repositories.json.
  --document, -d    Path to repositories.md.
  --check           Fail if repositories.md is out of date.
  --help, -h        Show this help message.
EOF
}

fail() {
    echo "Error: $1" >&2
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --config|-c)
            [[ $# -ge 2 ]] || fail "Option '$1' requires a value."
            CONFIG_PATH="$2"
            shift 2
            ;;
        --document|-d)
            [[ $# -ge 2 ]] || fail "Option '$1' requires a value."
            DOCUMENT_PATH="$2"
            shift 2
            ;;
        --check)
            CHECK=true
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

for dependency in jq awk grep cmp mktemp cp; do
    command -v "$dependency" >/dev/null 2>&1 || fail "$dependency was not found in PATH."
done
[[ -f "$CONFIG_PATH" ]] || fail "Configuration file was not found: $CONFIG_PATH"
[[ -f "$DOCUMENT_PATH" ]] || fail "Document was not found: $DOCUMENT_PATH"

jq -e '
    (.repositories | type == "array" and length > 0) and
    all(.repositories[];
        (.name | type == "string" and length > 0) and
        (.description | type == "string" and length > 0) and
        (.url | type == "string" and length > 0) and
        (.directory | type == "string" and length > 0) and
        (.bootstrap.common | type == "boolean") and
        (.bootstrap.teams | type == "array" and all(.[]; type == "string" and length > 0))
    )
' "$CONFIG_PATH" >/dev/null || fail "Configuration has an invalid repository catalog: $CONFIG_PATH"

jq -e '[.repositories[].name] | length == (unique | length)' "$CONFIG_PATH" >/dev/null || \
    fail "Repository names must be unique: $CONFIG_PATH"

begin_count="$(grep -Fxc -- "$BEGIN_MARKER" "$DOCUMENT_PATH" || true)"
end_count="$(grep -Fxc -- "$END_MARKER" "$DOCUMENT_PATH" || true)"
[[ "$begin_count" == 1 && "$end_count" == 1 ]] || \
    fail "Expected exactly one generated catalog block in '$DOCUMENT_PATH'."

block_path="$(mktemp)"
output_path="$(mktemp)"
cleanup() {
    rm -f -- "$block_path" "$output_path"
}
trap cleanup EXIT

{
    printf '%s\n\n' "$BEGIN_MARKER"
    printf '%s\n\n' '<!-- Не редактируйте этот блок вручную. Он создаётся из config/repositories.json. -->'
    printf '%s\n' '| Репозиторий | Назначение | URL для клонирования | Локальный каталог | Команда |'
    printf '%s\n' '|---|---|---|---|---|'
    jq -r '
        def markdown_text:
            tostring | gsub("[\\r\\n]+"; " ") | gsub("\\|"; "\\|");
        def markdown_code:
            "`" + (tostring | gsub("`"; "``")) + "`";

        .repositories[] |
        (.bootstrap.teams // []) as $teams |
        (if .bootstrap.common == true then
            "Все"
        elif ($teams | length) > 0 then
            ($teams | map(markdown_code) | join(", "))
        else
            "Не клонируется скриптом"
        end) as $team_label |
        "| \(.name | markdown_code) | \(.description | markdown_text) | \(.url | markdown_code) | \(.directory | markdown_code) | \($team_label) |"
    ' "$CONFIG_PATH"
    printf '\n%s\n' "$END_MARKER"
} > "$block_path"

awk -v begin="$BEGIN_MARKER" -v end="$END_MARKER" -v block="$block_path" '
    function print_block(   line) {
        while ((getline line < block) > 0) {
            print line
        }
        close(block)
    }

    $0 == begin {
        print_block()
        inside_block = 1
        next
    }

    $0 == end {
        inside_block = 0
        next
    }

    !inside_block {
        print
    }
' "$DOCUMENT_PATH" > "$output_path"

if cmp -s -- "$output_path" "$DOCUMENT_PATH"; then
    echo "Repository catalog is up to date: $DOCUMENT_PATH"
    exit 0
fi

if [[ "$CHECK" == true ]]; then
    fail "Repository catalog is out of date: $DOCUMENT_PATH"
fi

cp -- "$output_path" "$DOCUMENT_PATH"
echo "Updated repository catalog: $DOCUMENT_PATH"
