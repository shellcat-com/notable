import SwiftUI

/// The SwiftUI selection UI drawn inside an `OverlayWindow` for one frozen display.
///
/// Interaction: drag = rectangular Selection (commits on release); single click on a highlighted
/// window = window-snap Selection. Esc (handled by `OverlayController`) cancels.
struct SelectionOverlayView: View {
    let frozen: FrozenScreen
    /// Commit a Selection rect (local top-left points) for this display.
    let onCommit: (CGRect) -> Void

    @State private var dragOrigin: CGPoint?
    @State private var liveRect: CGRect?
    @State private var hoverWindow: SnapWindow?
    @State private var isDragging = false

    /// The rect currently emphasized: an in-progress drag, else the hovered window.
    private var highlightRect: CGRect? {
        liveRect ?? hoverWindow?.frameInScreen
    }

    var body: some View {
        GeometryReader { _ in
            ZStack {
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
                let rect = CGRect(corner: value.startLocation, corner: value.location)
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
                        onCommit(win.frameInScreen.integral)
                    }
                } else {
                    let rect = CGRect(corner: value.startLocation, corner: value.location).integral
                    if rect.width >= 1, rect.height >= 1 { onCommit(rect) }
                }
            }
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
