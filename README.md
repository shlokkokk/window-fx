# 🪟 WindowFX (`window-fx`)

> **Surgical window transparency, click-through overlays, and HUD mode for Windows.**  
> Turn any application into a sleek, non-intrusive heads-up display with seamless mouse passthrough and per-app persistence.

[![GitHub Repo](https://img.shields.io/badge/GitHub-shlokkokk%2Fwindow--fx-181717?style=flat-square&logo=github)](https://github.com/shlokkokk/window-fx)
[![Platform: Windows](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011-0078D6?style=flat-square&logo=windows)](https://www.microsoft.com/windows)
[![AutoHotkey v1.1+](https://img.shields.io/badge/AutoHotkey-v1.1%2B-334455?style=flat-square&logo=autohotkey)](https://www.autohotkey.com/)
[![Memory Footprint](https://img.shields.io/badge/Footprint-%3C15MB%20RAM-brightgreen?style=flat-square)](https://github.com/shlokkokk/window-fx)
[![Zero Dependencies](https://img.shields.io/badge/Dependencies-None-orange?style=flat-square)](https://github.com/shlokkokk/window-fx)

---

## ⚡ Overview

**WindowFX** is an ultra-lightweight Windows utility that gives you instant, granular control over any window's opacity and mouse interaction layer. Whether you want to turn a browser window into a click-through tracing reference, float transparent terminal logs over your IDE, or overlay a Twitch stream over a fullscreen game, `window-fx` handles it instantly via global hotkeys, HUD toasts, or a dark-themed control dashboard.

```
┌──────────────────────────────────────────────────────────────┐
│ WindowFX Control Dashboard                        [ _ ][ X ] │
├──────────────────────────────────────────────────────────────┤
│ Target HWND : 0x00240B2A       Process : Code.exe            │
│ Window Title: Visual Studio Code                             │
│                                                              │
│ ┌── Opacity & Transparency ────────────────────────────────┐ │
│ │  Slider : [=======================*-------]  191 (75%)   │ │
│ │  Presets:  [ 25% ]     [ 50% ]     [ 75% ]     [ 100% ]  │ │
│ └──────────────────────────────────────────────────────────┘ │
│ ┌── Quick Action Controls ─────────────────────────────────┐ │
│ │  [ Toggle Trans ]    [ Click-Through ]    [ Ghost Mode ] │ │
│ └──────────────────────────────────────────────────────────┘ │
│ [x] Keep Window Always On Top                                │
│ [ Reset Window to Defaults ]                                 │
│                                                              │
│ StatusBar: Opacity: 191 | ClickThru: ON | Pinned: ON         │
└──────────────────────────────────────────────────────────────┘
```

---

## ✨ Key Features

- 🎯 **Ghost Mode (`Ctrl+Alt+G`)**: Simultaneously applies optimal transparency (`200/255`) and enables click-through mouse passthrough with a single hotkey.
- 🖱️ **Click-Through Passthrough (`Ctrl+Alt+C`)**: Makes the window physically click-invisible—all mouse clicks, scrolls, and drags pass straight through to whatever is beneath it.
- 🎚️ **Granular Opacity Control (`Ctrl+Alt+T`)**: Smooth slider range (50–255 alpha) + rapid one-click presets (`25%`, `50%`, `75%`, `100%`).
- 📌 **Always-on-Top Pinning**: Keep floating reference materials, terminals, or video overlays locked above your workspace.
- 💾 **Per-Process Persistent Memory**: Automatically saves opacity and click-through configurations to `ghost_profiles.ini` by executable name (e.g., `spotify.exe`, `chrome.exe`). Your preferences restore automatically.
- 🍞 **Sleek HUD Toast Notifications**: Instant, unobtrusive dark-mode feedback when firing quick hotkeys without needing to open the GUI.
- 🎛️ **Dual-Mode Workflow**:
  - **Headless Mode**: Lightning-fast hotkeys with toast feedback for distraction-free work.
  - **Dashboard Mode (`Ctrl+Alt+E`)**: Catppuccin-inspired dark UI showing window title, process name, HWND identifier, live preview slider, and toggles.
- 🧯 **Safety & Emergency Resets**: One-key instant reset (`Ctrl+Alt+R`) or bulk emergency reset from system tray to recover all modified windows immediately.

---

## ⌨️ Hotkey Cheatsheet

All hotkeys target whichever window currently has active focus:

| Shortcut | Action | Scope | Description |
| :--- | :--- | :--- | :--- |
| `Ctrl` + `Alt` + `E` | **Open Controller GUI** | Active Window | Launches/retargets the dark-mode control panel for precision tweaks. |
| `Ctrl` + `Alt` + `G` | **Toggle Ghost Mode** | Active Window | Instant combined Alpha + Click-Through toggle (Headless). |
| `Ctrl` + `Alt` + `T` | **Toggle Transparency** | Active Window | Cycles between 100% opaque and default opacity (`200/255`). |
| `Ctrl` + `Alt` + `C` | **Toggle Click-Through** | Active Window | Toggles mouse event passthrough on/off. |
| `Ctrl` + `Alt` + `R` | **Quick Reset Window** | Active Window | Restores normal window styles and clears saved profile. |
| `Ctrl` + `Alt` + `Shift` + `R` | **Reload Script** | Global | Reloads the script environment and clears transient state. |

---

## 💡 Practical Use Cases

<details>
<summary><b>🎨 Digital Art & UI/UX Design (Tracing & Alignment)</b></summary>

Pin an image viewer or browser with reference art or wireframes over Photoshop, Figma, or Blender. Hit `Ctrl+Alt+G` to make it semi-transparent and click-through. Draw or model directly underneath the overlay with perfect pixel precision.
</details>

<details>
<summary><b>💻 Software Engineering & DevOps</b></summary>

Float terminal output, log tails (`tail -f`), or API documentation over your IDE or browser. Keep your real-time build status visible while your editor retains 100% click focus.
</details>

<details>
<summary><b>🎮 Gaming & Live Streaming</b></summary>

Overlay Twitch chat, Discord channels, Discord streams, or interactive game maps over borderless fullscreen games without triggering accidental clicks or window minimization.
</details>

<details>
<summary><b>📊 Multitasking & Media Consumption</b></summary>

Watch video tutorials, webinars, sports, or stock tickers translucent on top of your main work canvas while continuing to write, code, or browse uninterrupted.
</details>

---

## 🛠️ Architecture & Under the Hood

`window-fx` manipulates native Win32 window attributes via the Windows User32 API:

```
                  ┌───────────────────────────────┐                  
                  │     Active Window Target      │                  
                  │     HWND: WinGet, ID, A       │                  
                  └───────────────┬───────────────┘                  
                                  │                                  
          ┌───────────────────────┼───────────────────────┐          
          ▼                       ▼                       ▼          
   [ Alpha Layer ]       [ Extended Styles ]       [ Z-Order Layer ] 
 SetLayeredWindowAttr     WS_EX_TRANSPARENT         WS_EX_TOPMOST    
 (WinSet Transparent)        (0x00000020)            (0x00000008)    
          │                       │                       │          
          ▼                       ▼                       ▼          
    Visual Opacity         Click-Through            Always On Top    
    (Alpha 0-255)         (Mouse Passthrough)      (Pinned on Top)   
          │                       │                       │          
          └───────────────────────┼───────────────────────┘          
                                  ▼                                  
                    ┌───────────────────────────┐                    
                    │   Per-App Profile Cache   │                    
                    │    ghost_profiles.ini     │                    
                    └───────────────────────────┘                    
```

1. **Alpha Channel & Layering**: Uses `WS_EX_LAYERED` (`0x80000`) and calls `SetLayeredWindowAttributes` to blend opacity at the DWM compositor level with zero CPU overhead.
2. **Mouse Hit-Testing Bypass**: Injects the `WS_EX_TRANSPARENT` (`0x20`) extended window style. This instructs Windows hit-testing routines to disregard the window for pointer input, passing mouse clicks directly to underlying HWNDs.
3. **Z-Ordering**: Adjusts `WS_EX_TOPMOST` (`0x8`) to retain overlay priority above background applications.
4. **State Persistence**: Serializes state to `ghost_profiles.ini` keyed by process executable (`ahk_exe`), decoupling persistent rules from dynamic window titles.

---

## 🚀 Installation & Setup

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
   The WindowFX icon will appear in your Windows System Tray. Click any window and press `Ctrl+Alt+G` to test.

---

### 📦 Standalone Executable (No AutoHotkey Installation Required)

You can compile `windows_fx_menu.ahk` into a standalone `.exe`:

1. Open **Ahk2Exe** (included with standard AutoHotkey installations).
2. Set **Source (script file)** to `windows_fx_menu.ahk`.
3. (Optional) Set custom `.ico` icon.
4. Click **Convert**. Run the generated `windows_fx_menu.exe` anywhere.

---

### 🔄 Run Automatically on Windows Startup

To have WindowFX start on boot:

1. Press `Win + R`, type `shell:startup`, and press `Enter`.
2. Create a shortcut to `windows_fx_menu.ahk` (or the compiled `.exe`) inside the Startup folder.

---

## ⚙️ Configuration & Customization

Open `windows_fx_menu.ahk` in any text editor to modify default behaviors:

```ahk
; ==============================
; CONFIGURATION
; ==============================
global ConfigFile         := A_ScriptDir "\ghost_profiles.ini" ; Profile save location
global DefaultGhostOpacity := 200                              ; Default alpha when toggling ghost mode (0-255)
global ToastDuration       := 900                              ; Toast notification duration (milliseconds)
```

### Profile Storage (`ghost_profiles.ini`)
Window states are saved automatically per executable. Example format:

```ini
[chrome.exe]
Transparency=180
ClickThrough=1

[Code.exe]
Transparency=220
ClickThrough=0

[Spotify.exe]
Transparency=150
ClickThrough=1
```

---

## 🛡️ Safety & Window Recovery FAQ

#### Q: I made a window click-through and transparent, and now I can't click it to focus it. How do I get it back?
- **Option 1 (Hotkey)**: Use `Alt + Tab` or click the application's icon in the Windows Taskbar to give it active focus, then press **`Ctrl + Alt + R`** (Quick Reset) or **`Ctrl + Alt + G`** to disable Ghost Mode.
- **Option 2 (System Tray)**: Right-click the WindowFX icon in your System Tray and select **`Reset ALL tracked windows`**. This immediately clears extended styles and restores 100% opacity to all registered applications.

#### Q: Does this add input lag or consume GPU resources?
- **No.** Transparency and window composition are handled natively by the Windows Desktop Window Manager (DWM). The script operates on Windows OS event hooks and sits at virtually **0.0% CPU** and **< 15MB RAM**.

#### Q: Does it work with anti-cheat protected games?
- `window-fx` modifies window styles using official Win32 APIs without injecting code into target processes or reading process memory. However, for games running in exclusive fullscreen mode, switch to **Borderless Windowed** mode to allow OS overlay composition.

---

## 🤝 Contributing

Contributions, bug fixes, and feature suggestions are welcome!

1. Fork the Project at [github.com/shlokkokk/window-fx](https://github.com/shlokkokk/window-fx)
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'feat: Add AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a [Pull Request](https://github.com/shlokkokk/window-fx/pulls)
