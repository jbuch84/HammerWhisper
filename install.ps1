$ErrorActionPreference = "Stop"

Write-Host "`n⚡ QuickGroq Installer for Windows" -ForegroundColor Cyan
Write-Host "---------------------------------"

# ── 1. Check for AutoHotkey ──────────────────────────────────────────────────
if (-not (Get-Command "AutoHotkey.exe" -ErrorAction SilentlyContinue) -and -not (Get-Command "AutoHotkey64.exe" -ErrorAction SilentlyContinue)) {
    Write-Host "Installing AutoHotkey v2..."
    winget install AutoHotkey.AutoHotkey --silent --accept-package-agreements --accept-source-agreements
}

# ── 2. Check for Node.js ─────────────────────────────────────────────────────
if (-not (Get-Command "node" -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Node.js..."
    winget install OpenJS.NodeJS --silent --accept-package-agreements --accept-source-agreements
}

$InstallDir = "$env:USERPROFILE\quickgroq"
if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
}

# ── 3. API Key Setup ─────────────────────────────────────────────────────────
Write-Host "`nGet a free Groq API key at https://console.groq.com"
$ApiKey = Read-Host "Paste your API key"

if ([string]::IsNullOrWhiteSpace($ApiKey)) {
    Write-Host "❌ No API key entered. Exiting." -ForegroundColor Red
    exit
}

$ConfigJson = @{
    apiKey = $ApiKey
    apiUrl = "https://api.groq.com/openai/v1/audio/transcriptions"
    model = "whisper-large-v3"
} | ConvertTo-Json

Set-Content -Path "$InstallDir\config.json" -Value $ConfigJson

# ── 4. Hotkey Selection ──────────────────────────────────────────────────────
Write-Host "`nChoose your Windows hotkey modifier:"
Write-Host "1) Ctrl + Shift + D (Default)"
Write-Host "2) Alt + Shift + D"
Write-Host "3) Ctrl + Alt + 0"
$Choice = Read-Host "Enter 1, 2, or 3 [1]"

$HotkeyPrefix = switch ($Choice) {
    "2" { "+!d" }
    "3" { "^!0" }
    Default { "^+d" }
}

# ── 5. Download and Configure Files ──────────────────────────────────────────
Write-Host "`nDownloading QuickGroq files..."
$RepoUrl = "https://raw.githubusercontent.com/jbuch84/QuickGroq/main"

# Download the core engine
Invoke-WebRequest -Uri "$RepoUrl/dictate.js" -OutFile "$InstallDir\dictate.js"

# Download AHK script and replace the hotkey line dynamically
$AHKRaw = (Invoke-WebRequest -Uri "$RepoUrl/QuickGroq.ahk" -UseBasicParsing).Content
$AHKFinal = $AHKRaw -replace "~.*\:\:", "~$($HotkeyPrefix)::"
Set-Content -Path "$InstallDir\QuickGroq.ahk" -Value $AHKFinal

# ── 6. Startup Setup ─────────────────────────────────────────────────────────
Write-Host "Setting up automatic launch..."
$StartupFolder = [Environment]::GetFolderPath('Startup')
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$StartupFolder\QuickGroq.lnk")
$Shortcut.TargetPath = "$InstallDir\QuickGroq.ahk"
$Shortcut.Save()

# ── 7. Final Path Disclosure ─────────────────────────────────────────────────
Write-Host "`n✅ QuickGroq installed successfully!" -ForegroundColor Green
Write-Host "--------------------------------------------------"
Write-Host "📂 Installation Folder: $InstallDir"
Write-Host "⚙️  Config File: $InstallDir\config.json"
Write-Host "🚀 Startup Shortcut: $StartupFolder\QuickGroq.lnk"
Write-Host "--------------------------------------------------"

# Launch the script
Invoke-Item "$InstallDir\QuickGroq.ahk"
