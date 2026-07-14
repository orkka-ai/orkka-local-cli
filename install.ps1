# Orkka Local installer (Windows) — downloads the latest orkka-local binary and puts
# it on your PATH. Usage:
#   irm https://raw.githubusercontent.com/orkka-ai/orkka-local-cli/main/install.ps1 | iex
# Then:
#   orkka-local start

$ErrorActionPreference = "Stop"

$repo = "orkka-ai/orkka-local-cli"
$installDir = Join-Path $env:USERPROFILE ".orkka\bin"

Write-Host "Resolving the latest Orkka Local release..."
$release = Invoke-RestMethod "https://api.github.com/repos/$repo/releases/latest"
$asset = $release.assets | Where-Object name -eq "orkka-local-win-x64.zip" | Select-Object -First 1
if (-not $asset) { throw "No orkka-local-win-x64.zip asset on the latest release of $repo." }

Write-Host "Downloading $($release.tag_name)..."
New-Item -ItemType Directory -Force $installDir | Out-Null
$zipPath = Join-Path $env:TEMP "orkka-local.zip"
Invoke-WebRequest $asset.browser_download_url -OutFile $zipPath
Expand-Archive $zipPath -DestinationPath $installDir -Force
Remove-Item $zipPath -Force -Confirm:$false

# Put the install dir on the user PATH (persistent) if it isn't already.
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$installDir*") {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$installDir", "User")
    $env:Path = "$env:Path;$installDir"
    Write-Host "Added $installDir to your PATH (new terminals pick it up automatically)."
}

Write-Host ""
Write-Host "Orkka Local $($release.tag_name) installed." -ForegroundColor Green
Write-Host "Prerequisites: Docker Desktop running, and the Claude CLI logged in ('claude /login')."
Write-Host "Start everything with:  orkka-local start"
