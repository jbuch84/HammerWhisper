#Requires AutoHotkey v2.0
#SingleInstance Force
InstallKeybdHook()

; ── Kill any other QuickGroq.ahk instances by script name ────────────────────
for proc in ComObjGet("winmgmts:").ExecQuery("Select * from Win32_Process where Name='AutoHotkey64.exe' or Name='AutoHotkey.exe'") {
    cmdLine := proc.CommandLine
    if (cmdLine && InStr(cmdLine, "QuickGroq.ahk") && proc.ProcessId != DllCall("GetCurrentProcessId")) {
        proc.Terminate()
    }
}

global IsRecording := false
global ClipVault   := ""
global ConfigPath  := A_UserProfile "\quickgroq\config.json"
global ActiveHotkey := "^+d" ; Default fallback

; ── 1. Load Hotkey from Config ───────────────────────────────────────────────
if FileExist(ConfigPath) {
    try {
        ConfigData := FileRead(ConfigPath)
        if RegExMatch(ConfigData, '"hotkey":\s*"([^"]+)"', &Match) {
            ActiveHotkey := Match[1]
        }
    }
}

; ── 2. Initialize Hotkey ─────────────────────────────────────────────────────
try {
    Hotkey(ActiveHotkey, ToggleQuickGroq)
} catch {
    MsgBox("Invalid hotkey in config.json: " . ActiveHotkey . "`nFalling back to Ctrl+Shift+D")
    Hotkey("^+d", ToggleQuickGroq)
}

StopRecording() {
    DllCall("winmm\mciSendString", "Str", "stop capture",  "Str", "", "UInt", 0, "Ptr", 0)
    DllCall("winmm\mciSendString", "Str", "close capture", "Str", "", "UInt", 0, "Ptr", 0)
}

ToggleQuickGroq(HotkeyName)
{
    global IsRecording, ClipVault
    WorkDir    := A_UserProfile "\quickgroq"
    AudioFile  := WorkDir "\audio.wav"
    NodeScript := WorkDir "\dictate.js"
    OutFile    := WorkDir "\out.txt"
    ErrFile    := WorkDir "\err.txt"

    if (!IsRecording) {
        if !DirExist(WorkDir)
            DirCreate(WorkDir)

        ; Attempt to open microphone — bail early if unavailable
        result := DllCall("winmm\mciSendString",
                          "Str", "open new type waveaudio alias capture",
                          "Str", "", "UInt", 0, "Ptr", 0)
        if (result != 0) {
            MsgBox("Microphone unavailable (error " . result . ").`n"
                 . "Check Windows microphone permissions:`n"
                 . "Settings → Privacy & Security → Microphone")
            return
        }

        IsRecording := true
        ClipVault   := ClipboardAll()

        ToolTip("🎤 Recording… (Press hotkey to stop)")
        DllCall("winmm\mciSendString", "Str", "record capture", "Str", "", "UInt", 0, "Ptr", 0)

    } else {
        IsRecording := false
        ToolTip("⏳ Transcribing…")

        ; Save and close the audio driver
        DllCall("winmm\mciSendString", "Str", "save capture " . AudioFile, "Str", "", "UInt", 0, "Ptr", 0)
        StopRecording()

        if FileExist(OutFile)
            FileDelete(OutFile)
        if FileExist(ErrFile)
            FileDelete(ErrFile)

        ; Run the Node engine — stdout to OutFile, stderr to ErrFile
        RunWait(A_ComSpec " /c node `"" NodeScript "`" > `"" OutFile "`" 2> `"" ErrFile "`"",, "Hide")

        if FileExist(OutFile) {
            transcription := Trim(FileRead(OutFile))
            if (transcription != "") {
                A_Clipboard := transcription
                ClipWait(1)
                Send("^v")
                Sleep(300)
            } else if FileExist(ErrFile) {
                errMsg := Trim(FileRead(ErrFile))
                if (errMsg != "")
                    MsgBox("QuickGroq error:`n" . errMsg)
            }
        }

        ; Brief pause before restoring clipboard so paste completes
        Sleep(200)
        A_Clipboard := ClipVault
        ClipVault   := ""

        ToolTip("✅ Done!")
        SetTimer(() => ToolTip(), -2000)
    }
}

~Esc:: {
    global IsRecording := false
    StopRecording()
    ToolTip()
}
