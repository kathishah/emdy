import AppKit

enum PDFExportService {
    static func savePDF(attributedString: NSAttributedString, suggestedName: String) -> Bool {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = suggestedName.replacingOccurrences(of: ".md", with: ".pdf")
        panel.canCreateDirectories = true

        guard panel.runModal() == .OK, let url = panel.url else { return false }

        let printView = NSTextView(frame: NSRect(x: 0, y: 0, width: 468, height: 648))
        printView.textStorage?.setAttributedString(attributedString)
        printView.isEditable = false
        printView.sizeToFit()

        let printInfo = NSPrintInfo()
        printInfo.topMargin = 72
        printInfo.bottomMargin = 72
        printInfo.leftMargin = 72
        printInfo.rightMargin = 72
        printInfo.jobDisposition = .save
        printInfo.dictionary()[NSPrintInfo.AttributeKey.jobSavingURL] = url

        let printOperation = NSPrintOperation(view: printView, printInfo: printInfo)
        printOperation.showsPrintPanel = false
        printOperation.showsProgressPanel = true
        return printOperation.run()
    }
}
