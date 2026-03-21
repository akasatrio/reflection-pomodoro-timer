import Cocoa
import WebKit

class AppDelegate: NSObject, NSApplicationDelegate, WKScriptMessageHandler {
    var panel: NSPanel!
    var webView: WKWebView!
    let fullWidth: CGFloat = 280
    let fullHeight: CGFloat = 440
    let reflectionWidth: CGFloat = 280
    let reflectionHeight: CGFloat = 580
    let compactWidth: CGFloat = 280
    let compactHeight: CGFloat = 310

    func applicationDidFinishLaunching(_ notification: Notification) {
        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: fullWidth, height: fullHeight),
            styleMask: [.titled, .closable, .nonactivatingPanel, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        panel.title = "Pomodoro Timer"
        panel.isFloatingPanel = false          // Start as normal window (not floating)
        panel.becomesKeyOnlyIfNeeded = true
        panel.level = .normal                  // Normal level when idle
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.isMovableByWindowBackground = true
        panel.titlebarAppearsTransparent = true
        panel.backgroundColor = NSColor(red: 0.918, green: 0.91, blue: 0.89, alpha: 0.88)
        panel.isOpaque = false

        // Position top-right
        if let screen = NSScreen.main {
            let sf = screen.visibleFrame
            panel.setFrameOrigin(NSPoint(x: sf.maxX - fullWidth - 12, y: sf.maxY - fullHeight - 12))
        } else {
            panel.center()
        }

        // WebView with message handler for JS → Swift communication
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        config.userContentController.add(self, name: "panelControl")

        webView = WKWebView(frame: panel.contentView!.bounds, configuration: config)
        webView.autoresizingMask = [.width, .height]
        webView.setValue(false, forKey: "drawsBackground")
        panel.contentView?.addSubview(webView)

        let resourcePath = Bundle.main.resourcePath ?? (Bundle.main.bundlePath as NSString).deletingLastPathComponent
        let htmlURL = URL(fileURLWithPath: (resourcePath as NSString).appendingPathComponent("index.html"))
        webView.loadFileURL(htmlURL, allowingReadAccessTo: URL(fileURLWithPath: resourcePath))

        panel.makeKeyAndOrderFront(nil)
    }

    // Handle messages from JavaScript
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let dict = message.body as? [String: Any],
              let action = dict["action"] as? String else { return }

        if action == "sessionStart" {
            // Float on top + shrink to compact
            panel.isFloatingPanel = true
            panel.level = .floating

            let origin = panel.frame.origin
            let oldHeight = panel.frame.height
            let newOrigin = NSPoint(x: origin.x, y: origin.y + (oldHeight - compactHeight))
            panel.setFrame(NSRect(origin: newOrigin, size: NSSize(width: compactWidth, height: compactHeight)), display: true, animate: true)

        } else if action == "sessionExpand" {
            // Expand to reflection size (taller) but stay floating on top
            let origin = panel.frame.origin
            let oldHeight = panel.frame.height
            let newOrigin = NSPoint(x: origin.x, y: origin.y + (oldHeight - reflectionHeight))
            panel.setFrame(NSRect(origin: newOrigin, size: NSSize(width: reflectionWidth, height: reflectionHeight)), display: true, animate: true)

        } else if action == "sessionStop" {
            // Back to normal level + restore full size
            panel.isFloatingPanel = false
            panel.level = .normal

            let origin = panel.frame.origin
            let oldHeight = panel.frame.height
            let newOrigin = NSPoint(x: origin.x, y: origin.y + (oldHeight - fullHeight))
            panel.setFrame(NSRect(origin: newOrigin, size: NSSize(width: fullWidth, height: fullHeight)), display: true, animate: true)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { return true }
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
