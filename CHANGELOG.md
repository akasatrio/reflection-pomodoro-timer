# Changelog

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
