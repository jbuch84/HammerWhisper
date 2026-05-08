import { execSync } from "node:child_process";
import { readFileSync, existsSync, unlinkSync } from "node:fs";
import { homedir, platform as getPlatform } from "node:os";

const platform = getPlatform();
const CONFIG_PATH = `${homedir()}/quickgroq/config.json`;

// ── Self-check mode ────────────────────────────────────────────────────────
if (process.argv.includes("--check")) {
  let allGood = true;

  const check = (label, pass, hint) => {
    const icon = pass ? "✅" : "❌";
    console.log(`${icon} ${label}`);
    if (!pass && hint) console.log(`   → ${hint}`);
    if (!pass) allGood = false;
  };

  // 1. Config file
  const configExists = existsSync(CONFIG_PATH);
  const installCmd = platform === "win32" 
    ? "irm https://raw.githubusercontent.com/jbuch84/QuickGroq/main/install.ps1 | iex"
    : "curl -sSL https://raw.githubusercontent.com/jbuch84/QuickGroq/main/install.sh | bash";
  
  check("config.json found", configExists, `Run the installer again:\n     ${installCmd}`);

  // 2. API key
  let apiKey = null;
  if (configExists) {
    try { const config = JSON.parse(readFileSync(CONFIG_PATH, "utf8")); apiKey = config.apiKey; } catch {}
  }
  const keyValid = apiKey && apiKey !== "YOUR_API_KEY_HERE" && apiKey.startsWith("gsk_");
  check("API key present in config", keyValid, "Open ~/quickgroq/config.json and paste your Groq key (starts with gsk_)");

  // 3. Node.js version (needs fetch, v18+)
  const nodeMajor = parseInt(process.version.replace("v", "").split(".")[0]);
  check(`Node.js version OK (${process.version})`, nodeMajor >= 18, "Update Node.js to v18+");

  // ── macOS Specific Checks ──
  if (platform === "darwin") {
    let ffmpegPath = null;
    for (const p of ["/opt/homebrew/bin/ffmpeg", "/usr/local/bin/ffmpeg"]) {
      if (existsSync(p)) { ffmpegPath = p; break; }
    }
    check(`ffmpeg found${ffmpegPath ? ` at ${ffmpegPath}` : ""}`, !!ffmpegPath, "Install via: brew install ffmpeg");

    const hsInstalled = existsSync("/Applications/Hammerspoon.app");
    check("Hammerspoon installed", hsInstalled, "Install via: brew install --cask hammerspoon");

    try {
      const result = execSync(
        `osascript -e 'tell application "System Events" to get name of every process whose name is "Hammerspoon"' 2>&1`,
        { encoding: "utf8" }
      ).trim();
      const hsRunning = result.length > 0 && !result.includes("error");
      check("Hammerspoon is running", hsRunning, "Open /Applications/Hammerspoon.app");
    } catch {
      check("Hammerspoon is running", false, "Open /Applications/Hammerspoon.app");
    }
  }

  // ── Windows Specific Checks ──
  if (platform === "win32") {
    try {
      const tasklist = execSync("tasklist", { encoding: "utf8" }).toLowerCase();
      const ahkRunning = tasklist.includes("autohotkey");
      check("AutoHotkey script is running", ahkRunning, "Ensure QuickGroq.ahk is running (check your system tray)");
    } catch {
      check("AutoHotkey running check", false, "Could not verify if AutoHotkey is running");
    }
  }

  console.log("");
  if (allGood) {
    console.log("Everything looks good! Press your hotkey to start dictating.");
  } else {
    console.log("Fix the items above and run: node dictate.js --check again.");
  }
  process.exit(allGood ? 0 : 1);
}

// ── Normal transcription mode ──────────────────────────────────────────────
if (!existsSync(CONFIG_PATH)) {
  console.error("Missing config.json — run the installer again.");
  process.exit(1);
}

const config = JSON.parse(readFileSync(CONFIG_PATH, "utf8"));

if (!config.apiKey || config.apiKey === "YOUR_API_KEY_HERE") {
  console.error("No API key set — open ~/quickgroq/config.json and add your key.");
  process.exit(1);
}

const API_URL = config.apiUrl || "https://api.groq.com/openai/v1/audio/transcriptions";
const MODEL = config.model || "whisper-large-v3";

const AUDIO_FILE = platform === "win32" 
    ? `${homedir()}/quickgroq/audio.wav` 
    : "/tmp/quickgroq.wav";

const file = readFileSync(AUDIO_FILE);
const blob = new Blob([file], { type: "audio/wav" });

const form = new FormData();
form.append("file", blob, "quickgroq.wav");
form.append("model", MODEL);

const response = await fetch(API_URL, {
  method: "POST",
  headers: { "Authorization": `Bearer ${config.apiKey}` },
  body: form,
});

const json = await response.json();
const text = json.text?.trim();

if (!text) {
  console.error("No transcription returned:", JSON.stringify(json));
  process.exit(1);
}

if (platform === "darwin") {
    execSync(`printf '%s' ${JSON.stringify(text)} | pbcopy`);
    execSync(`osascript -e 'tell application "System Events" to keystroke "v" using command down'`);
    if (existsSync(AUDIO_FILE)) unlinkSync(AUDIO_FILE);
} else if (platform === "win32") {
    console.log(text);
    if (existsSync(AUDIO_FILE)) unlinkSync(AUDIO_FILE);
}