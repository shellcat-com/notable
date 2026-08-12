import AppKit

enum ClipboardCaptureReader {
    static func capture(from pasteboard: NSPasteboard, scale: CGFloat) -> Capture? {
        guard let image = NSImage(pasteboard: pasteboard),
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
        else {
            return nil
        }
        return Capture(image: cgImage, scale: max(scale, 1))
    }
}
