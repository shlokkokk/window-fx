; ==============================
; WINDOW GHOST CONTROLLER v2.1 (fixed)
; ==============================
; Description: Advanced window transparency and click-through control
; Full GUI:        Ctrl+Alt+E
; Quick Transp:     Ctrl+Alt+T   (instant toggle, no GUI)
; Quick ClickThru:  Ctrl+Alt+C   (instant toggle, no GUI)
; Quick Ghost:      Ctrl+Alt+G   (instant toggle, no GUI)
; Quick Reset:      Ctrl+Alt+R   (instant reset, no GUI)
; Reload script:    Ctrl+Alt+Shift+R
; ==============================

#NoEnv
#SingleInstance Force
#Persistent
SendMode Input
SetWorkingDir %A_ScriptDir%
SetTitleMatchMode, 2

; ==============================
; CONFIG
; ==============================
global ConfigFile := A_ScriptDir "\ghost_profiles.ini"
global DefaultGhostOpacity := 200
global ToastDuration := 900   ; ms, for quick-hotkey feedback popups

; ==============================
; GLOBAL STATE
; ==============================
global g_TargetHWND := 0
global g_Transparency := 255
global g_ClickThrough := false
global g_GhostMode := false
global g_AlwaysOnTop := false
global g_GUIisOpen := false

; ==============================
; TRAY MENU
; ==============================
Menu, Tray, NoStandard
Menu, Tray, Add, Open Controller (Ctrl+Alt+E), OpenControlUIFromTray
Menu, Tray, Add, Quick Toggle Transparency (Ctrl+Alt+T), TrayQuickTrans
Menu, Tray, Add, Quick Toggle Click-through (Ctrl+Alt+C), TrayQuickClick
Menu, Tray, Add, Quick Ghost Mode (Ctrl+Alt+G), TrayQuickGhost
Menu, Tray, Add
Menu, Tray, Add, Reset ALL tracked windows, ResetAllTracked
Menu, Tray, Add
Menu, Tray, Add, Reload Script, ReloadScript
Menu, Tray, Add, Exit, ExitScript
Menu, Tray, Default, Open Controller (Ctrl+Alt+E)
Menu, Tray, Tip, Window Ghost Controller v2

OpenControlUIFromTray:
    WinGet, g_TargetHWND, ID, A
    OpenControlUI()
return

TrayQuickTrans:
    WinGet, g_TargetHWND, ID, A
    GetCurrentWindowState()
    QuickToggleTransparency()
return

TrayQuickClick:
    WinGet, g_TargetHWND, ID, A
    GetCurrentWindowState()
    QuickToggleClickThrough()
return

TrayQuickGhost:
    WinGet, g_TargetHWND, ID, A
    GetCurrentWindowState()
    QuickToggleGhost()
return

ResetAllTracked:
    ResetAllTrackedWindows()
return

ReloadScript:
    Reload
return

ExitScript:
    ExitApp
return

; ==============================
; MAIN HOTKEY - FULL GUI
; ==============================
^!e::
    WinGet, g_TargetHWND, ID, A
    if (g_GUIisOpen) {
        WinGetTitle, currentTitle, ahk_id %g_TargetHWND%
        GuiControl, Main:, TitleText, Controlling: %currentTitle%
        GetCurrentWindowState()
        UpdateGUIFromWindowState()
        return
    }
    OpenControlUI()
return

; ==============================
; QUICK HOTKEYS - NO GUI, INSTANT ACTION + TOAST
; ==============================
^!t::
    WinGet, g_TargetHWND, ID, A
    GetCurrentWindowState()
    QuickToggleTransparency()
return

^!c::
    WinGet, g_TargetHWND, ID, A
    GetCurrentWindowState()
    QuickToggleClickThrough()
return

^!g::
    WinGet, g_TargetHWND, ID, A
    GetCurrentWindowState()
    QuickToggleGhost()
return

^!r::
    WinGet, g_TargetHWND, ID, A
    QuickReset()
return

^!+r::Reload

; ==============================
; QUICK ACTIONS (used by hotkeys + tray)
; ==============================
QuickToggleTransparency() {
    global
    if (g_Transparency < 255) {
        g_Transparency := 255
    } else {
        g_Transparency := (g_Transparency < 255) ? g_Transparency : DefaultGhostOpacity
    }
    WinSet, Transparent, %g_Transparency%, ahk_id %g_TargetHWND%
    g_GhostMode := (g_Transparency < 255 && g_ClickThrough)
    SaveWindowProfile()
    ShowToast("Opacity: " . g_Transparency . (g_Transparency = 255 ? " (opaque)" : ""))
    if (g_GUIisOpen)
        UpdateGUIFromWindowState()
}

QuickToggleClickThrough() {
    global
    WS_EX_TRANSPARENT := 0x20
    if (g_ClickThrough) {
        WinSet, ExStyle, -%WS_EX_TRANSPARENT%, ahk_id %g_TargetHWND%
        g_ClickThrough := false
    } else {
        WinSet, ExStyle, +%WS_EX_TRANSPARENT%, ahk_id %g_TargetHWND%
        g_ClickThrough := true
    }
    g_GhostMode := (g_Transparency < 255 && g_ClickThrough)
    SaveWindowProfile()
    ShowToast("Click-through: " . (g_ClickThrough ? "ON" : "OFF"))
    if (g_GUIisOpen)
        UpdateGUIFromWindowState()
}

QuickToggleGhost() {
    global
    WS_EX_TRANSPARENT := 0x20
    if (!g_GhostMode) {
        if (g_Transparency = 255) {
            g_Transparency := DefaultGhostOpacity
            WinSet, Transparent, %g_Transparency%, ahk_id %g_TargetHWND%
        }
        if (!g_ClickThrough) {
            WinSet, ExStyle, +%WS_EX_TRANSPARENT%, ahk_id %g_TargetHWND%
            g_ClickThrough := true
        }
        g_GhostMode := true
        ShowToast("Ghost Mode: ON")
    } else {
        g_Transparency := 255
        WinSet, Transparent, 255, ahk_id %g_TargetHWND%
        if (g_ClickThrough) {
            WinSet, ExStyle, -%WS_EX_TRANSPARENT%, ahk_id %g_TargetHWND%
            g_ClickThrough := false
        }
        g_GhostMode := false
        ShowToast("Ghost Mode: OFF")
    }
    SaveWindowProfile()
    if (g_GUIisOpen)
        UpdateGUIFromWindowState()
}

QuickReset() {
    global
    WS_EX_TRANSPARENT := 0x20
    WS_EX_LAYERED := 0x80000
    g_Transparency := 255
    g_ClickThrough := false
    g_GhostMode := false
    WinSet, Transparent, 255, ahk_id %g_TargetHWND%
    WinSet, ExStyle, -%WS_EX_TRANSPARENT%, ahk_id %g_TargetHWND%
    WinSet, ExStyle, -%WS_EX_LAYERED%, ahk_id %g_TargetHWND%
    DeleteWindowProfile()
    ShowToast("Reset to default")
    if (g_GUIisOpen)
        UpdateGUIFromWindowState()
}

; ==============================
; PER-APP PROFILE MEMORY (INI-BACKED)
; ==============================
GetProcessKey(hwnd) {
    WinGet, procName, ProcessName, ahk_id %hwnd%
    if (procName = "")
        procName := "Unknown"
    return procName
}

SaveWindowProfile() {
    global
    key := GetProcessKey(g_TargetHWND)
    IniWrite, %g_Transparency%, %ConfigFile%, %key%, Transparency
    IniWrite, % (g_ClickThrough ? 1 : 0), %ConfigFile%, %key%, ClickThrough
}

LoadWindowProfile() {
    global
    key := GetProcessKey(g_TargetHWND)
    IniRead, savedTrans, %ConfigFile%, %key%, Transparency, %A_Space%
    IniRead, savedClick, %ConfigFile%, %key%, ClickThrough, %A_Space%
    if (savedTrans != "") {
        g_Transparency := savedTrans
        WinSet, Transparent, %g_Transparency%, ahk_id %g_TargetHWND%
    }
    if (savedClick = "1") {
        WS_EX_TRANSPARENT := 0x20
        WinSet, ExStyle, +%WS_EX_TRANSPARENT%, ahk_id %g_TargetHWND%
        g_ClickThrough := true
    }
    g_GhostMode := (g_Transparency < 255 && g_ClickThrough)
}

DeleteWindowProfile() {
    global
    key := GetProcessKey(g_TargetHWND)
    IniDelete, %ConfigFile%, %key%
}

ResetAllTrackedWindows() {
    global
    if (!FileExist(ConfigFile)) {
        ShowToast("No tracked windows to reset")
        return
    }
    IniRead, sections, %ConfigFile%
    Loop, Parse, sections, `n
    {
        if (A_LoopField = "")
            continue
        WinGet, matchedHWND, ID, ahk_exe %A_LoopField%
        if (matchedHWND) {
            WS_EX_TRANSPARENT := 0x20
            WinSet, Transparent, 255, ahk_id %matchedHWND%
            WinSet, ExStyle, -%WS_EX_TRANSPARENT%, ahk_id %matchedHWND%
        }
    }
    FileDelete, %ConfigFile%
    ShowToast("All tracked windows reset")
}

; ==============================
; TOAST NOTIFICATION (lightweight, auto-closes)
; FIX: was missing ":New," subcommand, would crash on first use
; ==============================
ShowToast(msg) {
    Gui, Toast:Destroy
    Gui, Toast:New, +AlwaysOnTop -Caption +ToolWindow +E0x08000000
    Gui, Toast:Color, 1e1e2e
    Gui, Toast:Font, s11 cF5F5F5, Segoe UI
    Gui, Toast:Add, Text, x16 y10 cF5F5F5, %msg%
    Gui, Toast:Show, AutoSize NoActivate, GhostToast
    WinSet, Transparent, 235, GhostToast
    SetTimer, HideToast, % -ToastDuration
}
HideToast:
    Gui, Toast:Destroy
return

; ==============================
; OPEN CONTROL UI (FULL GUI)
; ==============================
OpenControlUI() {
    global

    if (g_GUIisOpen) {
        Gui, Main:Show
        return
    }

    GetCurrentWindowState()
    LoadWindowProfile()

    WinGetTitle, windowTitle, ahk_id %g_TargetHWND%
    if (windowTitle = "")
        windowTitle := "Unknown Window"
    if (StrLen(windowTitle) > 42)
        windowTitle := SubStr(windowTitle, 1, 42) . "..."

    procName := GetProcessKey(g_TargetHWND)

    ; ---- Dark themed GUI ----
    Gui, Main:New, +AlwaysOnTop +ToolWindow +Caption -DPIScale, Window Ghost Controller
    Gui, Main:Color, 1e1e2e, 2a2a3d
    Gui, Main:Font, s10 cF5F5F5, Segoe UI

    Gui, Main:Add, Text, w300 vTitleText cF5F5F5, Controlling: %windowTitle%
    Gui, Main:Font, s8 c8888AA, Segoe UI
    Gui, Main:Add, Text, w300 vProcText, Process: %procName%  |  HWND: %g_TargetHWND%
    Gui, Main:Font, s10 cF5F5F5, Segoe UI

    ; FIX: old line had "; spacer" as literal trailing text which AHK
    ; does NOT treat as a comment here — it would have shown up as
    ; visible text on the GUI. Replaced with a genuine empty spacer.
    Gui, Main:Add, Text, w300 h6 y+12,

    ; Transparency
    Gui, Main:Add, GroupBox, w280 h110 Section cF5F5F5, Transparency
    Gui, Main:Add, Slider, xs+10 ys+22 w260 h30 vTransSlider Range50-255 TickInterval20 AltSubmit gUpdateTransparencyLive, %g_Transparency%
    Gui, Main:Add, Text, xs+10 y+2 w260 Center vTransValue cF5F5F5, Opacity: %g_Transparency% / 255

    ; Opacity presets
    ; FIX: literal "%" in button text must be escaped with a backtick,
    ; not doubled — doubling causes "Empty variable reference" error.
    Gui, Main:Add, Button, xs+10 y+6 w60 h24 gPreset25, 25`%
    Gui, Main:Add, Button, x+6 w60 h24 gPreset50, 50`%
    Gui, Main:Add, Button, x+6 w60 h24 gPreset75, 75`%
    Gui, Main:Add, Button, x+6 w60 h24 gPreset100, 100`%

    ; Quick controls
    Gui, Main:Add, GroupBox, xs w280 h80 Section cF5F5F5, Quick Controls
    Gui, Main:Add, Button, xs+10 ys+20 w84 h30 gToggleTransparency, Toggle Trans
    Gui, Main:Add, Button, x+8 w84 h30 gToggleClickThrough, Toggle Click
    Gui, Main:Add, Button, x+8 w84 h30 gToggleGhostMode, Ghost Mode

    ; Extras
    Gui, Main:Add, CheckBox, xs vAlwaysOnTopCheck gToggleAlwaysOnTop Checked%g_AlwaysOnTop%, Keep this window Always on Top
    Gui, Main:Add, Button, xs w280 h34 gResetWindow, Reset to Default
    Gui, Main:Add, Button, xs w280 h28 gCloseControlUI, Close Controller

    Gui, Main:Add, StatusBar
    SB_SetText("Ctrl+Alt+E: retarget | Ctrl+Alt+T/C/G: quick toggle | Ctrl+Alt+R: quick reset")

    Gui, Main:Show, Center AutoSize
    g_GUIisOpen := true
    WinSet, AlwaysOnTop, On, Window Ghost Controller

    UpdateGUIFromWindowState()
}

; ==============================
; STATE HELPERS
; ==============================
GetCurrentWindowState() {
    global
    WinGet, transValue, Transparent, ahk_id %g_TargetHWND%
    if (transValue = "" || transValue = "Off")
        g_Transparency := 255
    else
        g_Transparency := transValue

    g_ClickThrough := IsClickThrough(g_TargetHWND)
    g_AlwaysOnTop := IsAlwaysOnTop(g_TargetHWND)

    if (g_Transparency < 255 && g_ClickThrough)
        g_GhostMode := true
    else
        g_GhostMode := false
}

UpdateGUIFromWindowState() {
    global
    GuiControl, Main:, TransSlider, %g_Transparency%
    GuiControl, Main:, TransValue, Opacity: %g_Transparency% / 255
    GuiControl, Main:, AlwaysOnTopCheck, %g_AlwaysOnTop%

    statusText := "Trans: " g_Transparency
    statusText .= " | Click-thru: " (g_ClickThrough ? "ON" : "OFF")
    statusText .= " | Ghost: " (g_GhostMode ? "ON" : "OFF")
    statusText .= " | Pinned: " (g_AlwaysOnTop ? "ON" : "OFF")
    SB_SetText(statusText)
}

IsClickThrough(hwnd) {
    WS_EX_TRANSPARENT := 0x20
    WinGet, exStyle, ExStyle, ahk_id %hwnd%
    return (exStyle & WS_EX_TRANSPARENT) ? true : false
}

IsAlwaysOnTop(hwnd) {
    WinGet, exStyle, ExStyle, ahk_id %hwnd%
    WS_EX_TOPMOST := 0x8
    return (exStyle & WS_EX_TOPMOST) ? true : false
}

; ==============================
; GUI EVENT HANDLERS
; ==============================
ToggleTransparency:
    QuickToggleTransparency()
return

ToggleClickThrough:
    QuickToggleClickThrough()
return

ToggleGhostMode:
    QuickToggleGhost()
return

ToggleAlwaysOnTop:
    Gui, Main:Submit, NoHide
    if (AlwaysOnTopCheck) {
        WinSet, AlwaysOnTop, On, ahk_id %g_TargetHWND%
        g_AlwaysOnTop := true
    } else {
        WinSet, AlwaysOnTop, Off, ahk_id %g_TargetHWND%
        g_AlwaysOnTop := false
    }
    UpdateGUIFromWindowState()
return

Preset25:
    SetOpacityPreset(64)
return
Preset50:
    SetOpacityPreset(128)
return
Preset75:
    SetOpacityPreset(191)
return
Preset100:
    SetOpacityPreset(255)
return

SetOpacityPreset(val) {
    global
    g_Transparency := val
    WinSet, Transparent, %g_Transparency%, ahk_id %g_TargetHWND%
    g_GhostMode := (g_Transparency < 255 && g_ClickThrough)
    SaveWindowProfile()
    UpdateGUIFromWindowState()
}

UpdateTransparencyLive() {
    global
    GuiControlGet, g_Transparency,, TransSlider
    WinSet, Transparent, %g_Transparency%, ahk_id %g_TargetHWND%
    GuiControl,, TransValue, Opacity: %g_Transparency% / 255
    g_GhostMode := (g_Transparency < 255 && g_ClickThrough)
    SaveWindowProfile()
    SB_SetText("Live preview | Opacity: " g_Transparency)
}

ResetWindow:
    QuickReset()
return

CloseControlUI:
    Gui, Main:Hide
    g_GUIisOpen := false
return

GuiClose:
    Gui, Main:Hide
    g_GUIisOpen := false
return

GuiEscape:
    Gui, Main:Hide
    g_GUIisOpen := false
return
