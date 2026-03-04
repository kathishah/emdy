import AppKit

enum LinkHandler {
    static func handleLink(_ link: Any, fileURL: URL?) -> Bool {
        let urlString: String
        if let string = link as? String {
            urlString = string
        } else if let url = link as? URL {
            urlString = url.absoluteString
        } else {
            return false
        }

        // Anchor links (scroll within document)
        if urlString.hasPrefix("#") {
            return false
        }

        // Relative .md links — open in Emdy
        if isMarkdownLink(urlString), let resolved = resolveRelativeURL(urlString, relativeTo: fileURL) {
            NSWorkspace.shared.open(resolved)
            return true
        }

        // External links — open in default browser
        if let url = URL(string: urlString), url.scheme == "http" || url.scheme == "https" || url.scheme == "mailto" {
            NSWorkspace.shared.open(url)
            return true
        }

        // Relative non-markdown links — try to resolve and open
        if let resolved = resolveRelativeURL(urlString, relativeTo: fileURL) {
            NSWorkspace.shared.open(resolved)
            return true
        }

        return false
    }

    private static func isMarkdownLink(_ urlString: String) -> Bool {
        let lower = urlString.lowercased()
        let extensions = [".md", ".markdown", ".mdown", ".mkd"]
        return extensions.contains(where: { lower.hasSuffix($0) || lower.contains($0 + "#") })
    }

    private static func resolveRelativeURL(_ path: String, relativeTo fileURL: URL?) -> URL? {
        guard let base = fileURL?.deletingLastPathComponent() else { return nil }
        let cleanPath = path.components(separatedBy: "#").first ?? path
        let resolved = base.appendingPathComponent(cleanPath)
        return FileManager.default.fileExists(atPath: resolved.path) ? resolved : nil
    }
}
