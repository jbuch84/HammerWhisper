#!/bin/bash

set -e

echo ""
echo "⚡ QuickGroq Installer for macOS"
echo "--------------------------------"

# ── 1. Homebrew & Dependencies ──────────────────────────────────────────────
if ! command -v brew &>/dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [ -f /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -f /usr/local/bin/brew ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
fi

if ! command -v brew &>/dev/null; then
    echo "❌ Homebrew installation failed. Please install it manually at https://brew.sh"
    exit 1
fi

if ! command -v ffmpeg &>/dev/null; then brew install ffmpeg; fi
if ! command -v node &>/dev/null; then brew install node; fi

NODE_PATH=$(command -v node)
if [ -z "$NODE_PATH" ]; then
    NODE_PATH=$( [ -f "/opt/homebrew/bin/node" ] && echo "/opt/homebrew/bin/node" || echo "/usr/local/bin/node" )
fi

if [ ! -d "/Applications/Hammerspoon.app" ]; then
    echo "Installing Hammerspoon..."
    brew install --cask hammerspoon
fi

# ── 2. Configuration Setup ──────────────────────────────────────────────────
echo ""
echo "Get a free Groq API key at https://console.groq.com"
read -p "Paste your API key: " API_KEY </dev/tty
if [ -z "$API_KEY" ]; then echo "❌ API key required. Exiting."; exit 1; fi

read -p "API URL (Enter for default): " API_URL </dev/tty
API_URL=${API_URL:-"https://api.groq.com/openai/v1/audio/transcriptions"}

read -p "Model (Enter for whisper-large-v3): " MODEL </dev/tty
MODEL=${MODEL:-"whisper-large-v3"}

echo ""
echo "Choose a hotkey modifier:"
echo "  1) cmd+shift (default)"
echo "  2) cmd+option"
echo "  3) ctrl+shift"
read -p "Enter 1, 2, or 3 [1]: " MOD_CHOICE </dev/tty

case "$MOD_CHOICE" in
    2) MOD_STR='{"cmd", "option"}' ;;
    3) MOD_STR='{"ctrl", "shift"}' ;;
    *) MOD_STR='{"cmd", "shift"}' ;;
esac

read -p "Hotkey letter (default: D): " HOTKEY </dev/tty
HOTKEY=$(echo "${HOTKEY:-D}" | tr '[:lower:]' '[:upper:]')

# ── 3. Save config.json ─────────────────────────────────────────────────────
mkdir -p ~/quickgroq
cat > ~/quickgroq/config.json <<EOF
{
    "apiKey": "$API_KEY",
    "apiUrl": "$API_URL",
    "model": "$MODEL",
    "modifier": $MOD_STR,
    "hotkey": "$HOTKEY"
}
EOF

# ── 4. Download Core Script ─────────────────────────────────────────────────
curl -fsSL https://raw.githubusercontent.com/jbuch84/QuickGroq/main/dictate.js -o ~/quickgroq/dictate.js

# ── 5. Hammerspoon init.lua (Rich UI Engine) ────────────────────────────────
mkdir -p ~/.hammerspoon
cat > ~/.hammerspoon/init.lua <<LUA
-- QuickGroq -- auto-generated
hs.autoLaunch(true)

local recording = false
local ffmpegTask = nil
local indicatorCanvas = nil
local blinkTimer = nil
local durationTimer = nil
local indicatorPos = nil
local recordingStart = nil
local lastTrigger = 0

-- Load Config (Source of Truth)
local configPath = os.getenv("HOME") .. "/quickgroq/config.json"
local config = { modifier = {"cmd", "shift"}, hotkey = "D" }
local f = io.open(configPath, "r")
if f then
    local content = f:read("*all")
    f:close()
    local decoded = hs.json.decode(content)
    if decoded then config = decoded end
end

local bgColor = { red = 0.12, green = 0.12, blue = 0.12, alpha = 0.88 }
local recordingColor = { red = 0.85, green = 0.35, blue = 0.35, alpha = 0.9 }
local transcribingColor = { red = 0.85, green = 0.75, blue = 0.25, alpha = 0.9 }
local doneColor = { red = 0.35, green = 0.80, blue = 0.35, alpha = 0.9 }
local defaultColor = { white = 1, alpha = 0.9 }

local function showIndicator(labelText, pulse, textColor)
    if blinkTimer then blinkTimer:stop(); blinkTimer = nil end
    if indicatorCanvas then indicatorCanvas:delete(); indicatorCanvas = nil end
    local color = textColor or defaultColor
    local w = math.max(52, #labelText * 8 + 24)
    local h = 28
    indicatorCanvas = hs.canvas.new({ x = indicatorPos.x + 16, y = indicatorPos.y + 16, w = w, h = h })
    indicatorCanvas[1] = { type = "rectangle", action = "fill", fillColor = bgColor, roundedRectRadii = { xRadius = 8, yRadius = 8 }, frame = { x = 0, y = 0, w = w, h = h } }
    indicatorCanvas[2] = { type = "text", text = hs.styledtext.new(labelText, { color = color, font = { size = 12 } }), frame = { x = 10, y = 7, w = w - 16, h = 16 } }
    indicatorCanvas:show()
    if pulse then
        local visible = true
        blinkTimer = hs.timer.doEvery(0.6, function() visible = not visible; if indicatorCanvas then indicatorCanvas:alpha(visible and 1.0 or 0.35) end end)
    end
end

local function hideIndicator(labelText, duration, textColor)
    if blinkTimer then blinkTimer:stop(); blinkTimer = nil end
    if durationTimer then durationTimer:stop(); durationTimer = nil end
    if indicatorCanvas then indicatorCanvas:delete(); indicatorCanvas = nil end
    if labelText then 
        showIndicator(labelText, false, textColor) 
        hs.timer.doAfter(duration or 1.5, function() if indicatorCanvas then indicatorCanvas:delete(); indicatorCanvas = nil end end) 
    end
end

hs.hotkey.bind(config.modifier, config.hotkey, function()
    local now = hs.timer.secondsSinceEpoch()
    if now - lastTrigger < 0.5 then return end
    lastTrigger = now
    if not recording then
        indicatorPos = hs.mouse.absolutePosition()
        showIndicator("● 0:00", true, recordingColor)
        recordingStart = hs.timer.secondsSinceEpoch()
        durationTimer = hs.timer.doEvery(1.0, function()
            local elapsed = math.floor(hs.timer.secondsSinceEpoch() - recordingStart)
            showIndicator(string.format("● %d:%02d", math.floor(elapsed / 60), elapsed % 60), true, recordingColor)
        end)
        ffmpegTask = hs.task.new("/opt/homebrew/bin/ffmpeg", nil, { "-y", "-f", "avfoundation", "-i", ":0", "-ac", "1", "-ar", "16000", "/tmp/quickgroq.wav" }):start()
        recording = true
    else
        hideIndicator("transcribing...", 8, transcribingColor)
        if ffmpegTask and ffmpegTask:isRunning() then ffmpegTask:terminate() end
        recording = false
        hs.timer.doAfter(1.0, function()
            local previousClipboard = hs.pasteboard.getContents()
            hs.task.new("$NODE_PATH", function(code)
                if code == 0 then 
                    hideIndicator("done ✓", 1.5, doneColor) 
                    hs.timer.doAfter(0.3, function() hs.pasteboard.setContents(previousClipboard or "") end) 
                else
                    hideIndicator("error", 3, defaultColor)
                end
            end, { os.getenv("HOME") .. "/quickgroq/dictate.js" }):start()
        end)
    end
end)

hs.hotkey.bind({"cmd", "shift"}, "R", function() hs.reload() end)
LUA

# ── 6. Final Path Disclosure ────────────────────────────────────────────────
open -a Hammerspoon
osascript -e 'tell application "Hammerspoon" to reload config' 2>/dev/null || true
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"

echo ""
echo "✅ QuickGroq installed successfully!"
echo "--------------------------------------------------"
echo "📂 Installation Folder: ~/quickgroq"
echo "⚙️  Config File: ~/quickgroq/config.json"
echo "🚀 Hammerspoon Config: ~/.hammerspoon/init.lua"
echo "--------------------------------------------------"
echo "⚠️  Final Step: Enable Hammerspoon in Accessibility settings."
echo ""
