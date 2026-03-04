import SwiftUI

private let toolbarFont: Font = .system(size: 12)
private let toolbarIconFont: Font = .system(size: 10)

struct CopyButton: View {
    var action: () -> Void
    var isEnabled: Bool

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "doc.on.doc")
                    .font(toolbarIconFont)
                Text("Copy")
                    .font(toolbarFont)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .disabled(!isEnabled)
    }
}

struct PrintButton: View {
    var action: () -> Void
    var isEnabled: Bool

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "printer")
                    .font(toolbarIconFont)
                Text("Print")
                    .font(toolbarFont)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .disabled(!isEnabled)
    }
}

struct PDFButton: View {
    var action: () -> Void
    var isEnabled: Bool

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "arrow.down.doc")
                    .font(toolbarIconFont)
                Text("Save PDF")
                    .font(toolbarFont)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .disabled(!isEnabled)
    }
}
