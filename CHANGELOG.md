# Changelog

## v0.3.4 — 30 Mar 2026

### Fixed
- Large empty band below the footer in compact/session view: removed `min-height: 100vh` on `body` so layout height follows content; tightened bottom padding on `body`, container, toggles row, and done/compact states.
- Compact panel height reduced (`compactHeight` 310 → 278) so the window matches the shorter layout.

### Changed
- Footer: signature `margin-top` set to `0.85rem` (replacing `1cm`); signature vertical padding `0.20rem`.

---

## v0.3.3 — 30 Mar 2026

### Fixed
- Footer / copyright line: moved up slightly, tighter spacing under toggles, extra body bottom padding and `line-height` so text is not clipped by the panel edge.

---

## v0.3.2 — 30 Mar 2026

### Fixed
- Launch: the timer panel activates the app and comes to the front immediately (`NSApp.activate`, `orderFrontRegardless`) so it no longer starts hidden behind other windows.

---

## v0.3.1 — 30 Mar 2026

### New
- Top-left app label **RefPom Timer** in the drag bar (hidden in mini mode).

### Fixed
- In-app updater: `build.sh` creates `Contents/MacOS` before `swiftc` so builds from the GitHub zip no longer fail (`ld: errno=2`).
- Completion / cycle-break layouts: better document height reporting for `sessionDone`, extra panel height padding, and a taller scroll area for notes so content is less likely to clip.

### Changed
- Default panel height increased for the two-row settings grid; reflection panel height adjusted to match.
- Footer signature spacing and container padding so the bottom of the window doesn’t crowd the copyright line.

---

## v0.3.0 — 30 Mar 2026

### New
- **Sessions** (work blocks per cycle) and **Cycles** (how many full rounds), replacing the old single “Sets” counter; default **2** cycles with migration from saved settings.
- **Long @** unchanged in behavior: long break after every N completed sessions in a cycle; when N equals Sessions, the cycle ends at Done (no extra long break).
- **Cycle break** between rounds: long-break-length pause, congratulations, and notes compiled for the finished cycle only; final screen shows all notes across cycles.
- Notes store **cycle** and **work index**; markdown export reflects the full run.

### Fixed
- Completion and inter-cycle screens: scrollable notes area and more reliable macOS panel resize (`sessionDone`) so Copy / Again stay reachable.

---

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
