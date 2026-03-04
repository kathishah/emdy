import SwiftUI
import AppKit

struct MarkdownTextView: NSViewRepresentable {
    let markdown: String
    let fontFamily: FontFamily
    let zoomLevel: CGFloat
    let fileURL: URL?
    let isDark: Bool

    private static let maxContentWidth: CGFloat = 680
    private static let minPadding: CGFloat = 56

    func makeNSView(context: Context) -> NSScrollView {
        let palette = ColorPalette.current(dark: isDark)

        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = true
        scrollView.backgroundColor = palette.background

        let textView = EmdyTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.isRichText = true
        textView.drawsBackground = true
        textView.backgroundColor = palette.background
        textView.textContainerInset = NSSize(width: Self.minPadding, height: 92)
        textView.isAutomaticLinkDetectionEnabled = false
        textView.delegate = context.coordinator

        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(
            width: 0,
            height: CGFloat.greatestFiniteMagnitude
        )

        scrollView.documentView = textView
        context.coordinator.textView = textView
        context.coordinator.fileURL = fileURL

        renderMarkdown(into: textView)
        updateContentInsets(textView)

        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.frameDidChange(_:)),
            name: NSView.frameDidChangeNotification,
            object: textView
        )
        textView.postsFrameChangedNotifications = true

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let palette = ColorPalette.current(dark: isDark)
        scrollView.backgroundColor = palette.background

        guard let textView = scrollView.documentView as? NSTextView else { return }
        textView.backgroundColor = palette.background
        context.coordinator.fileURL = fileURL
        renderMarkdown(into: textView)
        updateContentInsets(textView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    private func renderMarkdown(into textView: NSTextView) {
        let renderer = MarkdownRenderer(fontFamily: fontFamily, zoomLevel: zoomLevel, isDark: isDark)
        let attributed = renderer.render(markdown)
        textView.textStorage?.setAttributedString(attributed)
    }

    private func updateContentInsets(_ textView: NSTextView) {
        let viewWidth = textView.bounds.width
        let horizontalInset = computeInsets(for: viewWidth)
        textView.textContainerInset = NSSize(width: horizontalInset, height: 92)
    }

    private func computeInsets(for viewWidth: CGFloat) -> CGFloat {
        let availableForContent = viewWidth - (Self.minPadding * 2)
        if availableForContent <= Self.maxContentWidth {
            return Self.minPadding
        }
        return (viewWidth - Self.maxContentWidth) / 2
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        weak var textView: NSTextView?
        var fileURL: URL?

        func textView(_ textView: NSTextView, clickedOnLink link: Any, at charIndex: Int) -> Bool {
            LinkHandler.handleLink(link, fileURL: fileURL)
        }

        @objc func frameDidChange(_ notification: Notification) {
            guard let textView = textView else { return }
            let viewWidth = textView.bounds.width
            let availableForContent = viewWidth - (MarkdownTextView.minPadding * 2)
            let horizontalInset: CGFloat
            if availableForContent <= MarkdownTextView.maxContentWidth {
                horizontalInset = MarkdownTextView.minPadding
            } else {
                horizontalInset = (viewWidth - MarkdownTextView.maxContentWidth) / 2
            }
            textView.textContainerInset = NSSize(width: horizontalInset, height: 92)
        }
    }
}
