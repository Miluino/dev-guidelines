# Скрипт подготовки локальной рабочей области для Windows PowerShell.
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string]$Team,

    [string]$WorkspaceRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path,

    [string]$ConfigPath = (Join-Path $PSScriptRoot '..\config\repositories.json')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function ConvertTo-NormalizedGitUrl {
    param(
        [Parameter(Mandatory)]
        [string]$Url
    )

    $normalizedUrl = $Url.Trim().TrimEnd('/')
    $normalizedUrl = $normalizedUrl -replace '^git@github\.com:', 'https://github.com/'
    $normalizedUrl = $normalizedUrl -replace '^ssh://git@github\.com/', 'https://github.com/'
    $normalizedUrl = $normalizedUrl -replace '\.git$', ''

    return $normalizedUrl.ToLowerInvariant()
}

function Add-RepositoriesToSet {
    param(
        [Parameter(Mandatory)]
        [System.Collections.Generic.List[object]]$Target,

        [Parameter(Mandatory)]
        [object[]]$Repositories
    )

    foreach ($repository in $Repositories) {
        if (-not ($Target | Where-Object { $_.name -eq $repository.name })) {
            $Target.Add($repository)
        }
    }
}

function Invoke-RepositoryClone {
    param(
        [Parameter(Mandatory)]
        [object]$Repository,

        [Parameter(Mandatory)]
        [string]$RootPath,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCmdlet]$ScriptCommand
    )

    $targetPath = Join-Path $RootPath $Repository.directory

    if (Test-Path -LiteralPath $targetPath) {
        if (-not (Test-Path -LiteralPath $targetPath -PathType Container)) {
            Write-Warning "Пропуск '$($Repository.name)': '$targetPath' существует, но не является каталогом."
            return
        }

        $remoteUrl = & git -C $targetPath config --get remote.origin.url 2>$null
        if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($remoteUrl)) {
            Write-Warning "Пропуск '$($Repository.name)': '$targetPath' не является Git-репозиторием с remote 'origin'."
            return
        }

        $expectedUrl = ConvertTo-NormalizedGitUrl -Url $Repository.url
        $actualUrl = ConvertTo-NormalizedGitUrl -Url $remoteUrl
        if ($actualUrl -eq $expectedUrl) {
            Write-Host "Уже клонирован: $($Repository.name)"
            return
        }

        Write-Warning "Пропуск '$($Repository.name)': каталог '$targetPath' привязан к другому remote: $remoteUrl"
        return
    }

    if ($ScriptCommand.ShouldProcess($targetPath, "Клонировать репозиторий '$($Repository.name)'")) {
        $targetParentPath = Split-Path -LiteralPath $targetPath -Parent
        if (-not (Test-Path -LiteralPath $targetParentPath)) {
            New-Item -ItemType Directory -Path $targetParentPath -Force | Out-Null
        }

        & git clone $Repository.url $targetPath
        if ($LASTEXITCODE -ne 0) {
            throw "Не удалось клонировать репозиторий '$($Repository.name)'."
        }
    }
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw 'Git не найден в PATH. Установите Git и повторите запуск.'
}

if (-not (Test-Path -LiteralPath $ConfigPath -PathType Leaf)) {
    throw "Файл конфигурации не найден: $ConfigPath"
}

$config = Get-Content -LiteralPath $ConfigPath -Raw -Encoding utf8 | ConvertFrom-Json
$availableTeams = @($config.teams.PSObject.Properties.Name)

if ($Team -ne 'all' -and $Team -notin $availableTeams) {
    throw "Неизвестная команда '$Team'. Доступные значения: $($availableTeams -join ', '), all."
}

$workspacePath = [System.IO.Path]::GetFullPath($WorkspaceRoot)
if (-not (Test-Path -LiteralPath $workspacePath)) {
    if ($PSCmdlet.ShouldProcess($workspacePath, 'Создать корневой каталог рабочей области')) {
        New-Item -ItemType Directory -Path $workspacePath | Out-Null
    }
    else {
        return
    }
}

$repositories = [System.Collections.Generic.List[object]]::new()
Add-RepositoriesToSet -Target $repositories -Repositories @($config.common)

if ($Team -eq 'all') {
    foreach ($teamProperty in $config.teams.PSObject.Properties) {
        Add-RepositoriesToSet -Target $repositories -Repositories @($teamProperty.Value)
    }
}
else {
    Add-RepositoriesToSet -Target $repositories -Repositories @($config.teams.$Team)
}

Write-Host "Рабочая область: $workspacePath"
Write-Host "Выбранная команда: $Team"

foreach ($repository in $repositories) {
    Invoke-RepositoryClone -Repository $repository -RootPath $workspacePath -ScriptCommand $PSCmdlet
}
