import AppKit
import Foundation
import UniformTypeIdentifiers

/// Saves / opens editable `.parcel` project bundles (Capture PNG + document JSON).
enum ParcelProjectIO {
    @MainActor
    static func save(model: EditorModel, to url: URL) {
        let fileManager = FileManager.default
        let temp = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        do {
            try fileManager.createDirectory(at: temp, withIntermediateDirectories: true)
            let captureURL = temp.appendingPathComponent("capture.png")
            let rep = NSBitmapImageRep(cgImage: model.capture.image)
            guard let data = rep.representation(using: .png, properties: [:]) else { return }
            try data.write(to: captureURL, options: .atomic)

            let document = model.historyDocument(
                id: UUID(),
                createdAt: Date(),
                captureFileName: "capture.png"
            )
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            try encoder.encode(document).write(
                to: temp.appendingPathComponent("document.json"),
                options: .atomic
            )

            if fileManager.fileExists(atPath: url.path) {
                try fileManager.removeItem(at: url)
            }
            try fileManager.copyItem(at: temp, to: url)
            try? fileManager.removeItem(at: temp)
        } catch {
            NSLog("Parcel: failed to write .parcel project — \(error)")
        }
    }

    @MainActor
    static func open(from url: URL) -> RestoredCaptureDocument? {
        let documentURL = url.appendingPathComponent("document.json")
        let captureURL = url.appendingPathComponent("capture.png")
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let document = try decoder.decode(CaptureDocument.self, from: Data(contentsOf: documentURL))
            let data = try Data(contentsOf: captureURL)
            guard let rep = NSBitmapImageRep(data: data), let image = rep.cgImage else { return nil }
            return RestoredCaptureDocument(
                capture: Capture(image: image, scale: document.captureScale),
                document: document
            )
        } catch {
            NSLog("Parcel: failed to open .parcel project — \(error)")
            return nil
        }
    }
}
