import AppKit

enum PrintService {
    static func print(attributedString: NSAttributedString) {
        let printView = NSTextView(frame: NSRect(x: 0, y: 0, width: 468, height: 648))
        printView.textStorage?.setAttributedString(attributedString)
        printView.isEditable = false
        printView.sizeToFit()

        let printInfo = NSPrintInfo.shared
        printInfo.topMargin = 72
        printInfo.bottomMargin = 72
        printInfo.leftMargin = 72
        printInfo.rightMargin = 72

        let printOperation = NSPrintOperation(view: printView, printInfo: printInfo)
        printOperation.showsPrintPanel = true
        printOperation.showsProgressPanel = true
        printOperation.run()
    }
}
