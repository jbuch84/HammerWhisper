import { execSync } from "node:child_process";
import { readFileSync, existsSync, unlinkSync } from "node:fs";
import { homedir } from "node:os";

const CONFIG_PATH = `${homedir()}/hammerwhisper/config.json`;

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
  check("config.json found", configExists,
    "Run the installer again: curl -sSL https://raw.githubusercontent.com/jbuch84/HammerWhisper/main/install.sh | bash");

  // 2. API key
  let apiKey = null;
  if (configExists) {
    try { const config = JSON.parse(readFileSync(CONFIG_PATH, "utf8")); apiKey = config.apiKey; } catch {}
  }
  const keyValid = apiKey && apiKey !== "YOUR_API_KEY_HERE" && apiKey.startsWith("gsk_");
  check("API key present in config", keyValid,
    "Open ~/hammerwhisper/config.json and paste your Groq key (starts with gsk_)");

  // 3. Node.js version (needs fetch, v18+)
  const nodeMajor = parseInt(process.version.replace("v", "").split(".")[0]);
  check(`Node.js version OK (${process.version})`, nodeMajor >= 18,
    "Install Node.js 18+ via: brew install node");

  // 4. ffmpeg
  let ffmpegPath = null;
  for (const p of ["/opt/homebrew/bin/ffmpeg", "/usr/local/bin/ffmpeg"]) {
    if (existsSync(p)) { ffmpegPath = p; break; }
  }
  check(`ffmpeg found${ffmpegPath ? ` at ${ffmpegPath}` : ""}`, !!ffmpegPath,
    "Install via: brew install ffmpeg");

  // 5. Mic via avfoundation
  if (ffmpegPath) {
    try {
      const result = execSync(`${ffmpegPath} -f avfoundation -list_devices true -i "" 2>&1 || true`, { encoding: "utf8" });
      const hasMic = result.includes("AVFoundation") || result.includes("avfoundation") || result.includes("[0]") || result.includes("input device");
      check("Microphone accessible via avfoundation", hasMic,
        "Make sure a mic is connected and Terminal has Microphone permission in System Settings → Privacy & Security");
    } catch {
      check("Microphone accessible via avfoundation", false, "Could not run ffmpeg device check");
    }
  }

  // 6. Hammerspoon installed
  const hsInstalled = existsSync("/Applications/Hammerspoon.app");
  check("Hammerspoon installed", hsInstalled,
    "Install via: brew install --cask hammerspoon");

  // 7. init.lua has HammerWhisper block
  const luaPath = `${homedir()}/.hammerspoon/init.lua`;
  const luaExists = existsSync(luaPath);
  const luaHasHW = luaExists && readFileSync(luaPath, "utf8").includes("HammerWhisper");
  check("Hammerspoon config has HammerWhisper block", luaHasHW,
    "Run the installer again to regenerate ~/.hammerspoon/init.lua");

  // 8. Hammerspoon is running
  try {
    const result = execSync(
      `osascript -e 'tell application "System Events" to get name of every process whose name is "Hammerspoon"' 2>&1`,
      { encoding: "utf8" }
    ).trim();
    const hsRunning = result.length > 0 && !result.includes("error");
    check("Hammerspoon is running", hsRunning,
      "Open /Applications/Hammerspoon.app — then enable 'Launch at login' in its Preferences");
  } catch {
    check("Hammerspoon is running", false, "Open /Applications/Hammerspoon.app");
  }

  console.log("");
  if (allGood) {
    console.log("Everything looks good! Press your hotkey to start dictating.");
  } else {
    console.log("Fix the items above and run --check again.");
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
  console.error("No API key set — open ~/hammerwhisper/config.json and add your key.");
  process.exit(1);
}

const API_URL = config.apiUrl || "https://api.groq.com/openai/v1/audio/transcriptions";
const MODEL = config.model || "whisper-large-v3";
const AUDIO_FILE = "/tmp/hammerwhisper.wav";

const file = readFileSync(AUDIO_FILE);
const blob = new Blob([file], { type: "audio/wav" });

const form = new FormData();
form.append("file", blob, "hammerwhisper.wav");
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

execSync(`printf '%s' ${JSON.stringify(text)} | pbcopy`);
execSync(`osascript -e 'tell application "System Events" to keystroke "v" using command down'`);

if (existsSync(AUDIO_FILE)) unlinkSync(AUDIO_FILE);
