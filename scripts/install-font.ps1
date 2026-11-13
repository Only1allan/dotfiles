# Install JetBrainsMono Nerd Font for the current Windows user.
# Run from Windows PowerShell:
#   powershell.exe -ExecutionPolicy Bypass -File .\scripts\install-font.ps1

$ErrorActionPreference = "Stop"

if (Get-Command winget -ErrorAction SilentlyContinue) {
    Write-Host "Installing JetBrainsMono Nerd Font via winget..."
    winget install --id DEVCOM.JetBrainsMonoNerdFont --exact --silent --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Font installed."
        exit 0
    }
}

Write-Host "winget unavailable or failed; downloading the font directly..."
$url = "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
$zip = Join-Path $env:TEMP "JetBrainsMonoNerdFont.zip"
$extract = Join-Path $env:TEMP "JetBrainsMonoNerdFont"

Invoke-WebRequest -Uri $url -OutFile $zip
if (Test-Path $extract) {
    Remove-Item $extract -Recurse -Force
}
Expand-Archive -Path $zip -DestinationPath $extract -Force

$fontDir = Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Fonts"
New-Item -ItemType Directory -Force -Path $fontDir | Out-Null
$regPath = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"

Get-ChildItem $extract -Filter *.ttf | ForEach-Object {
    Copy-Item $_.FullName -Destination $fontDir -Force
    New-ItemProperty -Path $regPath -Name ("{0} (TrueType)" -f $_.Name) -Value (Join-Path $fontDir $_.Name) -PropertyType String -Force | Out-Null
}

Write-Host "Installed JetBrainsMono Nerd Font for the current user."
