# 🎙️ HammerWhisper

Free voice dictation for Mac. Press a hotkey, speak, press again — your words appear wherever you're typing.

No subscription. Works in any app. Powered by Groq's free Whisper API.

---

## What you need before starting

A free Groq API key — this is what powers the speech-to-text. It's free, no credit card needed.

**Get your free key:**
1. Go to [console.groq.com](https://console.groq.com)
2. Sign up with Google or email
3. Click **API Keys** → **Create API Key**
4. Copy the key (it starts with `gsk_`)

That's the only thing you need to grab yourself. Everything else is handled automatically.

---

## Install

Open the **Terminal** app on your Mac and paste this:

```bash
curl -sSL https://raw.githubusercontent.com/jbuch84/HammerWhisper/main/install.sh | bash
```

> **Don't have Terminal?** Press `⌘Space`, type `Terminal`, hit Enter.

The installer will ask you a few questions:
1. Your Groq API key (paste the `gsk_...` key you copied above)
2. Your preferred hotkey (just press Enter to use the default `⌘⇧D`)

That's it. The installer handles most of the setup automatically, but macOS will still require a couple of permissions the first time.

---

## One thing you need to do manually

After the install finishes, macOS requires you to give Hammerspoon permission to type on your behalf:

1. Open **System Settings**
2. Go to **Privacy & Security → Accessibility**
3. Find **Hammerspoon** and turn it on

You'll only ever need to do this once. **If the hotkey does nothing, this is almost always why.**

---

## Make Hammerspoon launch at login

Hammerspoon needs to be running for your hotkey to work. If you restart your Mac and it isn't in your menu bar, HammerWhisper will silently stop working.

**Set it to launch at login:**
1. Open **Hammerspoon** from your Applications folder
2. Click the 🔨 icon in the menu bar
3. Click **Preferences**
4. Check **Launch Hammerspoon at login**

This only needs to be done once.

---

## How to use it

1. Click anywhere you want to type (a text box, email, Google Doc, anywhere)
2. Press your hotkey (`⌘⇧D` by default)
3. A small indicator appears near your cursor — start speaking
4. Press your hotkey again when you're done
5. Your words are typed automatically

---

## How to change your settings

Your settings are saved in a file at `~/hammerwhisper/config.json`. You can open it in any text editor to change your API key or switch to a different speech-to-text provider.

To change your hotkey, run the installer again.

---

## Uninstall

```bash
rm -rf ~/hammerwhisper
rm ~/.hammerspoon/init.lua
```

Then go to **System Settings → Privacy & Security → Accessibility** and remove Hammerspoon.

---

## Is it really free?

Yes. Groq gives you more than enough free usage for everyday dictation — no credit card, no hidden limits for normal use. If you ever want to use a different provider like OpenAI, you can swap it in `config.json`.

---

## Something not working?

**Run the self-check first:**

```bash
~/hammerwhisper/dictate --check
```

This verifies every component and tells you exactly what's wrong.

**Common issues:**

| Symptom | Fix |
|---|---|
| Hotkey does nothing | Grant Hammerspoon Accessibility permission (see above) |
| Works today, broken after restart | Enable "Launch at login" in Hammerspoon Preferences |
| macOS blocked Hammerspoon | System Settings → Privacy & Security → click **Open Anyway** |
| "error" flash but no text typed | Click 🔨 in menu bar → **Open Console** for details |
| Intel Mac not recording audio | Check that ffmpeg is at `/usr/local/bin/ffmpeg` |

For anything else, open the Hammerspoon console: click the 🔨 icon in the menu bar → **Open Console**.
