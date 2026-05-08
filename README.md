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
2. Copy the code below, paste it into the Terminal window, and hit Enter:
   ```bash
   curl -sSL [https://raw.githubusercontent.com/jbuch84/QuickGroq/main/install.sh](https://raw.githubusercontent.com/jbuch84/QuickGroq/main/install.sh) | bash
   ```
3. The screen will ask for your Groq API key. Paste it in and hit Enter.
4. **CRITICAL LAST STEP:** macOS protects your keyboard. You must give QuickGroq permission to type for you. 
   * Open **System Settings** → **Privacy & Security** → **Accessibility**.
   * Find **Hammerspoon** in the list and toggle the switch to **ON**.

### 🪟 For Windows Users
1. Open **PowerShell**. (Press the `Windows` key, type `PowerShell`, and hit Enter).
2. Copy the code below, paste it into the PowerShell window, and hit Enter:
   ```powershell
   irm [https://raw.githubusercontent.com/jbuch84/QuickGroq/main/install.ps1](https://raw.githubusercontent.com/jbuch84/QuickGroq/main/install.ps1) | iex
   ```
3. The screen will ask for your Groq API key. Paste it in and hit Enter.

---

## 🎙️ How to Use QuickGroq

Once installed, QuickGroq runs invisibly in the background. It will automatically launch itself every time you restart your computer.

1. Click into any text box where you want to type (an email, a code editor, a chat box).
2. Press your activation hotkey:
   * **Mac:** `Command + Shift + D`
   * **Windows:** `Ctrl + Shift + D`
3. A small indicator will appear near your mouse. Start speaking naturally. 
4. When you are finished, press the hotkey again.
5. Wait a second or two, and your transcribed text will magically type itself out. 

*(Note: QuickGroq safely backs up whatever you previously had copied to your clipboard, pastes your new text, and then restores your clipboard automatically!)*

---

## 🛟 Troubleshooting & FAQ

**"I pressed the hotkey and nothing happened!"**
* **Mac:** Look for a small hammer icon (🔨) in your top menu bar. If it's not there, open your Applications folder and launch **Hammerspoon**. Also, double-check that you enabled Hammerspoon in your Mac's Accessibility settings.
* **Windows:** Look for a green 'H' icon in your System Tray (bottom right of your screen, near the clock). If it's not there, press the Windows key, type `QuickGroq.ahk`, and run it.

**"It says it's transcribing, but no text ever appears."**
This usually means your Groq API key was entered incorrectly, or you ran out of free credits (rare, but possible if you dictate a novel in one day). 
* **Fix:** Open your user folder (e.g., `C:\Users\YourName\quickgroq` or `~/quickgroq/`), open the `config.json` file in any text editor, and ensure your `apiKey` is correct.

**"How do I uninstall it?"**
* **Mac:** Delete the `~/quickgroq` folder and the `~/.hammerspoon` folder. You can also uninstall Hammerspoon from your Applications.
* **Windows:** Delete the `C:\Users\YourName\quickgroq` folder, and remove the QuickGroq shortcut from your Windows Startup folder (Press `Win + R`, type `shell:startup`, and delete the file).