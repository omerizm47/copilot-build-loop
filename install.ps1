#Requires -Version 5.1
<#
.SYNOPSIS
    Installs the build-loop agent files into the VS Code user prompts folder.
.DESCRIPTION
    Copies the six files in this repo's prompts folder to the destination.
    Existing files that differ are skipped with a warning unless -Force is passed.
    Nothing is ever deleted.
.EXAMPLE
    .\install.ps1
.EXAMPLE
    .\install.ps1 -Destination "$env:APPDATA\Code - Insiders\User\prompts" -Force
#>
[CmdletBinding()]
param(
    [string]$Destination = (Join-Path $env:APPDATA 'Code\User\prompts'),
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$sourceDir = Join-Path $PSScriptRoot 'prompts'
if (-not (Test-Path -LiteralPath $sourceDir)) {
    throw "Source folder not found: $sourceDir"
}

$files = @(
    'build-loop.agent.md',
    'planner.agent.md',
    'implementer.agent.md',
    'reviewer.agent.md',
    'acceptance.agent.md',
    'standards.instructions.md'
)

if (-not (Test-Path -LiteralPath $Destination)) {
    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    Write-Host "Created $Destination"
}

$copied = 0
$skipped = 0

foreach ($file in $files) {
    $src = Join-Path $sourceDir $file
    $dst = Join-Path $Destination $file

    if (-not (Test-Path -LiteralPath $src)) {
        Write-Warning "Missing from repo, skipping: $file"
        $skipped++
        continue
    }

    if ((Test-Path -LiteralPath $dst) -and -not $Force) {
        $srcHash = (Get-FileHash -LiteralPath $src -Algorithm SHA256).Hash
        $dstHash = (Get-FileHash -LiteralPath $dst -Algorithm SHA256).Hash
        if ($srcHash -ne $dstHash) {
            Write-Warning "Already exists and differs, skipping: $file (pass -Force to overwrite)"
            $skipped++
            continue
        }
    }

    Copy-Item -LiteralPath $src -Destination $dst -Force
    Write-Host "Copied $file -> $dst"
    $copied++
}

Write-Host ""
Write-Host "Copied $copied file(s) to $Destination. Skipped $skipped."
if ($copied -gt 0) {
    Write-Host "Reload the VS Code window to pick up the new agents."
}
