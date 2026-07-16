import SwiftUI

/// The interactive Canvas: hosts the shared `AnnotatedCanvas` at fit-zoom and layers on drawing,
/// selection/move/resize, inline text editing, and keyboard commands. All model geometry is in
/// Capture points; gesture locations (view points) convert via `/ scale`.
struct EditorCanvasView: View {
    @ObservedObject var model: EditorModel

    @State private var draft: Annotation?
    @State private var op: DragOp = .none
    @State private var lastClick: (time: Date, point: CGPoint)?
    @FocusState private var textFocused: Bool

    private enum DragOp {
        case none
        case empty
        case creating
        case moving(before: [Annotation], original: AnnotationKind)
        case resizing(before: [Annotation], handle: Handle, original: AnnotationKind)
    }

    var body: some View {
        GeometryReader { geo in
            let scale = fitScale(into: geo.size)
            let display = CGSize(width: model.pointSize.width * scale, height: model.pointSize.height * scale)

            ZStack(alignment: .topLeading) {
                AnnotatedCanvas(
                    base: model.baseImage,
                    blurred: model.blurredImage,
                    pointSize: model.pointSize,
                    scale: scale,
                    annotations: model.annotations,
                    draft: draft
                )

                if model.activeTool == .select, model.editingTextID == nil, let selected = model.selectedAnnotation {
                    handles(for: selected, scale: scale)
                }

                if let id = model.editingTextID, let annotation = model.annotation(id),
                   case let .text(rect, _) = annotation.kind {
                    textEditor(id: id, rect: rect, style: annotation.style, scale: scale)
                }
            }
            .frame(width: display.width, height: display.height)
            .shadow(color: .black.opacity(0.18), radius: 8, y: 2)
            .contentShape(Rectangle())
            .gesture(drag(scale: scale))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .onExitCommand {
                if model.editingTextID != nil { model.endEditingText() }
                else { model.selectedID = nil }
            }
        }
    }

    // MARK: Layout

    private func fitScale(into size: CGSize) -> CGFloat {
        let margin: CGFloat = 40
        let availW = max(size.width - margin, 1)
        let availH = max(size.height - margin, 1)
        guard model.pointSize.width > 0, model.pointSize.height > 0 else { return 1 }
        let s = min(availW / model.pointSize.width, availH / model.pointSize.height)
        return min(max(s, 0.05), 1) // fit-to-window, never upscale past 1×
    }

    // MARK: Overlays

    @ViewBuilder
    private func handles(for annotation: Annotation, scale: CGFloat) -> some View {
        let box = annotation.kind.boundingBox.scaled(scale)
        Rectangle()
            .strokeBorder(Color.accentColor, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
            .frame(width: box.width, height: box.height)
            .position(x: box.midX, y: box.midY)
            .allowsHitTesting(false)

        ForEach(Array(annotation.kind.handles.enumerated()), id: \.offset) { _, item in
            let center = item.1 * scale
            RoundedRectangle(cornerRadius: 2)
                .fill(.white)
                .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color.accentColor, lineWidth: 1.5))
                .frame(width: 10, height: 10)
                .position(x: center.x, y: center.y)
                .allowsHitTesting(false)
        }
    }

    private func textEditor(id: UUID, rect: CGRect, style: AnnotationStyle, scale: CGFloat) -> some View {
        let viewRect = rect.scaled(scale)
        return TextField("Text", text: model.textBinding(id), axis: .vertical)
            .textFieldStyle(.plain)
            .font(.system(size: style.fontSize * scale))
            .foregroundColor(style.color.color)
            .frame(width: max(viewRect.width, 60), alignment: .topLeading)
            .position(x: viewRect.midX, y: viewRect.midY)
            .focused($textFocused)
            .onAppear { DispatchQueue.main.async { textFocused = true } }
    }

    // MARK: Gesture

    private func drag(scale: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                dragChanged(start: value.startLocation / scale, current: value.location / scale, scale: scale)
            }
            .onEnded { value in
                dragEnded(start: value.startLocation / scale, current: value.location / scale, scale: scale)
            }
    }

    private func dragChanged(start: CGPoint, current: CGPoint, scale: CGFloat) {
        if case .none = op { beginOp(at: start, scale: scale) }
        switch op {
        case .creating:
            updateDraft(start: start, current: current)
        case let .moving(_, original):
            model.updateSelected(kind: original.translated(dx: current.x - start.x, dy: current.y - start.y))
        case let .resizing(_, handle, original):
            model.updateSelected(kind: original.resized(handle: handle, to: current))
        case .none, .empty:
            break
        }
    }

    private func dragEnded(start: CGPoint, current: CGPoint, scale: CGFloat) {
        switch op {
        case .creating:
            finalizeDraft(start: start, current: current)
        case let .moving(before, _):
            model.commitInteractive(before: before)
        case let .resizing(before, _, _):
            model.commitInteractive(before: before)
        case .none, .empty:
            break
        }
        detectDoubleClickToEdit(start: start, current: current, scale: scale)
        op = .none
    }

    private func beginOp(at start: CGPoint, scale: CGFloat) {
        if model.editingTextID != nil { model.endEditingText() }

        guard model.activeTool == .select else {
            draft = makeDraft(at: start)
            op = .creating
            return
        }

        if let selected = model.selectedAnnotation, let handle = handle(at: start, of: selected, scale: scale) {
            op = .resizing(before: model.annotations, handle: handle, original: selected.kind)
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
        case .arrow: kind = .arrow(start: point, end: point)
        case .rectangle: kind = .rectangle(rect: CGRect(origin: point, size: .zero))
        case .censor: kind = .censor(rect: CGRect(origin: point, size: .zero))
        case .pencil: kind = .pencil(points: [point])
        case .text: kind = .text(rect: CGRect(x: point.x, y: point.y, width: 180, height: 30), string: "")
        case .select: kind = .rectangle(rect: .zero)
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
        case .censor:
            draft.kind = .censor(rect: CGRect(corner: start, corner: current))
        case let .pencil(points):
            draft.kind = .pencil(points: points + [current])
        case .text:
            draft.kind = .text(rect: CGRect(corner: start, corner: current), string: "")
        }
        self.draft = draft
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
            model.add(annotation)
            model.beginEditingText(annotation.id, isNew: true)
        case .pencil:
            if case let .pencil(points) = draft.kind, points.count >= 2 { model.add(draft) }
        case .arrow:
            if case let .arrow(s, e) = draft.kind, s.distance(to: e) >= 4 { model.add(draft) }
        case .rectangle, .censor:
            let box = draft.kind.boundingBox
            if box.width >= 4, box.height >= 4 { model.add(draft) }
        case .select:
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
        return model.annotations.reversed().first {
            $0.kind.hitTest(point, tolerance: tolerance, lineWidth: $0.style.lineWidth)
        }
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
