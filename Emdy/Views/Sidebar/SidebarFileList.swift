import SwiftUI

struct SidebarFileList: View {
    @Bindable var directory: DirectoryModel
    @Environment(\.colorScheme) private var colorScheme

    private var palette: ColorPalette { .current(for: colorScheme) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("FILES")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color(nsColor: palette.muted))
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 8)

            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(directory.files, id: \.self) { file in
                        SidebarFileRow(url: file, isSelected: directory.selectedFile == file)
                            .onTapGesture {
                                directory.selectedFile = file
                            }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .frame(minWidth: 200, idealWidth: 220, maxWidth: 280)
        .background(Color(nsColor: palette.sidebarBackground))
    }
}
