import AppKit
import SwiftUI

/// The Editor's SwiftUI surface: a two-row Tool/style toolbar over the interactive Canvas.
struct EditorView: View {
    @ObservedObject var model: EditorModel
    var onClose: () -> Void
    var onShowHistory: () -> Void

    @State private var showingAdjust = false
    @State private var showingBeautify = false
    @State private var showingVision = false

    var body: some View {
        VStack(spacing: 0) {
            toolsRow
            Divider()
            actionsRow
            Divider()
            EditorCanvasView(model: model)
                .background(Color(nsColor: .underPageBackgroundColor))
            statusStrip
        }
        .frame(minWidth: 720, minHeight: 420)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private static let createTools: [Tool] = [
        .select, .arrow, .rectangle, .ellipse, .text, .pencil, .censor,
        .number, .stamp, .highlighter, .measure, .spotlight,
    ]
    private static let utilityTools: [Tool] = [.loupe, .eyedropper]

    // MARK: Row 1 — Tools

    private var toolsRow: some View {
        HStack(spacing: 2) {
            toolGroupLabel("Create")
            ForEach(Self.createTools) { toolButton($0) }
            Divider().frame(height: 22).padding(.horizontal, 4)
            toolGroupLabel("Utility")
            ForEach(Self.utilityTools) { toolButton($0) }
            Spacer(minLength: 6)
            contextualControls
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
    }

    private func toolGroupLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.secondary)
            .padding(.trailing, 2)
    }

    private func toolButton(_ tool: Tool) -> some View {
        Button {
            model.selectTool(tool)
        } label: {
            Image(systemName: tool.symbol)
                .frame(width: 24, height: 22)
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(model.activeTool == tool ? Color.accentColor.opacity(0.22) : .clear)
        )
        .foregroundStyle(model.activeTool == tool ? Color.accentColor : Color.primary)
        .accessibilityLabel(tool.label)
        .accessibilityIdentifier("tool-\(tool.rawValue)")
        .help(tool.label)
    }

    @ViewBuilder
    private var contextualControls: some View {
        if showsArrowControls {
            Menu {
                ForEach(ArrowStyle.allCases) { style in
                    Button { model.setArrowStyle(style) } label: { Label(style.label, systemImage: style.symbol) }
                }
            } label: {
                Image(systemName: model.displayArrowStyle.symbol)
            }
            .menuStyle(.borderlessButton)
            .frame(width: 48, height: 28)
            .accessibilityLabel("Arrow style")
            .accessibilityValue(model.displayArrowStyle.label)
            .accessibilityIdentifier("arrow-style-menu")
            .help("Arrow style")
        }

        if showsCensorControls {
            Picker("", selection: censorModeBinding) {
                ForEach(CensorMode.allCases) { mode in
                    Label(mode.label, systemImage: mode.symbol)
                        .labelStyle(.iconOnly)
                        .tag(mode)
                        .accessibilityLabel(mode.label)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 164)
            .accessibilityLabel("Censor mode")
            .accessibilityValue(model.displayCensorMode.label)
            .accessibilityIdentifier("censor-mode-picker")
            .help("Censor mode")
        }

        if model.activeTool == .stamp {
            Menu {
                ForEach(EditorModel.stampChoices, id: \.self) { emoji in
                    Button(emoji) { model.currentEmoji = emoji }
                }
            } label: {
                Text(model.currentEmoji)
            }
            .menuStyle(.borderlessButton)
            .frame(width: 46)
            .help("Stamp")
        }

        if model.activeTool == .spotlight {
            Picker("", selection: $model.spotlightShape) {
                ForEach(SpotlightShape.allCases) { shape in Image(systemName: shape.symbol).tag(shape) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 74)
            .help("Spotlight shape")
        }

        if model.activeTool == .measure {
            Toggle(isOn: $model.measureShowsSize) {
                Image(systemName: "aspectratio")
            }
            .toggleStyle(.button)
            .help("Show width × height")
        }
    }

    // MARK: Row 2 — Style + actions

    private var actionsRow: some View {
        HStack(spacing: 10) {
            style
            Divider().frame(height: 22)
            effects
            Divider().frame(height: 22)
            layers
            Divider().frame(height: 22)
            history
            Spacer(minLength: 8)
            output
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
    }

    private var style: some View {
        HStack(spacing: 8) {
            ColorPicker("", selection: colorBinding, supportsOpacity: false)
                .labelsHidden()
                .help("Color")

            if !model.savedColors.isEmpty {
                ForEach(Array(model.savedColors.prefix(6).enumerated()), id: \.offset) { _, swatch in
                    Button {
                        model.toolColor = swatch
                    } label: {
                        Circle()
                            .fill(swatch.color)
                            .frame(width: 14, height: 14)
                            .overlay(Circle().strokeBorder(Color.primary.opacity(0.2), lineWidth: 0.5))
                    }
                    .buttonStyle(.plain)
                }
            }
            Button {
                model.saveCurrentColorSwatch()
            } label: {
                Image(systemName: "plus.circle")
            }
            .buttonStyle(.borderless)
            .help("Save color swatch")

            HStack(spacing: 4) {
                Image(systemName: "lineweight").foregroundStyle(.secondary).font(.system(size: 11))
                Slider(
                    value: lineWidthBinding, in: 1...16,
                    onEditingChanged: { editing in if !editing { model.endLineWidthEdit() } }
                )
                .frame(width: 84)
                .help("Line width")
            }
        }
    }

    private var effects: some View {
        HStack(spacing: 4) {
            Button { showingAdjust.toggle() } label: { Image(systemName: "slider.horizontal.3") }
                .buttonStyle(.borderless)
                .foregroundStyle(model.adjustments.isNeutral ? Color.primary : Color.accentColor)
                .help("Adjust")
                .popover(isPresented: $showingAdjust, arrowEdge: .bottom) {
                    AdjustmentsPanel(model: model)
                }

            Button { showingBeautify.toggle() } label: { Image(systemName: "wand.and.stars") }
                .buttonStyle(.borderless)
                .foregroundStyle(model.beautifyEnabled ? Color.accentColor : Color.primary)
                .help("Beautify")
                .popover(isPresented: $showingBeautify, arrowEdge: .bottom) {
                    BeautifyPanel(model: model)
                }

            Button { showingVision.toggle() } label: { Image(systemName: "viewfinder.circle") }
                .buttonStyle(.borderless)
                .foregroundStyle(model.visionAnalysis.text.isEmpty && model.visionAnalysis.faces.isEmpty
                    ? Color.primary : Color.accentColor)
                .help("Inspect Capture")
                .popover(isPresented: $showingVision, arrowEdge: .bottom) {
                    VisionPanel(model: model)
                }
        }
    }

    private var layers: some View {
        HStack(spacing: 2) {
            Button { model.sendToBack() } label: { Image(systemName: "square.3.layers.3d.bottom.filled") }
                .disabled(model.selectedID == nil)
                .help("Send to back")
            Button { model.sendBackward() } label: { Image(systemName: "square.2.layers.3d.bottom.filled") }
                .disabled(model.selectedID == nil)
                .help("Send backward")
            Button { model.bringForward() } label: { Image(systemName: "square.2.layers.3d.top.filled") }
                .disabled(model.selectedID == nil)
                .help("Bring forward")
            Button { model.bringToFront() } label: { Image(systemName: "square.3.layers.3d.top.filled") }
                .disabled(model.selectedID == nil)
                .help("Bring to front")
        }
        .buttonStyle(.borderless)
    }

    private var statusStrip: some View {
        HStack(spacing: 12) {
            Text("\(Int(model.pointSize.width))×\(Int(model.pointSize.height)) pt")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.secondary)
            Text(model.activeTool.label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
            if model.isUploading {
                ProgressView().controlSize(.mini)
            }
            if let message = model.statusMessage {
                Text(message)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var history: some View {
        HStack(spacing: 2) {
            Button { model.undo() } label: { Image(systemName: "arrow.uturn.backward") }
                .keyboardShortcut("z", modifiers: .command)
                .disabled(!model.canUndo)
                .help("Undo")

            Button { model.redo() } label: { Image(systemName: "arrow.uturn.forward") }
                .keyboardShortcut("z", modifiers: [.command, .shift])
                .disabled(!model.canRedo)
                .help("Redo")

            Button { model.deleteSelected() } label: { Image(systemName: "trash") }
                .keyboardShortcut(.delete, modifiers: [])
                .disabled(model.selectedID == nil || model.editingTextID != nil)
                .help("Delete selected")
        }
        .buttonStyle(.borderless)
    }

    private var output: some View {
        HStack(spacing: 8) {
            Menu {
                Button("Crop to Selection Bounds") {
                    if let selected = model.selectedAnnotation {
                        model.cropCapture(toPoints: selected.kind.boundingBox.insetBy(dx: -4, dy: -4))
                    }
                }
                .disabled(model.selectedID == nil)
                Button("Resize to 50%") {
                    let size = model.pointSize
                    model.resizeCapture(toPointSize: CGSize(width: size.width * 0.5, height: size.height * 0.5))
                }
                Button("Rotate 90°") { model.rotateCapture90CW() }
                Button("Flip Horizontal") { model.flipCaptureHorizontal() }
                Button("Flip Vertical") { model.flipCaptureVertical() }
                Button("Expand Canvas +40pt") {
                    model.expandCanvas(top: 40, left: 40, bottom: 40, right: 40)
                }
                Button("Remove Backdrop") {
                    model.removeOpaqueBackground()
                }
                Divider()
                Button("Combine from Clipboard…") {
                    guard let image = NSImage(pasteboard: NSPasteboard.general),
                          let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
                    else { return }
                    let other = Capture(image: cg, scale: model.capture.scale)
                    let rect = CGRect(
                        x: model.pointSize.width * 0.1,
                        y: model.pointSize.height * 0.1,
                        width: model.pointSize.width * 0.35,
                        height: model.pointSize.height * 0.35
                    )
                    model.combineCapture(other, into: rect)
                }
            } label: {
                Image(systemName: "crop.rotate")
            }
            .menuStyle(.borderlessButton)
            .help("Capture transforms")

            Button {
                model.copyToClipboard()
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
            .keyboardShortcut("c", modifiers: .command)

            Menu {
                ForEach(OutputFormat.allCases) { format in
                    Button {
                        model.outputFormat = format
                    } label: {
                        if model.outputFormat == format {
                            Label(format.label, systemImage: "checkmark")
                        } else {
                            Text(format.label)
                        }
                    }
                }
            } label: {
                Text(model.outputFormat.label)
            }
            .menuStyle(.borderlessButton)
            .frame(minWidth: 56)
            .accessibilityLabel("Output format")
            .accessibilityValue(model.outputFormat.label)
            .accessibilityIdentifier("output-format-menu")
            .help("Output format")

            Button {
                model.save()
            } label: {
                Label("Save…", systemImage: "square.and.arrow.down")
            }
            .keyboardShortcut("s", modifiers: .command)

            Button {
                model.saveParcelProject()
            } label: {
                Image(systemName: "doc.badge.gearshape")
            }
            .help("Save editable .parcel project")

            Button {
                model.printCapture()
            } label: {
                Image(systemName: "printer")
            }
            .keyboardShortcut("p", modifiers: .command)
            .help("Print")

            Button {
                model.shareCapture()
            } label: {
                Image(systemName: "square.and.arrow.up")
            }
            .help("Share")

            Button {
                model.uploadCapture()
            } label: {
                Label("Upload", systemImage: "icloud.and.arrow.up")
            }
            .disabled(model.isUploading || !UploadPreferences.isConfigured)
            .help(UploadPreferences.isConfigured ? "Upload to Supabase and copy link" : "Configure Supabase in Preferences")

            Button(action: onShowHistory) {
                Image(systemName: "clock.arrow.circlepath")
            }
            .help("Capture History")

            Button {
                onClose()
            } label: {
                Image(systemName: "xmark")
            }
            .keyboardShortcut("w", modifiers: .command)
            .help("Close")
        }
        .labelStyle(.titleAndIcon)
    }

    // MARK: Contextual visibility

    private var showsArrowControls: Bool {
        if model.activeTool == .arrow { return true }
        if let selected = model.selectedAnnotation, case .arrow = selected.kind { return true }
        return false
    }

    private var showsCensorControls: Bool {
        if model.activeTool == .censor { return true }
        if let selected = model.selectedAnnotation, case .censor = selected.kind { return true }
        return false
    }

    // MARK: Bindings

    private var colorBinding: Binding<Color> {
        Binding(get: { model.displayColor.color }, set: { model.setColor(RGBAColor($0)) })
    }

    private var lineWidthBinding: Binding<Double> {
        Binding(get: { Double(model.displayLineWidth) }, set: { model.setLineWidth(CGFloat($0)) })
    }

    private var censorModeBinding: Binding<CensorMode> {
        Binding(get: { model.displayCensorMode }, set: { model.setCensorMode($0) })
    }
}

/// Small, fully local Vision surface. Results are not baked into the Capture unless the user
/// explicitly asks to create Censor Annotations from them.
private struct VisionPanel: View {
    @ObservedObject var model: EditorModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Inspect Capture").font(.headline)
                Spacer()
                if model.isAnalyzingVision { ProgressView().controlSize(.small) }
            }

            Button("Recognize Text, Faces & QR Codes") { model.inspectCapture() }
                .disabled(model.isAnalyzingVision)

            if hasResults {
                Divider()
                resultSummary
            } else if !model.isAnalyzingVision {
                Text("Inspection stays on this Mac. It can recognize text, find faces, and read QR codes.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(width: 330)
    }

    private var hasResults: Bool {
        !model.visionAnalysis.text.isEmpty || !model.visionAnalysis.faces.isEmpty || !model.visionAnalysis.qrCodes.isEmpty
    }

    @ViewBuilder
    private var resultSummary: some View {
        if !model.visionAnalysis.text.isEmpty {
            HStack {
                Label("\(model.visionAnalysis.text.count) text regions", systemImage: "text.viewfinder")
                Spacer()
                Button("Copy Text") { model.copyRecognizedText() }
            }
            if TranslationService.isAvailable {
                Button("Translate On-Device") { model.translateRecognizedText() }
                    .disabled(model.isTranslating)
            }
            if model.isTranslating {
                ProgressView().controlSize(.small)
            }
            if let translated = model.translatedText, !translated.isEmpty {
                Divider()
                Text(translated)
                    .font(.footnote)
                    .textSelection(.enabled)
                    .frame(maxHeight: 80)
                Button("Copy Translation") { model.copyTranslatedText() }
            }
        }
        if !model.visionAnalysis.piiText.isEmpty {
            Button("Censor Detected Sensitive Text") { model.censorDetectedPII() }
        }
        if !model.visionAnalysis.faces.isEmpty {
            Button("Censor \(model.visionAnalysis.faces.count) Faces") { model.censorDetectedFaces() }
        }
        if !model.visionAnalysis.qrCodes.isEmpty {
            Divider()
            Text("QR Codes").font(.subheadline.weight(.medium))
            ForEach(model.visionAnalysis.qrCodes) { code in
                Button(code.payload) { model.copyQRCode(code) }
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help("Copy QR code payload")
            }
        }
    }
}
