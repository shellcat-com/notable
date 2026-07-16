import Foundation

/// Per-pixel color transform applied to the base Capture BEFORE Annotations composite over it.
/// Pure value type; the CIFilter chain lives in `CaptureAdjuster`. Neutral == untouched Capture.
struct Adjustments: Equatable {
    var brightness: Double = 0   // CIColorControls, additive
    var contrast: Double = 1     // CIColorControls, multiplicative
    var saturation: Double = 1   // CIColorControls, multiplicative
    var vibrance: Double = 0     // CIVibrance
    var temperature: Double = 0  // CITemperatureAndTint, ±100 → ±3000K
    var tint: Double = 0         // CITemperatureAndTint, green↔magenta
    var sharpness: Double = 0    // CISharpenLuminance

    static let neutral = Adjustments()
    var isNeutral: Bool { self == .neutral }
}

/// One slider in the Adjust panel: label, range, neutral value, and the field it drives.
enum AdjustmentParam: String, CaseIterable, Identifiable {
    case brightness, contrast, saturation, vibrance, temperature, tint, sharpness

    var id: String { rawValue }

    var label: String {
        switch self {
        case .brightness: return "Brightness"
        case .contrast: return "Contrast"
        case .saturation: return "Saturation"
        case .vibrance: return "Vibrance"
        case .temperature: return "Temperature"
        case .tint: return "Tint"
        case .sharpness: return "Sharpness"
        }
    }

    var range: ClosedRange<Double> {
        switch self {
        case .brightness: return -0.5...0.5
        case .contrast: return 0.5...1.5
        case .saturation: return 0...2
        case .vibrance: return -1...1
        case .temperature: return -100...100
        case .tint: return -100...100
        case .sharpness: return 0...2
        }
    }

    var neutralValue: Double {
        switch self {
        case .contrast, .saturation: return 1
        default: return 0
        }
    }

    var keyPath: WritableKeyPath<Adjustments, Double> {
        switch self {
        case .brightness: return \.brightness
        case .contrast: return \.contrast
        case .saturation: return \.saturation
        case .vibrance: return \.vibrance
        case .temperature: return \.temperature
        case .tint: return \.tint
        case .sharpness: return \.sharpness
        }
    }
}

/// Named combination of adjustment values. "Original" is the neutral escape hatch.
struct AdjustmentPreset: Identifiable, Hashable {
    let id: String
    let name: String
    let symbol: String
    let adjustments: Adjustments

    static func == (lhs: AdjustmentPreset, rhs: AdjustmentPreset) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    static let all: [AdjustmentPreset] = [
        AdjustmentPreset(id: "original", name: "Original", symbol: "circle", adjustments: .neutral),
        AdjustmentPreset(
            id: "punch", name: "Punch", symbol: "bolt.fill",
            adjustments: Adjustments(contrast: 1.12, saturation: 1.15, sharpness: 0.3)
        ),
        AdjustmentPreset(
            id: "vivid", name: "Vivid", symbol: "sun.max.fill",
            adjustments: Adjustments(contrast: 1.05, saturation: 1.1, vibrance: 0.5)
        ),
        AdjustmentPreset(
            id: "warm", name: "Warm", symbol: "thermometer.sun",
            adjustments: Adjustments(temperature: 40)
        ),
        AdjustmentPreset(
            id: "cool", name: "Cool", symbol: "snowflake",
            adjustments: Adjustments(temperature: -40)
        ),
        AdjustmentPreset(
            id: "mono", name: "Mono", symbol: "circle.lefthalf.filled",
            adjustments: Adjustments(contrast: 1.05, saturation: 0)
        ),
        AdjustmentPreset(
            id: "clarity", name: "Clarity", symbol: "wand.and.rays",
            adjustments: Adjustments(contrast: 1.08, sharpness: 0.6)
        ),
    ]
}
