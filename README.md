# 🎙️ HammerWhisper

Free, system-wide voice dictation for macOS — powered by [Groq Whisper](https://console.groq.com). Press a hotkey anywhere, speak, press again, and your words are typed instantly.

No subscription. No always-on mic. No bloatware.

***

## How it works

1. Press your hotkey to start recording
2. Speak
3. Press your hotkey again to stop
4. Your transcription is typed wherever your cursor is

A small indicator appears near your cursor showing recording status and duration.

***

## Requirements

- macOS (Apple Silicon or Intel)
- Internet connection (for Groq API)
- A free [Groq API key](https://console.groq.com) — no credit card needed

Everything else (Homebrew, ffmpeg, Hammerspoon) is installed automatically.

***

## Install

Open Terminal and run:

```bash
curl -sSL https://raw.githubusercontent.com/jbuch84/HammerWhisper/main/install.sh | bash
```

You'll be asked for:
- Your Groq API key (get one free at [console.groq.com](https://console.groq.com))
- Your preferred hotkey (default: `⌘⇧D`)

That's it.

***

## One manual step after install

macOS requires you to grant Hammerspoon accessibility access:

1. Open **System Settings → Privacy & Security → Accessibility**
2. Enable **Hammerspoon**

This is a one-time step required for any app that types on your behalf.

***

## Config

Your settings live at `~/hammerwhisper/config.json`:

```json
{
    "apiKey": "your-groq-api-key",
    "apiUrl": "https://api.groq.com/openai/v1/audio/transcriptions",
    "model": "whisper-large-v3"
}
```

| Field | Description | Default |
|-------|-------------|---------|
| `apiKey` | Your API key | — |
| `apiUrl` | Any OpenAI-compatible Whisper endpoint | Groq |
| `model` | Whisper model to use | `whisper-large-v3` |

HammerWhisper works with any OpenAI-compatible STT endpoint — not just Groq. Swap `apiUrl` and `model` to use OpenAI, a local Whisper server, or any compatible provider.

***

## Updating

To reload your Hammerspoon config after any manual edits:

```
⌘⇧R
```

***

## Uninstall

```bash
rm -rf ~/hammerwhisper
rm ~/.hammerspoon/init.lua
```

Then remove Hammerspoon from **System Settings → Privacy & Security → Accessibility** and delete `/Applications/Hammerspoon.app` if you no longer need it.

***

## Is it really free?

Groq's Whisper API is free with generous limits — far more than typical daily dictation usage. No credit card is required to sign up. If you ever hit limits or want to use a different provider, just update `config.json`.

***

## License

MIT
