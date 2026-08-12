import AppKit
import SwiftUI

/// The interactive Canvas: hosts the shared `BeautifyCanvas` at fit-zoom and layers on drawing,
/// selection/move/resize, inline text editing, utility overlays, and keyboard commands.
///
/// Coordinate rule (the ONE mapping, everywhere):
///   capturePoint = viewPoint / scale − innerOrigin
/// where innerOrigin = effectiveSettings.innerOrigin absorbs the Beautify padding/chrome, and the
/// inverse (+ innerOrigin·scale) positions the Capture-space overlays (handles, text editor).
struct EditorCanvasView: View {
    @ObservedObject var model: EditorModel

    @State private var draft: Annotation?
    @State private var op: DragOp = .none
    @State private var lastClick: (time: Date, point: CGPoint)?
    @State private var hoverLocation: CGPoint? // canvas-local view points, same space as the drag
    @State private var rotationDragStartAngle: CGFloat = 0
    @State private var shiftHeld = false
    @State private var spaceHeld = false
    @State private var draftRepositionAnchor: CGPoint?
    @FocusState private var textFocused: Bool

    private enum DragOp {
        case none
        case empty
        case creating
        case moving(before: [Annotation], original: AnnotationKind)
        case resizing(before: [Annotation], handle: Handle, original: AnnotationKind)
        case rotating(before: [Annotation], center: CGPoint, originalRotation: CGFloat)
    }

    var body: some View {
        GeometryReader { geo in
            let settings = model.effectiveSettings
            let outer = settings.outerSize(for: model.pointSize)
            let scale = fitScale(outer: outer, into: geo.size)
            let origin = settings.innerOrigin
            let display = CGSize(width: outer.width * scale, height: outer.height * scale)
            let originOffset = CGPoint(x: origin.x * scale, y: origin.y * scale)

            ZStack(alignment: .topLeading) {
                BeautifyCanvas(
                    base: model.baseImage,
                    blurred: model.blurredImage,
                    pixelated: model.pixelatedImage,
                    capturePointSize: model.pointSize,
                    captureScale: model.capture.scale,
                    settings: settings,
                    scale: scale,
                    annotations: model.annotations,
                    draft: draft
                )

                if model.activeTool == .select, model.editingTextID == nil,
                   let selected = model.selectedAnnotation {
                    handles(for: selected, scale: scale, originOffset: originOffset)
                }

                if let id = model.editingTextID, let annotation = model.annotation(id),
                   case let .text(rect, _) = annotation.kind {
                    textEditor(id: id, rect: rect, style: annotation.style, scale: scale, originOffset: originOffset)
                }

                if model.activeTool.isUtility, let location = hoverLocation {
                    utilityOverlay(at: location, scale: scale, origin: origin, display: display)
                        .allowsHitTesting(false)
                }
            }
            .frame(width: display.width, height: display.height)
            .shadow(
                color: .black.opacity(model.beautifyEnabled ? 0 : 0.18),
                radius: model.beautifyEnabled ? 0 : 8,
                y: model.beautifyEnabled ? 0 : 2
            )
            .contentShape(Rectangle())
            .gesture(drag(scale: scale, origin: origin))
            .onContinuousHover { phase in
                switch phase {
                case .active(let point):
                    if model.activeTool.isUtility {
                        NSCursor.crosshair.set()
                        hoverLocation = point
                    } else {
                        hoverLocation = nil
                    }
                case .ended:
                    hoverLocation = nil
                }
            }
            .onChange(of: model.activeTool) { tool in
                if !tool.isUtility { hoverLocation = nil }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .onExitCommand {
                if model.editingTextID != nil {
                    model.endEditingText()
                } else if model.activeTool.isUtility {
                    model.exitUtilityTool()
                    hoverLocation = nil
                } else {
                    model.selectedID = nil
                }
            }
            .background(
                ModifierKeyTracker(
                    onShiftChange: { shiftHeld = $0 },
                    onSpaceChange: { held in
                        spaceHeld = held
                        if !held { draftRepositionAnchor = nil }
                    }
                )
            )
        }
    }

    // MARK: Layout

    private func fitScale(outer: CGSize, into size: CGSize) -> CGFloat {
        let margin: CGFloat = 40
        let availW = max(size.width - margin, 1)
        let availH = max(size.height - margin, 1)
        guard outer.width > 0, outer.height > 0 else { return 1 }
        let s = min(availW / outer.width, availH / outer.height)
        return min(max(s, 0.05), 1) // fit-to-window, never upscale past 1×
    }

    /// The ONE view→capture mapping.
    private func toCapture(_ point: CGPoint, scale: CGFloat, origin: CGPoint) -> CGPoint {
        CGPoint(x: point.x / scale - origin.x, y: point.y / scale - origin.y)
    }

    // MARK: Overlays

    @ViewBuilder
    private func handles(for annotation: Annotation, scale: CGFloat, originOffset: CGPoint) -> some View {
        let box = annotation.kind.boundingBox.scaled(scale)
        Rectangle()
            .strokeBorder(Color.accentColor, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
            .frame(width: box.width, height: box.height)
            .position(x: box.midX + originOffset.x, y: box.midY + originOffset.y)
            .allowsHitTesting(false)

        ForEach(Array(annotation.kind.handles.enumerated()), id: \.offset) { _, item in
            let center = item.1 * scale
            RoundedRectangle(cornerRadius: 2)
                .fill(.white)
                .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color.accentColor, lineWidth: 1.5))
                .frame(width: 10, height: 10)
                .position(x: center.x + originOffset.x, y: center.y + originOffset.y)
                .allowsHitTesting(false)
        }
    }

    private func textEditor(
        id: UUID, rect: CGRect, style: AnnotationStyle, scale: CGFloat, originOffset: CGPoint
    ) -> some View {
        let viewRect = rect.scaled(scale)
        return TextField("Text", text: model.textBinding(id), axis: .vertical)
            .textFieldStyle(.plain)
            .font(.system(size: style.fontSize * scale))
            .foregroundColor(style.color.color)
            .frame(width: max(viewRect.width, 60), alignment: .topLeading)
            .position(x: viewRect.midX + originOffset.x, y: viewRect.midY + originOffset.y)
            .focused($textFocused)
            .onAppear { DispatchQueue.main.async { textFocused = true } }
    }

    // MARK: Utility overlays (Loupe / Eyedropper — display-only, never exported)

    @ViewBuilder
    private func utilityOverlay(at location: CGPoint, scale: CGFloat, origin: CGPoint, display: CGSize) -> some View {
        let capturePoint = toCapture(location, scale: scale, origin: origin)
        let pixel = capturePixel(at: capturePoint)
        let color = model.sampleColor(atCapturePoint: capturePoint)
        let bubbleSize = CGSize(width: 150, height: 160)
        let center = clampedBubbleCenter(near: location, size: bubbleSize, in: display)

        Group {
            if model.activeTool == .loupe {
                LoupeView(image: model.adjustedImage, centerPixel: pixel, color: color)
            } else {
                EyedropperView(image: model.adjustedImage, centerPixel: pixel, color: color)
            }
        }
        .position(x: center.x, y: center.y)
    }

    private func capturePixel(at capturePoint: CGPoint) -> (x: Int, y: Int) {
        let scale = model.capture.scale
        let width = model.adjustedImage.width
        let height = model.adjustedImage.height
        let x = min(max(Int((capturePoint.x * scale).rounded(.down)), 0), max(width - 1, 0))
        let y = min(max(Int((capturePoint.y * scale).rounded(.down)), 0), max(height - 1, 0))
        return (x, y)
    }

    /// Offset up-right of the cursor; flipped near edges so the bubble stays inside the canvas
    /// and out from under the pointer.
    private func clampedBubbleCenter(near location: CGPoint, size: CGSize, in display: CGSize) -> CGPoint {
        var x = location.x + 20 + size.width / 2
        if x + size.width / 2 > display.width { x = location.x - 20 - size.width / 2 }
        var y = location.y - 20 - size.height / 2
        if y - size.height / 2 < 0 { y = location.y + 20 + size.height / 2 }
        return CGPoint(
            x: min(max(x, size.width / 2), max(display.width - size.width / 2, size.width / 2)),
            y: min(max(y, size.height / 2), max(display.height - size.height / 2, size.height / 2))
        )
    }

    // MARK: Gesture

    private func drag(scale: CGFloat, origin: CGPoint) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                dragChanged(
                    start: toCapture(value.startLocation, scale: scale, origin: origin),
                    current: toCapture(value.location, scale: scale, origin: origin),
                    scale: scale
                )
            }
            .onEnded { value in
                dragEnded(
                    start: toCapture(value.startLocation, scale: scale, origin: origin),
                    current: toCapture(value.location, scale: scale, origin: origin),
                    scale: scale
                )
            }
    }

    private func dragChanged(start: CGPoint, current: CGPoint, scale: CGFloat) {
        if case .none = op { beginOp(at: start, scale: scale) }
        switch op {
        case .creating:
            if spaceHeld {
                if let anchor = draftRepositionAnchor {
                    let delta = CGPoint(x: current.x - anchor.x, y: current.y - anchor.y)
                    translateDraft(by: delta)
                }
                draftRepositionAnchor = current
            } else {
                draftRepositionAnchor = nil
                updateDraft(start: start, current: constrainedEnd(start: start, end: current))
            }
        case let .moving(_, original):
            model.updateSelected(kind: original.translated(dx: current.x - start.x, dy: current.y - start.y))
        case let .resizing(_, handle, original):
            model.updateSelected(kind: original.resized(handle: handle, to: current))
        case let .rotating(_, center, originalRotation):
            let currentAngle = atan2(current.y - center.y, current.x - center.x)
            model.updateSelectedRotation(originalRotation + (currentAngle - rotationDragStartAngle))
        case .none, .empty:
            break
        }
    }

    private func dragEnded(start: CGPoint, current: CGPoint, scale: CGFloat) {
        // Capture before pickColor/exitUtilityTool flips activeTool back to the prior Tool —
        // a utility click must never fall through to Select-mode double-click handling.
        let wasUtility = model.activeTool.isUtility

        switch op {
        case .creating:
            finalizeDraft(start: start, current: constrainedEnd(start: start, end: current))
        case let .moving(before, _):
            model.commitInteractive(before: before)
        case let .resizing(before, _, _):
            model.commitInteractive(before: before)
        case let .rotating(before, _, _):
            model.commitInteractive(before: before)
        case .none, .empty:
            break
        }
        if model.activeTool == .eyedropper, start.distance(to: current) < 4 {
            model.pickColor(atCapturePoint: current)
        }
        if !wasUtility {
            detectDoubleClickToEdit(start: start, current: current, scale: scale)
        }
        op = .none
    }

    private func beginOp(at start: CGPoint, scale: CGFloat) {
        if model.editingTextID != nil { model.endEditingText() }

        // Utility Tools never create drafts or change selection.
        if model.activeTool.isUtility {
            op = .empty
            return
        }

        guard model.activeTool == .select else {
            draft = makeDraft(at: start)
            op = .creating
            return
        }

        // A pending restyle must commit BEFORE `before:` snapshots are captured, so a later
        // move can't fold an uncommitted recolor into its undo step.
        model.flushStyleTransaction()

        if let selected = model.selectedAnnotation, let handle = handle(at: start, of: selected, scale: scale) {
            if handle == .rotate {
                let center = selected.kind.boundingBox.center
                rotationDragStartAngle = atan2(start.y - center.y, start.x - center.x)
                op = .rotating(before: model.annotations, center: center, originalRotation: selected.rotation)
            } else {
                op = .resizing(before: model.annotations, handle: handle, original: selected.kind)
            }
            return
        }
        if let hit = topmost(at: start, scale: scale) {
            model.selectedID = hit.id
            op = .moving(before: model.annotations, original: hit.kind)
            return
        }
        model.selectedID = nil
        op = .empty
    }

    // MARK: Draft lifecycle

    private func makeDraft(at point: CGPoint) -> Annotation {
        let style = model.currentStyle
        let kind: AnnotationKind
        switch model.activeTool {
        case .arrow:
            kind = .arrow(start: point, end: point)
        case .rectangle:
            kind = .rectangle(rect: CGRect(origin: point, size: .zero))
        case .ellipse:
            kind = .ellipse(rect: CGRect(origin: point, size: .zero))
        case .censor:
            kind = .censor(rect: CGRect(origin: point, size: .zero))
        case .pencil:
            kind = .pencil(points: [point])
        case .text:
            kind = .text(rect: CGRect(x: point.x, y: point.y, width: 180, height: 30), string: "")
        case .number:
            kind = .number(center: point, radius: max(14, style.lineWidth * 3), value: model.nextBadgeNumber)
        case .stamp:
            kind = .stamp(rect: CGRect(origin: point, size: .zero), emoji: model.currentEmoji)
        case .highlighter:
            kind = .highlight(points: [point])
        case .measure:
            kind = .measure(start: point, end: point, showsSize: model.measureShowsSize)
        case .spotlight:
            kind = .spotlight(rect: CGRect(origin: point, size: .zero), shape: model.spotlightShape)
        case .select, .loupe, .eyedropper:
            kind = .rectangle(rect: .zero) // unreachable (beginOp gates these)
        }
        return Annotation(kind: kind, style: style)
    }

    private func updateDraft(start: CGPoint, current: CGPoint) {
        guard var draft else { return }
        switch draft.kind {
        case .arrow:
            draft.kind = .arrow(start: start, end: current)
        case .rectangle:
            draft.kind = .rectangle(rect: CGRect(corner: start, corner: current))
        case .ellipse:
            draft.kind = .ellipse(rect: CGRect(corner: start, corner: current))
        case .censor:
            draft.kind = .censor(rect: CGRect(corner: start, corner: current))
        case let .pencil(points):
            draft.kind = .pencil(points: points + [current])
        case .text:
            draft.kind = .text(rect: CGRect(corner: start, corner: current), string: "")
        case let .number(_, _, value):
            let radius = max(max(14, model.lineWidth * 3), start.distance(to: current))
            draft.kind = .number(center: start, radius: radius, value: value)
        case let .stamp(_, emoji):
            let side = max(abs(current.x - start.x), abs(current.y - start.y))
            draft.kind = .stamp(rect: CGRect(x: start.x, y: start.y, width: side, height: side), emoji: emoji)
        case let .highlight(points):
            draft.kind = .highlight(points: points + [current])
        case let .measure(_, _, showsSize):
            draft.kind = .measure(start: start, end: current, showsSize: showsSize)
        case let .spotlight(_, shape):
            draft.kind = .spotlight(rect: CGRect(corner: start, corner: current), shape: shape)
        }
        self.draft = draft
    }

    private func translateDraft(by delta: CGPoint) {
        guard var draft else { return }
        draft.kind = draft.kind.translated(dx: delta.x, dy: delta.y)
        self.draft = draft
    }

    private func constrainedEnd(start: CGPoint, end: CGPoint) -> CGPoint {
        guard shiftHeld else { return end }
        let dx = end.x - start.x
        let dy = end.y - start.y
        switch model.activeTool {
        case .arrow, .measure:
            let length = hypot(dx, dy)
            guard length > 0 else { return end }
            let angle = atan2(dy, dx)
            let snap = (angle / (.pi / 4)).rounded() * (.pi / 4)
            return CGPoint(x: start.x + cos(snap) * length, y: start.y + sin(snap) * length)
        case .rectangle, .ellipse, .censor, .spotlight, .stamp:
            let side = max(abs(dx), abs(dy))
            return CGPoint(
                x: start.x + (dx >= 0 ? side : -side),
                y: start.y + (dy >= 0 ? side : -side)
            )
        case .pencil, .highlighter:
            if abs(dx) >= abs(dy) {
                return CGPoint(x: end.x, y: start.y)
            }
            return CGPoint(x: start.x, y: end.y)
        case .select, .text, .number, .loupe, .eyedropper:
            return end
        }
    }

    private func finalizeDraft(start: CGPoint, current: CGPoint) {
        guard let draft else { return }
        defer { self.draft = nil }

        switch model.activeTool {
        case .text:
            var rect = CGRect(corner: start, corner: current)
            if rect.width < 40 || rect.height < 24 {
                rect = CGRect(x: start.x, y: start.y, width: 180, height: 30)
            }
            var annotation = draft
            annotation.kind = .text(rect: rect, string: "")
            model.addNewText(annotation)
        case .pencil:
            if case let .pencil(points) = draft.kind, points.count >= 2 { model.add(draft) }
        case .arrow:
            if case let .arrow(s, e) = draft.kind, s.distance(to: e) >= 4 { model.add(draft) }
        case .rectangle, .ellipse, .censor:
            let box = draft.kind.boundingBox
            if box.width >= 4, box.height >= 4 { model.add(draft) }
        case .number:
            model.add(draft) // a pure click places a badge
        case .stamp:
            var annotation = draft
            if case let .stamp(rect, emoji) = annotation.kind, rect.width < 24 || rect.height < 24 {
                let side: CGFloat = 64 // a pure click places a default-size stamp
                annotation.kind = .stamp(
                    rect: CGRect(x: start.x - side / 2, y: start.y - side / 2, width: side, height: side),
                    emoji: emoji
                )
            }
            model.add(annotation)
        case .highlighter:
            if case let .highlight(points) = draft.kind, points.count >= 2 {
                var snapped = draft
                snapped.kind = .highlight(points: model.smartSnapHighlighter(points))
                model.add(snapped)
            }
        case .measure:
            if case let .measure(s, e, _) = draft.kind, s.distance(to: e) >= 4 { model.add(draft) }
        case .spotlight:
            let box = draft.kind.boundingBox
            if box.width >= 8, box.height >= 8 { model.add(draft) }
        case .select, .loupe, .eyedropper:
            break
        }
    }

    // MARK: Hit testing

    private func handle(at point: CGPoint, of annotation: Annotation, scale: CGFloat) -> Handle? {
        let tolerance = 9 / scale
        for (handle, position) in annotation.kind.handles where point.distance(to: position) <= tolerance {
            return handle
        }
        return nil
    }

    private func topmost(at point: CGPoint, scale: CGFloat) -> Annotation? {
        let tolerance = 6 / scale
        return model.annotations.reversed().first { $0.hitTest(point, tolerance: tolerance) }
    }

    private func detectDoubleClickToEdit(start: CGPoint, current: CGPoint, scale: CGFloat) {
        guard model.activeTool == .select, start.distance(to: current) < 4 else { return }
        let now = Date()
        if let hit = topmost(at: current, scale: scale), case .text = hit.kind,
           let last = lastClick, now.timeIntervalSince(last.time) < 0.45, last.point.distance(to: current) < 8 {
            model.beginEditingText(hit.id, isNew: false)
        }
        lastClick = (now, current)
    }
}
