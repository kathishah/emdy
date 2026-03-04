import Foundation
import UniformTypeIdentifiers

enum DefaultHandlerService {
    private static let promptShownKey = "defaultHandlerPromptShown"

    static var hasShownPrompt: Bool {
        UserDefaults.standard.bool(forKey: promptShownKey)
    }

    static func markPromptShown() {
        UserDefaults.standard.set(true, forKey: promptShownKey)
    }

    static var shouldShowPrompt: Bool {
        !hasShownPrompt && !isDefaultHandler
    }

    static var isDefaultHandler: Bool {
        guard let bundleID = Bundle.main.bundleIdentifier else { return false }
        guard let handler = LSCopyDefaultRoleHandlerForContentType(
            "net.daringfireball.markdown" as CFString,
            .viewer
        )?.takeRetainedValue() as String? else {
            return false
        }
        return handler.caseInsensitiveCompare(bundleID) == .orderedSame
    }

    static func setAsDefaultHandler() {
        guard let bundleID = Bundle.main.bundleIdentifier else { return }
        LSSetDefaultRoleHandlerForContentType(
            "net.daringfireball.markdown" as CFString,
            .viewer,
            bundleID as CFString
        )
    }
}
