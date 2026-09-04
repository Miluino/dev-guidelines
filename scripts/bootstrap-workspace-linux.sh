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
Использование:
  bash bootstrap-workspace-linux.sh --team <firmware_team|hardware_team|all> [параметры]

Параметры:
  --team, -t             Набор репозиториев команды.
  --workspace-root, -w   Корневой каталог рабочей области.
  --config, -c           Путь к файлу repositories.json.
  --what-if, -n          Вывести план действий без изменений.
  --help, -h             Показать эту справку.
EOF
}

fail() {
    echo "Ошибка: $1" >&2
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
            echo "Предупреждение: пропуск '$name': '$target_path' существует, но не является каталогом." >&2
            return
        fi

        local remote_url
        remote_url="$(git -C "$target_path" config --get remote.origin.url 2>/dev/null || true)"
        if [[ -z "$remote_url" ]]; then
            echo "Предупреждение: пропуск '$name': '$target_path' не является Git-репозиторием с remote 'origin'." >&2
            return
        fi

        if [[ "$(normalize_git_url "$remote_url")" == "$(normalize_git_url "$url")" ]]; then
            echo "Уже клонирован: $name"
            return
        fi

        echo "Предупреждение: пропуск '$name': каталог '$target_path' привязан к другому remote: $remote_url" >&2
        return
    fi

    if [[ "$WHAT_IF" == true ]]; then
        echo "Будет клонирован: $name -> $target_path"
        return
    fi

    mkdir -p "$(dirname -- "$target_path")"
    git clone "$url" "$target_path"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --team|-t)
            [[ $# -ge 2 ]] || fail "Для параметра '$1' требуется значение."
            TEAM="$2"
            shift 2
            ;;
        --workspace-root|-w)
            [[ $# -ge 2 ]] || fail "Для параметра '$1' требуется значение."
            WORKSPACE_ROOT="$2"
            shift 2
            ;;
        --config|-c)
            [[ $# -ge 2 ]] || fail "Для параметра '$1' требуется значение."
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
            fail "Неизвестный параметр '$1'. Используйте --help для справки."
            ;;
    esac
done

[[ -n "$TEAM" ]] || fail "Укажите команду через --team."
command -v git >/dev/null 2>&1 || fail "Git не найден в PATH."
command -v jq >/dev/null 2>&1 || fail "jq не найден в PATH."
[[ -f "$CONFIG_PATH" ]] || fail "Файл конфигурации не найден: $CONFIG_PATH"
jq -e . "$CONFIG_PATH" >/dev/null || fail "Файл конфигурации содержит некорректный JSON: $CONFIG_PATH"

if [[ "$TEAM" != "all" ]] && ! jq -e --arg team "$TEAM" '.teams | has($team)' "$CONFIG_PATH" >/dev/null; then
    available_teams="$(jq -r '.teams | keys | join(", ")' "$CONFIG_PATH")"
    fail "Неизвестная команда '$TEAM'. Доступные значения: $available_teams, all."
fi

if [[ ! -d "$WORKSPACE_ROOT" ]]; then
    if [[ "$WHAT_IF" == true ]]; then
        echo "Будет создан корневой каталог рабочей области: $WORKSPACE_ROOT"
    else
        mkdir -p "$WORKSPACE_ROOT"
    fi
fi

if [[ "$TEAM" == "all" ]]; then
    repositories_filter='[.common[], (.teams | to_entries[] | .value[])] | unique_by(.name)[]'
else
    repositories_filter='[.common[], .teams[$team][]] | unique_by(.name)[]'
fi

echo "Рабочая область: $WORKSPACE_ROOT"
echo "Выбранная команда: $TEAM"

while IFS=$'\t' read -r name url directory; do
    clone_repository "$name" "$url" "$directory"
done < <(jq -r --arg team "$TEAM" "$repositories_filter | [.name, .url, .directory] | @tsv" "$CONFIG_PATH")
