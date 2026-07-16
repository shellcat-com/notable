import SwiftUI

/// The Editor's SwiftUI surface: the Tool/style toolbar over the interactive Canvas.
struct EditorView: View {
    @ObservedObject var model: EditorModel
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            EditorCanvasView(model: model)
                .background(Color(nsColor: .underPageBackgroundColor))
        }
        .frame(minWidth: 620, minHeight: 380)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: Toolbar

    private var toolbar: some View {
        HStack(spacing: 10) {
            tools
            Divider().frame(height: 22)
            style
            Divider().frame(height: 22)
            history
            Spacer(minLength: 8)
            output
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var tools: some View {
        HStack(spacing: 2) {
            ForEach(Tool.allCases) { tool in
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
        }
    }

    private var style: some View {
        HStack(spacing: 8) {
            ColorPicker("", selection: colorBinding, supportsOpacity: false)
                .labelsHidden()
                .help("Color")

            HStack(spacing: 4) {
                Image(systemName: "lineweight").foregroundStyle(.secondary).font(.system(size: 11))
                Slider(value: $model.lineWidth, in: 1...16)
                    .frame(width: 90)
                    .help("Line width")
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

            Button {
                model.save()
            } label: {
                Label("Save…", systemImage: "square.and.arrow.down")
            }
            .keyboardShortcut("s", modifiers: .command)

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

    private var colorBinding: Binding<Color> {
        Binding(
            get: { model.toolColor.color },
            set: { model.toolColor = RGBAColor($0) }
        )
    }
}
