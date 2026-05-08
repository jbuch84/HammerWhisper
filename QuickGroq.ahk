#Requires AutoHotkey v2.0
#SingleInstance Force
InstallKeybdHook()

global IsRecording := false
global ClipVault := ""

; Installer dynamically sets the hotkey on the line below
~^+d::
{
    global IsRecording, ClipVault
    
    WorkDir := A_UserProfile "\quickgroq"
    NodeScript := WorkDir "\dictate.js"
    OutFile := WorkDir "\out.txt"

    if (!IsRecording) {
        ; Start Recording
        IsRecording := true
        ClipVault := ClipboardAll()
        ToolTip("🎤 Recording... (Clipboard backed up)")
    } 
    else {
        ; Stop Recording & Transcribe
        IsRecording := false
        ToolTip("⏳ Transcribing...")
        
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
        
        ; Restore original data
        A_Clipboard := ClipVault
        ClipVault := ""
        
        ToolTip("✅ Done!")
        SetTimer () => ToolTip(), -2000 
    }
}

~Esc:: {
    global IsRecording := false
    ToolTip()
}
