import AppKit
import UniformTypeIdentifiers

/// Image formats Parcel can export. WebP uses bundled libwebp because ImageIO
/// does not expose a WebP destination on every supported macOS version.
enum OutputFormat: String, CaseIterable, Identifiable, Codable {
    case png, jpeg, heic, tiff, webp

    var id: String { rawValue }
    var label: String { rawValue.uppercased() }
    var fileExtension: String {
        switch self {
        case .jpeg: return "jpg"
        default: return rawValue
        }
    }

    var contentType: UTType {
        switch self {
        case .png: return .png
        case .jpeg: return .jpeg
        case .heic: return .heic
        case .tiff: return .tiff
        case .webp: return UTType(filenameExtension: "webp") ?? .data
        }
    }

    /// HEIC goes through ImageIO; WebP is handled by ParcelWebPEncoder.
    var usesImageIO: Bool {
        self == .heic
    }

    var bitmapType: NSBitmapImageRep.FileType? {
        switch self {
        case .png: return .png
        case .jpeg: return .jpeg
        case .tiff: return .tiff
        case .heic, .webp: return nil
        }
    }
}
