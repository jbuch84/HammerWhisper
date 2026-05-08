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
global ConfigPath  := A_UserProfile "\\quickgroq\\config.json"
global ActiveHotkey := "^+d"

; ── 1. Load Hotkey from Config ───────────────────────────────────────────────
if FileExist(ConfigPath) {
    try {
        ConfigData := FileRead(ConfigPath)
        if RegExMatch(ConfigData, '"hotkey":\\s*"([^"]+)"', &Match) {
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

; ── 3. Detect Node.js path ───────────────────────────────────────────────────
DetectNodePath() {
    candidates := [
        A_UserProfile "\\AppData\\Roaming\\nvm\\current\\node.exe",
        "C:\\Program Files\\nodejs\\node.exe",
        "C:\\Program Files (x86)\\nodejs\\node.exe",
        A_UserProfile "\\scoop\\apps\\nodejs\\current\\node.exe"
    ]
    for _, candidate in candidates {
        if FileExist(candidate)
            return candidate
    }
    ; Fall back to bare "node" and hope it's in PATH
    return "node"
}

StopRecording() {
    DllCall("winmm\\mciSendString", "Str", "stop capture",  "Str", "", "UInt", 0, "Ptr", 0)
    DllCall("winmm\\mciSendString", "Str", "close capture", "Str", "", "UInt", 0, "Ptr", 0)
}

ToggleQuickGroq(HotkeyName)
{
    global IsRecording, ClipVault
    WorkDir    := A_UserProfile "\\quickgroq"
    AudioFile  := WorkDir "\\audio.wav"
    NodeScript := WorkDir "\\dictate.js"
    OutFile    := WorkDir "\\out.txt"
    ErrFile    := WorkDir "\\err.txt"

    if (!IsRecording) {
        if !DirExist(WorkDir)
            DirCreate(WorkDir)

        ; Attempt to open microphone — bail early if unavailable
        result := DllCall("winmm\\mciSendString",
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
        DllCall("winmm\\mciSendString", "Str", "record capture", "Str", "", "UInt", 0, "Ptr", 0)

    } else {
        IsRecording := false
        ToolTip("⏳ Transcribing…")

        ; Save and close the audio driver
        DllCall("winmm\\mciSendString", "Str", "save capture " . AudioFile, "Str", "", "UInt", 0, "Ptr", 0)
        StopRecording()

        ; Guard: bail if audio file is too small (nothing recorded)
        try {
            audioSize := FileGetSize(AudioFile)
        } catch {
            audioSize := 0
        }
        if (audioSize < 1000) {
            ToolTip()
            A_Clipboard := ClipVault
            ClipVault   := ""
            MsgBox("Nothing was recorded. Check your microphone.")
            return
        }

        if FileExist(OutFile)
            FileDelete(OutFile)
        if FileExist(ErrFile)
            FileDelete(ErrFile)

        ; Resolve Node.js path
        NodeExe := DetectNodePath()

        ; Run the Node engine — stdout to OutFile, stderr to ErrFile
        RunWait(A_ComSpec " /c `"" NodeExe "`" `"" NodeScript "`" > `"" OutFile "`" 2> `"" ErrFile "`"",, "Hide")

        if FileExist(OutFile) {
            transcription := Trim(FileRead(OutFile))
            if (transcription != "") {
                A_Clipboard := transcription
                ClipWait(1)
                Send("^v")
                Sleep(1500)
            } else if FileExist(ErrFile) {
                errMsg := Trim(FileRead(ErrFile))
                if (errMsg != "")
                    MsgBox("QuickGroq error:`n" . errMsg)
            }
        }

        ; Restore previous clipboard after paste has completed
        A_Clipboard := ClipVault
        ClipVault   := ""

        ToolTip("✅ Done!")
        SetTimer(() => ToolTip(), -2000)
    }
}

~Esc:: {
    global IsRecording
    IsRecording := false
    StopRecording()
    ToolTip()
}
