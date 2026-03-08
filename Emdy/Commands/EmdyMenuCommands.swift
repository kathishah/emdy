import SwiftUI

struct EmdyMenuCommands: Commands {
    var body: some Commands {
        // Remove Undo/Redo — not applicable for a read-only viewer
        CommandGroup(replacing: .undoRedo) {}

        // Replace standard Cut/Copy/Paste with just Copy and Select All
        // Route through NSApp.sendAction so the action reaches the NSTextView
        CommandGroup(replacing: .pasteboard) {
            Button("Copy") {
                NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: nil)
            }
            .keyboardShortcut("c", modifiers: .command)

            Button("Select All") {
                NSApp.sendAction(#selector(NSText.selectAll(_:)), to: nil, from: nil)
            }
            .keyboardShortcut("a", modifiers: .command)

            Divider()

            Button("Find…") {
                NotificationCenter.default.post(name: .findInPage, object: nil)
            }
            .keyboardShortcut("f", modifiers: .command)

            Button("Find Next") {
                NotificationCenter.default.post(name: .findNext, object: nil)
            }
            .keyboardShortcut("g", modifiers: .command)

            Button("Find Previous") {
                NotificationCenter.default.post(name: .findPrevious, object: nil)
            }
            .keyboardShortcut("g", modifiers: [.command, .shift])
        }

        CommandGroup(after: .toolbar) {
            Button("Refresh") {
                NotificationCenter.default.post(name: .refreshDocument, object: nil)
            }
            .keyboardShortcut("r", modifiers: .command)

            Button("Toggle Headings") {
                NotificationCenter.default.post(name: .toggleHeadingNavigator, object: nil)
            }
            .keyboardShortcut("h", modifiers: [.command, .shift])

            Button("Toggle Minimap") {
                NotificationCenter.default.post(name: .toggleMinimap, object: nil)
            }
            .keyboardShortcut("m", modifiers: [.command, .shift])

            Button("Export as PDF…") {
                NotificationCenter.default.post(name: .exportPDF, object: nil)
            }
            .keyboardShortcut("e", modifiers: [.command, .shift])
        }

        CommandGroup(after: .textFormatting) {
            Section {
                Button("Zoom In") {
                    NotificationCenter.default.post(name: .zoomIn, object: nil)
                }
                .keyboardShortcut("+", modifiers: .command)

                Button("Zoom Out") {
                    NotificationCenter.default.post(name: .zoomOut, object: nil)
                }
                .keyboardShortcut("-", modifiers: .command)

                Button("Actual Size") {
                    NotificationCenter.default.post(name: .zoomReset, object: nil)
                }
                .keyboardShortcut("0", modifiers: .command)
            }

            Divider()

            Section {
                Button("Sans-Serif") {
                    NotificationCenter.default.post(name: .setFont, object: FontFamily.sansSerif)
                }
                .keyboardShortcut("1", modifiers: .command)
                Button("Serif") {
                    NotificationCenter.default.post(name: .setFont, object: FontFamily.serif)
                }
                .keyboardShortcut("2", modifiers: .command)
                Button("Monospace") {
                    NotificationCenter.default.post(name: .setFont, object: FontFamily.monospace)
                }
                .keyboardShortcut("3", modifiers: .command)
            }

            Divider()

            Section {
                Button("Light") {
                    NotificationCenter.default.post(name: .setTheme, object: AppTheme.light)
                }
                .keyboardShortcut("7", modifiers: .command)
                Button("Dark") {
                    NotificationCenter.default.post(name: .setTheme, object: AppTheme.dark)
                }
                .keyboardShortcut("8", modifiers: .command)
                Button("System") {
                    NotificationCenter.default.post(name: .setTheme, object: AppTheme.system)
                }
                .keyboardShortcut("9", modifiers: .command)
            }
        }
    }
}

extension Notification.Name {
    static let zoomIn = Notification.Name("emdy.zoomIn")
    static let zoomOut = Notification.Name("emdy.zoomOut")
    static let zoomReset = Notification.Name("emdy.zoomReset")
    static let setFont = Notification.Name("emdy.setFont")
    static let setTheme = Notification.Name("emdy.setTheme")
    static let openDirectory = Notification.Name("emdy.openDirectory")
    static let findInPage = Notification.Name("emdy.findInPage")
    static let refreshDocument = Notification.Name("emdy.refreshDocument")
    static let toggleHeadingNavigator = Notification.Name("emdy.toggleHeadingNavigator")
    static let toggleMinimap = Notification.Name("emdy.toggleMinimap")
    static let exportPDF = Notification.Name("emdy.exportPDF")
    static let findNext = Notification.Name("emdy.findNext")
    static let findPrevious = Notification.Name("emdy.findPrevious")
    static let copyNotification = Notification.Name("emdy.copy")
}
