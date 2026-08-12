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
    /// When set, OCR-mode commits route here.
    var onOCRCommit: ((CGRect) -> Void)? = nil
    /// When set, Record-mode commits route here.
    var onRecordCommit: ((CGRect) -> Void)? = nil
    /// Initial All-in-One mode (defaults to region).
    var initialMode: OverlayCaptureMode = .region

    @State private var dragOrigin: CGPoint?
    @State private var dragCurrent: CGPoint?
    @State private var liveRect: CGRect?
    @State private var hoverWindow: SnapWindow?
    @State private var snapCycleIndex = -1
    @State private var isDragging = false
    @State private var aspectPreset: SelectionAspectPreset = .free
    @State private var mode: OverlayCaptureMode = .region
    @State private var cursorPoint: CGPoint?

    private var showCrosshair: Bool { CapturePreferences.showCrosshair }
    private var showMagnifier: Bool { CapturePreferences.showMagnifier }
    private var showAllInOne: Bool { CapturePreferences.showAllInOneBar }

    /// The rect currently emphasized: an in-progress drag, else the hovered window.
    private var highlightRect: CGRect? {
        if mode == .fullscreen { return CGRect(origin: .zero, size: frozen.pointSize) }
        return liveRect ?? hoverWindow?.frameInScreen
    }

    var body: some View {
        GeometryReader { _ in
            ZStack(alignment: .topTrailing) {
                Image(decorative: frozen.image, scale: frozen.scale, orientation: .up)
                    .resizable()
                    .frame(width: frozen.pointSize.width, height: frozen.pointSize.height)

                DimmingLayer(hole: highlightRect)

                if showCrosshair, let point = cursorPoint, liveRect == nil {
                    CrosshairLayer(point: point, bounds: frozen.pointSize)
                }

                if showMagnifier, let point = cursorPoint, !isDragging {
                    MagnifierLoupe(frozen: frozen, point: point)
                }

                if liveRect == nil, mode != .fullscreen, let win = hoverWindow {
                    windowHighlight(win)
                }

                if let rect = liveRect {
                    selectionBorder(rect)
                    sizeReadout(for: rect)
                }

                VStack {
                    if showAllInOne {
                        allInOneBar
                            .padding(.top, 14)
                    }
                    Spacer()
                    HStack {
                        overlayHints
                        Spacer()
                        if onScrollCommit != nil, !showAllInOne {
                            scrollCaptureButton
                        }
                    }
                    .padding(14)
                }

                if !showAllInOne {
                    aspectMenu
                        .padding(14)
                }
            }
            .frame(width: frozen.pointSize.width, height: frozen.pointSize.height)
            .contentShape(Rectangle())
            .gesture(dragGesture)
            .onContinuousHover { phase in
                switch phase {
                case .active(let point):
                    NSCursor.crosshair.set()
                    cursorPoint = point
                    if !isDragging, mode != .fullscreen {
                        hoverWindow = frozen.window(at: point)
                        snapCycleIndex = -1
                    }
                case .ended:
                    cursorPoint = nil
                    hoverWindow = nil
                    snapCycleIndex = -1
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .overlayTabPressed)) { note in
                guard note.object as? CGDirectDisplayID == frozen.id else { return }
                handleTab()
            }
            .onAppear { mode = initialMode }
        }
        .ignoresSafeArea()
    }

    // MARK: Gesture

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                cursorPoint = value.location
                if mode == .window || mode == .fullscreen { return }
                if dragOrigin == nil { dragOrigin = value.startLocation }
                dragCurrent = value.location
                let rect = selectionRect(start: value.startLocation, current: value.location)
                if rect.width > 2 || rect.height > 2 {
                    isDragging = true
                    hoverWindow = nil
                    snapCycleIndex = -1
                    liveRect = rect
                }
            }
            .onEnded { value in
                defer {
                    dragOrigin = nil
                    dragCurrent = nil
                    isDragging = false
                    liveRect = nil
                }

                if mode == .fullscreen {
                    commitSelection(CGRect(origin: .zero, size: frozen.pointSize))
                    return
                }

                if mode == .window {
                    if let win = hoverWindow ?? frozen.window(at: value.location) {
                        commitSelection(win.frameInScreen.integral)
                    }
                    return
                }

                let travelled = value.startLocation.distance(to: value.location)
                if travelled < 4 {
                    if mode == .region || mode == .scroll {
                        if let win = hoverWindow ?? frozen.window(at: value.location) {
                            commitSelection(win.frameInScreen.integral)
                        }
                    }
                } else {
                    let rect = selectionRect(start: value.startLocation, current: value.location).integral
                    if rect.width >= 1, rect.height >= 1 { commitSelection(rect) }
                }
            }
    }

    private func handleTab() {
        if isDragging, let start = dragOrigin, let current = dragCurrent {
            aspectPreset = aspectPreset.next
            liveRect = selectionRect(start: start, current: current)
            return
        }
        cycleSnapWindow()
    }

    private func cycleSnapWindow() {
        let windows = frozen.windows.sorted { $0.frameInScreen.area < $1.frameInScreen.area }
        guard !windows.isEmpty else { return }
        snapCycleIndex = (snapCycleIndex + 1) % windows.count
        hoverWindow = windows[snapCycleIndex]
    }

    private func commitSelection(_ rect: CGRect) {
        switch mode {
        case .scroll:
            if let onScrollCommit {
                onScrollCommit(rect)
            } else {
                onCommit(rect)
            }
        case .ocr:
            if let onOCRCommit {
                onOCRCommit(rect)
            } else {
                onCommit(rect)
            }
        case .record:
            if let onRecordCommit {
                onRecordCommit(rect)
            } else {
                onCommit(rect)
            }
        case .region, .window, .fullscreen:
            onCommit(rect)
        }
    }

    /// Snaps the actively dragged corner to display and detected-window boundaries, then applies
    /// an optional aspect preset while retaining the original drag direction.
    /// Hold ⇧ Shift while dragging to temporarily ignore the aspect preset.
    private func selectionRect(start: CGPoint, current: CGPoint) -> CGRect {
        SelectionGeometry.rect(
            start: start,
            snappedEnd: snapped(point: current),
            aspectPreset: aspectPreset,
            bypassPreset: NSEvent.modifierFlags.contains(.shift)
        )
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
            .stroke(mode == .ocr ? Color.green : Color.accentColor, lineWidth: 1.5)
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
            Text(mode.hint)
                .font(.system(size: 11, weight: .medium))
            Text("Tab window snap · Tab aspect while dragging · Esc to cancel")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private var scrollCaptureButton: some View {
        Button {
            mode = mode == .scroll ? .region : .scroll
        } label: {
            Label(mode == .scroll ? "Scroll mode on" : "Scroll Capture", systemImage: "arrow.up.and.down.text.horizontal")
                .font(.system(size: 11, weight: .medium))
        }
        .buttonStyle(.borderedProminent)
        .tint(mode == .scroll ? .orange : .accentColor)
        .help("Select a region, then scroll the source to stitch frames")
    }

    private var allInOneBar: some View {
        HStack(spacing: 4) {
            ForEach(availableModes) { item in
                Button {
                    mode = item
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: item.systemImage)
                            .font(.system(size: 13, weight: .semibold))
                        Text(item.label)
                            .font(.system(size: 9, weight: .medium))
                    }
                    .frame(width: 58, height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(mode == item ? Color.accentColor.opacity(0.9) : Color.black.opacity(0.55))
                    )
                    .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .help(item.hint)
            }

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
                    .frame(width: 36, height: 40)
                    .background(Color.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(.white)
            }
            .menuStyle(.borderlessButton)
            .help("Selection aspect ratio")
        }
        .padding(6)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.25), radius: 10, y: 4)
    }

    private var availableModes: [OverlayCaptureMode] {
        OverlayCaptureMode.allCases
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

// MARK: - Crosshair / Magnifier

private struct CrosshairLayer: View {
    let point: CGPoint
    let bounds: CGSize

    var body: some View {
        ZStack {
            Path { path in
                path.move(to: CGPoint(x: 0, y: point.y))
                path.addLine(to: CGPoint(x: bounds.width, y: point.y))
            }
            .stroke(Color.white.opacity(0.55), lineWidth: 1)

            Path { path in
                path.move(to: CGPoint(x: point.x, y: 0))
                path.addLine(to: CGPoint(x: point.x, y: bounds.height))
            }
            .stroke(Color.white.opacity(0.55), lineWidth: 1)
        }
        .allowsHitTesting(false)
    }
}

private struct MagnifierLoupe: View {
    let frozen: FrozenScreen
    let point: CGPoint

    private let loupeSize: CGFloat = 110
    private let zoom: CGFloat = 2.5

    var body: some View {
        let crop = CGRect(
            x: point.x - loupeSize / (2 * zoom),
            y: point.y - loupeSize / (2 * zoom),
            width: loupeSize / zoom,
            height: loupeSize / zoom
        )
        let pixel = CGRect(
            x: crop.minX * frozen.scale,
            y: crop.minY * frozen.scale,
            width: crop.width * frozen.scale,
            height: crop.height * frozen.scale
        ).integral
        let clamped = pixel.intersection(
            CGRect(x: 0, y: 0, width: frozen.image.width, height: frozen.image.height)
        )

        Group {
            if clamped.width > 1, clamped.height > 1, let cropped = frozen.image.cropping(to: clamped) {
                Image(decorative: cropped, scale: frozen.scale / zoom, orientation: .up)
                    .frame(width: loupeSize, height: loupeSize)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .shadow(radius: 6)
                    .position(loupePosition)
            }
        }
        .allowsHitTesting(false)
    }

    private var loupePosition: CGPoint {
        var x = point.x + loupeSize * 0.7
        var y = point.y + loupeSize * 0.7
        if x + loupeSize / 2 > frozen.pointSize.width {
            x = point.x - loupeSize * 0.7
        }
        if y + loupeSize / 2 > frozen.pointSize.height {
            y = point.y - loupeSize * 0.7
        }
        return CGPoint(x: x, y: y)
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
