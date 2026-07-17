import CoreGraphics
import SwiftUI

extension RGBAColor {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}

/// A named linear-gradient background for the Beautify frame.
struct GradientPreset: Identifiable, Equatable, Codable {
    let id: String
    let name: String
    let colors: [RGBAColor]
    /// Direction in degrees; 0° = left→right, 90° = top→bottom.
    let angle: Double

    var startUnitPoint: UnitPoint {
        let a = angle * .pi / 180
        return UnitPoint(x: 0.5 - cos(a) / 2, y: 0.5 - sin(a) / 2)
    }

    var endUnitPoint: UnitPoint {
        let a = angle * .pi / 180
        return UnitPoint(x: 0.5 + cos(a) / 2, y: 0.5 + sin(a) / 2)
    }

    var gradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: colors.map(\.color)),
            startPoint: startUnitPoint,
            endPoint: endUnitPoint
        )
    }

    static var defaultPreset: GradientPreset { all[0] }

    private static func preset(_ name: String, _ hexes: [UInt32], _ angle: Double) -> GradientPreset {
        GradientPreset(id: name.lowercased(), name: name, colors: hexes.map { RGBAColor(hex: $0) }, angle: angle)
    }

    /// 30 original gradient presets (name / stops / angle).
    static let all: [GradientPreset] = [
        preset("Sunset", [0xFF7E5F, 0xFEB47B], 120),
        preset("Twilight", [0x6A11CB, 0x2575FC], 135),
        preset("Mojito", [0x1D976C, 0x93F9B9], 120),
        preset("Bloom", [0xFF5F6D, 0xFFC371], 120),
        preset("Sky", [0x56CCF2, 0x2F80ED], 120),
        preset("Grape", [0xDA22FF, 0x9733EE], 135),
        preset("Rouge", [0xFF512F, 0xDD2476], 120),
        preset("Peach", [0xED4264, 0xFFEDBC], 120),
        preset("Mint", [0x00B09B, 0x96C93D], 120),
        preset("Ocean", [0x2193B0, 0x6DD5ED], 120),
        preset("Lavender", [0x654EA3, 0xEAAFC8], 120),
        preset("Coral", [0xFF9966, 0xFF5E62], 120),
        preset("Aqua", [0x13547A, 0x80D0C7], 120),
        preset("Slate", [0x232526, 0x414345], 120),
        preset("Graphite", [0x434343, 0x000000], 120),
        preset("Blush", [0xFFC3A0, 0xFFAFBD], 120),
        preset("Citrus", [0xFDC830, 0xF37335], 120),
        preset("Berry", [0xC31432, 0x240B36], 135),
        preset("Forest", [0x134E5E, 0x71B280], 120),
        preset("Fuchsia", [0xEB3349, 0xF45C43], 120),
        preset("Indigo", [0x4776E6, 0x8E54E9], 135),
        preset("Emerald", [0x43C6AC, 0x191654], 135),
        preset("Flame", [0xF12711, 0xF5AF19], 120),
        preset("Steel", [0x757F9A, 0xD7DDE8], 120),
        preset("Royal", [0x141E30, 0x243B55], 120),
        preset("Sunrise", [0xFF512F, 0xF09819], 120),
        preset("Cotton", [0xD9AFD9, 0x97D9E1], 120),
        preset("Cyan", [0x4E54C8, 0x8F94FB], 135),
        preset("Rose", [0xE55D87, 0x5FC3E4], 120),
        preset("Midnight", [0x0F2027, 0x203A43, 0x2C5364], 120),
    ]
}

/// Document-level frame around the Capture: background, padding, corner radius, shadow, chrome.
/// NOT part of the annotation undo stack — every control is directly reversible, plus panel Reset.
///
/// This type is the single source of the geometry formulas:
///   innerOrigin = (padding, padding + chromeHeight)
///   outerSize   = (captureW + 2·padding, captureH + 2·padding + chromeHeight)
struct BeautifySettings: Equatable, Codable {

    enum Background: Equatable, Codable {
        case none
        case solid(RGBAColor)
        case gradient(GradientPreset)
    }

    struct ShadowSettings: Equatable, Codable {
        var enabled = true
        var blur: CGFloat = 24
        var opacity: Double = 0.35
        var yOffset: CGFloat = 12
    }

    enum ChromeStyle: String, CaseIterable, Identifiable, Equatable, Codable {
        case light, dark
        var id: String { rawValue }
        var label: String { self == .light ? "Light" : "Dark" }
    }

    struct ChromeSettings: Equatable, Codable {
        var enabled = false
        var title = ""
        var style: ChromeStyle = .light
    }

    var background: Background = .gradient(GradientPreset.defaultPreset)
    var padding: CGFloat = 48
    var cornerRadius: CGFloat = 12
    var shadow = ShadowSettings()
    var chrome = ChromeSettings()

    var chromeHeight: CGFloat { chrome.enabled ? 28 : 0 }

    /// Where the Capture's (0,0) lands in beautify-point space.
    var innerOrigin: CGPoint { CGPoint(x: padding, y: padding + chromeHeight) }

    /// The window silhouette (chrome bar + Capture) in beautify points.
    func windowFrame(for capture: CGSize) -> CGRect {
        CGRect(x: padding, y: padding, width: capture.width, height: chromeHeight + capture.height)
    }

    /// Total composition size in beautify points.
    func outerSize(for capture: CGSize) -> CGSize {
        CGSize(width: capture.width + 2 * padding, height: capture.height + 2 * padding + chromeHeight)
    }

    /// Pass-through: outerSize == capture size, innerOrigin == .zero, nothing drawn around the
    /// Capture. Exports stay byte-identical to a plain AnnotatedCanvas render.
    static let disabled = BeautifySettings(
        background: .none,
        padding: 0,
        cornerRadius: 0,
        shadow: ShadowSettings(enabled: false),
        chrome: ChromeSettings(enabled: false)
    )
}
