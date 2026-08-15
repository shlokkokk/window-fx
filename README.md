# WindowFX Pro (`window-fx`)

> **Surgical window transparency, dynamic multi-window targeting, click-through overlays, and HUD mode for Windows.**  
> Turn any application into a sleek, non-intrusive heads-up display with seamless mouse passthrough, multi-window management, and per-app persistence.

[![GitHub Repo](https://img.shields.io/badge/GitHub-shlokkokk%2Fwindow--fx-181717?style=flat-square&logo=github)](https://github.com/shlokkokk/window-fx)
[![Platform: Windows](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011-0078D6?style=flat-square&logo=windows)](https://www.microsoft.com/windows)
[![AutoHotkey v1.1+](https://img.shields.io/badge/AutoHotkey-v1.1%2B-334455?style=flat-square&logo=autohotkey)](https://www.autohotkey.com/)
[![Memory Footprint](https://img.shields.io/badge/Footprint-%3C15MB%20RAM-brightgreen?style=flat-square)](https://github.com/shlokkokk/window-fx)
[![Zero Dependencies](https://img.shields.io/badge/Dependencies-None-orange?style=flat-square)](https://github.com/shlokkokk/window-fx)

---

## Overview

**WindowFX Pro** is an ultra-lightweight Windows utility that gives you instant, granular control over any window's opacity, click-through layer, geometry, and presentation.

Whether you want to turn a browser window into a click-through tracing reference, float transparent terminal logs over your IDE, collapse reference windows to their titlebars with roll-up shading, strip borders for frameless video overlays, or dynamically manage multiple floating windows, WindowFX handles it all via global hotkeys, mouse-wheel opacity gestures, or a sleek dark control dashboard.

```
┌──────────────────────────────────────────────────────────────────────────┐
│ WindowFX Pro v3.0 - Dashboard                  [ Pick Win ] [ Refresh ] [ Shortcuts ]│
├──────────────────────────────────────────────────────────────────────────┤
│ Target: [ Code.exe - Visual Studio Code                             ▼ ]  │
│                                                                          │
│ ┌── Target Information ────────────────────────────────────────────────┐ │
│ │ Visual Studio Code                                                   │ │
│ │ Process: Code.exe | HWND: 0x00240B2A | PID: 14220  [ 75% ALPHA ] PIN │ │
│ └──────────────────────────────────────────────────────────────────────┘ │
│                                                                          │
│ ┌── Window Opacity ────────────────────────────────────────────────────┐ │
│ │ [=======================*-------]                          75% (191) │ │
│ │ [ 25% ]  [ 50% ]  [ 75% ]  [ 100% Solid ]   -5%  +5%   Reset Opacity │ │
│ └──────────────────────────────────────────────────────────────────────┘ │
│                                                                          │
│ ┌───────────────────────────┐  ┌───────────────────────────┐             │
│ │        Ghost Mode         │  │       Click-Through       │             │
│ │ (Translucent + PassThru)  │  │ (Clicks Pass Straight Thru)             │
│ └───────────────────────────┘  └───────────────────────────┘             │
│ ┌───────────────────────────┐  ┌───────────────────────────┐             │
│ │       Always On Top       │  │       Roll-Up Shade       │             │
│ │ (Pin Window Above All)    │  │   (Collapse To Titlebar)  │             │
│ └───────────────────────────┘  └───────────────────────────┘             │
│                                                                          │
│ [ Borderless Frame ]  [ Center Window ]  [ Top-Right PiP ]  [ Bot-Right PiP ]│
│                                                                          │
│ Shortcuts: Ctrl+Alt+E (Menu) | Ctrl+Alt+G (Ghost) | Ctrl+Alt+Scroll      │
│ [ Active Windows ] [ Settings & Auto ]     [ Hide to Tray ] [ Exit App ] │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## Key Features

- **100% Silent Background Startup**: Runs quietly in the background without popping up annoying windows on boot. Opens on demand via `Ctrl+Alt+E` or tray menu.
- **Native Windows 10/11 Dark Titlebar**: Uses DWM Immersive Dark Mode for seamless obsidian window framing and close controls.
- **Clean Minimalist Design**: Modern typography and crisp labels with zero encoding glitches or surrogate emoji corruption.
- **Interactive Hover Tooltips**: Hover over any button, slider, or toggle to see instant real-time helper explanations.
- **Quick Help Modal (`[ Shortcuts ]`)**: Built-in compact cheatsheet and FAQ dialog accessible via the header bar or `F1`.
- **Fully Dynamic Multi-Window Targeting**:
  - **Window Dropdown Switcher**: Live list of all active desktop apps (VS Code, Chrome, Spotify, Discord, etc.) with instant retargeting.
  - **Crosshair Target Picker (`[ Pick Win ]`)**: Click any window on any monitor to immediately lock focus.
  - **Auto-Follow Focus Mode**: Dynamically follows whichever window you switch to in real time.
- **Active Windows Manager Table**: Dedicated modal listing all modified windows with their current opacity, passthrough, pin, and shade status, plus 1-click batch controls.
- **Transparent Overlay (`Ctrl+Alt+G`)**: Simultaneously applies optimal transparency (`200/255`) and enables click passthrough with a single hotkey.
- **Click Passthrough (`Ctrl+Alt+C`)**: Makes any window physically click-invisible—all clicks, scrolls, and drags pass straight through to whatever is beneath it.
- **Granular Opacity Control**:
  - Smooth slider (10–255 alpha) + direct percentage chips (`25%`, `50%`, `75%`, `100% Solid`).
  - Precision adjustment buttons (`-5%`, `+5%`).
  - **Mouse-Wheel Live Opacity (`Ctrl+Alt+Scroll`)**: Hover mouse over any window and scroll wheel up/down to adjust transparency on the fly without opening any menus!
- **Always-on-Top Pinning (`Ctrl+Alt+P`)**: Keep floating reference materials, terminals, or video overlays locked above your workspace.
- **Titlebar Collapse / Shade (`Ctrl+Alt+S`)**: Collapse any window down into just its titlebar like a roll-up window blind, click again to restore full height.
- **Borderless Frame Removal**: Strip captions and borders for clean borderless presentations or floating media player frames.
- **Picture-in-Picture & Quick Snapping**: Instantly snap windows to screen center or Top-Right / Bottom-Right corners at compact PiP dimensions.
- **Hotkey Pause Toggle (`Ctrl+Alt+Shift+S`)**: Temporarily suspend all shortcuts for uninterrupted gaming, Photoshop, or 3D modeling work.
- **Per-Process Persistent Memory**: Automatically saves opacity and styling configurations to `window_profiles.ini` by executable name (e.g., `spotify.exe`, `chrome.exe`).
- **Built-in Windows Startup Manager**: 1-click toggle directly in the Settings modal to enable/disable launching on Windows boot.
- **Safety & Emergency Resets**: Global emergency hotkey (`Ctrl+Alt+Shift+Escape`) immediately restores all modified windows to 100% normal opacity, disables click passthrough, and clears custom styles.

---

## Hotkey Cheatsheet

All hotkeys operate instantly on whichever window is active or under the cursor (using safe `Ctrl+Alt` combinations with zero Windows system shortcut collisions):

| Shortcut | Action | Scope | Description |
| :--- | :--- | :--- | :--- |
| `Ctrl` + `Alt` + `E` | **Open Controller GUI** | Active Window | Launches or retargets the dark-mode dashboard for precision control. |
| `Ctrl` + `Alt` + `G` | **Toggle Overlay** | Active Window | Instant combined Alpha (`200/255`) + Click Passthrough toggle. |
| `Ctrl` + `Alt` + `T` | **Toggle Opacity** | Active Window | Cycles between 100% opaque and default opacity (`200/255`). |
| `Ctrl` + `Alt` + `C` | **Toggle Click Passthrough** | Active Window | Toggles mouse event passthrough on/off (`WS_EX_TRANSPARENT`). |
| `Ctrl` + `Alt` + `P` | **Toggle Always On Top** | Active Window | Pins the active window above all background applications. |
| `Ctrl` + `Alt` + `S` | **Collapse Titlebar** | Active Window | Collapses window height down to only its titlebar. |
| `Ctrl` + `Alt` + `R` | **Reset Window** | Active Window | Restores normal window styles and clears saved profile. |
| `Ctrl` + `Alt` + `WheelUp/Dn` | **Live Opacity Scroll** | Window Under Cursor | Adjusts transparency up or down by 15 levels on the fly. |
| `Ctrl` + `Alt` + `Shift` + `S` | **Pause Hotkeys** | Global | Suspends all hotkeys for gaming or creative work. |
| `Ctrl` + `Alt` + `Shift` + `Esc` | **EMERGENCY RESET ALL** | Global | Instantly restores ALL modified windows to 100% normal styles. |
| `Ctrl` + `Alt` + `Shift` + `R` | **Reload Script** | Global | Reloads the script environment and clears transient state. |

---

## Practical Use Cases

<details>
<summary><b>Digital Art & UI/UX Design (Tracing & Alignment)</b></summary>

Pin an image viewer or browser with reference art or wireframes over Photoshop, Figma, or Blender. Hit `Ctrl+Alt+G` to make it semi-transparent and click-through. Draw or model directly underneath the overlay with perfect pixel precision.
</details>

<details>
<summary><b>Software Engineering & DevOps</b></summary>

Float terminal output, log tails (`tail -f`), or API documentation over your IDE or browser. Keep your real-time build status visible while your editor retains 100% click focus.
</details>

<details>
<summary><b>Gaming & Live Streaming</b></summary>

Overlay Twitch chat, Discord channels, Discord streams, or interactive game maps over borderless fullscreen games without triggering accidental clicks or window minimization. Use `Ctrl+Alt+Shift+S` to pause hotkeys while playing.
</details>

<details>
<summary><b>Multitasking & Media Consumption</b></summary>

Watch video tutorials, webinars, sports, or stock tickers translucent on top of your main work canvas while continuing to write, code, or browse uninterrupted. Use `Ctrl+Alt+S` to roll up video players when you need temporary screen space.
</details>

---

## Architecture & Under the Hood

WindowFX Pro manipulates native Win32 window attributes via the Windows User32 and DWM APIs:

```
                      ┌────────────────────────┐
                      │  Target Window (HWND)  │
                      └───────────┬────────────┘
                                  │
    ┌────────────────┬────────────┼────────────┬────────────────┐
    ▼                ▼            ▼            ▼                ▼
[ Alpha Layer ]  [ ClickThru ]  [ Z-Order ]  [ Frame Style ]  [ Roll-Up ]
WS_EX_LAYERED    WS_EX_TRANSP.  WS_EX_TOPMOST WS_CAPTION       SM_CYCAPTION
(10–255 Opacity) (Passthrough)  (Pinned Top)  (Borderless)     (Shade Blind)
    │                │            │            │                │
    └────────────────┴────────────┼────────────┴────────────────┘
                                  ▼
                     ┌──────────────────────────┐
                     │    ghost_profiles.ini    │
                     │  (Per-App Persistence)   │
                     └──────────────────────────┘
```

1. **Alpha Channel & Layering**: Injects `WS_EX_LAYERED` (`0x80000`) and calls `SetLayeredWindowAttributes` to blend opacity at the DWM compositor level with zero CPU overhead.
2. **Mouse Hit-Testing Bypass**: Injects `WS_EX_TRANSPARENT` (`0x20`), instructing Windows hit-testing routines to pass mouse clicks directly to underlying HWNDs.
3. **Z-Ordering**: Adjusts `WS_EX_TOPMOST` (`0x8`) to retain overlay priority above background applications.
4. **Window Shading / Roll-Up**: Queries system caption and sizing border metrics (`SM_CYCAPTION` + `SM_CYSIZEFRAME`) to dynamically collapse window height while preserving original dimensions in memory.
5. **DWM Immersive Dark Titlebar**: Calls `DwmSetWindowAttribute` with `DWMWA_USE_IMMERSIVE_DARK_MODE` (`20`/`19`) for sleek obsidian window headers.
6. **State Persistence**: Serializes state to `ghost_profiles.ini` keyed by executable name (`ahk_exe`).

---

## Installation & Setup

### Prerequisites
- **OS**: Windows 10 / Windows 11
- **Runtime**: [AutoHotkey v1.1+](https://www.autohotkey.com/download/) (v1.1.30+ recommended)

### Quick Start

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/shlokkokk/window-fx.git
   cd window-fx
   ```

2. **Run the Script**:
   Double-click `windows_fx_menu.ahk` or launch via terminal:
   ```powershell
   AutoHotkey.exe windows_fx_menu.ahk
   ```

3. **Verify Execution**:
   WindowFX will start silently in your Windows System Tray (near your clock). Press `Ctrl+Alt+E` to open the dashboard or click any window and press `Ctrl+Alt+G`.

---

### Run Automatically on Windows Startup

1. Open the WindowFX Dashboard (`Ctrl + Alt + E`).
2. Go to the **Settings** tab.
3. Check the box **"Run WindowFX automatically on Windows Startup"**.
4. WindowFX will now start silently in the background on every PC boot without opening unnecessary windows!

---

## Safety & Window Recovery FAQ

#### Q: I made a window click-through and transparent, and now I can't click it. How do I get it back?
- **Option 1 (Hotkey)**: Press `Alt + Tab` or click the application in the Windows Taskbar to give it active focus, then press **`Ctrl + Alt + R`** (Quick Reset) or **`Ctrl + Alt + G`** to disable Ghost Mode.
- **Option 2 (Emergency Reset)**: Press **`Ctrl + Alt + Shift + Escape`** anywhere. This instantly restores **ALL** modified windows back to 100% opacity and normal styles.
- **Option 3 (Active Windows Tab)**: Open Dashboard (`Ctrl+Alt+E`), click the **Active Windows** tab, select the window from the table, and click **"Reset Selected"**.
- **Option 4 (System Tray)**: Right-click the WindowFX icon in your System Tray and select **`Emergency Reset ALL`**.

#### Q: Does this add input lag or consume GPU resources?
- **No.** Transparency and window composition are handled natively by the Windows Desktop Window Manager (DWM). The script operates on Win32 event hooks and sits at virtually **0.0% CPU** and **< 15MB RAM**.

---

## Contributing

Contributions, bug fixes, and feature suggestions are welcome!

1. Fork the Project at [github.com/shlokkokk/window-fx](https://github.com/shlokkokk/window-fx)
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'feat: Add AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a [Pull Request](https://github.com/shlokkokk/window-fx/pulls)
