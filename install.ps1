$ErrorActionPreference = "Stop"

Write-Host "`n⚡ QuickGroq Installer for Windows" -ForegroundColor Cyan
Write-Host "---------------------------------"

# ── 0. Check for winget ───────────────────────────────────────────────────────
if (-not (Get-Command "winget" -ErrorAction SilentlyContinue)) {
    Write-Host "❌ winget not found. Please update Windows or install the App Installer from the Microsoft Store." -ForegroundColor Red
    Write-Host "   Then re-run this installer."
    exit 1
}

# ── 1. Check for AutoHotkey ──────────────────────────────────────────────────
if (-not (Get-Command "AutoHotkey.exe"   -ErrorAction SilentlyContinue) -and
    -not (Get-Command "AutoHotkey64.exe" -ErrorAction SilentlyContinue)) {
    Write-Host "Installing AutoHotkey v2..."
    winget install AutoHotkey.AutoHotkey --silent --accept-package-agreements --accept-source-agreements
}

# ── 2. Check for Node.js (v18+ required) ────────────────────────────────────
$needsNode = $true
if (Get-Command "node" -ErrorAction SilentlyContinue) {
    $nodeMajor = [int](node -e "process.stdout.write(process.version.slice(1).split('.')[0])")
    if ($nodeMajor -ge 18) {
        $needsNode = $false
    } else {
        Write-Host "⚠️  Node.js v$nodeMajor found but v18+ is required. Upgrading..." -ForegroundColor Yellow
        winget upgrade OpenJS.NodeJS --silent --accept-package-agreements --accept-source-agreements
        $needsNode = $false
    }
}
if ($needsNode) {
    Write-Host "Installing Node.js..."
    winget install OpenJS.NodeJS --silent --accept-package-agreements --accept-source-agreements
}

# Refresh PATH so node is available in this session without reopening PowerShell
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
            [System.Environment]::GetEnvironmentVariable("Path", "User")

# Verify Node is findable after install
$nodePath = Get-Command "node" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
if (-not $nodePath) {
    Write-Host "⚠️  Node.js not found in PATH after install. You may need to restart before using QuickGroq." -ForegroundColor Yellow
} else {
    Write-Host "✅ Node.js found at: $nodePath" -ForegroundColor Green
}

# ── 3. Create install directory ──────────────────────────────────────────────
$InstallDir = "$env:USERPROFILE\quickgroq"
if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
}

# ── 4. API Key Setup ─────────────────────────────────────────────────────────
Write-Host "`nGet a free Groq API key at https://console.groq.com"
$ApiKey = Read-Host "Paste your API key"

if ([string]::IsNullOrWhiteSpace($ApiKey)) {
    Write-Host "❌ No API key entered. Exiting." -ForegroundColor Red
    exit 1
}

if (-not $ApiKey.StartsWith("gsk_")) {
    Write-Host "⚠️  This key doesn't look like a Groq API key (should start with 'gsk_')." -ForegroundColor Yellow
    $confirm = Read-Host "Continue anyway? (y/n)"
    if ($confirm -ne "y") { exit 1 }
}

# ── 5. Hotkey Selection ──────────────────────────────────────────────────────
Write-Host "`nChoose your Windows hotkey:"
Write-Host "1) Ctrl + Shift + D (Default)"
Write-Host "2) Alt + Shift + D"
Write-Host "3) Ctrl + Alt + 0"
$Choice = Read-Host "Enter 1, 2, or 3 [1]"

$HotkeyString = switch ($Choice) {
    "2" { "+!d" }
    "3" { "^!0" }
    Default { "^+d" }
}

# ── 6. Create Config ─────────────────────────────────────────────────────────
$ConfigJson = @{
    apiKey = $ApiKey
    apiUrl = "https://api.groq.com/openai/v1/audio/transcriptions"
    model  = "whisper-large-v3"
    hotkey = $HotkeyString
} | ConvertTo-Json

[System.IO.File]::WriteAllText(
    "$InstallDir\config.json",
    $ConfigJson,
    [System.Text.UTF8Encoding]::new($false)
)

# ── 7. Download Files ────────────────────────────────────────────────────────
Write-Host "`nDownloading QuickGroq files..."
$RepoUrl = "https://raw.githubusercontent.com/jbuch84/QuickGroq/main"

Invoke-WebRequest -Uri "$RepoUrl/dictate.js"    -OutFile "$InstallDir\dictate.js"
Invoke-WebRequest -Uri "$RepoUrl/QuickGroq.ahk" -OutFile "$InstallDir\QuickGroq.ahk"

# ── 8. Patch hotkey and paths into AHK file ──────────────────────────────────
$NvmPath   = "$env:USERPROFILE\AppData\Roaming\nvm\current\node.exe"
$ScoopPath = "$env:USERPROFILE\scoop\apps\nodejs\current\node.exe"

$ahkContent = Get-Content "$InstallDir\QuickGroq.ahk" -Raw
$ahkContent = $ahkContent -replace '~\^\+d::',  "~$HotkeyString`::"
$ahkContent = $ahkContent -replace 'A_UserProfile "\\quickgroq"', "`"$InstallDir`""
$ahkContent = $ahkContent -replace 'NVM_PATH',   $NvmPath
$ahkContent = $ahkContent -replace 'SCOOP_PATH', $ScoopPath
[System.IO.File]::WriteAllText(
    "$InstallDir\QuickGroq.ahk",
    $ahkContent,
    [System.Text.UTF8Encoding]::new($false)
)
Write-Host "✅ Hotkey and paths configured." -ForegroundColor Green

# ── 9. Startup Setup ─────────────────────────────────────────────────────────
Write-Host "Setting up automatic launch..."
$StartupFolder = [Environment]::GetFolderPath('Startup')
$WshShell  = New-Object -ComObject WScript.Shell
$Shortcut  = $WshShell.CreateShortcut("$StartupFolder\QuickGroq.lnk")
$Shortcut.TargetPath       = "$InstallDir\QuickGroq.ahk"
$Shortcut.WorkingDirectory = $InstallDir
$Shortcut.Save()

# ── 10. Summary ──────────────────────────────────────────────────────────────
Write-Host "`n✅ QuickGroq installed successfully!" -ForegroundColor Green
Write-Host "--------------------------------------------------"
Write-Host "📂 Installation Folder: $InstallDir"
Write-Host "⚙️  Config File:         $InstallDir\config.json"
Write-Host "🚀 Startup Shortcut:    $StartupFolder\QuickGroq.lnk"
Write-Host "--------------------------------------------------"
Write-Host "💡 You can change your hotkey later by editing config.json."

# Launch the script
Invoke-Item "$InstallDir\QuickGroq.ahk"
