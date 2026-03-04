import Foundation

@Observable
final class DirectoryModel {
    let directoryURL: URL
    private(set) var files: [URL] = []
    var selectedFile: URL?

    private static let markdownExtensions: Set<String> = ["md", "markdown", "mdown", "mkd"]

    init(directoryURL: URL) {
        self.directoryURL = directoryURL
        loadFiles()
    }

    func loadFiles() {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            files = []
            return
        }

        files = contents
            .filter { Self.markdownExtensions.contains($0.pathExtension.lowercased()) }
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }

        if selectedFile == nil, let first = files.first {
            selectedFile = first
        }
    }
}
