# Репозитории

Здесь опубликован каталог репозиториев компании. Таблица формируется из
`config/repositories.json`, который является единственным источником данных о
репозиториях и наборах bootstrap.

## Порядок ведения каталога

Каталог ведёт только администратор. Он создаёт новые репозитории в организации
Miluino и определяет, должны ли они входить в наборы конкретных команд. Другие
разработчики не изменяют `config/repositories.json` без явного поручения
администратора. Сгенерированный блок этого документа вручную не редактируется.

## Формат записи

Для каждого репозитория указываются:

- имя репозитория;
- описание назначения;
- URL для клонирования;
- рекомендуемый локальный каталог;
- принадлежность к общему или командному набору bootstrap.

## Каталог

<!-- BEGIN GENERATED REPOSITORY CATALOG -->

<!-- Не редактируйте этот блок вручную. Он создаётся из config/repositories.json. -->

| Репозиторий | Назначение | URL для клонирования | Локальный каталог | Команда |
|---|---|---|---|---|
| `dev-guidelines` | Правила и инструкции для разработчиков | `https://github.com/Miluino/dev-guidelines.git` | `dev-guidelines` | Все |
| `mdr1986` | Кодовая база библиотеки mdr1986-periph | `https://github.com/Miluino/mdr1986.git` | `platforms/mdr1986` | `firmware_team` |
| `Miluino_MA1_StudyKit_firmware` | Кодовая база для работы с шилдами Miluino MA1 | `https://github.com/Miluino/Miluino_MA1_StudyKit_firmware.git` | `kits/Miluino_MA1_StudyKit/firmware` | `firmware_team` |
| `Miluino_MA1_hardware` | Схемы и печатные платы Miluino MA1 | `https://github.com/Miluino/Miluino_MA1_hardware.git` | `boards/Miluino_MA1/hardware` | `hardware_team` |
| `Miluino_MA1_StudyKit_hardware` | Схемы и печатные платы учебного комплекта Miluino MA1 | `https://github.com/Miluino/Miluino_MA1_StudyKit_hardware.git` | `kits/Miluino_MA1_StudyKit/hardware` | `hardware_team` |
| `.github` | Общие настройки и инструкции GitHub организации | `https://github.com/Miluino/.github.git` | `.github` | Не клонируется скриптом |

<!-- END GENERATED REPOSITORY CATALOG -->

Репозиторий `.github` намеренно не входит в наборы для клонирования: он содержит общие настройки GitHub и не требуется для обычной разработки.

## Обновление каталога

После изменения `config/repositories.json` администратор обновляет таблицу
одним из генераторов.

В Windows PowerShell:

```powershell
.\scripts\generate-repositories-docs.ps1
```

В Linux:

```bash
bash ./scripts/generate-repositories-docs.sh
```

Режим `-Check` в PowerShell или `--check` в Linux проверяет актуальность
таблицы, не изменяя документ.
