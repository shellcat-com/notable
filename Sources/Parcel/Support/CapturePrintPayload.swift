import AppKit

enum CapturePrintPayload {
    static func printableView(for image: NSImage) -> NSImageView {
        let view = NSImageView(image: image)
        view.frame = NSRect(origin: .zero, size: image.size)
        return view
    }

    static func printInfo(from base: NSPrintInfo = .shared) -> NSPrintInfo {
        let info = (base.copy() as? NSPrintInfo) ?? NSPrintInfo()
        info.horizontalPagination = .fit
        info.verticalPagination = .fit
        return info
    }

    static func printOperation(for image: NSImage, showsPrintPanel: Bool = true) -> NSPrintOperation {
        let operation = NSPrintOperation(
            view: printableView(for: image),
            printInfo: printInfo()
        )
        operation.showsPrintPanel = showsPrintPanel
        return operation
    }
}
