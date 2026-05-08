# ⚡ QuickGroq

Free, cross-platform voice dictation for Mac and Windows. Press a hotkey, speak, press again — your words appear wherever your cursor is.

No subscription. Works in any app (Word, Chrome, Slack, etc.). Powered by Groq's lightning-fast, free Whisper AI.

---

## 🛑 What you need before starting

To make this work, QuickGroq needs a "key" to access the AI that turns your speech into text. We use Groq because it is incredibly fast and completely free.

**How to get your free Groq API key:**
1. Go to [console.groq.com](https://console.groq.com)
2. Sign in with Google or your email. (No credit card is required).
3. On the left menu, click **API Keys**, then click **Create API Key**.
4. Copy the long string of text it gives you (it will start with `gsk_`). Keep this handy; the installer will ask for it!

---

## 🛠️ Installation

Choose your operating system below. The installer handles downloading the necessary background tools (like Node.js and shortcut managers) automatically.

### 🍎 For Mac Users
1. Open the **Terminal** app. (Press `Command + Space` on your keyboard, type `Terminal`, and hit Enter).
2. Click the **Copy icon** in the top-right corner of the code box below, paste it into the Terminal window, and hit Enter:
   ```bash
   curl -sSL 'https://raw.githubusercontent.com/jbuch84/QuickGroq/main/install.sh' -o /tmp/quickgroq_install.sh && bash /tmp/quickgroq_install.sh
   ```
3. The screen will ask for your Groq API key. Paste it in and hit Enter.
4. **CRITICAL LAST STEP:** macOS protects your keyboard. You must give QuickGroq permission to type for you.
   * Open **System Settings** → **Privacy & Security** → **Accessibility**.
   * Find **Hammerspoon** in the list and toggle the switch to **ON**.

### 🪟 For Windows Users
1. Open **PowerShell**. (Press the `Windows` key, type `PowerShell`, and hit Enter).
2. Click the **Copy icon** in the top-right corner of the code box below, paste it into the PowerShell window, and hit Enter:
   ```powershell
   irm 'https://raw.githubusercontent.com/jbuch84/QuickGroq/main/install.ps1' | iex
   ```
3. The screen will ask for your Groq API key. Paste it in and hit Enter.

---

## 🎙️ How to Use QuickGroq

Once installed, QuickGroq runs invisibly in the background. It will automatically launch itself every time you restart your computer.

1. Click into any text box where you want to type (an email, a code editor, a chat box).
2. Press your activation hotkey:
   * **Mac:** `Command + Shift + D`
   * **Windows:** `Ctrl + Shift + D`
3. A small indicator will appear near your cursor showing a live recording timer (e.g. `● 0:04`). Start speaking naturally.
4. When you are finished, press the hotkey again.
5. The indicator will show `transcribing...` for a moment, then `done ✓` — and your transcribed text will appear automatically.

*(Note: QuickGroq safely backs up whatever you previously had copied to your clipboard, pastes your new text, and then restores your clipboard automatically!)*

---

## 🛟 Troubleshooting & FAQ

**"I pressed the hotkey and nothing happened!"**
* **Mac:** Look for a small hammer icon (🔨) in your top menu bar. If it's not there, open your Applications folder and launch **Hammerspoon**. Also double-check that you enabled Hammerspoon in your Mac's Accessibility settings (System Settings → Privacy & Security → Accessibility).
* **Windows:** Look for a tray icon near the clock in the bottom-right of your screen. If it's not there, press the Windows key, type `QuickGroq.ahk`, and run it.

**"It says it's transcribing, but no text ever appears."**
This usually means your Groq API key was entered incorrectly, or you ran out of free credits (rare, but possible if you dictate a very large amount in one day).
* **Fix:** Open your config file — `~/quickgroq/config.json` on Mac or `C:\Users\YourName\quickgroq\config.json` on Windows — in any text editor and confirm your `apiKey` value is correct and starts with `gsk_`.
* **Mac advanced:** Click 🔨 in the menu bar → **Console** to see detailed error logs.

**"I see ❌ failed after transcribing."**
This means the transcription request didn't go through. Check your internet connection and verify your API key as above.

**"How do I change my hotkey?"**
Edit `~/quickgroq/config.json` (Mac) or `C:\Users\YourName\quickgroq\config.json` (Windows) and update the hotkey value. On Mac, click 🔨 → **Reload Config** after saving. On Windows, right-click the tray icon → **Exit**, then relaunch `QuickGroq.ahk`.

**"How do I uninstall it?"**
* **Mac:** Delete the `~/quickgroq` folder and the `~/.hammerspoon` folder. You can also uninstall Hammerspoon from your Applications.
* **Windows:** Delete the `C:\Users\YourName\quickgroq` folder and remove the QuickGroq shortcut from your Startup folder (Press `Win + R`, type `shell:startup`, and delete the shortcut file).
