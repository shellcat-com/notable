import CoreGraphics

enum SelectionAspectPreset: String, CaseIterable, Identifiable {
    case free, square, standard, widescreen

    var id: String { rawValue }
    var label: String {
        switch self {
        case .free: return "Free"
        case .square: return "1:1"
        case .standard: return "4:3"
        case .widescreen: return "16:9"
        }
    }
    var ratio: CGFloat? {
        switch self {
        case .free: return nil
        case .square: return 1
        case .standard: return 4.0 / 3.0
        case .widescreen: return 16.0 / 9.0
        }
    }

    var next: SelectionAspectPreset {
        let all = Self.allCases
        guard let index = all.firstIndex(of: self) else { return self }
        return all[(index + 1) % all.count]
    }
}

enum SelectionGeometry {
    static func rect(
        start: CGPoint,
        snappedEnd: CGPoint,
        aspectPreset: SelectionAspectPreset,
        bypassPreset: Bool
    ) -> CGRect {
        var end = snappedEnd
        if !bypassPreset, let ratio = aspectPreset.ratio {
            let dx = end.x - start.x
            let dy = end.y - start.y
            let horizontal = dx >= 0 ? 1.0 : -1.0
            let vertical = dy >= 0 ? 1.0 : -1.0
            var width = abs(dx)
            var height = abs(dy)
            if width / max(height, 0.001) > ratio {
                height = width / ratio
            } else {
                width = height * ratio
            }
            end = CGPoint(x: start.x + horizontal * width, y: start.y + vertical * height)
        }
        return CGRect(corner: start, corner: end)
    }
}
