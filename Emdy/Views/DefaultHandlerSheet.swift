import SwiftUI

struct DefaultHandlerSheet: View {
    @Binding var isPresented: Bool
    @Environment(\.colorScheme) private var colorScheme

    private var palette: ColorPalette { .current(for: colorScheme) }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(Color(nsColor: palette.accent))

            Text("Set Emdy as your default Markdown viewer?")
                .font(.system(.headline, design: .monospaced))
                .foregroundStyle(Color(nsColor: palette.headline))
                .multilineTextAlignment(.center)

            Text("Markdown files (.md) will open in Emdy when you double-click them in Finder.")
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(Color(nsColor: palette.medium))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)

            HStack(spacing: 12) {
                Button("No Thanks") {
                    DefaultHandlerService.markPromptShown()
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)

                Button("Yes, Set as Default") {
                    DefaultHandlerService.setAsDefaultHandler()
                    DefaultHandlerService.markPromptShown()
                    isPresented = false
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .tint(Color(nsColor: palette.accent))
            }
        }
        .padding(32)
        .frame(width: 400)
    }
}
