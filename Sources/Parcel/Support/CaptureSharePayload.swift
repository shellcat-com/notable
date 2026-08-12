import AppKit

struct CaptureShareAnchor {
    let rect: NSRect
    let view: NSView
    let preferredEdge: NSRectEdge
}

enum CaptureSharePayload {
    static let preferredEdge: NSRectEdge = .minY

    static func items(for image: NSImage) -> [Any] {
        [image]
    }

    static func picker(for image: NSImage) -> NSSharingServicePicker {
        NSSharingServicePicker(items: items(for: image))
    }

    static func anchor(in window: NSWindow?) -> CaptureShareAnchor? {
        guard let content = window?.contentView else { return nil }
        return CaptureShareAnchor(
            rect: content.bounds,
            view: content,
            preferredEdge: preferredEdge
        )
    }
}
