import CoreGraphics
import Foundation

/// Routes `parcel://` URL scheme actions into AppCoordinator.
enum ParcelURLAction: Equatable {
    case region
    case area(CGRect, CGDirectDisplayID?)
    case window
    case fullscreen
    case previous
    case scroll
    case ocr
    case record
    case history
    case annotateLast
    case openClipboard
    case restoreRecentlyClosed
    case hideOverlays
}

enum ParcelURLRouter {
    @MainActor
    static func route(_ url: URL, coordinator: AppCoordinator) {
        guard let action = action(for: url) else {
            NSLog("Parcel: unrecognized URL \(url.absoluteString)")
            return
        }
        route(action, coordinator: coordinator)
    }

    static func action(for url: URL) -> ParcelURLAction? {
        guard url.scheme?.lowercased() == "parcel" else { return nil }
        let host = (url.host ?? "").lowercased()
        let path = url.path.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        var query: [String: String] = [:]
        for item in components?.queryItems ?? [] {
            if let value = item.value {
                query[item.name.lowercased()] = value
            }
        }

        switch (host, path) {
        case ("capture", "region"), ("capture", ""):
            if let rect = parseRect(query) {
                let displayID: CGDirectDisplayID? = query["display"].flatMap { raw in
                    guard let value = UInt32(raw), value != 0 else { return nil }
                    return CGDirectDisplayID(value)
                }
                return .area(rect, displayID)
            } else {
                return .region
            }
        case ("capture", "window"):
            return .window
        case ("capture", "fullscreen"), ("capture", "display"):
            return .fullscreen
        case ("capture", "previous"):
            return .previous
        case ("capture", "scroll"):
            return .scroll
        case ("ocr", _), ("capture", "ocr"):
            return .ocr
        case ("record", _), ("capture", "record"):
            return .record
        case ("open", "history"), ("history", _):
            return .history
        case ("annotate", "last"), ("open", "annotate"):
            return .annotateLast
        case ("open", "clipboard"):
            return .openClipboard
        case ("restore", _), ("open", "restore"):
            return .restoreRecentlyClosed
        case ("overlays", "hide"), ("hide", "overlays"):
            return .hideOverlays
        default:
            // parcel://region style without host path
            switch host {
            case "region": return .region
            case "window": return .window
            case "fullscreen", "display": return .fullscreen
            case "previous": return .previous
            case "scroll": return .scroll
            case "ocr": return .ocr
            case "record": return .record
            case "history": return .history
            default: return nil
            }
        }
    }

    @MainActor
    private static func route(_ action: ParcelURLAction, coordinator: AppCoordinator) {
        switch action {
        case .region:
            coordinator.beginRegionCapture()
        case let .area(rect, displayID):
            coordinator.beginAreaCapture(rect: rect, displayID: displayID)
        case .window:
            coordinator.beginWindowCapture()
        case .fullscreen:
            coordinator.beginFullscreenCapture()
        case .previous:
            coordinator.beginPreviousAreaCapture()
        case .scroll:
            coordinator.beginScrollCapture()
        case .ocr:
            coordinator.beginOCRCapture()
        case .record:
            coordinator.toggleRecording()
        case .history:
            coordinator.openHistory()
        case .annotateLast:
            coordinator.annotateLastCapture()
        case .openClipboard:
            coordinator.openFromClipboard()
        case .restoreRecentlyClosed:
            coordinator.restoreRecentlyClosed()
        case .hideOverlays:
            coordinator.hideAllOverlays()
        }
    }

    private static func parseRect(_ query: [String: String]) -> CGRect? {
        guard
            let x = query["x"].flatMap(Double.init),
            let y = query["y"].flatMap(Double.init),
            let w = query["width"].flatMap(Double.init) ?? query["w"].flatMap(Double.init),
            let h = query["height"].flatMap(Double.init) ?? query["h"].flatMap(Double.init),
            w > 0, h > 0
        else { return nil }
        return CGRect(x: x, y: y, width: w, height: h)
    }
}
