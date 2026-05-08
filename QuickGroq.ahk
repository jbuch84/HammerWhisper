#Requires AutoHotkey v2.0
#SingleInstance Force
InstallKeybdHook()

; ── Kill any other QuickGroq.ahk instances ───────────────────────────────────
for proc in ComObjGet("winmgmts:").ExecQuery("Select * from Win32_Process where Name='AutoHotkey64.exe' or Name='AutoHotkey.exe'") {
    cmdLine := proc.CommandLine
    if (cmdLine && InStr(cmdLine, "QuickGroq.ahk") && proc.ProcessId != DllCall("GetCurrentProcessId")) {
        proc.Terminate()
    }
}

global IsRecording := false
global ClipVault   := ""

; ── Installer patches hotkey and paths before this runs ──────────────────────
~^+d::
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

        result := DllCall("winmm\mciSendString",
                          "Str", "open new type waveaudio alias capture",
                          "Str", "", "UInt", 0, "Ptr", 0)
        if (result != 0) {
            MsgBox("Microphone unavailable (error " . result . ").`n"
                 . "Check: Settings → Privacy & Security → Microphone")
            return
        }

        DllCall("winmm\mciSendString", "Str", "set capture bitspersample 16 channels 1 samplespersec 16000 bytespersec 32000 alignment 2", "Str", "", "UInt", 0, "Ptr", 0)

        IsRecording := true
        ClipVault   := ClipboardAll()

        ToolTip("Recording...(Press hotkey to stop)")
        DllCall("winmm\mciSendString", "Str", "record capture", "Str", "", "UInt", 0, "Ptr", 0)

    } else {
        IsRecording := false
        ToolTip("Transcribing…")

        DllCall("winmm\mciSendString", "Str", "save capture " . AudioFile, "Str", "", "UInt", 0, "Ptr", 0)
        DllCall("winmm\mciSendString", "Str", "stop capture",  "Str", "", "UInt", 0, "Ptr", 0)
        DllCall("winmm\mciSendString", "Str", "close capture", "Str", "", "UInt", 0, "Ptr", 0)

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

        ; Node.js path patched by installer
        NodeExe := "NODEEXE_PATH"

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

        A_Clipboard := ClipVault
        ClipVault   := ""

        ToolTip("Done!")
        SetTimer(() => ToolTip(), -2000)
    }
}

~Esc:: {
    global IsRecording
    IsRecording := false
    DllCall("winmm\mciSendString", "Str", "stop capture",  "Str", "", "UInt", 0, "Ptr", 0)
    DllCall("winmm\mciSendString", "Str", "close capture", "Str", "", "UInt", 0, "Ptr", 0)
    ToolTip()
}
