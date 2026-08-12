import Foundation

/// Capture intent chosen from the All-in-One strip on the Selection Overlay.
enum OverlayCaptureMode: String, CaseIterable, Identifiable {
    case region
    case window
    case fullscreen
    case scroll
    case ocr
    case record

    var id: String { rawValue }

    var label: String {
        switch self {
        case .region: return "Region"
        case .window: return "Window"
        case .fullscreen: return "Display"
        case .scroll: return "Scroll"
        case .ocr: return "OCR"
        case .record: return "Record"
        }
    }

    var systemImage: String {
        switch self {
        case .region: return "rectangle.dashed"
        case .window: return "macwindow"
        case .fullscreen: return "rectangle"
        case .scroll: return "arrow.up.and.down.text.horizontal"
        case .ocr: return "text.viewfinder"
        case .record: return "record.circle"
        }
    }

    var hint: String {
        switch self {
        case .region: return "Drag to select · Click window to snap"
        case .window: return "Click a window to Capture it"
        case .fullscreen: return "Click anywhere to Capture this display"
        case .scroll: return "Drag a tall region, then add scroll frames"
        case .ocr: return "Drag text to copy it on-device to the clipboard"
        case .record: return "Drag a region to start recording"
        }
    }
}
