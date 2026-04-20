import Cocoa
import WebKit
import UniformTypeIdentifiers

class DragView: NSView {
    override func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, WKScriptMessageHandler, WKUIDelegate {
    var panel: NSPanel!
    var webView: WKWebView!
    var statusItem: NSStatusItem!
    var idleTimer: Timer?
    var idleThresholdSec: Double = 0 // 0 = disabled
    let fullWidth: CGFloat = 280
    let fullHeight: CGFloat = 500
    let funnySoundsHeight: CGFloat = 620
    let reflectionWidth: CGFloat = 280
    let reflectionHeight: CGFloat = 580
    let compactWidth: CGFloat = 280
    let compactHeight: CGFloat = 310
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
        webView.uiDelegate = self
        webView.loadFileURL(htmlURL, allowingReadAccessTo: URL(fileURLWithPath: resourcePath))

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
            startIdleMonitor()

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
            // Dynamic height for done/cycle-break screens based on content
            let contentHeight: CGFloat
            if let v = dict["height"] as? CGFloat { contentHeight = v }
            else if let d = dict["height"] as? Double { contentHeight = CGFloat(d) }
            else { contentHeight = 0 }

            if contentHeight > 0 {
                let maxHeight: CGFloat
                if let screen = panel.screen ?? NSScreen.main {
                    maxHeight = screen.visibleFrame.height * 0.85
                } else {
                    maxHeight = 720
                }
                let padding: CGFloat = 24
                let rawTarget = contentHeight + dragBarHeight + padding
                let targetHeight = min(max(rawTarget, fullHeight), maxHeight)
                let origin = panel.frame.origin
                let oldHeight = panel.frame.height
                let newOrigin = NSPoint(x: origin.x, y: origin.y + (oldHeight - targetHeight))
                panel.setFrame(NSRect(origin: newOrigin, size: NSSize(width: fullWidth, height: targetHeight)), display: true, animate: true)
            }

            panel.isFloatingPanel = false
            panel.level = .normal
            stopIdleMonitor()

        } else if action == "sessionStop" {
            panel.isFloatingPanel = false
            panel.level = .normal
            stopIdleMonitor()

            let origin = panel.frame.origin
            let oldHeight = panel.frame.height
            let newOrigin = NSPoint(x: origin.x, y: origin.y + (oldHeight - fullHeight))
            panel.setFrame(NSRect(origin: newOrigin, size: NSSize(width: fullWidth, height: fullHeight)), display: true, animate: true)

        } else if action == "funnySoundsShow" {
            let origin = panel.frame.origin
            let oldHeight = panel.frame.height
            let newOrigin = NSPoint(x: origin.x, y: origin.y + (oldHeight - funnySoundsHeight))
            panel.setFrame(NSRect(origin: newOrigin, size: NSSize(width: fullWidth, height: funnySoundsHeight)), display: true, animate: true)

        } else if action == "funnySoundsHide" {
            let origin = panel.frame.origin
            let oldHeight = panel.frame.height
            let newOrigin = NSPoint(x: origin.x, y: origin.y + (oldHeight - fullHeight))
            panel.setFrame(NSRect(origin: newOrigin, size: NSSize(width: fullWidth, height: fullHeight)), display: true, animate: true)

        } else if action == "panelHide" {
            panel.orderOut(nil)

        } else if action == "panelClose" {
            NSApp.terminate(nil)

        } else if action == "setIdleThreshold" {
            // Seconds; 0 disables idle detection.
            if let v = dict["seconds"] as? Double { idleThresholdSec = max(0, v) }
            else if let v = dict["seconds"] as? Int { idleThresholdSec = Double(max(0, v)) }

        } else if action == "runShortcut" {
            // Invokes a user-authored macOS Shortcut by name via `/usr/bin/shortcuts run "<name>"`.
            // Uses Process arguments array (no shell), so the name is not interpreted — injection-safe.
            // Sanity bound the name length to block absurd inputs.
            guard let name = dict["name"] as? String,
                  !name.isEmpty,
                  name.count <= 200,
                  !name.contains("\0") else {
                return
            }
            DispatchQueue.global(qos: .utility).async {
                let p = Process()
                p.executableURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
                p.arguments = ["run", name]
                p.standardOutput = FileHandle.nullDevice
                p.standardError = FileHandle.nullDevice
                try? p.run()
                // Don't wait — Shortcuts can be slow; fire-and-forget is fine.
            }

        } else if action == "appendDailyNote" {
            // Append markdown to a user-specified daily note file.
            // Hard constraints: absolute path, ends with .md, no ".." segments, path resolves
            // under $HOME. These block traversal and writes to arbitrary system paths.
            guard let rawPath = dict["path"] as? String,
                  let content = dict["content"] as? String else {
                webView.evaluateJavaScript("appendDailyNoteFailed('Missing path or content')", completionHandler: nil)
                return
            }
            let expanded = (rawPath as NSString).expandingTildeInPath
            let home = FileManager.default.homeDirectoryForCurrentUser.path
            let url = URL(fileURLWithPath: expanded)
            let std = url.standardizedFileURL.path
            guard expanded.hasPrefix("/"),
                  expanded.hasSuffix(".md"),
                  !expanded.contains(".."),
                  std.hasPrefix(home + "/") || std == home else {
                webView.evaluateJavaScript("appendDailyNoteFailed('Invalid path')", completionHandler: nil)
                return
            }
            DispatchQueue.global(qos: .utility).async { [weak self] in
                let dir = (std as NSString).deletingLastPathComponent
                do {
                    try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
                    let data = content.data(using: .utf8) ?? Data()
                    if FileManager.default.fileExists(atPath: std) {
                        if let h = FileHandle(forWritingAtPath: std) {
                            h.seekToEndOfFile()
                            h.write(data)
                            try? h.close()
                        }
                    } else {
                        try data.write(to: URL(fileURLWithPath: std))
                    }
                    DispatchQueue.main.async {
                        self?.webView.evaluateJavaScript("appendDailyNoteOk()", completionHandler: nil)
                    }
                } catch {
                    let msg = error.localizedDescription.replacingOccurrences(of: "'", with: "\\'")
                    DispatchQueue.main.async {
                        self?.webView.evaluateJavaScript("appendDailyNoteFailed('\(msg)')", completionHandler: nil)
                    }
                }
            }

        } else if action == "updateApp" {
            // Pinned-tag updater: JS must supply the release tag; reject anything
            // that doesn't match strict semver to block shell-injection.
            guard let rawTag = dict["tag"] as? String else {
                webView.evaluateJavaScript("updateFailed('Missing release tag')", completionHandler: nil)
                return
            }
            let tagPattern = #"^v?\d{1,3}\.\d{1,3}\.\d{1,3}$"#
            guard rawTag.range(of: tagPattern, options: .regularExpression) != nil else {
                webView.evaluateJavaScript("updateFailed('Invalid release tag')", completionHandler: nil)
                return
            }
            let tag = rawTag
            let stripped = rawTag.hasPrefix("v") ? String(rawTag.dropFirst()) : rawTag

            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                let tempDir = NSTemporaryDirectory() + "pomodoro-update"
                let repo = "akasatrio/reflection-pomodoro-timer"
                let zipURL = "https://github.com/\(repo)/archive/refs/tags/\(tag).zip"
                let extractedDir = "reflection-pomodoro-timer-\(stripped)"
                let script = """
                set -euo pipefail
                rm -rf "\(tempDir)"
                mkdir -p "\(tempDir)"
                /usr/bin/curl -fsSL --proto '=https' --tlsv1.2 "\(zipURL)" -o "\(tempDir)/source.zip"
                cd "\(tempDir)"
                /usr/bin/unzip -q source.zip
                cd "\(extractedDir)"
                chmod +x build.sh
                ./build.sh
                rm -rf "\(tempDir)"
                """

                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/bin/bash")
                process.arguments = ["-c", script]

                // Capture stderr so build failures surface rather than dying silently.
                let errPipe = Pipe()
                process.standardOutput = FileHandle.nullDevice
                process.standardError = errPipe

                do {
                    try process.run()
                    process.waitUntilExit()
                    let errData = try? errPipe.fileHandleForReading.readToEnd()

                    DispatchQueue.main.async {
                        if process.terminationStatus == 0 {
                            let relaunch = Process()
                            relaunch.executableURL = URL(fileURLWithPath: "/usr/bin/open")
                            relaunch.arguments = ["/Applications/Reflection Pomodoro Timer.app"]
                            try? relaunch.run()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                NSApp.terminate(nil)
                            }
                        } else {
                            let tail = (errData.flatMap { String(data: $0, encoding: .utf8) } ?? "")
                                .suffix(200)
                                .replacingOccurrences(of: "'", with: "\\'")
                                .replacingOccurrences(of: "\n", with: " ")
                            self?.webView.evaluateJavaScript("updateFailed('Build failed: \(tail)')", completionHandler: nil)
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        self?.webView.evaluateJavaScript("updateFailed('Update failed')", completionHandler: nil)
                    }
                }
            }
        }
    }

    // File upload support for WKWebView
    func webView(_ webView: WKWebView, runOpenPanelWith parameters: WKOpenPanelParameters, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping ([URL]?) -> Void) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = parameters.allowsMultipleSelection
        openPanel.allowedContentTypes = [
            .mp3, .wav, .aiff, .audio
        ]
        openPanel.beginSheetModal(for: panel) { response in
            completionHandler(response == .OK ? openPanel.urls : nil)
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

    // Idle detection — polls CGEventSource while a work session is active.
    // When idle exceeds threshold, notifies JS (which pauses the timer) and stops
    // polling for this session so we don't fire repeatedly.
    func startIdleMonitor() {
        stopIdleMonitor()
        guard idleThresholdSec > 0 else { return }
        idleTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            // rawValue ~0 is the documented "any input event" selector for this API.
            let any = CGEventType(rawValue: ~0) ?? .null
            let idle = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: any)
            if idle >= self.idleThresholdSec {
                self.stopIdleMonitor()
                DispatchQueue.main.async {
                    self.webView.evaluateJavaScript("onIdleDetected(\(Int(idle)))", completionHandler: nil)
                }
            }
        }
        if let t = idleTimer { RunLoop.main.add(t, forMode: .common) }
    }
    func stopIdleMonitor() {
        idleTimer?.invalidate()
        idleTimer = nil
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
