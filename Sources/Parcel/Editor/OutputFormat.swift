import AppKit
import UniformTypeIdentifiers

/// Native image formats macOS can encode without bundling a third-party codec.
enum OutputFormat: String, CaseIterable, Identifiable, Codable {
    case png, jpeg, heic, tiff

    var id: String { rawValue }
    var label: String { rawValue.uppercased() }
    var fileExtension: String { rawValue == "jpeg" ? "jpg" : rawValue }
    var contentType: UTType {
        switch self {
        case .png: return .png
        case .jpeg: return .jpeg
        case .heic: return .heic
        case .tiff: return .tiff
        }
    }
    var bitmapType: NSBitmapImageRep.FileType? {
        switch self {
        case .png: return .png
        case .jpeg: return .jpeg
        case .heic: return nil
        case .tiff: return .tiff
        }
    }
}
