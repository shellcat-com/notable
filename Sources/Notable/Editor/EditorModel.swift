import AppKit
import CoreImage
import SwiftUI
import UniformTypeIdentifiers

/// Backing state for one Editor window: the Capture, its Layer of Annotations, the active Tool and
/// style, undo/redo, and annotation-aware Copy/Save.
@MainActor
final class EditorModel: ObservableObject {

    let capture: Capture

    @Published var annotations: [Annotation] = []
    @Published var selectedID: UUID?
    @Published var editingTextID: UUID?

    @Published var activeTool: Tool = .arrow
    @Published var toolColor: RGBAColor = .red
    @Published var lineWidth: CGFloat = 4

    private let textFontSize: CGFloat = 18

    private var undoStack: [[Annotation]] = []
    private var redoStack: [[Annotation]] = []

    init(capture: Capture) {
        self.capture = capture
    }

    // MARK: Derived

    var pointSize: CGSize { capture.pointSize }

    lazy var baseImage: NSImage = NSImage(cgImage: capture.image, size: capture.pointSize)

    /// A gaussian-blurred copy of the whole Capture, sampled inside Censor rects. Built once.
    lazy var blurredImage: CGImage = makeBlurredImage()

    var currentStyle: AnnotationStyle {
        AnnotationStyle(color: toolColor, lineWidth: lineWidth, fontSize: textFontSize)
    }

    var selectedAnnotation: Annotation? {
        guard let selectedID else { return nil }
        return annotations.first { $0.id == selectedID }
    }

    func annotation(_ id: UUID) -> Annotation? {
        annotations.first { $0.id == id }
    }

    // MARK: Tool

    func selectTool(_ tool: Tool) {
        endEditingText()
        activeTool = tool
        if tool.isDrawing { selectedID = nil }
    }

    // MARK: Editing operations (each is one undo step)

    func add(_ annotation: Annotation) {
        pushUndo()
        annotations.append(annotation)
        selectedID = annotation.id
    }

    func deleteSelected() {
        guard let id = selectedID, annotations.contains(where: { $0.id == id }) else { return }
        pushUndo()
        annotations.removeAll { $0.id == id }
        selectedID = nil
        editingTextID = nil
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

    // MARK: Text editing

    func beginEditingText(_ id: UUID, isNew: Bool) {
        if !isNew { pushUndo() }
        selectedID = id
        editingTextID = id
    }

    func endEditingText() {
        guard let id = editingTextID else { return }
        editingTextID = nil
        // Drop an Annotation left empty, and undo the creation entry so it isn't a dangling step.
        if let index = annotations.firstIndex(where: { $0.id == id }),
           case let .text(_, string) = annotations[index].kind,
           string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            annotations.remove(at: index)
            if !undoStack.isEmpty { undoStack.removeLast() }
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
        guard let previous = undoStack.popLast() else { return }
        redoStack.append(annotations)
        annotations = previous
        clearTransient()
    }

    func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(annotations)
        annotations = next
        clearTransient()
    }

    private func pushUndo() {
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

    // MARK: Output

    func copyToClipboard() {
        guard let image = renderedNSImage() else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
    }

    func save() {
        // Commit any in-progress text before rendering.
        endEditingText()
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = Self.defaultFileName()
        if let dir = Self.lastSaveDirectory { panel.directoryURL = dir }

        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url, let self else { return }
            self.writePNG(to: url)
            Self.lastSaveDirectory = url.deletingLastPathComponent()
        }
    }

    /// The flattened Capture + Annotations. `ImageRenderer` rasterizes the shared `AnnotatedCanvas`
    /// at the Capture's native scale, so output is full-resolution and matches what's on screen.
    private func exportCanvas() -> AnnotatedCanvas {
        AnnotatedCanvas(
            base: baseImage,
            blurred: blurredImage,
            pointSize: pointSize,
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

    private func writePNG(to url: URL) {
        guard let cgImage = renderedCGImage() else {
            NSLog("Notable: failed to render image for save")
            return
        }
        let rep = NSBitmapImageRep(cgImage: cgImage)
        rep.size = pointSize
        guard let data = rep.representation(using: .png, properties: [:]) else {
            NSLog("Notable: failed to encode PNG")
            return
        }
        do {
            try data.write(to: url)
        } catch {
            NSLog("Notable: failed to write PNG — \(error)")
        }
    }

    private func makeBlurredImage() -> CGImage {
        let source = CIImage(cgImage: capture.image)
        let extent = source.extent
        let sigma = max(8, Double(min(extent.width, extent.height)) / 90)
        let blurred = source
            .clampedToExtent()
            .applyingGaussianBlur(sigma: sigma)
            .cropped(to: extent)
        let context = CIContext()
        return context.createCGImage(blurred, from: extent) ?? capture.image
    }

    // MARK: Save location memory

    private static let lastSaveDirectoryKey = "io.notable.lastSaveDirectory"

    private static var lastSaveDirectory: URL? {
        get {
            guard let path = UserDefaults.standard.string(forKey: lastSaveDirectoryKey) else { return nil }
            return URL(fileURLWithPath: path, isDirectory: true)
        }
        set { UserDefaults.standard.set(newValue?.path, forKey: lastSaveDirectoryKey) }
    }

    private static func defaultFileName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd 'at' HH.mm.ss"
        return "Notable \(formatter.string(from: Date())).png"
    }
}
