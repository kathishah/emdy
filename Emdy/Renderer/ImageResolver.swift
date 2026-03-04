import AppKit

final class ImageResolver {
    let baseURL: URL?
    let palette: ColorPalette

    init(baseURL: URL?, isDark: Bool = false) {
        self.baseURL = baseURL
        self.palette = ColorPalette.current(dark: isDark)
    }

    func resolveImage(src: String, maxWidth: CGFloat = 600) -> NSAttributedString {
        if let image = loadImage(src: src) {
            return imageAttachment(image: image, maxWidth: maxWidth)
        }
        // Placeholder for failed loads
        let attrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: palette.muted,
            .font: NSFont.systemFont(ofSize: 12)
        ]
        return NSAttributedString(string: "[Image: \(src)]", attributes: attrs)
    }

    func resolveImageAsync(src: String, maxWidth: CGFloat = 600, completion: @escaping (NSAttributedString) -> Void) {
        // Try local first
        if let image = loadLocalImage(src: src) {
            completion(imageAttachment(image: image, maxWidth: maxWidth))
            return
        }

        // Try remote
        guard let url = URL(string: src), url.scheme == "http" || url.scheme == "https" else {
            completion(resolveImage(src: src, maxWidth: maxWidth))
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            DispatchQueue.main.async {
                if let data, let image = NSImage(data: data) {
                    completion(self.imageAttachment(image: image, maxWidth: maxWidth))
                } else {
                    completion(self.resolveImage(src: src, maxWidth: maxWidth))
                }
            }
        }.resume()
    }

    private func loadImage(src: String) -> NSImage? {
        loadLocalImage(src: src) ?? loadRemoteImageSync(src: src)
    }

    private func loadLocalImage(src: String) -> NSImage? {
        guard let base = baseURL?.deletingLastPathComponent() else { return nil }
        let fileURL = base.appendingPathComponent(src)
        return NSImage(contentsOf: fileURL)
    }

    private func loadRemoteImageSync(src: String) -> NSImage? {
        guard let url = URL(string: src),
              url.scheme == "http" || url.scheme == "https",
              let data = try? Data(contentsOf: url) else {
            return nil
        }
        return NSImage(data: data)
    }

    private func imageAttachment(image: NSImage, maxWidth: CGFloat) -> NSAttributedString {
        let size = image.size
        let scale = size.width > maxWidth ? maxWidth / size.width : 1.0
        let displaySize = NSSize(
            width: size.width * scale,
            height: size.height * scale
        )

        let attachment = NSTextAttachment()
        let cell = NSTextAttachmentCell(imageCell: image)
        cell.image?.size = displaySize
        attachment.attachmentCell = cell

        return NSAttributedString(attachment: attachment)
    }
}
