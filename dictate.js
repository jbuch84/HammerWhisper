import { execSync } from "node:child_process";
import { readFileSync, existsSync, unlinkSync } from "node:fs";
import { homedir } from "node:os";

const CONFIG_PATH = `${homedir()}/hammerwhisper/config.json`;

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
    headers: {
        "Authorization": `Bearer ${config.apiKey}`,
    },
    body: form,
});

const json = await response.json();
const text = json.text?.trim();

if (!text) {
    console.error("No transcription returned:", JSON.stringify(json));
    process.exit(1);
}

execSync(`echo ${JSON.stringify(text)} | pbcopy`);
execSync(`osascript -e 'tell application "System Events" to keystroke "v" using command down'`);

if (existsSync(AUDIO_FILE)) unlinkSync(AUDIO_FILE);