$ErrorActionPreference = "Stop"

Write-Host "`n⚡ QuickGroq Installer for Windows"
Write-Host "---------------------------------"

if (-not (Get-Command "AutoHotkey.exe" -ErrorAction SilentlyContinue) -and -not (Get-Command "AutoHotkey64.exe" -ErrorAction SilentlyContinue)) {
    Write-Host "Installing AutoHotkey v2..."
    winget install AutoHotkey.AutoHotkey --silent --accept-package-agreements --accept-source-agreements
}

if (-not (Get-Command "node" -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Node.js..."
    winget install OpenJS.NodeJS --silent --accept-package-agreements --accept-source-agreements
}

$InstallDir = "$env:USERPROFILE\quickgroq"
if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
}

Write-Host "`nGet a free Groq API key at https://console.groq.com"
$ApiKey = Read-Host "Paste your API key"

if ([string]::IsNullOrWhiteSpace($ApiKey)) {
    Write-Host "❌ No API key entered. Exiting."
    exit
}

$ConfigJson = @{
    apiKey = $ApiKey
    apiUrl = "https://api.groq.com/openai/v1/audio/transcriptions"
    model = "whisper-large-v3"
} | ConvertTo-Json

Set-Content -Path "$InstallDir\config.json" -Value $ConfigJson

Write-Host "`nDownloading QuickGroq files..."
$RepoUrl = "https://raw.githubusercontent.com/jbuch84/QuickGroq/main"
Invoke-WebRequest -Uri "$RepoUrl/dictate.js" -OutFile "$InstallDir\dictate.js"
Invoke-WebRequest -Uri "$RepoUrl/QuickGroq.ahk" -OutFile "$InstallDir\QuickGroq.ahk"

Write-Host "Setting up automatic launch..."
$StartupFolder = [Environment]::GetFolderPath('Startup')
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$StartupFolder\QuickGroq.lnk")
$Shortcut.TargetPath = "$InstallDir\QuickGroq.ahk"
$Shortcut.Save()

Write-Host "`n✅ QuickGroq installed!"
Write-Host "Press Ctrl+Shift+D anywhere to start dictating."
Invoke-Item "$InstallDir\QuickGroq.ahk"