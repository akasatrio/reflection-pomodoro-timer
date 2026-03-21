# Pomodoro Timer

A minimal, always-on-top Pomodoro timer for macOS. Built with Swift + WKWebView.

Designed for focused deep work sessions with built-in reflection notes that compile to markdown for pasting into Obsidian.

![macOS](https://img.shields.io/badge/macOS-13%2B-blue) ![Swift](https://img.shields.io/badge/Swift-5-orange) ![License](https://img.shields.io/badge/license-MIT-green)

## Features

- **Configurable sessions** — work, short break, long break durations and session count
- **Always-on-top during work** — floats above other windows only when a session is active
- **Compact mode** — shrinks to show only the clock and controls during work
- **2-minute reflection** — note panel appears in the last 2 minutes of each work session
- **Session notes** — title + body for each pomodoro, compiled to markdown with "Copy All"
- **Keyboard shortcuts** — Space (start/pause), R (reset), S (skip)
- **Mute toggle** and **Funny Mode** toggle
- **Settings persist** via localStorage

## Design

Minimal aesthetic with M PLUS Rounded 1c font. Color-coded phases: green (work), light beige (break), dark brown (done). Semi-transparent window at 88% opacity.

## Build

Requires macOS 13+ and Xcode Command Line Tools (`xcode-select --install`).

```bash
git clone https://github.com/YOUR_USERNAME/pomodoro-timer.git
cd pomodoro-timer
./build.sh
```

Then open the app:

```bash
open "Pomodoro Timer.app"
```

Or copy it to your Desktop / Applications folder.

## Sound Effects

Sound files are not included in this repo. To add notification sounds:

1. Create a `sound effect/` folder in the project root
2. Add an MP3 file named `nintendo-game-boy-startup.mp3` (or any short notification sound)
3. Run `./build.sh` to copy it into the app bundle

If no sound files are present, the app falls back to a synthesised bell sound.

## Project Structure

```
├── index.html              # Single-file HTML/CSS/JS app
├── PomodoroApp.swift       # Native macOS wrapper (NSPanel + WKWebView)
├── build.sh                # Build & sign script
├── Pomodoro Timer.app/     # App bundle
│   └── Contents/
│       ├── Info.plist
│       ├── MacOS/          # Compiled binary (built by build.sh)
│       └── Resources/      # index.html + sound effects
└── CHANGELOG.md
```

## License

MIT
