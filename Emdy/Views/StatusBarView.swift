import SwiftUI

struct StatusBarView: View {
    let fileURL: URL?
    let wordCount: Int
    let isDark: Bool

    private var palette: ColorPalette {
        ColorPalette.current(dark: isDark)
    }

    private var dateModified: String? {
        guard let url = fileURL,
              let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let date = attrs[.modificationDate] as? Date else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var body: some View {
        HStack(spacing: 16) {
            if let date = dateModified {
                Text("Modified \(date)")
            }
            if wordCount > 0 {
                Text("\(wordCount.formatted()) words")
            }
            Spacer()
        }
        .font(.system(size: 11, weight: .regular, design: .default))
        .foregroundStyle(Color(nsColor: isDark ? NSColor(hex: "#B9B9B9") : palette.muted))
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .frame(height: 24)
        .background(Color(nsColor: palette.background))
    }
}
