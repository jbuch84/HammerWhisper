#!/bin/bash

set -e

echo ""
echo "⚡ QuickGroq Installer"
echo "----------------------"

# 1. Homebrew & Dependencies
if ! command -v brew &>/dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

brew install ffmpeg node
if [ ! -d "/Applications/Hammerspoon.app" ]; then brew install --cask hammerspoon; fi

NODE_PATH=$(command -v node)

# 2. Config & API
read -p "Paste your Groq API key: " API_KEY </dev/tty
mkdir -p ~/quickgroq

cat > ~/quickgroq/config.json <<EOF
{
    "apiKey": "$API_KEY",
    "apiUrl": "https://api.groq.com/openai/v1/audio/transcriptions",
    "model": "whisper-large-v3"
}
EOF

# 3. Hotkey Selection
echo ""
echo "Choose a hotkey modifier:"
echo "  1) cmd+shift (default)"
echo "  2) cmd+option"
echo "  3) ctrl+shift"
read -p "Enter 1, 2, or 3 [1]: " MOD_CHOICE </dev/tty

case "$MOD_CHOICE" in
    2) MODIFIER='{"cmd", "option"}' ;;
    3) MODIFIER='{"ctrl", "shift"}' ;;
    *) MODIFIER='{"cmd", "shift"}' ;;
esac

read -p "Hotkey letter (default: D): " HOTKEY </dev/tty
HOTKEY=${HOTKEY:-D}
HOTKEY=$(echo "$HOTKEY" | tr '[:lower:]' '[:upper:]')

# 4. Download Script
curl -fsSL https://raw.githubusercontent.com/jbuch84/QuickGroq/main/dictate.js -o ~/quickgroq/dictate.js

# 5. Hammerspoon Config
mkdir -p ~/.hammerspoon
cat > ~/.hammerspoon/init.lua <<LUA
hs.autoLaunch(true)
local recording = false
local ffmpegTask = nil
local lastTrigger = 0

hs.hotkey.bind($MODIFIER, "$HOTKEY", function()
    local now = hs.timer.secondsSinceEpoch()
    if now - lastTrigger < 0.5 then return end
    lastTrigger = now

    if not recording then
        hs.alert.show("🎤 Recording...")
        ffmpegTask = hs.task.new("/opt/homebrew/bin/ffmpeg", nil, {
            "-y", "-f", "avfoundation", "-i", ":0",
            "-ac", "1", "-ar", "16000", "/tmp/quickgroq.wav"
        })
        ffmpegTask:start()
        recording = true
    else
        hs.alert.show("⏳ Transcribing...")
        if ffmpegTask then ffmpegTask:terminate() end
        recording = false

        hs.timer.doAfter(1.0, function()
            local previousClipboard = hs.pasteboard.getContents()
            hs.task.new("$NODE_PATH", function(exitCode)
                if exitCode == 0 then
                    hs.alert.show("✅ Done")
                    hs.timer.doAfter(0.3, function() hs.pasteboard.setContents(previousClipboard or "") end)
                end
            end, { os.getenv("HOME") .. "/quickgroq/dictate.js" }):start()
        end)
    end
end)
LUA

open -a Hammerspoon
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
echo "✅ Installed! Enable Accessibility for Hammerspoon to begin."
