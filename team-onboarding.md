# Онбординг участника команды

Эта инструкция помогает новому участнику подготовить локальную рабочую область и получить набор репозиториев своей команды.

## Перед началом

Необходимо:

- установить Git и убедиться, что команда `git --version` выполняется в терминале;
- получить от администратора название своей команды: `firmware_team` или `hardware_team`;
- иметь доступ к репозиториям организации Miluino;
- выбрать и создать корневой каталог рабочей области, например `D:\Work\Miluino` (на свой выбор).
- при работе в Linux установить `jq` — утилиту для чтения файла конфигурации репозиториев.

## Последовательность действий

1. Перейдите в созданный корневой каталог. В Windows PowerShell:

   ```powershell
   Set-Location D:\Work\Miluino
   ```

   В Linux:

   ```bash
   cd ~/work/Miluino
   ```

2. Клонируйте репозиторий с инструкциями:

   ```powershell
   git clone https://github.com/Miluino/dev-guidelines.git
   ```

3. Перейдите в каталог `dev-guidelines`. В Windows PowerShell:

   ```powershell
   Set-Location .\dev-guidelines
   ```

   В Linux:

   ```bash
   cd ./dev-guidelines
   ```

4. При необходимости предварительно просмотрите действия скрипта. В Windows PowerShell:

   ```powershell
   .\scripts\bootstrap-workspace-windows.ps1 -Team firmware_team -WhatIf
   ```

   В Linux:

   ```bash
   bash ./scripts/bootstrap-workspace-linux.sh --team firmware_team --what-if
   ```

5. Запустите скрипт для своей команды. В Windows PowerShell:

   ```powershell
   .\scripts\bootstrap-workspace-windows.ps1 -Team firmware_team
   ```

   В Linux:

   ```bash
   bash ./scripts/bootstrap-workspace-linux.sh --team firmware_team
   ```

   Для команды аппаратной разработки замените `firmware_team` на `hardware_team`.

   Для Windows PowerShell это будет:

   ```powershell
   .\scripts\bootstrap-workspace-windows.ps1 -Team hardware_team
   ```

   Для Linux:

   ```bash
   bash ./scripts/bootstrap-workspace-linux.sh --team hardware_team
   ```

6. Убедитесь, что репозитории появились в корневом каталоге рабочей области. Для `firmware` будут подготовлены `platforms/mdr1986` и `kits/Miluino_MA1_StudyKit/firmware`; для `hardware` — `boards/Miluino_MA1/hardware` и `kits/Miluino_MA1_StudyKit/hardware`.

## Повторный запуск

Скрипт можно запускать повторно. Корректно клонированные репозитории он пропускает. Если каталог уже занят не-Git-проектом или репозиторием с другим `origin`, скрипт выводит предупреждение и не изменяет этот каталог.

## Важные правила

- Не изменяйте `config/repositories.json`, скрипты и другие материалы `dev-guidelines` без явного поручения администратора.
- Не создавайте новые репозитории в организации Miluino: это выполняет администратор.
- Указывайте название только тех команд, членами которых вы являетесь.

## Проблемы при запуске

- Если Git не найден, установите Git и перезапустите терминал.
- Если в Linux не найден `jq`, установите его средствами пакетного менеджера используемого дистрибутива.
- Если PowerShell запрещает запуск Windows-скрипта политикой выполнения, обратитесь к администратору или специалисту, который отвечает за настройку рабочего компьютера.
- Если скрипт сообщает о неизвестной команде или конфликте каталога, не меняйте конфигурацию самостоятельно — передайте текст сообщения администратору.
