import AppKit
import SwiftUI
import WebKit

class AppDelegate: NSObject, NSApplicationDelegate {

    private var directoryWindow: NSWindow?
    private var shortcutWindow: NSWindow?
    private var welcomeWindow: NSWindow?
    private var helpWindow: NSWindow?
    private var currentPanel: NSOpenPanel?
    private var panelIsOpen = false
    private var panelDismissed = false

    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        false
    }

    private var strayPanelTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Listen for help-related notifications
        NotificationCenter.default.addObserver(
            self, selector: #selector(showShortcutCheatSheet),
            name: .showShortcutCheatSheet, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(showWelcomeScreen),
            name: .showWelcome, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(handleOpenDirectory(_:)),
            name: .openDirectory, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(showHelpWindow),
            name: .showHelp, object: nil
        )

        // Show welcome on first launch (skip open panel), otherwise show open panel
        if !UserDefaults.standard.bool(forKey: "hasShownWelcome") {
            UserDefaults.standard.set(true, forKey: "hasShownWelcome")
            DispatchQueue.main.async { [weak self] in
                self?.showWelcomeScreen()
            }
        } else {
            showOpenPanel()
        }
        // DocumentGroup may spawn its own NSOpenPanel after launch.
        // Poll briefly to close any stray panels it creates.
        strayPanelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            var found = false
            for window in NSApp.windows {
                if let stray = window as? NSOpenPanel, stray !== self?.currentPanel {
                    stray.close()
                    found = true
                }
            }
            // Stop after 2 seconds — if it hasn't appeared by then, it won't.
            if timer.fireDate.timeIntervalSince(Date()) < -2 {
                timer.invalidate()
                self?.strayPanelTimer = nil
            }
        }
        // Auto-invalidate after 2 seconds.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.strayPanelTimer?.invalidate()
            self?.strayPanelTimer = nil
        }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            var isDir: ObjCBool = false
            guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) else { continue }

            if isDir.boolValue {
                openDirectoryBrowser(url: url)
            } else {
                NSDocumentController.shared.openDocument(
                    withContentsOf: url, display: true) { _, _, _ in }
            }
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag && !panelDismissed && !(welcomeWindow?.isVisible ?? false) {
            showOpenPanel()
        }
        // Reset so a future dock-click can show the panel again.
        panelDismissed = false
        return true
    }

    func showOpenPanel() {
        guard !panelIsOpen else { return }
        panelIsOpen = true

        let panel = NSOpenPanel()
        currentPanel = panel
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select a file or folder to open"
        panel.prompt = "Open"

        panel.begin { [weak self] response in
            self?.panelIsOpen = false
            self?.currentPanel = nil

            guard response == .OK, let url = panel.url else {
                // User cancelled — suppress the reopen loop.
                self?.panelDismissed = true
                return
            }
            panel.close()

            var isDir: ObjCBool = false
            FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)

            if isDir.boolValue {
                self?.openDirectoryBrowser(url: url)
            } else {
                NSDocumentController.shared.openDocument(
                    withContentsOf: url, display: true) { _, _, _ in }
            }
        }
    }

    func openDirectoryBrowser(url: URL) {
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1280, height: 800)
        let width = min(screenFrame.width * 0.75, 1400)
        let height = min(screenFrame.height * 0.8, 900)

        let model = DirectoryModel(directoryURL: url)
        let view = DirectoryBrowserView(directory: model)
        let controller = NSHostingController(rootView: view)
        controller.sizingOptions = []

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        // Toolbar for NavigationSplitView integration.
        let toolbar = NSToolbar(identifier: "DirectoryBrowser")
        toolbar.displayMode = .iconAndLabel
        window.toolbar = toolbar
        window.toolbarStyle = .unified
        window.titleVisibility = .visible

        window.contentViewController = controller
        window.title = url.lastPathComponent
        window.minSize = NSSize(width: 700, height: 500)

        // Force the window to the intended size and center it.
        window.setContentSize(NSSize(width: width, height: height))
        window.center()

        // Keep a strong reference so the window isn't deallocated.
        directoryWindow = window
        window.makeKeyAndOrderFront(nil)
    }

    @objc private func handleOpenDirectory(_ notification: Notification) {
        guard let url = notification.object as? URL else { return }
        openDirectoryBrowser(url: url)
    }

    // MARK: - Help windows

    @objc func showShortcutCheatSheet() {
        if let existing = shortcutWindow, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            return
        }

        let controller = NSHostingController(rootView: ShortcutCheatSheet())
        let window = NSWindow(
            contentRect: .zero,
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.contentViewController = controller
        window.title = "Keyboard Shortcuts"
        window.center()
        shortcutWindow = window
        window.makeKeyAndOrderFront(nil)
    }

    @objc func showWelcomeScreen() {
        if let existing = welcomeWindow, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            return
        }

        let controller = NSHostingController(rootView: WelcomeView())
        let window = NSWindow(
            contentRect: .zero,
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.contentViewController = controller
        window.title = "Welcome to Emdy"
        // Force layout so the window knows its content size before centering
        controller.view.layoutSubtreeIfNeeded()
        window.setContentSize(controller.view.fittingSize)
        window.center()
        welcomeWindow = window
        window.makeKeyAndOrderFront(nil)
    }

    @objc func showHelpWindow() {
        if let existing = helpWindow, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            return
        }

        guard let helpBundle = Bundle.main.url(forResource: "Emdy", withExtension: "help"),
              let indexURL = helpBundle
                .appendingPathComponent("Contents/Resources/en.lproj/index.html") as URL? else {
            return
        }

        let webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 640, height: 520))
        webView.loadFileURL(indexURL, allowingReadAccessTo: indexURL.deletingLastPathComponent())

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 640, height: 520),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.contentView = webView
        window.title = "Emdy Help"
        window.minSize = NSSize(width: 400, height: 300)
        window.center()
        helpWindow = window
        window.makeKeyAndOrderFront(nil)
    }
}
