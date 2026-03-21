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
    let fullHeight: CGFloat = 460
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
                let tempDir = NSTemporaryDirectory() + "pomodoro-update"
                let script = """
                set -e
                rm -rf "\(tempDir)"
                mkdir -p "\(tempDir)"
                /usr/bin/curl -sL "https://github.com/akasatrio/reflection-pomodoro-timer/archive/refs/heads/main.zip" -o "\(tempDir)/source.zip"
                cd "\(tempDir)"
                /usr/bin/unzip -q source.zip
                cd reflection-pomodoro-timer-main
                chmod +x build.sh
                ./build.sh
                rm -rf "\(tempDir)"
                """

                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/bin/bash")
                process.arguments = ["-c", script]
                process.standardOutput = FileHandle.nullDevice
                process.standardError = FileHandle.nullDevice

                do {
                    try process.run()
                    process.waitUntilExit()

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
                            self?.webView.evaluateJavaScript("updateFailed('Build failed')", completionHandler: nil)
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

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { return false }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

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
