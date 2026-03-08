import SwiftUI
import UniformTypeIdentifiers

extension View {
    /// Accepts dropped `.md` files or directories and opens them.
    func markdownFileDrop() -> some View {
        onDrop(of: [.fileURL], isTargeted: nil) { providers in
            guard let provider = providers.first else { return false }
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { data, _ in
                guard let data = data as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else { return }

                DispatchQueue.main.async {
                    var isDir: ObjCBool = false
                    guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) else { return }

                    if isDir.boolValue {
                        (NSApp.delegate as? AppDelegate)?.openDirectoryBrowser(url: url)
                    } else {
                        let ext = url.pathExtension.lowercased()
                        guard ["md", "markdown", "mdown", "mkd"].contains(ext) else { return }
                        NSDocumentController.shared.openDocument(
                            withContentsOf: url, display: true) { _, _, _ in }
                    }
                }
            }
            return true
        }
    }
}
