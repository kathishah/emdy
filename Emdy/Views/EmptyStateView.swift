import SwiftUI

struct EmptyStateView: View {
    @Environment(\.colorScheme) private var colorScheme

    private var palette: ColorPalette { .current(for: colorScheme) }

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Color(nsColor: palette.muted))

            Text("Open a Markdown file to get started")
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(Color(nsColor: palette.body))

            Text("File \u{2192} Open  or  \u{2318}O")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(Color(nsColor: palette.muted))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: palette.background))
    }
}
