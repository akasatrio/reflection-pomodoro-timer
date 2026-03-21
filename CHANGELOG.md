# Changelog

## v0.2.1 — 21 Mar 2026

### New
- Preferences submenu in right-click menu (auto-start after break toggle)
- Settings reset button (↻) to restore defaults
- App icon (minimal tomato + clock design)
- Enter key applies objective text
- Build script auto-installs to /Applications

### Fixed
- Double sound when auto-starting after break
- Objective text no longer persists between app launches
- Panel remembers position when toggling from menu bar
- Info.plist missing icon reference after rename

### Changed
- Renamed app to Reflection Pomodoro Timer
- Phase label ("Ready"/"Work") enlarged to 0.9rem
- Counter text enlarged to 0.6rem

---

## v0.2 — 21 Mar 2026

### New
- Menu bar app: timer icon in the macOS status bar, left-click to show/hide
- Right-click menu with "Launch at Login" toggle and Quit option
- Custom window controls: minimize (hide to menu bar) and close buttons
- Borderless window with hidden titlebar and draggable top area

### Fixed
- Buttons not showing during break and when skipping sessions (exitCompact fix)
- Double sound playing when a cycle ends

### Changed
- App no longer shows in Dock — lives in the menu bar only
- Closing the window hides it instead of quitting
- Signature added: &copy; Baradhio with Claude Code

---

## v0.1 — 21 Mar 2026

Initial release.

### Features
- Pomodoro timer with configurable work, short break, and long break durations
- Configurable number of sessions and long break interval (set to 0 for no long break)
- 2-minute reflection prompt: note panel appears in the last 2 minutes of each work session
- Note title + body for each session — titles appear in summary and copied markdown
- Auto-save: unsaved notes are captured when the timer ends
- Copy All: compiles all session notes into markdown for pasting into Obsidian
- Session summary screen at completion with per-pomodoro notes

### App
- Native macOS app (Swift + WKWebView), launched from .app bundle
- Always-on-top during active work sessions; normal positioning otherwise
- Compact mode: window shrinks during work to show only clock + controls
- Expands back to full size at 2-minute mark (for reflection) and during breaks
- Visible in Cmd+Tab app switcher
- Semi-transparent window background (88% opacity)

### Design
- M PLUS Rounded 1c font throughout (Muji-inspired aesthetic)
- Color-coded phases: green (work), light beige (break), dark brown (done)
- Nintendo Game Boy startup sound for all notifications
- Mute toggle and Funny Mode toggle (dedicated sound TBD)
- Keyboard shortcuts: Space (start/pause), R (reset), S (skip)
- Settings persist via localStorage
