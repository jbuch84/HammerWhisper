#Requires AutoHotkey v2.0
#SingleInstance Force
InstallKeybdHook()

global IsRecording := false
global ClipVault := ""
global WorkDir := A_Profile "\quickgroq"
global AudioFile := WorkDir "\audio.wav"
global NodeScript := WorkDir "\dictate.js"
global OutFile := WorkDir "\out.txt"

~^+d::
{
    global IsRecording, ClipVault, WorkDir, AudioFile, NodeScript, OutFile
    
    if (!IsRecording) {
        IsRecording := true
        ClipVault := ClipboardAll()
        
        ToolTip("🎤 Recording... (Press Ctrl+Shift+D to stop)")
        
        DllCall("winmm\mciSendString", "Str", "open new type waveaudio alias capture", "Str", "", "UInt", 0, "Ptr", 0)
        DllCall("winmm\mciSendString", "Str", "record capture", "Str", "", "UInt", 0, "Ptr", 0)
    } 
    else {
        IsRecording := false
        ToolTip("⏳ Transcribing...")
        
        DllCall("winmm\mciSendString", "Str", "save capture " . AudioFile, "Str", "", "UInt", 0, "Ptr", 0)
        DllCall("winmm\mciSendString", "Str", "close capture", "Str", "", "UInt", 0, "Ptr", 0)
        
        if FileExist(OutFile)
            FileDelete(OutFile)
            
        RunWait(A_ComSpec " /c node `"" NodeScript "`" > `"" OutFile "`"",, "Hide")
        
        if FileExist(OutFile) {
            transcription := FileRead(OutFile)
            if (transcription != "") {
                A_Clipboard := transcription
                Send("^v")
                Sleep(500)
            }
        }
        
        A_Clipboard := ClipVault 
        ClipVault := "" 
        
        ToolTip("✅ Done!")
        SetTimer () => ToolTip(), -2000 
    }
}

~Esc:: {
    global IsRecording := false
    DllCall("winmm\mciSendString", "Str", "close capture", "Str", "", "UInt", 0, "Ptr", 0)
    ToolTip()
}