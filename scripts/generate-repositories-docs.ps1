# Generates the repository catalog in repositories.md from repositories.json.
[CmdletBinding()]
param(
    [string]$ConfigPath = (Join-Path $PSScriptRoot '..\config\repositories.json'),

    [string]$DocumentPath = (Join-Path $PSScriptRoot '..\repositories.md'),

    [switch]$Check
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$beginMarker = '<!-- BEGIN GENERATED REPOSITORY CATALOG -->'
$endMarker = '<!-- END GENERATED REPOSITORY CATALOG -->'

function ConvertTo-MarkdownText {
    param(
        [Parameter(Mandatory)]
        [string]$Value
    )

    return ($Value -replace '[\r\n]+', ' ' -replace '\|', '\|')
}

function Format-MarkdownCode {
    param(
        [Parameter(Mandatory)]
        [string]$Value
    )

    return ('`{0}`' -f ($Value -replace '`', '``'))
}

$resolvedConfigPath = (Resolve-Path -LiteralPath $ConfigPath).Path
$resolvedDocumentPath = (Resolve-Path -LiteralPath $DocumentPath).Path
$config = Get-Content -LiteralPath $resolvedConfigPath -Raw -Encoding utf8 | ConvertFrom-Json

if ($null -eq $config.repositories -or @($config.repositories).Count -eq 0) {
    throw "Configuration does not contain any repositories: $resolvedConfigPath"
}

$duplicateNames = @(
    $config.repositories |
        Group-Object -Property name |
        Where-Object { $_.Count -gt 1 } |
        ForEach-Object { $_.Name }
)
if ($duplicateNames.Count -gt 0) {
    throw "Repository names must be unique: $($duplicateNames -join ', ')"
}

$rows = foreach ($repository in $config.repositories) {
    foreach ($propertyName in @('name', 'description', 'url', 'directory')) {
        if ([string]::IsNullOrWhiteSpace([string]$repository.$propertyName)) {
            throw "Repository '$($repository.name)' does not define '$propertyName'."
        }
    }

    if ($null -eq $repository.bootstrap -or
        $repository.bootstrap.common -isnot [bool] -or
        $null -eq $repository.bootstrap.teams) {
        throw "Repository '$($repository.name)' has an invalid 'bootstrap' section."
    }

    $repositoryTeams = @($repository.bootstrap.teams)
    if (@($repositoryTeams | Where-Object { [string]::IsNullOrWhiteSpace([string]$_) }).Count -gt 0) {
        throw "Repository '$($repository.name)' contains an empty team name."
    }
    if ($repository.bootstrap.common) {
        $teamLabel = 'Все'
    }
    elseif ($repositoryTeams.Count -gt 0) {
        $teamLabel = @(
            $repositoryTeams | ForEach-Object { Format-MarkdownCode -Value $_ }
        ) -join ', '
    }
    else {
        $teamLabel = 'Не клонируется скриптом'
    }

    '| {0} | {1} | {2} | {3} | {4} |' -f @(
        (Format-MarkdownCode -Value $repository.name),
        (ConvertTo-MarkdownText -Value $repository.description),
        (Format-MarkdownCode -Value $repository.url),
        (Format-MarkdownCode -Value $repository.directory),
        $teamLabel
    )
}

$generatedBlock = @(
    $beginMarker
    ''
    '<!-- Не редактируйте этот блок вручную. Он создаётся из config/repositories.json. -->'
    ''
    '| Репозиторий | Назначение | URL для клонирования | Локальный каталог | Команда |'
    '|---|---|---|---|---|'
    $rows
    ''
    $endMarker
) -join "`n"

$document = [System.IO.File]::ReadAllText($resolvedDocumentPath)
$normalizedDocument = $document.Replace("`r`n", "`n").Replace("`r", "`n")
$pattern = '(?ms)^{0}\n.*?^{1}$' -f @(
    [regex]::Escape($beginMarker),
    [regex]::Escape($endMarker)
)
$markerMatches = [regex]::Matches($normalizedDocument, $pattern)
if ($markerMatches.Count -ne 1) {
    throw "Expected exactly one generated catalog block in '$resolvedDocumentPath'."
}

$replaceBlock = [System.Text.RegularExpressions.MatchEvaluator]{
    param($match)
    return $generatedBlock
}
$updatedDocument = [regex]::Replace($normalizedDocument, $pattern, $replaceBlock)

if ($updatedDocument -ceq $normalizedDocument) {
    Write-Host "Repository catalog is up to date: $resolvedDocumentPath"
    return
}

if ($Check) {
    throw "Repository catalog is out of date: $resolvedDocumentPath"
}

$utf8WithoutBom = [System.Text.UTF8Encoding]::new($false)
[System.IO.File]::WriteAllText($resolvedDocumentPath, $updatedDocument, $utf8WithoutBom)
Write-Host "Updated repository catalog: $resolvedDocumentPath"
