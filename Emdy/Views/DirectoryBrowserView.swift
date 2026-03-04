import SwiftUI

struct DirectoryBrowserView: View {
    @State var directory: DirectoryModel
    @State private var settings = DisplaySettings()
    @State private var currentText: String = ""

    var body: some View {
        NavigationSplitView {
            SidebarFileList(directory: directory)
        } detail: {
            if !currentText.isEmpty {
                MarkdownTextView(
                    markdown: currentText,
                    fontFamily: settings.fontFamily,
                    zoomLevel: settings.zoomLevel,
                    fileURL: directory.selectedFile,
                    isDark: settings.theme.isDark
                )
            } else {
                EmptyStateView()
            }
        }
        .applyTheme(settings.theme)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                ZoomControls(settings: settings, isEnabled: !currentText.isEmpty)
                FontPicker(settings: settings, isEnabled: !currentText.isEmpty)
                ThemePicker(settings: settings)

                Spacer()

                CopyButton(action: {
                    NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: nil)
                }, isEnabled: !currentText.isEmpty)
                PrintButton(action: {
                    NSApp.sendAction(#selector(NSView.printView(_:)), to: nil, from: nil)
                }, isEnabled: !currentText.isEmpty)
            }
        }
        .navigationTitle(directory.directoryURL.lastPathComponent)
        .onChange(of: directory.selectedFile) { _, newValue in
            loadFile(newValue)
        }
        .onAppear {
            loadFile(directory.selectedFile)
        }
        .onReceive(NotificationCenter.default.publisher(for: .zoomIn)) { _ in
            settings.zoomIn()
        }
        .onReceive(NotificationCenter.default.publisher(for: .zoomOut)) { _ in
            settings.zoomOut()
        }
        .onReceive(NotificationCenter.default.publisher(for: .zoomReset)) { _ in
            settings.zoomReset()
        }
        .onReceive(NotificationCenter.default.publisher(for: .setFont)) { notification in
            if let family = notification.object as? FontFamily {
                settings.fontFamily = family
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .setTheme)) { notification in
            if let theme = notification.object as? AppTheme {
                settings.theme = theme
            }
        }
    }

    private func loadFile(_ url: URL?) {
        guard let url else {
            currentText = ""
            return
        }
        currentText = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
    }
}
