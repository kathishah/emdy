import SwiftUI

// MARK: - Data model

private struct ShortcutEntry {
    let action: String
    let keys: String
}

private struct ShortcutCategory {
    let name: String
    let shortcuts: [ShortcutEntry]
}

// MARK: - Static data

private let shortcutCategories: [ShortcutCategory] = [
    ShortcutCategory(name: "File", shortcuts: [
        ShortcutEntry(action: "Open", keys: "⌘O"),
        ShortcutEntry(action: "Close", keys: "⌘W"),
        ShortcutEntry(action: "Print", keys: "⌘P"),
        ShortcutEntry(action: "Export PDF", keys: "⇧⌘E"),
    ]),
    ShortcutCategory(name: "Edit", shortcuts: [
        ShortcutEntry(action: "Copy", keys: "⌘C"),
        ShortcutEntry(action: "Select All", keys: "⌘A"),
        ShortcutEntry(action: "Find", keys: "⌘F"),
        ShortcutEntry(action: "Find Next", keys: "⌘G"),
        ShortcutEntry(action: "Find Previous", keys: "⇧⌘G"),
    ]),
    ShortcutCategory(name: "View", shortcuts: [
        ShortcutEntry(action: "Zoom In", keys: "⌘+"),
        ShortcutEntry(action: "Zoom Out", keys: "⌘−"),
        ShortcutEntry(action: "Actual Size", keys: "⌘0"),
        ShortcutEntry(action: "Sans-Serif", keys: "⌘1"),
        ShortcutEntry(action: "Serif", keys: "⌘2"),
        ShortcutEntry(action: "Monospace", keys: "⌘3"),
        ShortcutEntry(action: "Light", keys: "⌘7"),
        ShortcutEntry(action: "Dark", keys: "⌘8"),
        ShortcutEntry(action: "System", keys: "⌘9"),
        ShortcutEntry(action: "Toggle Headings", keys: "⇧⌘H"),
        ShortcutEntry(action: "Toggle Minimap", keys: "⇧⌘M"),
        ShortcutEntry(action: "Refresh", keys: "⌘R"),
    ]),
]

// MARK: - View

struct ShortcutCheatSheet: View {
    @Environment(\.colorScheme) private var colorScheme

    private var palette: ColorPalette { .current(for: colorScheme) }

    var body: some View {
        VStack(spacing: 20) {
            Text("Keyboard Shortcuts")
                .font(.system(.headline, design: .monospaced))
                .foregroundStyle(Color(nsColor: palette.headline))

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(shortcutCategories.indices, id: \.self) { index in
                        categorySection(shortcutCategories[index])
                    }
                }
                .padding(.horizontal, 4)
            }

            Button("Done") {
                NSApp.keyWindow?.close()
            }
            .keyboardShortcut(.cancelAction)
        }
        .padding(24)
        .frame(width: 380, height: 480)
    }

    @ViewBuilder
    private func categorySection(_ category: ShortcutCategory) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(category.name)
                .font(.system(.subheadline, design: .monospaced, weight: .bold))
                .foregroundStyle(Color(nsColor: palette.headline))

            VStack(spacing: 4) {
                ForEach(category.shortcuts.indices, id: \.self) { index in
                    shortcutRow(category.shortcuts[index])
                }
            }
        }
    }

    @ViewBuilder
    private func shortcutRow(_ entry: ShortcutEntry) -> some View {
        HStack {
            Text(entry.action)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(Color(nsColor: palette.body))

            Spacer()

            Text(entry.keys)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(Color(nsColor: palette.body))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(nsColor: palette.muted).opacity(0.25))
                )
        }
    }
}
