#Requires AutoHotkey v2.0
#SingleInstance Force
InstallKeybdHook()

global IsRecording := false
global ClipVault := ""

; The installer will replace the line below with your chosen hotkey
~^+d::
{
    global IsRecording, ClipVault
    
    WorkDir := A_UserProfile "\quickgroq"
    NodeScript := WorkDir "\dictate.js"
    OutFile := WorkDir "\out.txt"

    if (!IsRecording) {
        IsRecording := true
        ClipVault := ClipboardAll()
        ToolTip("🎤 Recording...")
    } 
    else {
        IsRecording := false
        ToolTip("⏳ Transcribing...")
        
        if FileExist(OutFile)
            FileDelete(OutFile)
            
        ; Run the transcription
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
    ToolTip()
}
