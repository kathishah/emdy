import AppKit

enum PasteboardService {
    static func copyRTF(from attributedString: NSAttributedString, range: NSRange) {
        let substring: NSAttributedString
        if range.length > 0 {
            substring = attributedString.attributedSubstring(from: range)
        } else {
            substring = attributedString
        }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        // RTF data
        if let rtfData = try? substring.data(
            from: NSRange(location: 0, length: substring.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        ) {
            pasteboard.setData(rtfData, forType: .rtf)
        }

        // Plain text fallback
        pasteboard.setString(substring.string, forType: .string)
    }
}
