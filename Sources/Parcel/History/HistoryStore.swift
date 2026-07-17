import AppKit
import Foundation
import SwiftUI

/// The complete editable state of one locally retained Capture. The source image stays separate
/// on disk so the JSON remains small and the original pixels are never altered by document edits.
struct CaptureDocument: Codable, Identifiable {
    let id: UUID
    let createdAt: Date
    var updatedAt: Date
    let captureFileName: String
    let captureScale: CGFloat
    var annotations: [Annotation]
    var adjustments: Adjustments
    var beautify: BeautifySettings
    var beautifyEnabled: Bool
    var outputFormat: OutputFormat

    enum CodingKeys: String, CodingKey {
        case id, createdAt, updatedAt, captureFileName, captureScale
        case annotations, adjustments, beautify, beautifyEnabled, outputFormat
    }

    init(
        id: UUID,
        createdAt: Date,
        updatedAt: Date,
        captureFileName: String,
        captureScale: CGFloat,
        annotations: [Annotation],
        adjustments: Adjustments,
        beautify: BeautifySettings,
        beautifyEnabled: Bool,
        outputFormat: OutputFormat = .png
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.captureFileName = captureFileName
        self.captureScale = captureScale
        self.annotations = annotations
        self.adjustments = adjustments
        self.beautify = beautify
        self.beautifyEnabled = beautifyEnabled
        self.outputFormat = outputFormat
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        captureFileName = try container.decode(String.self, forKey: .captureFileName)
        captureScale = try container.decode(CGFloat.self, forKey: .captureScale)
        annotations = try container.decode([Annotation].self, forKey: .annotations)
        adjustments = try container.decode(Adjustments.self, forKey: .adjustments)
        beautify = try container.decode(BeautifySettings.self, forKey: .beautify)
        beautifyEnabled = try container.decode(Bool.self, forKey: .beautifyEnabled)
        outputFormat = try container.decodeIfPresent(OutputFormat.self, forKey: .outputFormat) ?? .png
    }
}

/// Compact metadata used by the History list.
struct HistoryEntry: Codable, Identifiable, Equatable {
    let id: UUID
    let createdAt: Date
    var updatedAt: Date
    let captureFileName: String
    let pixelWidth: Int
    let pixelHeight: Int

    var displayDate: String {
        Self.displayFormatter.string(from: updatedAt)
    }

    private static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

struct RestoredCaptureDocument {
    let capture: Capture
    let document: CaptureDocument
}

/// Disk-backed local history. It deliberately has no network path: entries are private by
/// default, re-editable, and available before any optional sync service is configured.
@MainActor
final class HistoryStore: ObservableObject {

    @Published private(set) var entries: [HistoryEntry] = []

    private let fileManager: FileManager
    private let rootURL: URL
    private let indexURL: URL

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        rootURL = appSupport
            .appendingPathComponent(AppIdentity.appSupportComponent, isDirectory: true)
            .appendingPathComponent("History", isDirectory: true)
        indexURL = rootURL.appendingPathComponent("index.json")
        createRootIfNeeded()
        loadIndex()
    }

    @discardableResult
    func createDocument(for capture: Capture) -> UUID? {
        let id = UUID()
        let now = Date()
        let fileName = "capture.png"
        let document = CaptureDocument(
            id: id,
            createdAt: now,
            updatedAt: now,
            captureFileName: fileName,
            captureScale: capture.scale,
            annotations: [],
            adjustments: .neutral,
            beautify: BeautifySettings(),
            beautifyEnabled: false
        )
        let entry = HistoryEntry(
            id: id,
            createdAt: now,
            updatedAt: now,
            captureFileName: fileName,
            pixelWidth: capture.image.width,
            pixelHeight: capture.image.height
        )

        do {
            let directory = directoryURL(for: id)
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            guard let imageData = NSBitmapImageRep(cgImage: capture.image)
                .representation(using: .png, properties: [:]) else {
                throw CocoaError(.fileWriteUnknown)
            }
            try imageData.write(to: directory.appendingPathComponent(fileName), options: .atomic)
            try write(document, to: documentURL(for: id))
            entries.insert(entry, at: 0)
            writeIndex()
            return id
        } catch {
            NSLog("Parcel: could not create local history entry — \(error)")
            return nil
        }
    }

    func save(_ document: CaptureDocument) {
        do {
            var updated = document
            updated.updatedAt = Date()
            try write(updated, to: documentURL(for: document.id))
            if let index = entries.firstIndex(where: { $0.id == document.id }) {
                entries[index].updatedAt = updated.updatedAt
                entries.sort { $0.updatedAt > $1.updatedAt }
                writeIndex()
            }
        } catch {
            NSLog("Parcel: could not save local history entry — \(error)")
        }
    }

    func restore(_ id: UUID) -> RestoredCaptureDocument? {
        do {
            let document = try read(CaptureDocument.self, from: documentURL(for: id))
            let data = try Data(contentsOf: directoryURL(for: id).appendingPathComponent(document.captureFileName))
            guard let rep = NSBitmapImageRep(data: data), let image = rep.cgImage else {
                throw CocoaError(.fileReadCorruptFile)
            }
            return RestoredCaptureDocument(
                capture: Capture(image: image, scale: document.captureScale),
                document: document
            )
        } catch {
            NSLog("Parcel: could not restore local history entry — \(error)")
            return nil
        }
    }

    func preview(for entry: HistoryEntry) -> NSImage? {
        NSImage(contentsOf: directoryURL(for: entry.id).appendingPathComponent(entry.captureFileName))
    }

    func entry(for id: UUID) -> HistoryEntry? {
        entries.first { $0.id == id }
    }

    func remove(_ id: UUID) {
        do {
            let directory = directoryURL(for: id)
            guard directory.path.hasPrefix(rootURL.path) else { return }
            if fileManager.fileExists(atPath: directory.path) {
                try fileManager.removeItem(at: directory)
            }
            entries.removeAll { $0.id == id }
            writeIndex()
        } catch {
            NSLog("Parcel: could not remove local history entry — \(error)")
        }
    }

    func removeAll() {
        for entry in entries { remove(entry.id) }
    }

    // MARK: Disk helpers

    private func createRootIfNeeded() {
        do {
            try fileManager.createDirectory(at: rootURL, withIntermediateDirectories: true)
        } catch {
            NSLog("Parcel: could not create history directory — \(error)")
        }
    }

    private func loadIndex() {
        guard fileManager.fileExists(atPath: indexURL.path) else { return }
        do {
            entries = try read([HistoryEntry].self, from: indexURL).sorted { $0.updatedAt > $1.updatedAt }
        } catch {
            NSLog("Parcel: could not read local history index — \(error)")
        }
    }

    private func writeIndex() {
        do {
            try write(entries, to: indexURL)
        } catch {
            NSLog("Parcel: could not write local history index — \(error)")
        }
    }

    private func directoryURL(for id: UUID) -> URL {
        rootURL.appendingPathComponent(id.uuidString, isDirectory: true)
    }

    private func documentURL(for id: UUID) -> URL {
        directoryURL(for: id).appendingPathComponent("document.json")
    }

    private func write<T: Encodable>(_ value: T, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(value).write(to: url, options: .atomic)
    }

    private func read<T: Decodable>(_ type: T.Type, from url: URL) throws -> T {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: Data(contentsOf: url))
    }
}

struct BrandKit: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var settings: BeautifySettings
}

/// Named Beautify settings for repeatable branded Capture exports. Kept locally until a user
/// explicitly configures an optional sync service.
@MainActor
final class BrandKitStore: ObservableObject {
    static let shared = BrandKitStore()

    @Published private(set) var kits: [BrandKit] = []
    private let defaultsKey = "\(AppIdentity.defaultsPrefix).brandKits"

    private init() {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey) else { return }
        kits = (try? JSONDecoder().decode([BrandKit].self, from: data)) ?? []
    }

    func save(name: String, settings: BeautifySettings) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        kits.append(BrandKit(id: UUID(), name: trimmed, settings: settings))
        persist()
    }

    func remove(_ id: UUID) {
        kits.removeAll { $0.id == id }
        persist()
    }

    private func persist() {
        UserDefaults.standard.set(try? JSONEncoder().encode(kits), forKey: defaultsKey)
    }
}
