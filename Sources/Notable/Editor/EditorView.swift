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
        }
        .frame(minWidth: 720, minHeight: 420)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: Row 1 — Tools

    private var toolsRow: some View {
        HStack(spacing: 2) {
            ForEach(Tool.allCases.filter { !$0.isUtility }) { toolButton($0) }
            Divider().frame(height: 22).padding(.horizontal, 4)
            ForEach(Tool.allCases.filter { $0.isUtility }) { toolButton($0) }
            Spacer(minLength: 6)
            contextualControls
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
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
            .frame(width: 46)
            .help("Arrow style")
        }

        if showsCensorControls {
            Picker("", selection: censorModeBinding) {
                ForEach(CensorMode.allCases) { mode in Image(systemName: mode.symbol).tag(mode) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 108)
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
            .help("Output format")

            Button {
                model.save()
            } label: {
                Label("Save…", systemImage: "square.and.arrow.down")
            }
            .keyboardShortcut("s", modifiers: .command)

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
