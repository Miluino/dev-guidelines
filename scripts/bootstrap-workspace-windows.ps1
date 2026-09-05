# Windows PowerShell workspace bootstrap script.
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
            Write-Warning "Skipping '$($Repository.name)': '$targetPath' exists but is not a directory."
            return
        }

        $remoteUrl = & git -C $targetPath config --get remote.origin.url 2>$null
        if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($remoteUrl)) {
            Write-Warning "Skipping '$($Repository.name)': '$targetPath' is not a Git repository with an 'origin' remote."
            return
        }

        $expectedUrl = ConvertTo-NormalizedGitUrl -Url $Repository.url
        $actualUrl = ConvertTo-NormalizedGitUrl -Url $remoteUrl
        if ($actualUrl -eq $expectedUrl) {
            Write-Host "Already cloned: $($Repository.name)"
            return
        }

        Write-Warning "Skipping '$($Repository.name)': '$targetPath' has a different remote: $remoteUrl"
        return
    }

    if ($ScriptCommand.ShouldProcess($targetPath, "Clone repository '$($Repository.name)'")) {
        $targetParentPath = [System.IO.Path]::GetDirectoryName($targetPath)
        if (-not (Test-Path -LiteralPath $targetParentPath)) {
            New-Item -ItemType Directory -Path $targetParentPath -Force | Out-Null
        }

        & git clone $Repository.url $targetPath
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to clone repository '$($Repository.name)'."
        }
    }
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw 'Git was not found in PATH. Install Git and try again.'
}

if (-not (Test-Path -LiteralPath $ConfigPath -PathType Leaf)) {
    throw "Configuration file was not found: $ConfigPath"
}

$config = Get-Content -LiteralPath $ConfigPath -Raw -Encoding utf8 | ConvertFrom-Json
$availableTeams = @(
    $config.repositories |
        ForEach-Object { @($_.bootstrap.teams) } |
        Sort-Object -Unique
)

if ($Team -ne 'all' -and $Team -notin $availableTeams) {
    throw "Unknown team '$Team'. Available values: $($availableTeams -join ', '), all."
}

$workspacePath = [System.IO.Path]::GetFullPath($WorkspaceRoot)
if (-not (Test-Path -LiteralPath $workspacePath)) {
    if ($PSCmdlet.ShouldProcess($workspacePath, 'Create workspace root directory')) {
        New-Item -ItemType Directory -Path $workspacePath | Out-Null
    }
    else {
        return
    }
}

$repositories = @(
    $config.repositories | Where-Object {
        $repositoryTeams = @($_.bootstrap.teams)
        $_.bootstrap.common -or
            (($Team -eq 'all') -and ($repositoryTeams.Count -gt 0)) -or
            ($Team -in $repositoryTeams)
    }
)

Write-Host "Workspace: $workspacePath"
Write-Host "Selected team: $Team"

foreach ($repository in $repositories) {
    Invoke-RepositoryClone -Repository $repository -RootPath $workspacePath -ScriptCommand $PSCmdlet
}
