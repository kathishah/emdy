import SwiftUI
import UniformTypeIdentifiers

final class MarkdownDocument: ReferenceFileDocument {
    let text: String
    let fileURL: URL?

    static var readableContentTypes: [UTType] { [.markdown, .plainText] }

    init(text: String = "", fileURL: URL? = nil) {
        self.text = text
        self.fileURL = fileURL
    }

    required init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.text = string
        self.fileURL = nil
    }

    func snapshot(contentType: UTType) throws -> String {
        text
    }

    func fileWrapper(snapshot: String, configuration: WriteConfiguration) throws -> FileWrapper {
        throw CocoaError(.fileWriteNoPermission)
    }
}
