import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// Backing state for one Editor window. Phase 1a holds the Capture and drives Copy/Save;
/// annotation state and rendering land on top of this in the next step.
@MainActor
final class EditorModel: ObservableObject {

    let capture: Capture

    init(capture: Capture) {
        self.capture = capture
    }

    /// The Capture as an `NSImage` at true point size (so Retina pixels aren't shown doubled).
    var displayImage: NSImage {
        NSImage(cgImage: capture.image, size: capture.pointSize)
    }

    var pointSize: CGSize { capture.pointSize }

    // MARK: Output

    /// The image handed to clipboard/file. Once Annotations exist this composites them over the
    /// Capture; for now it is the raw Capture pixels.
    private func renderedCGImage() -> CGImage {
        capture.image
    }

    func copyToClipboard() {
        let image = NSImage(cgImage: renderedCGImage(), size: capture.pointSize)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
    }

    func save() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false
        panel.nameFieldStringValue = Self.defaultFileName()
        if let dir = Self.lastSaveDirectory { panel.directoryURL = dir }

        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url, let self else { return }
            self.writePNG(to: url)
            Self.lastSaveDirectory = url.deletingLastPathComponent()
        }
    }

    // MARK: Private

    private func writePNG(to url: URL) {
        let rep = NSBitmapImageRep(cgImage: renderedCGImage())
        rep.size = capture.pointSize
        guard let data = rep.representation(using: .png, properties: [:]) else {
            NSLog("Notable: failed to encode PNG")
            return
        }
        do {
            try data.write(to: url)
        } catch {
            NSLog("Notable: failed to write PNG — \(error)")
        }
    }

    private static func defaultFileName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd 'at' HH.mm.ss"
        return "Notable \(formatter.string(from: Date())).png"
    }

    private static let lastSaveDirectoryKey = "io.notable.lastSaveDirectory"

    private static var lastSaveDirectory: URL? {
        get {
            guard let path = UserDefaults.standard.string(forKey: lastSaveDirectoryKey) else { return nil }
            return URL(fileURLWithPath: path, isDirectory: true)
        }
        set {
            UserDefaults.standard.set(newValue?.path, forKey: lastSaveDirectoryKey)
        }
    }
}
