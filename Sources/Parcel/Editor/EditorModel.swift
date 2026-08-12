import AppKit
import CoreImage
import ImageIO
import SwiftUI
import UniformTypeIdentifiers

/// Backing state for one Editor window: the Capture, its Layer of Annotations, the active Tool,
/// style + restyle transactions, Adjustments (Core Image), Beautify settings, undo/redo, and
/// annotation-aware Copy/Save.
///
/// Undo scope: the ⌘Z stack covers ANNOTATION CONTENT ONLY (create/delete/move/resize/restyle).
/// Adjustments and Beautify are document-level, directly-reversible settings with panel Resets.
@MainActor
final class EditorModel: ObservableObject {

    @Published private(set) var capture: Capture

    // MARK: Annotation state

    @Published var annotations: [Annotation] = []
    @Published var selectedID: UUID? {
        didSet { if oldValue != selectedID { commitRestyle() } }
    }
    @Published var editingTextID: UUID?

    // MARK: Tool state (creation defaults — not undoable, like a palette)

    @Published var activeTool: Tool = .arrow
    @Published var toolColor: RGBAColor = .red
    @Published var lineWidth: CGFloat = 4
    @Published var toolArrowStyle: ArrowStyle = .standard
    @Published var toolCensorMode: CensorMode = .blur
    @Published var currentEmoji: String = "⭐️"
    @Published var spotlightShape: SpotlightShape = .rectangle
    @Published var measureShowsSize: Bool = false

    static let stampChoices: [String] = [
        "⭐️", "✅", "❌", "❗️", "❓", "🔥", "👍", "👎",
        "⚠️", "💡", "👀", "🎯", "➡️", "🚫", "💯", "📌",
    ]

    // MARK: Adjustments (Core Image, on-device)

    @Published var adjustments: Adjustments = .neutral {
        didSet { if oldValue != adjustments { scheduleRender() } }
    }

    /// The (possibly adjusted) Capture pixels driving display, loupe crops, and the sampler.
    @Published private(set) var adjustedImage: CGImage
    @Published private(set) var baseImage: NSImage
    @Published private(set) var blurredImage: CGImage
    @Published private(set) var pixelatedImage: CGImage

    private var adjuster: CaptureAdjuster
    private var censorSourcesReady = false
    /// Custom color swatches persisted across Editor sessions.
    @Published var savedColors: [RGBAColor] = ColorSwatchStore.load()
    /// The Adjustments the published images currently reflect (display can lag `adjustments`
    /// by the render debounce; export syncs the two).
    private var displayedAdjustments: Adjustments = .neutral
    private let renderQueue = DispatchQueue(label: "dev.parable.adjustments", qos: .userInitiated)
    private var renderWorkItem: DispatchWorkItem?

    // MARK: Beautify

    @Published var beautify = BeautifySettings()
    @Published var beautifyEnabled = false

    var effectiveSettings: BeautifySettings { beautifyEnabled ? beautify : .disabled }

    // MARK: Local output

    @Published var outputFormat: OutputFormat = .png

    // MARK: On-device Vision

    @Published private(set) var visionAnalysis = VisionAnalysis()
    @Published private(set) var isAnalyzingVision = false
    @Published private(set) var isUploading = false
    @Published var statusMessage: String?

    // MARK: Translation (on-device, macOS 26+)

    @Published private(set) var translatedText: String?
    @Published private(set) var isTranslating = false

    // MARK: Utilities (Loupe / Eyedropper) — never touch annotations or undo

    private var _pixelSampler: CapturePixelSampler?
    var pixelSampler: CapturePixelSampler? {
        if let sampler = _pixelSampler { return sampler }
        _pixelSampler = CapturePixelSampler(cgImage: adjustedImage)
        return _pixelSampler
    }
    private var toolBeforeUtility: Tool?

    // MARK: Undo / restyle internals

    private let textFontSize: CGFloat = 18
    private var undoStack: [[Annotation]] = []
    private var redoStack: [[Annotation]] = []

    private enum RestyleAxis { case color, lineWidth }
    private var restyle: (axis: RestyleAxis, before: [Annotation])?

    // MARK: Init

    init(capture: Capture, document: CaptureDocument? = nil) {
        let restoredAnnotations = document?.annotations ?? []
        let restoredAdjustments = document?.adjustments ?? .neutral
        let restoredBeautify = document?.beautify ?? BeautifySettings()
        let restoredBeautifyEnabled = document?.beautifyEnabled ?? false
        let restoredOutputFormat = document?.outputFormat ?? .png
        let restoredCensors = restoredAnnotations.contains { annotation in
            if case .censor = annotation.kind { return true }
            return false
        }
        let captureAdjuster = CaptureAdjuster(capture: capture)
        let adjusted = captureAdjuster.makeAdjusted(restoredAdjustments)

        self.capture = capture
        adjuster = captureAdjuster
        annotations = restoredAnnotations
        adjustments = restoredAdjustments
        beautify = restoredBeautify
        beautifyEnabled = restoredBeautifyEnabled
        outputFormat = restoredOutputFormat
        adjustedImage = adjusted
        baseImage = NSImage(cgImage: adjusted, size: capture.pointSize)
        censorSourcesReady = restoredCensors
        blurredImage = restoredCensors ? captureAdjuster.makeBlurred(restoredAdjustments) : adjusted
        pixelatedImage = restoredCensors ? captureAdjuster.makePixelated(restoredAdjustments) : adjusted
        displayedAdjustments = restoredAdjustments
    }

    // MARK: Derived

    var pointSize: CGSize { capture.pointSize }

    var currentStyle: AnnotationStyle {
        AnnotationStyle(
            color: toolColor, lineWidth: lineWidth, fontSize: textFontSize,
            arrowStyle: toolArrowStyle, censorMode: toolCensorMode
        )
    }

    var selectedAnnotation: Annotation? {
        guard let selectedID else { return nil }
        return annotations.first { $0.id == selectedID }
    }

    func annotation(_ id: UUID) -> Annotation? {
        annotations.first { $0.id == id }
    }

    /// Auto-increment source for the Number tool. Computed from the Layer, so it is correct
    /// after any undo/redo without side state.
    var nextBadgeNumber: Int {
        var maxValue = 0
        for annotation in annotations {
            if case let .number(_, _, value) = annotation.kind { maxValue = max(maxValue, value) }
        }
        return maxValue + 1
    }

    // MARK: Tool selection

    func selectTool(_ tool: Tool) {
        endEditingText()
        commitRestyle()
        if tool.isUtility, !activeTool.isUtility { toolBeforeUtility = activeTool }
        if !tool.isUtility { toolBeforeUtility = nil }
        activeTool = tool
        if tool == .censor { ensureCensorSourcesReady() }
        if tool.isDrawing { selectedID = nil }
    }

    func exitUtilityTool() {
        guard activeTool.isUtility else { return }
        activeTool = toolBeforeUtility ?? .select
        toolBeforeUtility = nil
    }

    // MARK: Editing operations (each is one undo step)

    func add(_ annotation: Annotation) {
        if case .censor = annotation.kind { ensureCensorSourcesReady() }
        pushUndo()
        annotations.append(annotation)
        selectedID = annotation.id
    }

    func deleteSelected() {
        guard let id = selectedID, annotations.contains(where: { $0.id == id }) else { return }
        pushUndo()
        annotations.removeAll { $0.id == id }
        renumberBadges() // keeps Number badges 1…n; same undo step as the delete
        selectedID = nil
        editingTextID = nil
    }

    func updateSelectedRotation(_ rotation: CGFloat) {
        guard let id = selectedID, let index = annotations.firstIndex(where: { $0.id == id }) else { return }
        annotations[index].rotation = rotation
    }

    func bringForward() { moveSelectedLayer(by: 1) }
    func sendBackward() { moveSelectedLayer(by: -1) }
    func bringToFront() {
        guard let id = selectedID, let index = annotations.firstIndex(where: { $0.id == id }) else { return }
        guard index < annotations.count - 1 else { return }
        pushUndo()
        let item = annotations.remove(at: index)
        annotations.append(item)
    }

    func sendToBack() {
        guard let id = selectedID, let index = annotations.firstIndex(where: { $0.id == id }) else { return }
        guard index > 0 else { return }
        pushUndo()
        let item = annotations.remove(at: index)
        annotations.insert(item, at: 0)
    }

    private func moveSelectedLayer(by offset: Int) {
        guard let id = selectedID, let index = annotations.firstIndex(where: { $0.id == id }) else { return }
        let target = index + offset
        guard target >= 0, target < annotations.count else { return }
        pushUndo()
        annotations.swapAt(index, target)
        selectedID = id
    }

    /// Live update during a move/resize drag (no undo entry until `commitInteractive`).
    func updateSelected(kind: AnnotationKind) {
        guard let id = selectedID, let index = annotations.firstIndex(where: { $0.id == id }) else { return }
        annotations[index].kind = kind
    }

    /// Called once when a move/resize drag ends; records a single undo step if anything changed.
    func commitInteractive(before: [Annotation]) {
        guard annotations != before else { return }
        undoStack.append(before)
        redoStack.removeAll()
        trimUndo()
    }

    private func renumberBadges() {
        var next = 1
        for index in annotations.indices {
            if case let .number(center, radius, _) = annotations[index].kind {
                annotations[index].kind = .number(center: center, radius: radius, value: next)
                next += 1
            }
        }
    }

    // MARK: Restyle (selection-aware style edits; one undo step per gesture/pick)

    /// Finalize any open continuous restyle as ONE undo step. Called at every interaction
    /// boundary (selection change, tool change, undo/redo, before move/resize snapshots).
    func flushStyleTransaction() { commitRestyle() }

    func setColor(_ color: RGBAColor) {
        guard selectedAnnotation != nil else { toolColor = color; return }
        beginOrContinueRestyle(.color)
        mutateSelectedStyle { $0.color = color }
    }

    /// Called continuously during the slider drag; `endLineWidthEdit` commits the undo step.
    func setLineWidth(_ width: CGFloat) {
        guard selectedAnnotation != nil else { lineWidth = width; return }
        beginOrContinueRestyle(.lineWidth)
        mutateSelectedStyle { $0.lineWidth = width }
    }

    func endLineWidthEdit() { commitRestyle() }

    func setArrowStyle(_ style: ArrowStyle) {
        guard let selected = selectedAnnotation, case .arrow = selected.kind else {
            toolArrowStyle = style
            return
        }
        guard selected.style.arrowStyle != style else { return } // re-pick = no-op, no undo step
        pushUndo() // discrete pick = one undo step (pushUndo flushes any open transaction first)
        mutateSelectedStyle { $0.arrowStyle = style }
    }

    func setCensorMode(_ mode: CensorMode) {
        ensureCensorSourcesReady()
        guard let selected = selectedAnnotation, case .censor = selected.kind else {
            toolCensorMode = mode
            return
        }
        guard selected.style.censorMode != mode else { return } // re-pick = no-op, no undo step
        pushUndo()
        mutateSelectedStyle { $0.censorMode = mode }
    }

    // Toolbar read-backs: reflect the selected Annotation when present, else the tool defaults.
    var displayColor: RGBAColor { selectedAnnotation?.style.color ?? toolColor }
    var displayLineWidth: CGFloat { selectedAnnotation?.style.lineWidth ?? lineWidth }
    var displayArrowStyle: ArrowStyle {
        if let selected = selectedAnnotation, case .arrow = selected.kind { return selected.style.arrowStyle }
        return toolArrowStyle
    }
    var displayCensorMode: CensorMode {
        if let selected = selectedAnnotation, case .censor = selected.kind { return selected.style.censorMode }
        return toolCensorMode
    }

    private func beginOrContinueRestyle(_ axis: RestyleAxis) {
        if let open = restyle, open.axis != axis { commitRestyle() }
        if restyle == nil { restyle = (axis, annotations) } // snapshot BEFORE first mutation
    }

    private func mutateSelectedStyle(_ mutate: (inout AnnotationStyle) -> Void) {
        guard let id = selectedID, let index = annotations.firstIndex(where: { $0.id == id }) else { return }
        mutate(&annotations[index].style)
    }

    private func commitRestyle() {
        guard let pending = restyle else { return }
        restyle = nil
        guard annotations != pending.before else { return }
        undoStack.append(pending.before)
        redoStack.removeAll()
        trimUndo()
    }

    // MARK: Text editing

    /// Restores both history stacks if a brand-new text is discarded empty, making
    /// create-then-discard a true no-op (no dangling undo entry, no lost redo).
    private var newTextRestore: (id: UUID, undo: [[Annotation]], redo: [[Annotation]])?

    /// Creates a new text Annotation and enters editing. Snapshots the history stacks first so
    /// an empty-discard can roll them back exactly, regardless of restyles in between.
    func addNewText(_ annotation: Annotation) {
        commitRestyle()
        newTextRestore = (annotation.id, undoStack, redoStack)
        pushUndo()
        annotations.append(annotation)
        selectedID = annotation.id
        editingTextID = annotation.id
    }

    func beginEditingText(_ id: UUID, isNew: Bool) {
        if !isNew { pushUndo() }
        selectedID = id
        editingTextID = id
    }

    func endEditingText() {
        guard let id = editingTextID else { return }
        editingTextID = nil
        defer { newTextRestore = nil }
        // Drop an Annotation left empty and roll the history stacks back so the aborted
        // creation leaves no trace (including any restyle steps on the doomed text).
        if let index = annotations.firstIndex(where: { $0.id == id }),
           case let .text(_, string) = annotations[index].kind,
           string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            restyle = nil // an open transaction on the doomed text must not commit
            annotations.remove(at: index)
            if let restore = newTextRestore, restore.id == id {
                undoStack = restore.undo
                redoStack = restore.redo
            }
            // Re-edit path: KEEP the beginEditingText entry — it holds the pre-edit text, so
            // emptying an existing Text acts as an undoable delete.
            if selectedID == id { selectedID = nil }
        }
    }

    func textBinding(_ id: UUID) -> Binding<String> {
        Binding(
            get: { [weak self] in
                guard let self, let annotation = self.annotation(id),
                      case let .text(_, string) = annotation.kind else { return "" }
                return string
            },
            set: { [weak self] newValue in
                guard let self,
                      let index = self.annotations.firstIndex(where: { $0.id == id }),
                      case let .text(rect, _) = self.annotations[index].kind else { return }
                self.annotations[index].kind = .text(rect: rect, string: newValue)
            }
        )
    }

    // MARK: Undo / redo

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    func undo() {
        commitRestyle() // an open recolor drag becomes the step this undo reverts
        guard let previous = undoStack.popLast() else { return }
        redoStack.append(annotations)
        annotations = previous
        clearTransient()
    }

    func redo() {
        commitRestyle()
        guard let next = redoStack.popLast() else { return }
        undoStack.append(annotations)
        annotations = next
        clearTransient()
    }

    private func pushUndo() {
        commitRestyle()
        undoStack.append(annotations)
        redoStack.removeAll()
        trimUndo()
    }

    private func trimUndo() {
        if undoStack.count > 100 { undoStack.removeFirst(undoStack.count - 100) }
    }

    private func clearTransient() {
        selectedID = nil
        editingTextID = nil
    }

    // MARK: Adjustments plumbing

    func updateAdjustment(_ keyPath: WritableKeyPath<Adjustments, Double>, _ value: Double) {
        adjustments[keyPath: keyPath] = value
    }

    func applyPreset(_ preset: AdjustmentPreset) {
        adjustments = preset.adjustments
    }

    func resetAdjustments() {
        adjustments = .neutral
    }

    /// First Censor use builds blur + pixelate SYNCHRONOUSLY so a Censor never flashes raw
    /// sensitive pixels. Later adjustment-driven rebuilds are async (blurred→blurred, never raw).
    func ensureCensorSourcesReady() {
        guard !censorSourcesReady else { return }
        censorSourcesReady = true
        blurredImage = adjuster.makeBlurred(adjustments)
        pixelatedImage = adjuster.makePixelated(adjustments)
    }

    /// Debounced background re-render of the adjusted base (and censor sources if in use).
    private func scheduleRender() {
        renderWorkItem?.cancel()
        let adj = adjustments
        let size = pointSize
        let needsCensorSources = censorSourcesReady
        let adjuster = self.adjuster
        let work = DispatchWorkItem { [weak self] in
            let adjusted = adjuster.makeAdjusted(adj)
            let blurred = needsCensorSources ? adjuster.makeBlurred(adj) : nil
            let pixelated = needsCensorSources ? adjuster.makePixelated(adj) : nil
            DispatchQueue.main.async {
                guard let self, self.adjustments == adj else { return } // superseded mid-drag
                self.adjustedImage = adjusted
                self.baseImage = NSImage(cgImage: adjusted, size: size)
                self._pixelSampler = nil // sampler/loupe re-read the adjusted pixels lazily
                if let blurred { self.blurredImage = blurred }
                if let pixelated { self.pixelatedImage = pixelated }
                self.displayedAdjustments = adj
            }
        }
        renderWorkItem = work
        renderQueue.asyncAfter(deadline: .now() + 0.12, execute: work)
    }

    // MARK: Utility sampling (Loupe / Eyedropper)

    func sampleColor(atCapturePoint point: CGPoint) -> RGBAColor? {
        guard let sampler = pixelSampler else { return nil }
        let x = min(max(Int((point.x * capture.scale).rounded(.down)), 0), sampler.width - 1)
        let y = min(max(Int((point.y * capture.scale).rounded(.down)), 0), sampler.height - 1)
        return sampler.rgba(x: x, y: y)
    }

    /// Eyedropper click: set the tool color (non-undo state) and hop back to the prior Tool.
    func pickColor(atCapturePoint point: CGPoint) {
        guard let color = sampleColor(atCapturePoint: point) else { return }
        toolColor = color
        exitUtilityTool()
    }

    // MARK: On-device Vision

    /// Recognizes text, QR codes, and faces with Apple Vision. The active Adjustment values are
    /// rendered first so inspection matches the pixels the Editor will export.
    func inspectCapture() {
        endEditingText()
        let image = exportImages().base.cgImage(forProposedRect: nil, context: nil, hints: nil) ?? adjustedImage
        let size = pointSize
        isAnalyzingVision = true
        Task { [weak self] in
            let analysis = await VisionAnalyzer.analyze(image: image, pointSize: size)
            guard let self else { return }
            visionAnalysis = analysis
            isAnalyzingVision = false
        }
    }

    func copyRecognizedText() {
        let text = visionAnalysis.recognizedText
        guard !text.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    func translateRecognizedText() {
        let text = visionAnalysis.recognizedText
        guard !text.isEmpty else { return }
        isTranslating = true
        translatedText = nil
        Task { [weak self] in
            let result = await TranslationService.translate(text)
            guard let self else { return }
            translatedText = result
            isTranslating = false
            if let result, !result.isEmpty {
                statusMessage = "Translation ready — copy from Vision panel."
            } else if !TranslationService.isAvailable {
                statusMessage = "On-device translation requires macOS 26 or later."
            }
        }
    }

    func copyTranslatedText() {
        guard let translatedText, !translatedText.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(translatedText, forType: .string)
    }

    func copyQRCode(_ code: VisionQRCode) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(code.payload, forType: .string)
    }

    /// Adds solid Censors for likely email addresses, phone numbers, and card-like strings.
    /// Detection is local and deliberately redacts the entire recognized line rather than risk
    /// leaking a nearby character at the boundary.
    func censorDetectedPII() {
        addCensors(visionAnalysis.piiText.map(\.rect), mode: .solid)
    }

    /// Adds blur Censors around faces found locally by Vision.
    func censorDetectedFaces() {
        addCensors(visionAnalysis.faces.map(\.rect), mode: .blur)
    }

    private func addCensors(_ rects: [CGRect], mode: CensorMode) {
        guard !rects.isEmpty else { return }
        pushUndo()
        let style = AnnotationStyle(
            color: .black,
            lineWidth: 0,
            fontSize: textFontSize,
            arrowStyle: .standard,
            censorMode: mode
        )
        annotations.append(contentsOf: rects.map { Annotation(kind: .censor(rect: $0), style: style) })
        selectedID = annotations.last?.id
        ensureCensorSourcesReady()
    }

    // MARK: Capture transforms (document-level, undoable as annotation snapshots)

    func cropCapture(toPoints rect: CGRect) {
        let oldSize = capture.pointSize
        guard let next = CaptureTransform.crop(capture, toPoints: rect) else { return }
        pushUndo()
        annotations = CaptureTransform.cropAnnotations(annotations, by: rect)
        replaceCapture(next, remappedFrom: oldSize)
    }

    func resizeCapture(toPointSize size: CGSize) {
        let oldSize = capture.pointSize
        guard let next = CaptureTransform.resize(capture, toPointSize: size) else { return }
        pushUndo()
        annotations = CaptureTransform.scaleAnnotations(annotations, from: oldSize, to: size)
        replaceCapture(next, remappedFrom: oldSize)
    }

    func rotateCapture90CW() {
        let oldSize = capture.pointSize
        guard let next = CaptureTransform.rotate90CW(capture) else { return }
        pushUndo()
        annotations = CaptureTransform.rotateAnnotations90CW(annotations, canvasSize: oldSize)
        replaceCapture(next, remappedFrom: oldSize)
    }

    func flipCaptureHorizontal() {
        let oldSize = capture.pointSize
        guard let next = CaptureTransform.flipHorizontal(capture) else { return }
        pushUndo()
        annotations = CaptureTransform.flipAnnotationsH(annotations, canvasWidth: oldSize.width)
        replaceCapture(next, remappedFrom: oldSize)
    }

    func flipCaptureVertical() {
        let oldSize = capture.pointSize
        guard let next = CaptureTransform.flipVertical(capture) else { return }
        pushUndo()
        annotations = CaptureTransform.flipAnnotationsV(annotations, canvasHeight: oldSize.height)
        replaceCapture(next, remappedFrom: oldSize)
    }

    func expandCanvas(top: CGFloat, left: CGFloat, bottom: CGFloat, right: CGFloat, fill: NSColor = .white) {
        let oldSize = capture.pointSize
        guard let next = CaptureTransform.expand(
            capture, top: top, left: left, bottom: bottom, right: right, fill: fill
        ) else { return }
        pushUndo()
        annotations = CaptureTransform.offsetAnnotations(
            annotations,
            by: CGPoint(x: left, y: top)
        )
        replaceCapture(next, remappedFrom: oldSize)
    }

    func combineCapture(_ other: Capture, into rect: CGRect) {
        let oldSize = capture.pointSize
        guard let next = CaptureTransform.combine(base: capture, other: other, into: rect) else { return }
        pushUndo()
        replaceCapture(next, remappedFrom: oldSize)
    }

    func removeOpaqueBackground(tolerance: CGFloat = 28) {
        let oldSize = capture.pointSize
        guard let next = CaptureTransform.removeBackground(capture, tolerance: tolerance) else { return }
        pushUndo()
        replaceCapture(next, remappedFrom: oldSize)
    }

    /// Snaps highlighter stroke endpoints toward nearby OCR word boxes (on-device Vision).
    func smartSnapHighlighter(_ points: [CGPoint]) -> [CGPoint] {
        HighlighterSnapper.snappedPoints(points, to: visionAnalysis.text.map(\.rect))
    }

    func saveCurrentColorSwatch() {
        ColorSwatchStore.add(toolColor)
        savedColors = ColorSwatchStore.load()
    }

    func printCapture() {
        guard let image = renderedNSImage() else { return }
        CapturePrintPayload.printOperation(for: image).run()
    }

    func shareCapture() {
        guard let image = renderedNSImage() else { return }
        let picker = CaptureSharePayload.picker(for: image)
        if let anchor = CaptureSharePayload.anchor(in: NSApp.keyWindow) {
            picker.show(relativeTo: anchor.rect, of: anchor.view, preferredEdge: anchor.preferredEdge)
        }
    }

    func saveParcelProject() {
        endEditingText()
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType(filenameExtension: "parcel") ?? .data]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = CaptureFileName.make(extension: "parcel")
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url, let self else { return }
            ParcelProjectIO.save(model: self, to: url)
        }
    }

    private func replaceCapture(_ next: Capture, remappedFrom _: CGSize) {
        capture = next
        adjuster = CaptureAdjuster(capture: next)
        censorSourcesReady = annotations.contains {
            if case .censor = $0.kind { return true }
            return false
        }
        displayedAdjustments = .neutral
        adjustments = adjustments // trigger refresh path
        let adjusted = adjuster.makeAdjusted(adjustments)
        adjustedImage = adjusted
        baseImage = NSImage(cgImage: adjusted, size: next.pointSize)
        blurredImage = censorSourcesReady ? adjuster.makeBlurred(adjustments) : adjusted
        pixelatedImage = censorSourcesReady ? adjuster.makePixelated(adjustments) : adjusted
        displayedAdjustments = adjustments
        _pixelSampler = nil
        objectWillChange.send()
    }

    // MARK: Output

    func copyToClipboard() {
        guard let image = renderedNSImage() else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
    }

    func save() {
        endEditingText() // commit any in-progress text before rendering
        let panel = NSSavePanel()
        panel.allowedContentTypes = [outputFormat.contentType]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = CaptureFileName.make(extension: outputFormat.fileExtension)
        if let dir = Self.lastSaveDirectory { panel.directoryURL = dir }

        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url, let self else { return }
            self.writeImage(to: url)
            Self.lastSaveDirectory = url.deletingLastPathComponent()
        }
    }

    func uploadCapture() {
        endEditingText()
        guard UploadPreferences.isConfigured else {
            statusMessage = UploadError.notConfigured.errorDescription
            return
        }
        guard let cgImage = renderedCGImage() else {
            statusMessage = UploadError.encodeFailed.errorDescription
            return
        }
        let rep = NSBitmapImageRep(cgImage: cgImage)
        guard let data = rep.representation(using: .png, properties: [:]) else {
            statusMessage = UploadError.encodeFailed.errorDescription
            return
        }

        isUploading = true
        statusMessage = "Uploading…"
        let fileName = CaptureFileName.make(extension: "png")
        Task { [weak self] in
            do {
                let url = try await UploadService.uploadPNG(data: data, fileName: fileName)
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(url.absoluteString, forType: .string)
                self?.statusMessage = "Uploaded — link copied to clipboard."
            } catch {
                self?.statusMessage = error.localizedDescription
            }
            self?.isUploading = false
        }
    }

    /// Synchronously renders the adjusted base + whichever censor sources are actually in use
    /// for the CURRENT adjustments, so export matches the settled adjustment values — never a
    /// mid-debounce frame. If the display is still lagging (debounce pending), it is synced to
    /// the same images here, so "on screen === saved" holds at the moment of export too.
    private func exportImages() -> (base: NSImage, blurred: CGImage, pixelated: CGImage) {
        let displayIsStale = displayedAdjustments != adjustments
        if displayIsStale { renderWorkItem?.cancel() } // we're doing its work synchronously now

        let adjusted = displayIsStale ? adjuster.makeAdjusted(adjustments) : adjustedImage
        // Censor sources: reuse the published ones when fresh; recompute when stale.
        let blurred: CGImage
        let pixelated: CGImage
        if censorSourcesReady {
            blurred = displayIsStale ? adjuster.makeBlurred(adjustments) : blurredImage
            pixelated = displayIsStale ? adjuster.makePixelated(adjustments) : pixelatedImage
        } else {
            // No Censor has ever been drawn; sources are never sampled. Cheap stand-in.
            blurred = adjusted
            pixelated = adjusted
        }

        if displayIsStale {
            adjustedImage = adjusted
            baseImage = NSImage(cgImage: adjusted, size: pointSize)
            _pixelSampler = nil
            if censorSourcesReady {
                blurredImage = blurred
                pixelatedImage = pixelated
            }
            displayedAdjustments = adjustments
        }
        return (baseImage, blurred, pixelated)
    }

    /// The flattened composition: Beautify frame (pass-through when disabled) around the
    /// Capture + Annotations. `ImageRenderer` rasterizes at the Capture's native scale.
    private func exportCanvas() -> BeautifyCanvas {
        let images = exportImages()
        return BeautifyCanvas(
            base: images.base,
            blurred: images.blurred,
            pixelated: images.pixelated,
            capturePointSize: pointSize,
            captureScale: capture.scale,
            settings: effectiveSettings,
            scale: 1,
            annotations: annotations,
            draft: nil
        )
    }

    func renderedNSImage() -> NSImage? {
        let renderer = ImageRenderer(content: exportCanvas())
        renderer.scale = capture.scale
        return renderer.nsImage
    }

    func renderedCGImage() -> CGImage? {
        let renderer = ImageRenderer(content: exportCanvas())
        renderer.scale = capture.scale
        return renderer.cgImage
    }

    private func writeImage(to url: URL) {
        guard var cgImage = renderedCGImage() else {
            NSLog("Parcel: failed to render Capture for save")
            return
        }
        if CapturePreferences.convertToSRGB {
            cgImage = ImageColorSpace.convertToSRGB(cgImage) ?? cgImage
        }
        let data = Self.encodeImage(
            cgImage,
            as: outputFormat,
            outputSize: effectiveSettings.outerSize(for: pointSize)
        )
        guard let data else {
            NSLog("Parcel: failed to encode \(outputFormat.label)")
            return
        }
        do {
            try data.write(to: url)
        } catch {
            NSLog("Parcel: failed to write Capture — \(error)")
        }
    }

    static func encodeImage(_ cgImage: CGImage, as outputFormat: OutputFormat, outputSize: CGSize) -> Data? {
        if outputFormat == .webp {
            return ParcelWebPEncoder.encode(cgImage)
        } else if outputFormat.usesImageIO {
            let destinationData = NSMutableData()
            guard let destination = CGImageDestinationCreateWithData(
                destinationData, outputFormat.contentType.identifier as CFString, 1, nil
            ) else {
                NSLog("Parcel: failed to create \(outputFormat.label) destination")
                return nil
            }
            CGImageDestinationAddImage(destination, cgImage, nil)
            return CGImageDestinationFinalize(destination) ? destinationData as Data : nil
        } else if let bitmapType = outputFormat.bitmapType {
            let rep = NSBitmapImageRep(cgImage: cgImage)
            rep.size = outputSize
            var properties: [NSBitmapImageRep.PropertyKey: Any] = [:]
            if outputFormat == .jpeg { properties[.compressionFactor] = 0.92 }
            return rep.representation(using: bitmapType, properties: properties)
        } else {
            return nil
        }
    }

    // MARK: Local re-editable history

    func historyDocument(id: UUID, createdAt: Date, captureFileName: String) -> CaptureDocument {
        CaptureDocument(
            id: id,
            createdAt: createdAt,
            updatedAt: Date(),
            captureFileName: captureFileName,
            captureScale: capture.scale,
            annotations: annotations,
            adjustments: adjustments,
            beautify: beautify,
            beautifyEnabled: beautifyEnabled,
            outputFormat: outputFormat
        )
    }

    // MARK: Save location memory

    private static let lastSaveDirectoryKey = "\(AppIdentity.defaultsPrefix).lastSaveDirectory"

    private static var lastSaveDirectory: URL? {
        get {
            guard let path = UserDefaults.standard.string(forKey: lastSaveDirectoryKey) else { return nil }
            return URL(fileURLWithPath: path, isDirectory: true)
        }
        set { UserDefaults.standard.set(newValue?.path, forKey: lastSaveDirectoryKey) }
    }

}

enum HighlighterSnapper {
    static func snappedPoints(_ points: [CGPoint], to boxes: [CGRect], threshold: CGFloat = 24) -> [CGPoint] {
        guard !boxes.isEmpty else { return points }
        return points.map { point in
            let nearest = boxes.min {
                hypot($0.midX - point.x, $0.midY - point.y) < hypot($1.midX - point.x, $1.midY - point.y)
            }
            guard let box = nearest,
                  hypot(box.midX - point.x, box.midY - point.y) < threshold
            else { return point }
            return CGPoint(x: box.midX, y: box.midY)
        }
    }
}

// MARK: - Color swatches

enum ColorSwatchStore {
    private static let key = "\(AppIdentity.defaultsPrefix).editor.colorSwatches"

    static func load() -> [RGBAColor] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let colors = try? JSONDecoder().decode([RGBAColor].self, from: data)
        else { return [] }
        return colors
    }

    static func add(_ color: RGBAColor) {
        var colors = load()
        if !colors.contains(color) {
            colors.insert(color, at: 0)
            if colors.count > 12 { colors = Array(colors.prefix(12)) }
            if let data = try? JSONEncoder().encode(colors) {
                UserDefaults.standard.set(data, forKey: key)
            }
        }
    }
}

// MARK: - sRGB conversion

enum ImageColorSpace {
    static func convertToSRGB(_ image: CGImage) -> CGImage? {
        let srgb = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: image.width,
            height: image.height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: srgb,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        return context.makeImage()
    }
}
