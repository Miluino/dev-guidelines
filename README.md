# dev-guidelines

Общие правила, инструкции и инструменты для разработки в проектах компании.

## Содержание

- [Локальная рабочая область](local-workspace.md) — рекомендуемая структура каталогов на компьютере разработчика.
- [Требования к рабочей среде](requirements.md) — необходимые ОС, инструменты и доступы.
- [Репозитории](repositories.md) — каталог репозиториев компании и правила его ведения.
- [Стиль кода](code-style.md) — общие правила и профили для embedded-библиотек, прикладного C/C++ и Python.
- [Онбординг участника команды](team-onboarding.md) — последовательность подготовки локальной рабочей области.

## Порядок ведения

На текущем этапе содержимое `dev-guidelines` ведёт только администратор. Другие участники команды не добавляют, не изменяют и не удаляют материалы в этом репозитории без явного поручения администратора.

Новые репозитории в организации Miluino также создаёт только администратор.
После создания он добавляет репозиторий в `config/repositories.json` и запускает
генератор каталога по инструкции из [repositories.md](repositories.md).

## Подготовка рабочей области

1. Создайте корневой каталог рабочей области.
2. Клонируйте в него `dev-guidelines`.
3. Из каталога `dev-guidelines` выполните скрипт для своей команды.

   В Windows PowerShell:

```powershell
.\scripts\bootstrap-workspace-windows.ps1 -Team firmware_team
```

   В Linux:

```bash
bash ./scripts/bootstrap-workspace-linux.sh --team firmware_team
```

По умолчанию скрипты используют родительский каталог текущего клона `dev-guidelines` как корневой каталог рабочей области. Другой каталог можно указать явно:

```powershell
.\scripts\bootstrap-workspace-windows.ps1 -Team firmware_team -WorkspaceRoot D:\Work\Miluino
```

```bash
bash ./scripts/bootstrap-workspace-linux.sh --team firmware_team --workspace-root ~/work/Miluino
```

Для предварительного просмотра действий используйте `-WhatIf` в Windows PowerShell или `--what-if` в Linux.

## Статус

Состав репозиториев и их привязка к командам задаются в `config/repositories.json`.
