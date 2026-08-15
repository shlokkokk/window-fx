; ==============================================================================
;  WINDOWFX PRO - Advanced Dynamic Window Controller v3.0
; ==============================================================================
;  Features:
;   - 100% Silent Background Startup (Runs in background, GUI on demand)
;   - Native Windows 10/11 DWM Immersive Dark Titlebar
;   - Clean Developer Typography & Exact Functional Terminology (Zero emojis/jargon)
;   - Interactive ToolTips on Hover & Dedicated Modals for Active/Settings
;   - Hotkey Pause Toggle (Ctrl+Alt+Shift+S for gaming / uninterrupted work)
;   - Fully Dynamic Multi-Window Targeting (Dropdown, Crosshair Picker, Auto-Follow)
;   - Granular Opacity Control (Smooth slider, quick presets 25/50/75/100, fine +/-5%)
;   - Transparent Overlay Mode (Alpha + WS_EX_TRANSPARENT Click Passthrough)
;   - Titlebar Roll-Up Collapse & Frameless Border Removal
;   - Always-On-Top Pinning & Picture-in-Picture Quick Snapping
;   - Master Reset Mechanism: Hotkey, 1-Click Restore, & Factory Reset
;   - Per-App Persistence (INI) & Built-in Windows Startup Manager
;   - Global Emergency Reset (Ctrl+Alt+Shift+Esc) & Clean Process Lifecycle
; ==============================================================================

#NoEnv
#SingleInstance Force
#Persistent
#MaxHotkeysPerInterval 200
SendMode Input
SetWorkingDir %A_ScriptDir%
SetTitleMatchMode, 2
DetectHiddenWindows, Off

; ==============================================================================
; GLOBAL CONSTANTS & INI PATH
; ==============================================================================
global ConfigFile := A_ScriptDir "\window_profiles.ini"
global AppName := "WindowFX Pro"
global AppVersion := "v3.0"

; Win32 Extended Window Styles
global WS_EX_TOPMOST     := 0x00000008
global WS_EX_TRANSPARENT := 0x00000020
global WS_EX_LAYERED     := 0x00080000
global WS_CAPTION        := 0x00C00000
global WS_THICKFRAME     := 0x00040000

; ==============================================================================
; APPLICATION SETTINGS (Loaded from INI)
; ==============================================================================
global g_DefaultOverlayOpacity := 200
global g_ToastDuration         := 1200
global g_AutoFollowFocus       := false
global g_MouseWheelOpacity     := true
global g_StartupNotify         := true
global g_HotkeysSuspended      := false

; ==============================================================================
; RUNTIME STATE
; ==============================================================================
global g_TargetHWND       := 0
global g_TargetTitle      := ""
global g_TargetProc       := ""
global g_TargetPID        := 0
global g_Transparency     := 255
global g_ClickThrough     := false
global g_OverlayMode      := false
global g_AlwaysOnTop      := false
global g_IsShaded         := false
global g_OrigHeight       := 0
global g_IsBorderless     := false
global g_OrigStyle        := 0
global g_GUIisOpen        := false
global g_IsPicking        := false

; Tracking array for all modified windows: HWND -> Object
global g_ModifiedWindows := {}
global g_WindowListHwnds := []

; Load persistent configuration
LoadGeneralSettings()

; Register clean exit handler and tooltip message
OnExit("CleanExitHandler")
OnMessage(0x0200, "WM_MOUSEMOVE")

; Build Background Taskbar Menu
SetupTrayMenu()

; Start background timers
SetTimer, AutoFollowWatcher, 250
SetTimer, AutoFollowWatcher, Off
if (g_AutoFollowFocus)
    SetTimer, AutoFollowWatcher, On

; Check startup arguments: if launched with /gui or /show, open immediately
Loop, %0%
{
    arg := %A_Index%
    if (arg = "/gui" || arg = "/show" || arg = "--gui")
    {
        TargetActiveWindow()
        OpenControlUI()
        break
    }
}

; Startup notification (if enabled and started silently)
if (g_StartupNotify && !g_GUIisOpen)
    ShowToast("WindowFX running in background`nPress Ctrl+Alt+E to open dashboard", 1800)

; CRITICAL: End of auto-execute section so script runs silently in background!
return

; ==============================================================================
; SYSTEM TRAY SETUP & HANDLERS
; ==============================================================================
SetupTrayMenu() {
    Menu, Tray, NoStandard
    Menu, Tray, Add, %AppName% %AppVersion%, ShowHelpModal
    Menu, Tray, Add, Shortcuts and Guide, ShowHelpModal
    Menu, Tray, Add
    Menu, Tray, Add, Open Dashboard`t(Ctrl+Alt+E), OpenControlUIFromTray
    Menu, Tray, Add, Target Active Window, TargetActiveFromTray
    Menu, Tray, Add, Pick Window (Crosshair), StartCrosshairPick
    Menu, Tray, Add
    Menu, Tray, Add, Transparent Overlay`t(Ctrl+Alt+G), TrayQuickOverlay
    Menu, Tray, Add, Toggle Opacity`t(Ctrl+Alt+T), TrayQuickTrans
    Menu, Tray, Add, Toggle Click Passthrough`t(Ctrl+Alt+C), TrayQuickClick
    Menu, Tray, Add, Toggle Always On Top`t(Ctrl+Alt+P), TrayQuickTopmost
    Menu, Tray, Add, Collapse to Titlebar`t(Ctrl+Alt+S), TrayQuickShade
    Menu, Tray, Add
    Menu, Tray, Add, Reset Active Window`t(Ctrl+Alt+R), TrayQuickReset
    Menu, Tray, Add, Emergency Reset ALL Windows`t(Ctrl+Alt+Shift+Esc), EmergencyResetAll
    Menu, Tray, Add, Master Factory Reset..., MasterFactoryReset
    Menu, Tray, Add
    Menu, Tray, Add, Pause All Hotkeys`t(Ctrl+Alt+Shift+S), ToggleSuspendFromTray
    Menu, Tray, Add, Auto-Follow Active Focus, ToggleAutoFollowFromTray
    if (g_AutoFollowFocus)
        Menu, Tray, Check, Auto-Follow Active Focus
    Menu, Tray, Add, Run on Windows Startup, ToggleStartupFromTray
    if (IsStartupEnabled())
        Menu, Tray, Check, Run on Windows Startup
    Menu, Tray, Add
    Menu, Tray, Add, Reload WindowFX`t(Ctrl+Alt+Shift+R), ReloadScript
    Menu, Tray, Add, Exit WindowFX, CleanExitApp
    Menu, Tray, Default, Open Dashboard`t(Ctrl+Alt+E)
    Menu, Tray, Tip, %AppName% %AppVersion% (Press Ctrl+Alt+E)
}

OpenControlUIFromTray:
    TargetActiveWindow()
    OpenControlUI()
return

TargetActiveFromTray:
    TargetActiveWindow()
    ShowToast("Target locked: " . (g_TargetProc != "" ? g_TargetProc : "Window"))
    if (g_GUIisOpen)
        UpdateGUI()
return

TrayQuickOverlay:
    TargetActiveWindow()
    QuickToggleOverlay()
return

TrayQuickTrans:
    TargetActiveWindow()
    QuickToggleTransparency()
return

TrayQuickClick:
    TargetActiveWindow()
    QuickToggleClickThrough()
return

TrayQuickTopmost:
    TargetActiveWindow()
    QuickToggleAlwaysOnTop()
return

TrayQuickShade:
    TargetActiveWindow()
    QuickToggleShade()
return

TrayQuickReset:
    TargetActiveWindow()
    QuickResetCurrent()
return

ToggleSuspendFromTray:
    ToggleHotkeySuspend()
return

ToggleHotkeySuspend() {
    global
    Suspend, Toggle
    g_HotkeysSuspended := !g_HotkeysSuspended
    if (g_HotkeysSuspended) {
        Menu, Tray, Check, Pause All Hotkeys`t(Ctrl+Alt+Shift+S)
        ShowToast("Hotkeys PAUSED (Disabled for gaming/editing)")
    } else {
        Menu, Tray, Uncheck, Pause All Hotkeys`t(Ctrl+Alt+Shift+S)
        ShowToast("Hotkeys RESUMED (Active)")
    }
}

ToggleAutoFollowFromTray:
    g_AutoFollowFocus := !g_AutoFollowFocus
    IniWrite, % (g_AutoFollowFocus ? 1 : 0), %ConfigFile%, General, AutoFollowFocus
    if (g_AutoFollowFocus) {
        Menu, Tray, Check, Auto-Follow Active Focus
        SetTimer, AutoFollowWatcher, On
        ShowToast("Auto-Follow Focus: ON (Tracking current window)")
    } else {
        Menu, Tray, Uncheck, Auto-Follow Active Focus
        SetTimer, AutoFollowWatcher, Off
        ShowToast("Auto-Follow Focus: OFF")
    }
return

ToggleStartupFromTray:
    if (IsStartupEnabled()) {
        SetStartup(false)
        Menu, Tray, Uncheck, Run on Windows Startup
        ShowToast("Launch on Startup: Disabled")
    } else {
        SetStartup(true)
        Menu, Tray, Check, Run on Windows Startup
        ShowToast("Launch on Startup: Enabled (Starts silently in background)")
    }
return

ReloadScript:
    Reload
return

CleanExitApp:
    ExitApp
return

; ==============================================================================
; GLOBAL HOTKEYS (Safe Ctrl+Alt Combos - Zero Windows Collision)
; ==============================================================================

; Open / Focus Dashboard
^!e::
    if (g_GUIisOpen) {
        Gui, Main:Show
        TargetActiveWindow()
        UpdateGUI()
    } else {
        TargetActiveWindow()
        OpenControlUI()
    }
return

; Quick Transparent Overlay (Opacity + Click Passthrough)
^!g::
    TargetActiveWindow()
    QuickToggleOverlay()
return

; Quick Transparency Toggle
^!t::
    TargetActiveWindow()
    QuickToggleTransparency()
return

; Quick Click Passthrough Toggle
^!c::
    TargetActiveWindow()
    QuickToggleClickThrough()
return

; Quick Always On Top Pinning
^!p::
    TargetActiveWindow()
    QuickToggleAlwaysOnTop()
return

; Quick Titlebar Collapse / Shade Toggle
^!s::
    TargetActiveWindow()
    QuickToggleShade()
return

; Quick Reset Active Window
^!r::
    TargetActiveWindow()
    QuickResetCurrent()
return

; Pause / Resume Hotkeys (for Gaming or Photoshop)
^!+s::
    ToggleHotkeySuspend()
return

; Emergency Reset All Windows to Normal (Safe: Ctrl+Alt+Shift+Esc)
^!+Escape::
    EmergencyResetAll()
return

; Reload Script
^!+r::Reload

; Mouse Wheel Opacity (Hover over any window, hold Ctrl+Alt, scroll wheel)
#If (g_MouseWheelOpacity)
^!WheelUp::
    MouseGetPos,,, hoverHWND
    if (IsValidTarget(hoverHWND)) {
        AdjustWindowOpacity(hoverHWND, 15)
    }
return

^!WheelDown::
    MouseGetPos,,, hoverHWND
    if (IsValidTarget(hoverHWND)) {
        AdjustWindowOpacity(hoverHWND, -15)
    }
return
#If

; ==============================================================================
; TARGETING & STATE MANAGEMENT
; ==============================================================================

IsValidTarget(hwnd) {
    if (!hwnd || !WinExist("ahk_id " . hwnd))
        return false
    WinGetClass, winClass, ahk_id %hwnd%
    ; Ignore Shell, Desktop, Taskbar, and WindowFX itself
    if (winClass = "Progman" || winClass = "WorkerW" || winClass = "Shell_TrayWnd" 
     || winClass = "Shell_SecondaryTrayWnd" || winClass = "AutoHotkeyGUI")
        return false
    return true
}

TargetActiveWindow() {
    WinGet, activeHWND, ID, A
    if (IsValidTarget(activeHWND))
    {
        SetTargetHWND(activeHWND)
        return
    }
    ; Fallback: find first visible top-level application
    WinGet, idList, List,,, Program Manager
    Loop, %idList%
    {
        hwnd := idList%A_Index%
        if (IsValidTarget(hwnd))
        {
            SetTargetHWND(hwnd)
            return
        }
    }
}

SetTargetHWND(hwnd) {
    if (!IsValidTarget(hwnd))
        return false

    g_TargetHWND := hwnd
    WinGetTitle, g_TargetTitle, ahk_id %g_TargetHWND%
    WinGet, g_TargetProc, ProcessName, ahk_id %g_TargetHWND%
    WinGet, g_TargetPID, PID, ahk_id %g_TargetHWND%

    if (g_TargetTitle = "")
        g_TargetTitle := "Untitled Window"
    if (g_TargetProc = "")
        g_TargetProc := "Unknown"

    FetchWindowState(g_TargetHWND)
    LoadWindowProfile(g_TargetHWND)

    if (g_GUIisOpen)
        UpdateGUI()

    return true
}

FetchWindowState(hwnd) {
    global
    if (!hwnd || !WinExist("ahk_id " . hwnd))
        return

    WinGet, transVal, Transparent, ahk_id %hwnd%
    if (transVal = "" || transVal = "Off")
        g_Transparency := 255
    else
        g_Transparency := transVal

    WinGet, exStyle, ExStyle, ahk_id %hwnd%
    g_ClickThrough := (exStyle & WS_EX_TRANSPARENT) ? true : false
    g_AlwaysOnTop  := (exStyle & WS_EX_TOPMOST) ? true : false
    g_OverlayMode  := (g_Transparency < 255 && g_ClickThrough)

    ; Check shaded status from tracking map
    if (g_ModifiedWindows.HasKey(hwnd) && g_ModifiedWindows[hwnd].IsShaded)
        g_IsShaded := true
    else
        g_IsShaded := false

    ; Check borderless status
    WinGet, winStyle, Style, ahk_id %hwnd%
    g_IsBorderless := ((winStyle & WS_CAPTION) = 0)
}

RegisterModifiedWindow(hwnd) {
    global
    if (!hwnd || !WinExist("ahk_id " . hwnd))
        return

    WinGetTitle, title, ahk_id %hwnd%
    WinGet, proc, ProcessName, ahk_id %hwnd%
    WinGet, trans, Transparent, ahk_id %hwnd%
    if (trans = "" || trans = "Off")
        trans := 255
    WinGet, exStyle, ExStyle, ahk_id %hwnd%
    isClick := (exStyle & WS_EX_TRANSPARENT) ? true : false
    isTop   := (exStyle & WS_EX_TOPMOST) ? true : false

    isModified := (trans < 255 || isClick || isTop || g_IsShaded || g_IsBorderless)

    if (isModified) {
        if (!g_ModifiedWindows.HasKey(hwnd)) {
            g_ModifiedWindows[hwnd] := {}
            WinGetPos, x, y, w, h, ahk_id %hwnd%
            WinGet, origStyle, Style, ahk_id %hwnd%
            g_ModifiedWindows[hwnd].OrigHeight := h
            g_ModifiedWindows[hwnd].OrigStyle  := origStyle
        }
        g_ModifiedWindows[hwnd].Title        := title
        g_ModifiedWindows[hwnd].Proc         := proc
        g_ModifiedWindows[hwnd].Transparency := trans
        g_ModifiedWindows[hwnd].ClickThrough := isClick
        g_ModifiedWindows[hwnd].AlwaysOnTop  := isTop
        g_ModifiedWindows[hwnd].OverlayMode  := (trans < 255 && isClick)
        g_ModifiedWindows[hwnd].IsShaded     := g_IsShaded
        g_ModifiedWindows[hwnd].IsBorderless := g_IsBorderless
    } else {
        if (g_ModifiedWindows.HasKey(hwnd))
            g_ModifiedWindows.Delete(hwnd)
    }
}

; ==============================================================================
; QUICK ACTIONS & EFFECT IMPLEMENTATIONS
; ==============================================================================

QuickToggleOverlay() {
    global
    if (!IsValidTarget(g_TargetHWND))
        return

    FetchWindowState(g_TargetHWND)
    if (!g_OverlayMode) {
        g_Transparency := (g_Transparency = 255) ? g_DefaultOverlayOpacity : g_Transparency
        WinSet, Transparent, %g_Transparency%, ahk_id %g_TargetHWND%
        WinSet, ExStyle, +%WS_EX_TRANSPARENT%, ahk_id %g_TargetHWND%
        g_ClickThrough := true
        g_OverlayMode  := true
        ShowToast("Transparent Overlay: ON (" . g_Transparency . " alpha)")
    } else {
        g_Transparency := 255
        WinSet, Transparent, 255, ahk_id %g_TargetHWND%
        WinSet, ExStyle, -%WS_EX_TRANSPARENT%, ahk_id %g_TargetHWND%
        g_ClickThrough := false
        g_OverlayMode  := false
        ShowToast("Transparent Overlay: OFF (Normal Window)")
    }
    RegisterModifiedWindow(g_TargetHWND)
    SaveWindowProfile(g_TargetHWND)
    if (g_GUIisOpen)
        UpdateGUI()
}

QuickToggleTransparency() {
    global
    if (!IsValidTarget(g_TargetHWND))
        return

    FetchWindowState(g_TargetHWND)
    if (g_Transparency < 255) {
        g_Transparency := 255
        WinSet, Transparent, 255, ahk_id %g_TargetHWND%
        ShowToast("Opacity: 100% (Solid Opaque)")
    } else {
        g_Transparency := g_DefaultOverlayOpacity
        WinSet, Transparent, %g_Transparency%, ahk_id %g_TargetHWND%
        pct := Round((g_Transparency / 255) * 100)
        ShowToast("Opacity: " . pct . "% (" . g_Transparency . "/255)")
    }
    g_OverlayMode := (g_Transparency < 255 && g_ClickThrough)
    RegisterModifiedWindow(g_TargetHWND)
    SaveWindowProfile(g_TargetHWND)
    if (g_GUIisOpen)
        UpdateGUI()
}

QuickToggleClickThrough() {
    global
    if (!IsValidTarget(g_TargetHWND))
        return

    FetchWindowState(g_TargetHWND)
    if (g_ClickThrough) {
        WinSet, ExStyle, -%WS_EX_TRANSPARENT%, ahk_id %g_TargetHWND%
        g_ClickThrough := false
        ShowToast("Click Passthrough: OFF (Window captures mouse)")
    } else {
        WinSet, ExStyle, +%WS_EX_TRANSPARENT%, ahk_id %g_TargetHWND%
        g_ClickThrough := true
        ShowToast("Click Passthrough: ON (Clicks pass through)")
    }
    g_OverlayMode := (g_Transparency < 255 && g_ClickThrough)
    RegisterModifiedWindow(g_TargetHWND)
    SaveWindowProfile(g_TargetHWND)
    if (g_GUIisOpen)
        UpdateGUI()
}

QuickToggleAlwaysOnTop() {
    global
    if (!IsValidTarget(g_TargetHWND))
        return

    FetchWindowState(g_TargetHWND)
    if (g_AlwaysOnTop) {
        WinSet, AlwaysOnTop, Off, ahk_id %g_TargetHWND%
        g_AlwaysOnTop := false
        ShowToast("Always On Top: OFF")
    } else {
        WinSet, AlwaysOnTop, On, ahk_id %g_TargetHWND%
        g_AlwaysOnTop := true
        ShowToast("Always On Top: PINNED (Floats above other windows)")
    }
    RegisterModifiedWindow(g_TargetHWND)
    SaveWindowProfile(g_TargetHWND)
    if (g_GUIisOpen)
        UpdateGUI()
}

QuickToggleShade() {
    global
    if (!IsValidTarget(g_TargetHWND))
        return

    SysGet, captionH, 4   ; SM_CYCAPTION
    SysGet, borderH, 8    ; SM_CYSIZEFRAME
    shadeH := captionH + (borderH * 2) + 4
    if (shadeH < 32)
        shadeH := 32

    WinGetPos, x, y, w, h, ahk_id %g_TargetHWND%

    if (!g_IsShaded) {
        if (!g_ModifiedWindows.HasKey(g_TargetHWND))
            g_ModifiedWindows[g_TargetHWND] := {}
        g_ModifiedWindows[g_TargetHWND].OrigHeight := h
        WinMove, ahk_id %g_TargetHWND%,,,, w, %shadeH%
        g_IsShaded := true
        ShowToast("Window Collapsed to Titlebar")
    } else {
        origH := 450
        if (g_ModifiedWindows.HasKey(g_TargetHWND) && g_ModifiedWindows[hwnd].OrigHeight > 50)
            origH := g_ModifiedWindows[hwnd].OrigHeight
        WinMove, ahk_id %g_TargetHWND%,,,, w, %origH%
        g_IsShaded := false
        ShowToast("Window Restored (Full Height)")
    }
    RegisterModifiedWindow(g_TargetHWND)
    if (g_GUIisOpen)
        UpdateGUI()
}

QuickToggleBorderless() {
    global
    if (!IsValidTarget(g_TargetHWND))
        return

    WinGet, style, Style, ahk_id %g_TargetHWND%
    if (style & WS_CAPTION) {
        if (!g_ModifiedWindows.HasKey(g_TargetHWND))
            g_ModifiedWindows[g_TargetHWND] := {}
        g_ModifiedWindows[g_TargetHWND].OrigStyle := style
        WinSet, Style, -%WS_CAPTION%, ahk_id %g_TargetHWND%
        WinSet, Style, -%WS_THICKFRAME%, ahk_id %g_TargetHWND%
        g_IsBorderless := true
        ShowToast("Borders Removed (Frameless Window)")
    } else {
        origStyle := (g_ModifiedWindows.HasKey(g_TargetHWND) && g_ModifiedWindows[g_TargetHWND].OrigStyle) ? g_ModifiedWindows[g_TargetHWND].OrigStyle : (WS_CAPTION | WS_THICKFRAME)
        WinSet, Style, +%WS_CAPTION%, ahk_id %g_TargetHWND%
        WinSet, Style, +%WS_THICKFRAME%, ahk_id %g_TargetHWND%
        g_IsBorderless := false
        ShowToast("Borders Restored (Standard Window)")
    }
    WinSet, Redraw,, ahk_id %g_TargetHWND%
    RegisterModifiedWindow(g_TargetHWND)
    if (g_GUIisOpen)
        UpdateGUI()
}

SetWindowOpacity(hwnd, alpha) {
    global
    if (!IsValidTarget(hwnd))
        return

    alpha := (alpha > 255) ? 255 : (alpha < 10 ? 10 : alpha)
    g_Transparency := alpha
    WinSet, Transparent, %g_Transparency%, ahk_id %hwnd%
    g_OverlayMode := (g_Transparency < 255 && g_ClickThrough)
    RegisterModifiedWindow(hwnd)
    SaveWindowProfile(hwnd)
    if (g_GUIisOpen)
        UpdateGUI()
}

AdjustWindowOpacity(hwnd, delta) {
    global
    if (!IsValidTarget(hwnd))
        return

    WinGet, transVal, Transparent, ahk_id %hwnd%
    if (transVal = "" || transVal = "Off")
        transVal := 255

    newVal := transVal + delta
    newVal := (newVal > 255) ? 255 : (newVal < 15 ? 15 : newVal)
    WinSet, Transparent, %newVal%, ahk_id %hwnd%
    pct := Round((newVal / 255) * 100)
    ShowToast("Opacity: " . pct . "% (" . newVal . "/255)")

    if (hwnd = g_TargetHWND) {
        g_Transparency := newVal
        g_OverlayMode := (g_Transparency < 255 && g_ClickThrough)
        if (g_GUIisOpen)
            UpdateGUI()
    }
    RegisterModifiedWindow(hwnd)
    SaveWindowProfile(hwnd)
}

QuickResetCurrent() {
    global
    if (!IsValidTarget(g_TargetHWND))
        return

    ResetSingleWindow(g_TargetHWND)
    DeleteWindowProfile(g_TargetHWND)
    ShowToast("Target window restored to defaults")
    if (g_GUIisOpen)
        UpdateGUI()
}

ResetSingleWindow(hwnd) {
    global
    if (!WinExist("ahk_id " . hwnd))
        return

    ; Restore opacity
    WinSet, Transparent, 255, ahk_id %hwnd%
    WinSet, Transparent, Off, ahk_id %hwnd%

    ; Restore extended styles
    WinSet, ExStyle, -%WS_EX_TRANSPARENT%, ahk_id %hwnd%
    WinSet, ExStyle, -%WS_EX_LAYERED%, ahk_id %hwnd%
    WinSet, AlwaysOnTop, Off, ahk_id %hwnd%

    ; Restore frame & height if modified
    if (g_ModifiedWindows.HasKey(hwnd)) {
        if (g_ModifiedWindows[hwnd].OrigHeight > 50) {
            WinGetPos, x, y, w,, ahk_id %hwnd%
            WinMove, ahk_id %hwnd%,,,, w, % g_ModifiedWindows[hwnd].OrigHeight
        }
        WinSet, Style, +%WS_CAPTION%, ahk_id %hwnd%
        WinSet, Style, +%WS_THICKFRAME%, ahk_id %hwnd%
        WinSet, Redraw,, ahk_id %hwnd%
        g_ModifiedWindows.Delete(hwnd)
    }

    if (hwnd = g_TargetHWND) {
        g_Transparency := 255
        g_ClickThrough := false
        g_OverlayMode  := false
        g_AlwaysOnTop  := false
        g_IsShaded     := false
        g_IsBorderless := false
    }
}

EmergencyResetAll() {
    global
    count := 0
    for hwnd, data in g_ModifiedWindows {
        if (WinExist("ahk_id " . hwnd)) {
            ResetSingleWindow(hwnd)
            count++
        }
    }
    g_ModifiedWindows := {}

    if (IsValidTarget(g_TargetHWND))
        ResetSingleWindow(g_TargetHWND)

    ShowToast("Restored all windows to 100% normal!", 1800)
    if (g_GUIisOpen)
        UpdateGUI()
}

MasterFactoryReset() {
    global
    MsgBox, 36, % AppName . " - Factory Reset", % "Are you sure you want to reset EVERYTHING?`n`nThis will:`n1. Restore all windows on your computer back to 100% normal opacity and borders.`n2. Remove all click passthrough and unpin all windows.`n3. Delete all saved window profiles and reset settings to defaults."
    IfMsgBox, Yes
    {
        EmergencyResetAll()
        if (FileExist(ConfigFile))
            FileDelete, %ConfigFile%
        if (FileExist(A_ScriptDir "\ghost_profiles.ini"))
            FileDelete, %A_ScriptDir%\ghost_profiles.ini

        g_DefaultOverlayOpacity := 200
        g_AutoFollowFocus       := false
        g_MouseWheelOpacity     := true
        g_StartupNotify         := true
        SaveGeneralSettings()
        ShowToast("Factory Reset Complete: Everything restored to defaults", 2500)
        if (g_GUIisOpen)
            UpdateGUI()
    }
}

; ==============================================================================
; WINDOW SNAPPING & GEOMETRY HELPERS
; ==============================================================================

SnapCenter() {
    global
    if (!IsValidTarget(g_TargetHWND))
        return
    SysGet, mon, MonitorWorkArea
    monW := monRight - monLeft
    monH := monBottom - monTop
    WinGetPos,,, w, h, ahk_id %g_TargetHWND%
    newX := monLeft + ((monW - w) // 2)
    newY := monTop + ((monH - h) // 2)
    WinMove, ahk_id %g_TargetHWND%,, newX, newY
    ShowToast("Snapped: Screen Center")
}

SnapCornerPiP(corner) {
    global
    if (!IsValidTarget(g_TargetHWND))
        return
    SysGet, mon, MonitorWorkArea
    pipW := 480
    pipH := 270
    pad  := 20

    if (corner = "TR") {
        x := monRight - pipW - pad
        y := monTop + pad
    } else if (corner = "BR") {
        x := monRight - pipW - pad
        y := monBottom - pipH - pad
    }

    WinMove, ahk_id %g_TargetHWND%,, x, y, pipW, pipH
    WinSet, AlwaysOnTop, On, ahk_id %g_TargetHWND%
    g_AlwaysOnTop := true
    RegisterModifiedWindow(g_TargetHWND)
    ShowToast("Snapped: Picture-in-Picture (" . corner . ")")
    if (g_GUIisOpen)
        UpdateGUI()
}

; ==============================================================================
; CROSSHAIR TARGET PICKER TOOL
; ==============================================================================

StartCrosshairPick() {
    global
    if (g_IsPicking)
        return

    g_IsPicking := true
    if (g_GUIisOpen)
        Gui, Main:Hide

    ; Create a fullscreen transparent overlay with crosshair cursor
    Gui, PickerHUD:Destroy
    Gui, PickerHUD:New, +AlwaysOnTop -Caption +ToolWindow +LastFound
    Gui, PickerHUD:Color, 000000
    WinSet, Transparent, 30
    Gui, PickerHUD:Show, x0 y0 w%A_ScreenWidth% h%A_ScreenHeight%, WindowFX_Picker

    ShowToast("Click ANY window on your screen to select it (Esc to cancel)", 3000)
    SetTimer, CheckPickerClick, 50
}

CheckPickerClick:
    if (!g_IsPicking) {
        SetTimer, CheckPickerClick, Off
        return
    }

    if (GetKeyState("Escape", "P")) {
        g_IsPicking := false
        SetTimer, CheckPickerClick, Off
        Gui, PickerHUD:Destroy
        ShowToast("Picker cancelled")
        if (g_GUIisOpen)
            Gui, Main:Show
        return
    }

    if (GetKeyState("LButton", "P")) {
        g_IsPicking := false
        SetTimer, CheckPickerClick, Off
        Gui, PickerHUD:Destroy
        Sleep, 100
        MouseGetPos,,, clickedHWND
        if (IsValidTarget(clickedHWND)) {
            SetTargetHWND(clickedHWND)
            ShowToast("Target Selected: " . g_TargetProc)
        } else {
            ShowToast("Invalid target window")
        }
        Gui, Main:Show
        g_GUIisOpen := true
        UpdateGUI()
    }
return

; ==============================================================================
; AUTO-FOLLOW ACTIVE FOCUS WATCHER
; ==============================================================================

AutoFollowWatcher:
    if (!g_AutoFollowFocus || g_IsPicking)
        return

    WinGet, curHWND, ID, A
    if (curHWND && curHWND != g_TargetHWND && IsValidTarget(curHWND)) {
        WinGetClass, curClass, ahk_id %curHWND%
        if (curClass != "AutoHotkeyGUI") {
            SetTargetHWND(curHWND)
        }
    }
return

; ==============================================================================
; STREAMLINED MODERN DASHBOARD HUD (Minimalist Dark Design)
; ==============================================================================

ApplyDWMDarkMode(hwnd) {
    val := 1
    DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", hwnd, "Int", 20, "Int*", val, "Int", 4)
    DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", hwnd, "Int", 19, "Int*", val, "Int", 4)
}

OpenControlUI() {
    global
    if (g_GUIisOpen) {
        Gui, Main:Show
        UpdateGUI()
        return
    }

    if (!IsValidTarget(g_TargetHWND))
        TargetActiveWindow()

    ; Build Main GUI with Dark Titlebar & Slate Theme
    Gui, Main:Destroy
    Gui, Main:New, +AlwaysOnTop -DPIScale +HwndhMainGUI +LabelGui, %AppName% %AppVersion% - Dashboard
    Gui, Main:Color, 0F172A, 1E293B
    Gui, Main:Font, s9 cF8FAFC, Segoe UI

    ApplyDWMDarkMode(hMainGUI)

    ; ---- 1. HEADER & CONTROLS ----
    Gui, Main:Font, s11 Bold c38BDF8, Segoe UI
    Gui, Main:Add, Text, x18 y14 w140 h24, WindowFX Pro
    Gui, Main:Font, s8 c64748B, Segoe UI
    Gui, Main:Add, Text, x135 y17 w90 h20, v3.0

    Gui, Main:Font, s9 cF8FAFC, Segoe UI
    Gui, Main:Add, Button, x320 y11 w88 h26 gBtnStartPicker vBtnStartPicker, Pick Win
    Gui, Main:Add, Button, x414 y11 w78 h26 gBtnRefreshList vBtnRefreshList, Refresh
    Gui, Main:Add, Button, x498 y11 w82 h26 gShowHelpModal vBtnHelp, Shortcuts

    ; Target Switcher Dropdown
    Gui, Main:Font, s9 c94A3B8, Segoe UI
    Gui, Main:Add, Text, x18 y44 w50 h20, Target:
    Gui, Main:Font, s9 cF8FAFC, Segoe UI
    Gui, Main:Add, DropDownList, x72 y41 w508 h180 vWinDropdown gOnSelectWindow AltSubmit

    ; ---- 2. TARGET INFORMATION HERO CARD ----
    Gui, Main:Add, Progress, x18 y72 w564 h66 Background1E293B c1E293B Disabled, 100
    Gui, Main:Font, s10 Bold cF8FAFC, Segoe UI
    Gui, Main:Add, Text, x32 y82 w360 h20 +BackgroundTrans vCardTitle, Title: Loading...
    Gui, Main:Font, s8 c94A3B8, Segoe UI
    Gui, Main:Add, Text, x32 y106 w360 h18 +BackgroundTrans vCardProc, Process: None  |  HWND: 0x0  |  PID: 0

    Gui, Main:Font, s9 Bold c38BDF8, Segoe UI
    Gui, Main:Add, Text, x396 y82 w170 h20 Right +BackgroundTrans vCardBadges, [ OPAQUE ]
    Gui, Main:Font, s8 c10B981, Segoe UI
    Gui, Main:Add, Text, x396 y106 w170 h18 Right +BackgroundTrans vCardSubStatus, READY

    ; ---- 3. OPACITY SECTION ----
    Gui, Main:Add, Progress, x18 y146 w564 h86 Background1E293B c1E293B Disabled, 100
    Gui, Main:Font, s8 Bold c64748B, Segoe UI
    Gui, Main:Add, Text, x32 y156 w180 h16 +BackgroundTrans, WINDOW OPACITY
    Gui, Main:Font, s11 Bold c38BDF8, Segoe UI
    Gui, Main:Add, Text, x440 y152 w126 h22 Right +BackgroundTrans vTransText, 100`% (255)

    Gui, Main:Font, s9 cF8FAFC, Segoe UI
    Gui, Main:Add, Slider, x32 y174 w534 h26 vTransSlider Range10-255 TickInterval25 AltSubmit gOnSliderChange, %g_Transparency%

    ; Direct Presets Row (Exact 564px symmetric grid)
    Gui, Main:Font, s8 cF8FAFC, Segoe UI
    Gui, Main:Add, Button, x32 y200 w64 h22 gBtnPreset25 vBtnPreset25, 25`%
    Gui, Main:Add, Button, x+6 y200 w64 h22 gBtnPreset50 vBtnPreset50, 50`%
    Gui, Main:Add, Button, x+6 y200 w64 h22 gBtnPreset75 vBtnPreset75, 75`%
    Gui, Main:Add, Button, x+6 y200 w90 h22 gBtnPreset100 vBtnPreset100, 100`% Solid
    Gui, Main:Add, Button, x+14 y200 w48 h22 gBtnStepMinus5 vBtnStepMinus5, -5`%
    Gui, Main:Add, Button, x+6 y200 w48 h22 gBtnStepPlus5 vBtnStepPlus5, +5`%
    Gui, Main:Add, Button, x+14 y200 w112 h22 gBtnResetTarget vBtnResetTarget, Reset Opacity

    ; ---- 4. CORE EFFECTS GRID (2x2 Clean Action Blocks) ----
    Gui, Main:Font, s9 Bold cF8FAFC, Segoe UI
    Gui, Main:Add, Button, x18 y240 w274 h46 gBtnToggleOverlay vBtnOverlay, Transparent Overlay`n(Opacity + Click Passthrough)
    Gui, Main:Add, Button, x300 y240 w274 h46 gBtnToggleClick vBtnClick, Click Passthrough`n(Clicks Pass Through Window)

    Gui, Main:Add, Button, x18 y292 w274 h46 gBtnToggleTopmost vBtnTopmost, Pin On Top`n(Keep Window Above All)
    Gui, Main:Add, Button, x300 y292 w274 h46 gBtnToggleShade vBtnShade, Collapse Titlebar`n(Roll-Up Window Height)

    ; ---- 5. QUICK GEOMETRY STRIP ----
    Gui, Main:Font, s8 cF8FAFC, Segoe UI
    Gui, Main:Add, Button, x18 y346 w134 h30 gBtnToggleBorder vBtnBorder, Remove Borders
    Gui, Main:Add, Button, x160 y346 w134 h30 gBtnSnapCenter vBtnSnapCenter, Center Window
    Gui, Main:Add, Button, x302 y346 w134 h30 gBtnSnapPiPTR vBtnSnapPiPTR, Top-Right PiP
    Gui, Main:Add, Button, x444 y346 w138 h30 gBtnSnapPiPBR vBtnSnapPiPBR, Bot-Right PiP

    ; ---- 6. NAVIGATION & FOOTER ----
    Gui, Main:Font, s8 c64748B, Segoe UI
    Gui, Main:Add, Text, x18 y388 w564 h18 vStatusText, Ready | Hotkeys: Ctrl+Alt+E (Menu) | Ctrl+Alt+G (Overlay) | Ctrl+Alt+Scroll

    Gui, Main:Font, s8 cF8FAFC, Segoe UI
    Gui, Main:Add, Button, x18 y412 w134 h32 gShowActiveWindowsModal vBtnActiveList, Active Windows
    Gui, Main:Add, Button, x160 y412 w150 h32 gShowSettingsModal vBtnSettings, Settings and Auto

    Gui, Main:Add, Button, x360 y412 w106 h32 gGuiClose, Minimize
    Gui, Main:Add, Button, x474 y412 w108 h32 gCleanExitApp, Exit App

    ; Populate initial list and update
    PopulateWindowDropdown()
    UpdateGUI()

    Gui, Main:Show, Center AutoSize
    g_GUIisOpen := true
}

; ==============================================================================
; HOVER TOOLTIP ENGINE (Real-Time Interactive Hints)
; ==============================================================================

WM_MOUSEMOVE(wParam, lParam, msg, hwnd) {
    static prevHwnd := 0
    static ToolTipTexts := { "BtnStartPicker": "Pick Window`nClick this, then click ANY window on your screen to select and control it."
                           , "BtnRefreshList": "Refresh`nReloads the list of all open desktop applications."
                           , "BtnHelp": "Shortcuts and Guide`nOpens the full shortcut table and emergency recovery guide."
                           , "WinDropdown": "Target Window Dropdown`nSelect any running application from the list to control."
                           , "TransSlider": "Opacity Slider`nDrag to smoothly adjust transparency from 10 to 255 alpha."
                           , "BtnPreset25": "25% Opacity`nQuarter transparency."
                           , "BtnPreset50": "50% Opacity`nHalf transparent overlay."
                           , "BtnPreset75": "75% Opacity`nHigh readability translucent overlay."
                           , "BtnPreset100": "100% Opacity`nFully opaque solid window."
                           , "BtnStepMinus5": "Decrease opacity by 5%."
                           , "BtnStepPlus5": "Increase opacity by 5%."
                           , "BtnOverlay": "Transparent Overlay (Ctrl+Alt+G)`nSimultaneously applies transparency and click passthrough."
                           , "BtnClick": "Click Passthrough (Ctrl+Alt+C)`nClicks, scrolls, and mouse input pass straight through to whatever is beneath."
                           , "BtnTopmost": "Pin On Top (Ctrl+Alt+P)`nPins this window floating above all background applications."
                           , "BtnShade": "Collapse Titlebar (Ctrl+Alt+S)`nCollapses the window into just its titlebar to save screen space."
                           , "BtnBorder": "Remove Borders`nStrips window titlebars and borders for clean video / HUD overlays."
                           , "BtnSnapCenter": "Center Window`nMoves this window to the center of your monitor."
                           , "BtnSnapPiPTR": "Top-Right PiP`nSnaps window into a compact 480x270 Picture-in-Picture card at top-right."
                           , "BtnSnapPiPBR": "Bottom-Right PiP`nSnaps window into a compact 480x270 Picture-in-Picture card at bottom-right."
                           , "BtnResetTarget": "Reset Opacity`nRestores this window to 100% solid opacity."
                           , "BtnActiveList": "Active Windows`nView all modified windows on your system in a clean table."
                           , "BtnSettings": "Settings and Auto`nConfigure Windows Startup, auto-follow focus, and preferences." }

    if (hwnd = prevHwnd)
        return
    prevHwnd := hwnd

    MouseGetPos,,,, ctrlVar
    if (ToolTipTexts.HasKey(ctrlVar)) {
        ToolTip, % ToolTipTexts[ctrlVar]
        SetTimer, RemoveToolTip, -3000
    } else {
        ToolTip
    }
}

RemoveToolTip:
    ToolTip
return

; ==============================================================================
; DEDICATED MODAL: ACTIVE WINDOWS MANAGER
; ==============================================================================

ShowActiveWindowsModal() {
    global

    Gui, ActiveModal:Destroy
    Gui, ActiveModal:New, +AlwaysOnTop -DPIScale +HwndhActGUI +LabelActiveModal, %AppName% - Active Windows Manager
    Gui, ActiveModal:Color, 0F172A, 1E293B
    Gui, ActiveModal:Font, s9 cF8FAFC, Segoe UI

    ApplyDWMDarkMode(hActGUI)

    Gui, ActiveModal:Font, s10 Bold c38BDF8, Segoe UI
    Gui, ActiveModal:Add, Text, x18 y14 w520 h22, Active Modified Windows
    Gui, ActiveModal:Font, s8 c94A3B8, Segoe UI
    Gui, ActiveModal:Add, Text, x18 y36 w520 h18, All applications currently modified with transparency, pinning, or passthrough:

    Gui, ActiveModal:Font, s9 cF8FAFC, Segoe UI
    Gui, ActiveModal:Add, ListView, x18 y60 w540 h220 vModalActiveList +Grid -Multi gOnActiveModalClick, HWND|Process|Title|Opacity|ClickThru|TopMost|Shaded
    LV_ModifyCol(1, 70)
    LV_ModifyCol(2, 95)
    LV_ModifyCol(3, 170)
    LV_ModifyCol(4, 55)
    LV_ModifyCol(5, 55)
    LV_ModifyCol(6, 50)
    LV_ModifyCol(7, 45)

    for hwnd, data in g_ModifiedWindows {
        if (WinExist("ahk_id " . hwnd)) {
            pct := Round((data.Transparency / 255) * 100) . "%"
            clickStr := data.ClickThrough ? "ON" : "OFF"
            topStr   := data.AlwaysOnTop ? "ON" : "OFF"
            shadeStr := data.IsShaded ? "YES" : "NO"
            hwndHex  := Format("0x{:X}", hwnd)
            LV_Add("", hwndHex, data.Proc, data.Title, pct, clickStr, topStr, shadeStr)
        }
    }

    Gui, ActiveModal:Font, s8 cF8FAFC, Segoe UI
    Gui, ActiveModal:Add, Button, x18 y290 w126 h32 gBtnModalFocusSelected, Focus Window
    Gui, ActiveModal:Add, Button, x+8 y290 w126 h32 gBtnModalResetSelected, Reset Selected
    Gui, ActiveModal:Add, Button, x+8 y290 w138 h32 gBtnModalEmergencyReset, Reset ALL Windows
    Gui, ActiveModal:Add, Button, x+8 y290 w126 h32 gActiveModalClose Default, Close (Esc)

    Gui, ActiveModal:Show, Center AutoSize
}

ActiveModalClose:
ActiveModalEscape:
    Gui, ActiveModal:Destroy
return

OnActiveModalClick:
    if (A_GuiEvent = "DoubleClick") {
        rowNum := LV_GetNext(0, "Focused")
        if (rowNum > 0) {
            LV_GetText(hexHWND, rowNum, 1)
            targetNum := hexHWND + 0
            if (IsValidTarget(targetNum)) {
                SetTargetHWND(targetNum)
                WinActivate, ahk_id %targetNum%
                Gui, ActiveModal:Destroy
                if (g_GUIisOpen)
                    UpdateGUI()
            }
        }
    }
return

BtnModalFocusSelected:
    Gui, ActiveModal:ListView, ModalActiveList
    rowNum := LV_GetNext(0, "Focused")
    if (rowNum > 0) {
        LV_GetText(hexHWND, rowNum, 1)
        targetNum := hexHWND + 0
        if (IsValidTarget(targetNum)) {
            SetTargetHWND(targetNum)
            WinActivate, ahk_id %targetNum%
            Gui, ActiveModal:Destroy
            if (g_GUIisOpen)
                UpdateGUI()
        }
    }
return

BtnModalResetSelected:
    Gui, ActiveModal:ListView, ModalActiveList
    rowNum := LV_GetNext(0, "Focused")
    if (rowNum > 0) {
        LV_GetText(hexHWND, rowNum, 1)
        targetNum := hexHWND + 0
        ResetSingleWindow(targetNum)
        DeleteWindowProfile(targetNum)
        Gui, ActiveModal:Destroy
        ShowActiveWindowsModal()
        if (g_GUIisOpen)
            UpdateGUI()
    }
return

BtnModalEmergencyReset:
    EmergencyResetAll()
    Gui, ActiveModal:Destroy
return

; ==============================================================================
; DEDICATED MODAL: SETTINGS & PREFERENCES
; ==============================================================================

ShowSettingsModal() {
    global

    Gui, SettingsModal:Destroy
    Gui, SettingsModal:New, +AlwaysOnTop -DPIScale +HwndhSetGUI +LabelSettingsModal, %AppName% - Settings and Automation
    Gui, SettingsModal:Color, 0F172A, 1E293B
    Gui, SettingsModal:Font, s9 cF8FAFC, Segoe UI

    ApplyDWMDarkMode(hSetGUI)

    Gui, SettingsModal:Font, s10 Bold c38BDF8, Segoe UI
    Gui, SettingsModal:Add, Text, x18 y14 w480 h22, Settings and Automation
    Gui, SettingsModal:Font, s8 c94A3B8, Segoe UI
    Gui, SettingsModal:Add, Text, x18 y36 w480 h18, Configure system startup, focus tracking, and background behavior:

    isStart := IsStartupEnabled()
    Gui, SettingsModal:Font, s9 cF8FAFC, Segoe UI
    Gui, SettingsModal:Add, CheckBox, x24 y66 w480 h22 vSettingStartup gOnSettingStartup Checked%isStart%, Run WindowFX automatically on Windows Startup
    Gui, SettingsModal:Add, CheckBox, x24 y92 w480 h22 vSettingFollow gOnSettingFollow Checked%g_AutoFollowFocus%, Auto-Follow Focus (Dynamically track whichever window you click)
    Gui, SettingsModal:Add, CheckBox, x24 y118 w480 h22 vSettingWheel gOnSettingWheel Checked%g_MouseWheelOpacity%, Enable Ctrl+Alt+Scroll live mouse wheel opacity over any window
    Gui, SettingsModal:Add, CheckBox, x24 y144 w480 h22 vSettingNotify gOnSettingNotify Checked%g_StartupNotify%, Show notification popup when starting in background
    Gui, SettingsModal:Add, CheckBox, x24 y170 w480 h22 vSettingSuspend gOnSettingSuspend Checked%g_HotkeysSuspended%, Pause all hotkeys (Useful for gaming or precision apps)

    ; Overlay Alpha slider
    Gui, SettingsModal:Font, s8 Bold c64748B, Segoe UI
    Gui, SettingsModal:Add, Text, x24 y204 w200 h16, DEFAULT OVERLAY OPACITY
    Gui, SettingsModal:Font, s9 Bold c38BDF8, Segoe UI
    Gui, SettingsModal:Add, Text, x380 y202 w120 h18 Right vSetOverlayText, %g_DefaultOverlayOpacity% / 255

    Gui, SettingsModal:Font, s9 cF8FAFC, Segoe UI
    Gui, SettingsModal:Add, Slider, x24 y222 w480 h26 vSetOverlaySlider Range50-255 TickInterval25 AltSubmit gOnSetOverlaySliderChange, %g_DefaultOverlayOpacity%

    Gui, SettingsModal:Font, s8 cF8FAFC, Segoe UI
    Gui, SettingsModal:Add, Button, x24 y260 w150 h32 gBtnClearAllProfiles, Clear Saved Profiles
    Gui, SettingsModal:Add, Button, x+12 y260 w150 h32 gBtnOpenConfigFile, Open Config File
    Gui, SettingsModal:Add, Button, x+12 y260 w156 h32 gSettingsModalClose Default, Save and Close (Esc)

    Gui, SettingsModal:Show, Center AutoSize
}

SettingsModalClose:
SettingsModalEscape:
    Gui, SettingsModal:Destroy
return

OnSettingStartup:
    GuiControlGet, isChecked, SettingsModal:, SettingStartup
    SetStartup(isChecked)
    if (isChecked)
        Menu, Tray, Check, Run on Windows Startup
    else
        Menu, Tray, Uncheck, Run on Windows Startup
    ShowToast(isChecked ? "Startup enabled" : "Startup disabled")
return

OnSettingFollow:
    GuiControlGet, isChecked, SettingsModal:, SettingFollow
    g_AutoFollowFocus := isChecked
    IniWrite, % (g_AutoFollowFocus ? 1 : 0), %ConfigFile%, General, AutoFollowFocus
    if (g_AutoFollowFocus) {
        SetTimer, AutoFollowWatcher, On
        Menu, Tray, Check, Auto-Follow Active Focus
        ShowToast("Auto-Follow Focus: ON")
    } else {
        SetTimer, AutoFollowWatcher, Off
        Menu, Tray, Uncheck, Auto-Follow Active Focus
        ShowToast("Auto-Follow Focus: OFF")
    }
return

OnSettingWheel:
    GuiControlGet, isChecked, SettingsModal:, SettingWheel
    g_MouseWheelOpacity := isChecked
    IniWrite, % (g_MouseWheelOpacity ? 1 : 0), %ConfigFile%, General, MouseWheelOpacity
    ShowToast(g_MouseWheelOpacity ? "Mouse wheel opacity enabled" : "Mouse wheel opacity disabled")
return

OnSettingNotify:
    GuiControlGet, isChecked, SettingsModal:, SettingNotify
    g_StartupNotify := isChecked
    IniWrite, % (g_StartupNotify ? 1 : 0), %ConfigFile%, General, StartupNotification
return

OnSettingSuspend:
    ToggleHotkeySuspend()
return

OnSetOverlaySliderChange:
    GuiControlGet, sliderVal, SettingsModal:, SetOverlaySlider
    g_DefaultOverlayOpacity := sliderVal
    GuiControl, SettingsModal:, SetOverlayText, % g_DefaultOverlayOpacity . " / 255"
    IniWrite, %g_DefaultOverlayOpacity%, %ConfigFile%, General, DefaultOverlayOpacity
return

; ==============================================================================
; DEDICATED MODAL: QUICK GUIDE & SHORTCUTS (Expanded & Unclipped)
; ==============================================================================

ShowHelpModal() {
    global

    Gui, HelpModal:Destroy
    Gui, HelpModal:New, +AlwaysOnTop -DPIScale +HwndhHelpGUI +LabelHelpModal, %AppName% - Complete Feature and Shortcuts Guide
    Gui, HelpModal:Color, 0F172A, 1E293B
    Gui, HelpModal:Font, s9 cF8FAFC, Segoe UI

    ApplyDWMDarkMode(hHelpGUI)

    Gui, HelpModal:Font, s11 Bold c38BDF8, Segoe UI
    Gui, HelpModal:Add, Text, x18 y14 w740 h22, %AppName% %AppVersion% - Complete Feature & Shortcuts Guide
    Gui, HelpModal:Font, s8 c94A3B8, Segoe UI
    Gui, HelpModal:Add, Text, x18 y36 w740 h18, Scroll to view full instructions, hotkeys, mouse gestures, geometry framing, and emergency recovery:

    ; Comprehensive Scrollable Table (Full Width, Unclipped Columns)
    Gui, HelpModal:Font, s9 cF8FAFC, Segoe UI
    Gui, HelpModal:Add, ListView, x18 y60 w740 h340 +Grid -Multi +HScroll +VScroll, Shortcut / Control|Feature Name|Full Action and Behavior Description
    LV_ModifyCol(1, 160)
    LV_ModifyCol(2, 170)
    LV_ModifyCol(3, 385)

    LV_Add("", "Ctrl + Alt + E", "Open Controller GUI", "Opens or retargets the WindowFX dashboard for the active window.")
    LV_Add("", "Ctrl + Alt + G", "Transparent Overlay", "Applies 200/255 transparency and enables click-through passthrough simultaneously.")
    LV_Add("", "Ctrl + Alt + T", "Toggle Opacity", "Cycles window opacity between 100% solid and default 200/255 alpha.")
    LV_Add("", "Ctrl + Alt + C", "Click Passthrough", "Makes window click-invisible so all clicks pass directly to applications beneath.")
    LV_Add("", "Ctrl + Alt + P", "Pin On Top", "Pins the active window permanently floating above all background applications.")
    LV_Add("", "Ctrl + Alt + S", "Collapse Titlebar", "Collapses window down to only its titlebar height (Roll-Up Shade mode).")
    LV_Add("", "Ctrl + Alt + R", "Reset Window", "Restores active window back to 100% solid opacity and normal styles.")
    LV_Add("", "Ctrl + Alt + WheelUp", "Live Opacity +15", "Hover mouse over any window and scroll wheel up to increase opacity live.")
    LV_Add("", "Ctrl + Alt + WheelDn", "Live Opacity -15", "Hover mouse over any window and scroll wheel down to decrease opacity live.")
    LV_Add("", "Ctrl+Alt+Shift+S", "Pause All Hotkeys", "Temporarily disables all shortcuts (useful for gaming, Photoshop, or 3D editing).")
    LV_Add("", "Ctrl+Alt+Shift+Esc", "EMERGENCY RESET ALL", "Instantly restores EVERY window on your computer back to 100% normal appearance.")
    LV_Add("", "Ctrl+Alt+Shift+R", "Reload WindowFX", "Reloads the script environment and clears transient runtime state.")
    LV_Add("", "[ Pick Win ] Button", "Crosshair Window Picker", "Click anywhere on any monitor to visually select and lock onto that target window.")
    LV_Add("", "[ Remove Borders ]", "Frameless Window", "Strips titlebars and sizing frames for clean video overlays and HUDs.")
    LV_Add("", "[ Center Window ]", "Screen Center Snap", "Repositions target window directly into the middle of your active screen.")
    LV_Add("", "[ Top/Bot PiP ]", "Picture-in-Picture Snap", "Snaps window into a compact 480x270 floating PiP card at screen corner.")
    LV_Add("", "[ Active Windows ]", "Active Windows Manager", "Opens a dedicated live table of all modified windows with 1-click batch controls.")
    LV_Add("", "[ Settings & Auto ]", "Automation & Startup", "Configure Windows Startup, auto-follow focus tracking, and saved profiles.")

    Gui, HelpModal:Add, Button, x18 y410 w210 h32 gBtnHelpEmergencyReset, Reset ALL Windows (100`%)
    Gui, HelpModal:Add, Button, x+10 y410 w220 h32 gBtnHelpFactoryReset, Master Factory Reset All
    Gui, HelpModal:Add, Button, x+180 y410 w120 h32 gHelpModalClose Default, Close (Esc)

    Gui, HelpModal:Show, Center AutoSize
}

HelpModalClose:
HelpModalEscape:
    Gui, HelpModal:Destroy
return

BtnHelpEmergencyReset:
    EmergencyResetAll()
return

BtnHelpFactoryReset:
    MasterFactoryReset()
return

; ==============================================================================
; GUI REFRESH & DATA SYNC
; ==============================================================================

PopulateWindowDropdown() {
    global
    g_WindowListHwnds := []
    dropdownList := ""
    selectedIdx := 1

    WinGet, idList, List,,, Program Manager
    matchCount := 0

    Loop, %idList%
    {
        hwnd := idList%A_Index%
        if (!IsValidTarget(hwnd))
            continue

        WinGetTitle, title, ahk_id %hwnd%
        WinGet, proc, ProcessName, ahk_id %hwnd%

        if (title = "" || proc = "")
            continue

        cleanTitle := (StrLen(title) > 36) ? SubStr(title, 1, 36) . "..." : title
        StringReplace, cleanTitle, cleanTitle, |, -, All
        entry := proc . " - " . cleanTitle

        matchCount++
        g_WindowListHwnds.Push(hwnd)
        dropdownList .= entry . "|"

        if (hwnd = g_TargetHWND)
            selectedIdx := matchCount
    }

    GuiControl, Main:, WinDropdown, |%dropdownList%
    GuiControl, Main:Choose, WinDropdown, %selectedIdx%
}

UpdateGUI() {
    global
    if (!g_GUIisOpen)
        return

    FetchWindowState(g_TargetHWND)

    ; Target Header Card
    displayTitle := (g_TargetTitle != "") ? g_TargetTitle : "No Active Window Selected"
    if (StrLen(displayTitle) > 38)
        displayTitle := SubStr(displayTitle, 1, 38) . "..."
    displayProc := (g_TargetProc != "") ? g_TargetProc : "None"

    GuiControl, Main:, CardTitle, % "Title: " . displayTitle
    GuiControl, Main:, CardProc, % "Process: " . displayProc . "  |  HWND: " . Format("0x{:X}", g_TargetHWND) . "  |  PID: " . g_TargetPID

    ; Build Badges
    badges := ""
    if (g_OverlayMode)
        badges .= "[ OVERLAY ] "
    else if (g_Transparency < 255)
        badges .= "[ " . Round((g_Transparency/255)*100) . "% ALPHA ] "
    else
        badges .= "[ OPAQUE ] "

    if (g_ClickThrough)
        badges .= "[ PASSTHROUGH ] "
    if (g_AlwaysOnTop)
        badges .= "[ PINNED ] "
    if (g_IsShaded)
        badges .= "[ SHADED ] "
    if (g_IsBorderless)
        badges .= "[ BORDERLESS ]"

    GuiControl, Main:, CardBadges, %badges%

    ; Sub-status
    subStatus := ""
    if (g_AlwaysOnTop)
        subStatus .= "PINNED TOP  "
    if (g_ClickThrough)
        subStatus .= "CLICK PASSTHROUGH  "
    if (subStatus = "")
        subStatus := "NORMAL FOCUS"
    GuiControl, Main:, CardSubStatus, %subStatus%

    ; Opacity Slider & Text
    GuiControl, Main:, TransSlider, %g_Transparency%
    pct := Round((g_Transparency / 255) * 100)
    GuiControl, Main:, TransText, % pct . "% (" . g_Transparency . ")"

    ; Highlight dropdown selection if matched
    For idx, hwnd in g_WindowListHwnds {
        if (hwnd = g_TargetHWND) {
            GuiControl, Main:Choose, WinDropdown, %idx%
            break
        }
    }
}

; ==============================================================================
; GUI EVENT HANDLERS & CALLBACKS
; ==============================================================================

OnSelectWindow:
    GuiControlGet, chosenIdx, Main:, WinDropdown
    if (chosenIdx > 0 && chosenIdx <= g_WindowListHwnds.Length()) {
        newHWND := g_WindowListHwnds[chosenIdx]
        if (IsValidTarget(newHWND)) {
            SetTargetHWND(newHWND)
            ShowToast("Switched Target: " . g_TargetProc)
        }
    }
return

OnSliderChange:
    GuiControlGet, sliderVal, Main:, TransSlider
    SetWindowOpacity(g_TargetHWND, sliderVal)
return

BtnStartPicker:
    StartCrosshairPick()
return

BtnRefreshList:
    PopulateWindowDropdown()
    UpdateGUI()
    ShowToast("Window list refreshed")
return

BtnPreset25:
    SetWindowOpacity(g_TargetHWND, 64)
return
BtnPreset50:
    SetWindowOpacity(g_TargetHWND, 128)
return
BtnPreset75:
    SetWindowOpacity(g_TargetHWND, 191)
return
BtnPreset100:
    SetWindowOpacity(g_TargetHWND, 255)
return

BtnStepMinus5:
    AdjustWindowOpacity(g_TargetHWND, -13)
return
BtnStepPlus5:
    AdjustWindowOpacity(g_TargetHWND, 13)
return

BtnToggleOverlay:
    QuickToggleOverlay()
return

BtnToggleClick:
    QuickToggleClickThrough()
return

BtnToggleTopmost:
    QuickToggleAlwaysOnTop()
return

BtnToggleShade:
    QuickToggleShade()
return

BtnToggleBorder:
    QuickToggleBorderless()
return

BtnSnapCenter:
    SnapCenter()
return

BtnSnapPiPTR:
    SnapCornerPiP("TR")
return

BtnSnapPiPBR:
    SnapCornerPiP("BR")
return

BtnResetTarget:
    SetWindowOpacity(g_TargetHWND, 255)
    ShowToast("Opacity reset to 100%")
return

BtnClearAllProfiles:
    MsgBox, 36, %AppName%, Are you sure you want to clear all saved application profiles?
    IfMsgBox, Yes
    {
        if (FileExist(ConfigFile))
            FileDelete, %ConfigFile%
        SaveGeneralSettings()
        ShowToast("All saved profiles cleared")
    }
return

BtnOpenConfigFile:
    if (!FileExist(ConfigFile))
        SaveGeneralSettings()
    Run, notepad.exe "%ConfigFile%"
return

GuiClose:
GuiEscape:
    Gui, Main:Hide
    g_GUIisOpen := false
return

; ==============================================================================
; SETTINGS & PERSISTENCE (window_profiles.ini)
; ==============================================================================

LoadGeneralSettings() {
    global
    if (!FileExist(ConfigFile)) {
        SaveGeneralSettings()
        return
    }

    IniRead, valOverlay, %ConfigFile%, General, DefaultOverlayOpacity, 200
    IniRead, valFollow,  %ConfigFile%, General, AutoFollowFocus, 0
    IniRead, valWheel,   %ConfigFile%, General, MouseWheelOpacity, 1
    IniRead, valNotify,  %ConfigFile%, General, StartupNotification, 1

    g_DefaultOverlayOpacity := (valOverlay != "") ? valOverlay : 200
    g_AutoFollowFocus       := (valFollow = "1")
    g_MouseWheelOpacity     := (valWheel != "0")
    g_StartupNotify         := (valNotify != "0")
}

SaveGeneralSettings() {
    global
    IniWrite, %g_DefaultOverlayOpacity%, %ConfigFile%, General, DefaultOverlayOpacity
    IniWrite, % (g_AutoFollowFocus ? 1 : 0), %ConfigFile%, General, AutoFollowFocus
    IniWrite, % (g_MouseWheelOpacity ? 1 : 0), %ConfigFile%, General, MouseWheelOpacity
    IniWrite, % (g_StartupNotify ? 1 : 0), %ConfigFile%, General, StartupNotification
}

SaveWindowProfile(hwnd) {
    global
    if (!IsValidTarget(hwnd))
        return

    WinGet, procName, ProcessName, ahk_id %hwnd%
    if (procName = "")
        return

    IniWrite, %g_Transparency%, %ConfigFile%, %procName%, Transparency
    IniWrite, % (g_ClickThrough ? 1 : 0), %ConfigFile%, %procName%, ClickThrough
    IniWrite, % (g_AlwaysOnTop ? 1 : 0), %ConfigFile%, %procName%, AlwaysOnTop
}

LoadWindowProfile(hwnd) {
    global
    if (!IsValidTarget(hwnd))
        return

    WinGet, procName, ProcessName, ahk_id %hwnd%
    if (procName = "" || !FileExist(ConfigFile))
        return

    IniRead, savedTrans, %ConfigFile%, %procName%, Transparency, %A_Space%
    IniRead, savedClick, %ConfigFile%, %procName%, ClickThrough, %A_Space%
    IniRead, savedTop,   %ConfigFile%, %procName%, AlwaysOnTop,  %A_Space%

    if (savedTrans != "") {
        g_Transparency := savedTrans
        WinSet, Transparent, %g_Transparency%, ahk_id %hwnd%
    }
    if (savedClick = "1") {
        WinSet, ExStyle, +%WS_EX_TRANSPARENT%, ahk_id %hwnd%
        g_ClickThrough := true
    }
    if (savedTop = "1") {
        WinSet, AlwaysOnTop, On, ahk_id %hwnd%
        g_AlwaysOnTop := true
    }
    g_OverlayMode := (g_Transparency < 255 && g_ClickThrough)
    RegisterModifiedWindow(hwnd)
}

DeleteWindowProfile(hwnd) {
    global
    WinGet, procName, ProcessName, ahk_id %hwnd%
    if (procName != "" && FileExist(ConfigFile))
        IniDelete, %ConfigFile%, %procName%
}

; ==============================================================================
; WINDOWS STARTUP MANAGER
; ==============================================================================

GetStartupShortcutPath() {
    return A_Startup . "\WindowFX_Controller.lnk"
}

IsStartupEnabled() {
    shortcutPath := GetStartupShortcutPath()
    if (FileExist(shortcutPath))
        return true
    oldPath := A_Startup . "\windows_fx_menu - Shortcut.lnk"
    if (FileExist(oldPath))
        return true
    return false
}

SetStartup(enable) {
    shortcutPath := GetStartupShortcutPath()
    oldPath := A_Startup . "\windows_fx_menu - Shortcut.lnk"

    if (enable) {
        targetScript := A_ScriptFullPath
        workingDir   := A_ScriptDir
        FileCreateShortcut, %targetScript%, %shortcutPath%, %workingDir%,, WindowFX Background Controller
    } else {
        if (FileExist(shortcutPath))
            FileDelete, %shortcutPath%
        if (FileExist(oldPath))
            FileDelete, %oldPath%
    }
}

; ==============================================================================
; HUD TOAST NOTIFICATION (Lightweight, Non-Activating Glass HUD)
; ==============================================================================

ShowToast(msg, duration := 0) {
    global g_ToastDuration
    dur := (duration > 0) ? duration : g_ToastDuration

    Gui, Toast:Destroy
    Gui, Toast:New, +AlwaysOnTop -Caption +ToolWindow +E0x08000000 +LastFound, WindowFX_Toast
    Gui, Toast:Color, 0F172A
    Gui, Toast:Font, s10 Bold c38BDF8, Segoe UI
    Gui, Toast:Add, Text, x16 y10 cF8FAFC, %msg%

    SysGet, mon, MonitorWorkArea
    toastW := 340
    toastH := 56
    toastX := monRight - toastW - 24
    toastY := monBottom - toastH - 24

    Gui, Toast:Show, x%toastX% y%toastY% AutoSize NoActivate
    WinSet, Transparent, 230, WindowFX_Toast

    SetTimer, HideToast, % -dur
}

HideToast:
    Gui, Toast:Destroy
return

; ==============================================================================
; CLEAN SHUTDOWN HANDLER
; ==============================================================================

CleanExitHandler(ExitReason, ExitCode) {
    global
    Gui, PickerHUD:Destroy
    Gui, Toast:Destroy
    Gui, HelpModal:Destroy
    Gui, ActiveModal:Destroy
    Gui, SettingsModal:Destroy
    SetTimer, AutoFollowWatcher, Off
    SetTimer, CheckPickerClick, Off
    return 0
}