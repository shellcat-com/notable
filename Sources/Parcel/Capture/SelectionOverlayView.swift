import SwiftUI

/// The SwiftUI selection UI drawn inside an `OverlayWindow` for one frozen display.
///
/// Interaction: drag = rectangular Selection (commits on release); single click on a highlighted
/// window = window-snap Selection. Esc (handled by `OverlayController`) cancels.
struct SelectionOverlayView: View {
    let frozen: FrozenScreen
    /// Commit a Selection rect (local top-left points) for this display.
    let onCommit: (CGRect) -> Void
    /// When set, a Scroll Capture button appears; commits route here instead of `onCommit`.
    var onScrollCommit: ((CGRect) -> Void)? = nil

    @State private var dragOrigin: CGPoint?
    @State private var liveRect: CGRect?
    @State private var hoverWindow: SnapWindow?
    @State private var isDragging = false
    @State private var aspectPreset: SelectionAspectPreset = .free
    @State private var isScrollMode = false

    /// The rect currently emphasized: an in-progress drag, else the hovered window.
    private var highlightRect: CGRect? {
        liveRect ?? hoverWindow?.frameInScreen
    }

    var body: some View {
        GeometryReader { _ in
            ZStack(alignment: .topTrailing) {
                Image(decorative: frozen.image, scale: frozen.scale, orientation: .up)
                    .resizable()
                    .frame(width: frozen.pointSize.width, height: frozen.pointSize.height)

                DimmingLayer(hole: highlightRect)

                if liveRect == nil, let win = hoverWindow {
                    windowHighlight(win)
                }

                if let rect = liveRect {
                    selectionBorder(rect)
                    sizeReadout(for: rect)
                }

                VStack {
                    Spacer()
                    HStack {
                        overlayHints
                        Spacer()
                        if onScrollCommit != nil {
                            scrollCaptureButton
                        }
                    }
                    .padding(14)
                }

                aspectMenu
                    .padding(14)
            }
            .frame(width: frozen.pointSize.width, height: frozen.pointSize.height)
            .contentShape(Rectangle())
            .gesture(dragGesture)
            .onContinuousHover { phase in
                switch phase {
                case .active(let point):
                    NSCursor.crosshair.set()
                    if !isDragging { hoverWindow = frozen.window(at: point) }
                case .ended:
                    hoverWindow = nil
                }
            }
        }
        .ignoresSafeArea()
    }

    // MARK: Gesture

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if dragOrigin == nil { dragOrigin = value.startLocation }
                let rect = selectionRect(start: value.startLocation, current: value.location)
                if rect.width > 2 || rect.height > 2 {
                    isDragging = true
                    hoverWindow = nil
                    liveRect = rect
                }
            }
            .onEnded { value in
                defer { dragOrigin = nil; isDragging = false; liveRect = nil }
                let travelled = value.startLocation.distance(to: value.location)
                if travelled < 4 {
                    // A click — snap to the window under the cursor, if any.
                    if let win = frozen.window(at: value.location) {
                        commitSelection(win.frameInScreen.integral)
                    }
                } else {
                    let rect = selectionRect(start: value.startLocation, current: value.location).integral
                    if rect.width >= 1, rect.height >= 1 { commitSelection(rect) }
                }
            }
    }

    private func commitSelection(_ rect: CGRect) {
        if isScrollMode, let onScrollCommit {
            onScrollCommit(rect)
        } else {
            onCommit(rect)
        }
    }

    /// Snaps the actively dragged corner to display and detected-window boundaries, then applies
    /// an optional aspect preset while retaining the original drag direction.
    private func selectionRect(start: CGPoint, current: CGPoint) -> CGRect {
        var end = snapped(point: current)
        if let ratio = aspectPreset.ratio {
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

    private func snapped(point: CGPoint) -> CGPoint {
        let threshold: CGFloat = 8
        let verticalEdges = [CGFloat(0), frozen.pointSize.width] + frozen.windows.flatMap {
            [$0.frameInScreen.minX, $0.frameInScreen.maxX]
        }
        let horizontalEdges = [CGFloat(0), frozen.pointSize.height] + frozen.windows.flatMap {
            [$0.frameInScreen.minY, $0.frameInScreen.maxY]
        }
        let x = verticalEdges.min(by: { abs($0 - point.x) < abs($1 - point.x) }) ?? point.x
        let y = horizontalEdges.min(by: { abs($0 - point.y) < abs($1 - point.y) }) ?? point.y
        return CGPoint(
            x: abs(x - point.x) <= threshold ? x : point.x,
            y: abs(y - point.y) <= threshold ? y : point.y
        )
    }

    // MARK: Pieces

    private func windowHighlight(_ win: SnapWindow) -> some View {
        Rectangle()
            .fill(Color.accentColor.opacity(0.14))
            .overlay(Rectangle().stroke(Color.accentColor, lineWidth: 2))
            .frame(width: win.frameInScreen.width, height: win.frameInScreen.height)
            .position(x: win.frameInScreen.midX, y: win.frameInScreen.midY)
            .allowsHitTesting(false)
    }

    private func selectionBorder(_ rect: CGRect) -> some View {
        Rectangle()
            .stroke(Color.accentColor, lineWidth: 1.5)
            .frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
            .allowsHitTesting(false)
    }

    private func sizeReadout(for rect: CGRect) -> some View {
        Text("\(Int(rect.width.rounded())) × \(Int(rect.height.rounded()))")
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(.black.opacity(0.75), in: RoundedRectangle(cornerRadius: 4))
            .fixedSize()
            .position(x: rect.midX, y: max(rect.minY - 14, 12))
            .allowsHitTesting(false)
    }

    private var overlayHints: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(isScrollMode ? "Scroll Capture — drag a tall region" : "Drag to select · Click window to snap")
                .font(.system(size: 11, weight: .medium))
            Text("Esc to cancel")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private var scrollCaptureButton: some View {
        Button {
            isScrollMode.toggle()
        } label: {
            Label(isScrollMode ? "Scroll mode on" : "Scroll Capture", systemImage: "arrow.up.and.down.text.horizontal")
                .font(.system(size: 11, weight: .medium))
        }
        .buttonStyle(.borderedProminent)
        .tint(isScrollMode ? .orange : .accentColor)
        .help("Select a region, then scroll the source to stitch frames")
    }

    private var aspectMenu: some View {
        Menu {
            ForEach(SelectionAspectPreset.allCases) { preset in
                Button {
                    aspectPreset = preset
                } label: {
                    if aspectPreset == preset {
                        Label(preset.label, systemImage: "checkmark")
                    } else {
                        Text(preset.label)
                    }
                }
            }
        } label: {
            Image(systemName: "aspectratio")
                .frame(width: 28, height: 28)
                .background(.black.opacity(0.72), in: RoundedRectangle(cornerRadius: 5))
                .foregroundStyle(.white)
        }
        .menuStyle(.borderlessButton)
        .help("Selection aspect ratio")
    }
}

private enum SelectionAspectPreset: String, CaseIterable, Identifiable {
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
}

/// Full-screen dim with a bright "hole" punched out over the active Selection/window.
private struct DimmingLayer: View {
    let hole: CGRect?

    var body: some View {
        GeometryReader { geo in
            Path { path in
                path.addRect(CGRect(origin: .zero, size: geo.size))
                if let hole { path.addRect(hole) }
            }
            .fill(Color.black.opacity(0.35), style: FillStyle(eoFill: true))
        }
        .allowsHitTesting(false)
    }
}
