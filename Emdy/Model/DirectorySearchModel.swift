import Foundation

@Observable
final class DirectorySearchModel {
    var query: String = ""
    private(set) var matchingFiles: Set<URL> = []

    var isSearching: Bool { !query.isEmpty }

    private var searchTask: Task<Void, Never>?

    func search(in nodes: [FileNode], query: String) {
        searchTask?.cancel()

        guard !query.isEmpty else {
            matchingFiles = []
            return
        }

        let nameMatches = collectFileNameMatches(in: nodes, query: query)
        matchingFiles = nameMatches

        searchTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(200))
            guard !Task.isCancelled else { return }

            let allFiles = collectAllFiles(from: nodes)
            let contentMatches = await searchFileContents(files: allFiles, query: query)
            guard !Task.isCancelled else { return }

            await MainActor.run {
                self?.matchingFiles = nameMatches.union(contentMatches)
            }
        }
    }

    func clear() {
        searchTask?.cancel()
        query = ""
        matchingFiles = []
    }

    // MARK: - Helpers

    private func collectFileNameMatches(in nodes: [FileNode], query: String) -> Set<URL> {
        var results = Set<URL>()
        for node in nodes {
            if !node.isDirectory {
                if node.name.localizedCaseInsensitiveContains(query) {
                    results.insert(node.url)
                }
            }
            if let children = node.children {
                results.formUnion(collectFileNameMatches(in: children, query: query))
            }
        }
        return results
    }

    private func collectAllFiles(from nodes: [FileNode]) -> [URL] {
        var files: [URL] = []
        for node in nodes {
            if !node.isDirectory {
                files.append(node.url)
            }
            if let children = node.children {
                files.append(contentsOf: collectAllFiles(from: children))
            }
        }
        return files
    }

    private func searchFileContents(files: [URL], query: String) async -> Set<URL> {
        var matches = Set<URL>()
        for file in files {
            if Task.isCancelled { break }
            guard let contents = try? String(contentsOf: file, encoding: .utf8) else { continue }
            if contents.localizedCaseInsensitiveContains(query) {
                matches.insert(file)
            }
        }
        return matches
    }
}
