import SwiftUI

struct ToastView: View {
    let message: String
    let onDismiss: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var isVisible = true

    private var palette: ColorPalette { .current(for: colorScheme) }

    var body: some View {
        if isVisible {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color(nsColor: palette.success))

                Text(message)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(Color(nsColor: palette.body))

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color(nsColor: palette.medium))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(nsColor: palette.successBackground))
            .cornerRadius(6)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    dismiss()
                }
            }
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.2)) {
            isVisible = false
        }
        onDismiss()
    }
}

struct ToastModifier: ViewModifier {
    @Binding var toast: ToastMessage?

    func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            if let toast {
                ToastView(message: toast.message) {
                    self.toast = nil
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: toast != nil)
    }
}

struct ToastMessage: Equatable {
    let message: String
}

extension View {
    func toast(_ toast: Binding<ToastMessage?>) -> some View {
        modifier(ToastModifier(toast: toast))
    }
}
