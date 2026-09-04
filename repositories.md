# Репозитории

Здесь поддерживается каталог репозиториев компании, которые входят в стандартную локальную рабочую область.

## Порядок ведения каталога

Каталог ведёт только администратор. Он создаёт новые репозитории в организации Miluino и определяет, должны ли они входить в наборы конкретных команд. Другие разработчики не добавляют строки в этот документ и не изменяют `config/repositories.json` без явного поручения администратора.

## Формат записи

Для каждого репозитория указываются:

- имя репозитория;
- назначение;
- URL для клонирования;
- рекомендуемый локальный каталог;
- обязательность для конкретных ролей или проектов.

## Каталог

| Репозиторий | Назначение | URL для клонирования | Локальный каталог | Команда |
|---|---|---|---|---|
| `dev-guidelines` | Правила и инструкции для разработчиков | `https://github.com/Miluino/dev-guidelines.git` | `dev-guidelines` | Все |
| `mdr1986` | Кодовая база библиотеки `mdr1986-periph` | `https://github.com/Miluino/mdr1986.git` | `platforms/mdr1986` | `firmware_team` |
| `Miluino_MA1_StudyKit_firmware` | Кодовая база для работы с шилдами Miluino MA1 | `https://github.com/Miluino/Miluino_MA1_StudyKit_firmware.git` | `kits/Miluino_MA1_StudyKit/firmware` | `firmware_team` |
| `Miluino_MA1_hardware` | Схемы и печатные платы Miluino MA1 | `https://github.com/Miluino/Miluino_MA1_hardware.git` | `boards/Miluino_MA1/hardware` | `hardware_team` |
| `Miluino_MA1_StudyKit_hardware` | Схемы и печатные платы учебного комплекта Miluino MA1 | `https://github.com/Miluino/Miluino_MA1_StudyKit_hardware.git` | `kits/Miluino_MA1_StudyKit/hardware` | `hardware_team` |
| `.github` | Общие настройки и инструкции GitHub организации | `https://github.com/Miluino/.github.git` | `.github` | Не клонируется скриптом |

Репозиторий `.github` намеренно не входит в наборы для клонирования: он содержит общие настройки GitHub и не требуется для обычной разработки.

При добавлении репозитория администратор обновляет одновременно эту таблицу и `config/repositories.json`.
