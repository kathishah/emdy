import SwiftUI

struct WindowAccessor: NSViewRepresentable {
    let callback: (NSWindow?) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            callback(view.window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        callback(nsView.window)
    }
}

extension View {
    func configureWindow(minWidth: CGFloat = 700, minHeight: CGFloat = 500) -> some View {
        background(WindowAccessor { window in
            guard let window else { return }
            window.titlebarAppearsTransparent = false
            window.isMovableByWindowBackground = true
            window.minSize = NSSize(width: minWidth, height: minHeight)
        })
    }

    func applyTheme(_ theme: AppTheme) -> some View {
        self
            .background(WindowAccessor { window in
                guard let window else { return }
                let target = theme.resolvedAppearance
                window.appearance = target
                window.backgroundColor = ColorPalette.current(dark: theme.isDark).background
                // Recursively force all subviews (NSVisualEffectView, etc.) to redraw
                forceAppearanceUpdate(on: window.contentView, appearance: target)
                window.viewsNeedDisplay = true
                window.displayIfNeeded()
                window.invalidateShadow()
            })
            .preferredColorScheme(theme.preferredColorScheme)
    }
}

private func forceAppearanceUpdate(on view: NSView?, appearance: NSAppearance) {
    guard let view else { return }
    view.appearance = appearance
    view.needsDisplay = true
    view.needsLayout = true
    for subview in view.subviews {
        forceAppearanceUpdate(on: subview, appearance: appearance)
    }
}
