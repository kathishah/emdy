import AppKit

enum PDFExportService {
    static func savePDF(attributedString: NSAttributedString, suggestedName: String) -> Bool {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = suggestedName.replacingOccurrences(of: ".md", with: ".pdf")
        panel.canCreateDirectories = true

        guard panel.runModal() == .OK, let url = panel.url else { return false }

        let printInfo = NSPrintInfo()
        printInfo.topMargin = 72
        printInfo.bottomMargin = 72
        printInfo.leftMargin = 72
        printInfo.rightMargin = 72
        printInfo.jobDisposition = .save
        printInfo.dictionary()[NSPrintInfo.AttributeKey.jobSavingURL] = url

        // Content width = page width minus margins
        let pageWidth = printInfo.paperSize.width
        let contentWidth = pageWidth - printInfo.leftMargin - printInfo.rightMargin

        let printView = NSTextView(frame: NSRect(x: 0, y: 0, width: contentWidth, height: 1_000_000))
        printView.isEditable = false
        printView.isVerticallyResizable = true
        printView.isHorizontallyResizable = false
        printView.textContainer?.containerSize = NSSize(width: contentWidth, height: .greatestFiniteMagnitude)
        printView.textContainer?.widthTracksTextView = true
        printView.textContainer?.lineFragmentPadding = 0

        // Strip the bottom margin marker attribute before export
        let exportString = NSMutableAttributedString(attributedString: attributedString)
        let fullRange = NSRange(location: 0, length: exportString.length)
        exportString.enumerateAttribute(
            NSAttributedString.Key("EmdyBottomMargin"),
            in: fullRange,
            options: .reverse
        ) { value, range, _ in
            if value != nil {
                exportString.deleteCharacters(in: range)
            }
        }

        // Scale down images that exceed content width
        exportString.enumerateAttribute(.attachment, in: NSRange(location: 0, length: exportString.length), options: []) { value, _, _ in
            guard let attachment = value as? NSTextAttachment,
                  let cell = attachment.attachmentCell as? NSCell,
                  cell.cellSize.width > contentWidth else { return }
            let scale = contentWidth / cell.cellSize.width
            let newSize = NSSize(width: contentWidth, height: cell.cellSize.height * scale)
            attachment.bounds = CGRect(origin: .zero, size: newSize)
        }

        printView.textStorage?.setAttributedString(exportString)

        // Force layout so tables and images are measured correctly
        printView.layoutManager?.ensureLayout(forCharacterRange: NSRange(location: 0, length: exportString.length))
        if let layoutManager = printView.layoutManager, let textContainer = printView.textContainer {
            let contentRect = layoutManager.usedRect(for: textContainer)
            printView.frame = NSRect(x: 0, y: 0, width: contentWidth, height: contentRect.height)
        }

        let printOperation = NSPrintOperation(view: printView, printInfo: printInfo)
        printOperation.showsPrintPanel = false
        printOperation.showsProgressPanel = true
        return printOperation.run()
    }
}
