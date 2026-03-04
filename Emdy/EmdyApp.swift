import SwiftUI

@main
struct EmdyApp: App {
    @State private var showDefaultHandlerPrompt = false

    var body: some Scene {
        DocumentGroup(viewing: MarkdownDocument.self) { file in
            DocumentContentView(document: file.document)
                .configureWindow()
                .sheet(isPresented: $showDefaultHandlerPrompt) {
                    DefaultHandlerSheet(isPresented: $showDefaultHandlerPrompt)
                }
                .onAppear {
                    if DefaultHandlerService.shouldShowPrompt {
                        showDefaultHandlerPrompt = true
                    }
                }
        }
        .defaultSize(width: 800, height: 600)
        .commands {
            EmdyMenuCommands()
            OpenFolderCommand()
        }

        WindowGroup("Directory Browser", for: URL.self) { $url in
            if let url {
                DirectoryBrowserView(directory: DirectoryModel(directoryURL: url))
                    .configureWindow()
            }
        }
        .defaultSize(width: 960, height: 600)
    }
}

struct OpenFolderCommand: Commands {
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("Open Folder\u{2026}") {
                let panel = NSOpenPanel()
                panel.canChooseFiles = false
                panel.canChooseDirectories = true
                panel.allowsMultipleSelection = false
                panel.message = "Choose a folder containing Markdown files"

                guard panel.runModal() == .OK, let url = panel.url else { return }
                openWindow(value: url)
            }
            .keyboardShortcut("o", modifiers: [.command, .shift])
        }
    }
}
