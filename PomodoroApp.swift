import Cocoa
import WebKit

class DragView: NSView {
    override func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, WKScriptMessageHandler {
    var panel: NSPanel!
    var webView: WKWebView!
    var statusItem: NSStatusItem!
    let fullWidth: CGFloat = 280
    /// Taller default so two-row settings + footer signature clear the panel bottom.
    let fullHeight: CGFloat = 515
    let reflectionWidth: CGFloat = 280
    let reflectionHeight: CGFloat = 610
    let compactWidth: CGFloat = 280
    let compactHeight: CGFloat = 278
    let miniWidth: CGFloat = 150
    let miniHeight: CGFloat = 100
    let dragBarHeight: CGFloat = 28

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Menu bar icon
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "timer", accessibilityDescription: "Pomodoro Timer")
            button.action = #selector(togglePanel)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        // Right-click menu
        statusItem.menu = nil

        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: fullWidth, height: fullHeight),
            styleMask: [.titled, .fullSizeContentView, .nonactivatingPanel, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = false
        panel.becomesKeyOnlyIfNeeded = true
        panel.level = .normal
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        panel.backgroundColor = NSColor(red: 0.918, green: 0.91, blue: 0.89, alpha: 0.88)
        panel.isOpaque = false

        // Position top-right on launch
        if let screen = NSScreen.main {
            let sf = screen.visibleFrame
            panel.setFrameOrigin(NSPoint(x: sf.maxX - fullWidth - 12, y: sf.maxY - fullHeight - 12))
        } else {
            panel.center()
        }

        // WebView
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        config.userContentController.add(self, name: "panelControl")

        let contentView = panel.contentView!
        webView = WKWebView(frame: contentView.bounds, configuration: config)
        webView.autoresizingMask = [.width, .height]
        webView.setValue(false, forKey: "drawsBackground")
        contentView.addSubview(webView)

        // Transparent drag bar overlaid on top of webview (leave right side for buttons)
        let buttonAreaWidth: CGFloat = 80
        let dragBar = DragView(frame: NSRect(x: 0, y: contentView.bounds.height - dragBarHeight, width: contentView.bounds.width - buttonAreaWidth, height: dragBarHeight))
        dragBar.autoresizingMask = [.width, .minYMargin]
        contentView.addSubview(dragBar)

        let resourcePath = Bundle.main.resourcePath ?? (Bundle.main.bundlePath as NSString).deletingLastPathComponent
        let htmlURL = URL(fileURLWithPath: (resourcePath as NSString).appendingPathComponent("index.html"))
        webView.loadFileURL(htmlURL, allowingReadAccessTo: URL(fileURLWithPath: resourcePath))

        // Accessory (menu-bar-only) apps must activate explicitly or the panel stays behind other apps.
        NSApp.activate(ignoringOtherApps: true)
        panel.orderFrontRegardless()
        panel.makeKeyAndOrderFront(nil)
    }

    func positionPanelBelowStatusItem() {
        if let button = statusItem.button, let buttonWindow = button.window {
            let buttonRect = button.convert(button.bounds, to: nil)
            let screenRect = buttonWindow.convertToScreen(buttonRect)
            let panelHeight = panel.frame.height
            let x = screenRect.midX - (fullWidth / 2)
            let y = screenRect.minY - panelHeight - 4
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        } else if let screen = NSScreen.main {
            let sf = screen.visibleFrame
            panel.setFrameOrigin(NSPoint(x: sf.maxX - fullWidth - 12, y: sf.maxY - fullHeight - 12))
        } else {
            panel.center()
        }
    }

    @objc func togglePanel() {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            let menu = NSMenu()

            // Preferences submenu
            let prefsMenu = NSMenu()
            let autoStartItem = NSMenuItem(title: "Auto-start after break", action: #selector(toggleAutoStart(_:)), keyEquivalent: "")
            autoStartItem.target = self
            autoStartItem.state = getPreference("autoStartAfterBreak") ? .on : .off
            prefsMenu.addItem(autoStartItem)

            let prefsMenuItem = NSMenuItem(title: "Preferences", action: nil, keyEquivalent: "")
            prefsMenuItem.submenu = prefsMenu
            menu.addItem(prefsMenuItem)

            menu.addItem(NSMenuItem.separator())
            let loginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin(_:)), keyEquivalent: "")
            loginItem.target = self
            loginItem.state = isLaunchAtLoginEnabled() ? .on : .off
            menu.addItem(loginItem)
            menu.addItem(NSMenuItem.separator())
            menu.addItem(withTitle: "Quit Reflection Pomodoro Timer", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "")
            statusItem.menu = menu
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
            return
        }

        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            panel.makeKeyAndOrderFront(nil)
        }
    }

    // Handle messages from JavaScript
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let dict = message.body as? [String: Any],
              let action = dict["action"] as? String else { return }

        if action == "sessionStart" {
            panel.isFloatingPanel = true
            panel.level = NSWindow.Level(Int(CGWindowLevelForKey(.floatingWindow)) + 1)

            let origin = panel.frame.origin
            let oldHeight = panel.frame.height
            let newOrigin = NSPoint(x: origin.x, y: origin.y + (oldHeight - compactHeight))
            panel.setFrame(NSRect(origin: newOrigin, size: NSSize(width: compactWidth, height: compactHeight)), display: true, animate: true)

        } else if action == "sessionExpand" {
            let origin = panel.frame.origin
            let oldHeight = panel.frame.height
            let newOrigin = NSPoint(x: origin.x, y: origin.y + (oldHeight - reflectionHeight))
            panel.setFrame(NSRect(origin: newOrigin, size: NSSize(width: reflectionWidth, height: reflectionHeight)), display: true, animate: true)

        } else if action == "sessionMini" {
            // Stay floating, shrink to mini size
            let origin = panel.frame.origin
            let oldHeight = panel.frame.height
            let newOrigin = NSPoint(x: origin.x, y: origin.y + (oldHeight - miniHeight))
            panel.setFrame(NSRect(origin: newOrigin, size: NSSize(width: miniWidth, height: miniHeight)), display: true, animate: true)

        } else if action == "sessionDone" {
            if let contentHeight = dict["height"] as? CGFloat, contentHeight > 0 {
                let maxHeight: CGFloat
                if let screen = panel.screen ?? NSScreen.main {
                    maxHeight = screen.visibleFrame.height * 0.85
                } else {
                    maxHeight = 720
                }
                let minDoneHeight = fullHeight
                /// Extra points so footer, scrollbars, and WKWebView rounding don’t clip the last lines.
                let layoutPadding: CGFloat = 28
                let rawTarget = contentHeight + dragBarHeight + layoutPadding
                let targetHeight = min(max(rawTarget, minDoneHeight), maxHeight)
                let origin = panel.frame.origin
                let oldHeight = panel.frame.height
                let newOrigin = NSPoint(x: origin.x, y: origin.y + (oldHeight - targetHeight))
                panel.setFrame(NSRect(origin: newOrigin, size: NSSize(width: fullWidth, height: targetHeight)), display: true, animate: true)
            }

        } else if action == "sessionStop" {
            panel.isFloatingPanel = false
            panel.level = .normal

            let origin = panel.frame.origin
            let oldHeight = panel.frame.height
            let newOrigin = NSPoint(x: origin.x, y: origin.y + (oldHeight - fullHeight))
            panel.setFrame(NSRect(origin: newOrigin, size: NSSize(width: fullWidth, height: fullHeight)), display: true, animate: true)

        } else if action == "panelHide" {
            panel.orderOut(nil)

        } else if action == "panelClose" {
            NSApp.terminate(nil)

        } else if action == "updateApp" {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }

                let logsDir = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
                    .appendingPathComponent("Logs", isDirectory: true)
                try? FileManager.default.createDirectory(at: logsDir, withIntermediateDirectories: true)
                let logPath = logsDir.appendingPathComponent("ReflectionPomodoroTimer-update.log").path

                let workName = "pomodoro-update-\(UUID().uuidString.prefix(8))"
                let tempDir = (NSTemporaryDirectory() as NSString).appendingPathComponent(workName)
                let targetBundle = Bundle.main.bundlePath

                // Use env for paths so spaces/special chars stay safe; inherit user PATH for swiftc/codesign.
                var env = ProcessInfo.processInfo.environment
                env["POMO_TMP"] = tempDir
                env["POMO_TARGET"] = targetBundle
                env["POMO_LOG"] = logPath
                env["POMODORO_SKIP_INSTALL"] = "1"

                let script = """
                set -e
                exec >"$POMO_LOG" 2>&1
                echo "=== Update started $(date) ==="
                echo "Target bundle: $POMO_TARGET"
                echo "Temp: $POMO_TMP"
                rm -rf "$POMO_TMP"
                mkdir -p "$POMO_TMP"
                cd "$POMO_TMP"
                /usr/bin/curl -fSL "https://github.com/akasatrio/reflection-pomodoro-timer/archive/refs/heads/main.zip" -o source.zip
                /usr/bin/unzip -q source.zip
                cd reflection-pomodoro-timer-main
                chmod +x build.sh
                ./build.sh
                NEW_APP="$(pwd)/Reflection Pomodoro Timer.app"
                test -d "$NEW_APP"
                /usr/bin/ditto "$NEW_APP" "$POMO_TARGET"
                echo "=== Update finished OK $(date) ==="
                cd /
                rm -rf "$POMO_TMP"
                """

                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/bin/bash")
                process.arguments = ["-lc", script]
                process.environment = env
                process.currentDirectoryURL = URL(fileURLWithPath: NSHomeDirectory())

                do {
                    try process.run()
                    process.waitUntilExit()

                    let status = process.terminationStatus

                    DispatchQueue.main.async {
                        if status == 0 {
                            let relaunch = Process()
                            relaunch.executableURL = URL(fileURLWithPath: "/usr/bin/open")
                            relaunch.arguments = [targetBundle]
                            try? relaunch.run()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                                NSApp.terminate(nil)
                            }
                        } else {
                            let tail = AppDelegate.lastLinesOfFile(at: logPath, maxLines: 4)
                            let safe = tail
                                .replacingOccurrences(of: "\\", with: " ")
                                .replacingOccurrences(of: "'", with: "′")
                                .replacingOccurrences(of: "\n", with: " — ")
                            let jsSafe = safe.prefix(220)
                            let msg = jsSafe.isEmpty
                                ? "Build or install failed (exit \(status)). See ~/Library/Logs/ReflectionPomodoroTimer-update.log"
                                : String(jsSafe)
                            let escaped = msg.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
                            self.webView.evaluateJavaScript("updateFailed(\"\(escaped)\")", completionHandler: nil)
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.webView.evaluateJavaScript("updateFailed('Could not run updater: \\(error.localizedDescription)')", completionHandler: nil)
                    }
                }
            }
        }
    }

    // Launch at Login via LaunchAgent plist
    let launchAgentID = "com.adhi.pomodoro-timer"

    func launchAgentPath() -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return "\(home)/Library/LaunchAgents/\(launchAgentID).plist"
    }

    func isLaunchAtLoginEnabled() -> Bool {
        return FileManager.default.fileExists(atPath: launchAgentPath())
    }

    @objc func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        let path = launchAgentPath()
        if isLaunchAtLoginEnabled() {
            try? FileManager.default.removeItem(atPath: path)
        } else {
            let appPath = Bundle.main.bundlePath
            let plist: [String: Any] = [
                "Label": launchAgentID,
                "ProgramArguments": ["\(appPath)/Contents/MacOS/PomodoroTimer"],
                "RunAtLoad": true
            ]
            let data = try? PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
            // Ensure LaunchAgents directory exists
            let dir = (path as NSString).deletingLastPathComponent
            try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
            FileManager.default.createFile(atPath: path, contents: data)
        }
    }

    // Preferences stored in UserDefaults
    func getPreference(_ key: String) -> Bool {
        return UserDefaults.standard.bool(forKey: key)
    }

    func setPreference(_ key: String, value: Bool) {
        UserDefaults.standard.set(value, forKey: key)
        // Sync to JS localStorage
        webView.evaluateJavaScript("localStorage.setItem('\(key)', '\(value ? "1" : "0")')", completionHandler: nil)
    }

    @objc func toggleAutoStart(_ sender: NSMenuItem) {
        let current = getPreference("autoStartAfterBreak")
        setPreference("autoStartAfterBreak", value: !current)
    }

    /// Last lines of the updater log for surfacing errors in the web UI.
    private static func lastLinesOfFile(at path: String, maxLines: Int) -> String {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let text = String(data: data, encoding: .utf8) else { return "" }
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        let tail = lines.suffix(maxLines)
        return tail.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { return false }
}

let app = NSApplication.shared
app.setActivationPolicy(.regular)

let mainMenu = NSMenu()
let appMenuItem = NSMenuItem(); let appMenu = NSMenu()
appMenu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
appMenuItem.submenu = appMenu; mainMenu.addItem(appMenuItem)
let editMenuItem = NSMenuItem(); let editMenu = NSMenu(title: "Edit")
editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
editMenuItem.submenu = editMenu; mainMenu.addItem(editMenuItem)
app.mainMenu = mainMenu

let delegate = AppDelegate()
app.delegate = delegate
app.run()
