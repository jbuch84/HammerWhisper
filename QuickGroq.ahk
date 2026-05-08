#Requires AutoHotkey v2.0
#SingleInstance Force
InstallKeybdHook()

global IsRecording := false
global ClipVault := ""
global ConfigPath := A_UserProfile "\quickgroq\config.json"
global ActiveHotkey := "^+d" ; Default fallback

; ── 1. Load Hotkey from Config ───────────────────────────────────────────────
if FileExist(ConfigPath) {
    try {
        ConfigData := FileRead(ConfigPath)
        ; Extract the hotkey value from JSON without needing external libraries
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
    DllCall("winmm\mciSendString", "Str", "stop capture", "Str", "", "UInt", 0, "Ptr", 0)
    DllCall("winmm\mciSendString", "Str", "close capture", "Str", "", "UInt", 0, "Ptr", 0)
}

ToggleQuickGroq(HotkeyName)
{
    global IsRecording, ClipVault
    WorkDir := A_UserProfile "\quickgroq"
    AudioFile := WorkDir "\audio.wav"
    NodeScript := WorkDir "\dictate.js"
    OutFile := WorkDir "\out.txt"

    if (!IsRecording) {
        if !DirExist(WorkDir)
            DirCreate(WorkDir)

        IsRecording := true
        ClipVault := ClipboardAll()
        
        ToolTip("🎤 Recording... (Press hotkey to stop)")
        
        DllCall("winmm\mciSendString", "Str", "open new type waveaudio alias capture", "Str", "", "UInt", 0, "Ptr", 0)
        DllCall("winmm\mciSendString", "Str", "record capture", "Str", "", "UInt", 0, "Ptr", 0)
    } 
    else {
        IsRecording := false
        ToolTip("⏳ Transcribing...")
        
        ; Save and close the audio driver
        DllCall("winmm\mciSendString", "Str", "save capture " . AudioFile, "Str", "", "UInt", 0, "Ptr", 0)
        StopRecording()
        
        if FileExist(OutFile)
            FileDelete(OutFile)
            
        ; Run the Node engine
        RunWait(A_ComSpec " /c node `"" NodeScript "`" > `"" OutFile "`"",, "Hide")
        
        if FileExist(OutFile) {
            transcription := FileRead(OutFile)
            if (transcription != "") {
                A_Clipboard := transcription
                Send("^v")
                Sleep(500)
            }
        }
        
        ; Restore original clipboard
        A_Clipboard := ClipVault 
        ClipVault := "" 
        
        ToolTip("✅ Done!")
        SetTimer () => ToolTip(), -2000 
    }
}

~Esc:: {
    global IsRecording := false
    StopRecording()
    ToolTip()
}
