import SwiftUI

struct SidebarFileRow: View {
    let url: URL
    let isSelected: Bool
    @Environment(\.colorScheme) private var colorScheme

    private var palette: ColorPalette { .current(for: colorScheme) }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "doc.text")
                .font(.system(size: 14))
                .foregroundStyle(Color(nsColor: palette.medium))

            Text(url.lastPathComponent)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(Color(nsColor: palette.body))
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isSelected ? Color(nsColor: palette.sidebarSelection) : .clear)
        .cornerRadius(4)
    }
}
