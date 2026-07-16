import SwiftUI

/// The Editor's SwiftUI surface. Phase 1a shows the Capture with Copy / Save / Close and their
/// keyboard shortcuts; the annotation toolbar and editable Canvas build on top of this next.
struct EditorView: View {
    @ObservedObject var model: EditorModel
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            canvas
        }
        .frame(minWidth: 360, minHeight: 260)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var toolbar: some View {
        HStack(spacing: 10) {
            Text("\(Int(model.pointSize.width)) × \(Int(model.pointSize.height))")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.secondary)

            Spacer()

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

            Button(role: .cancel) {
                onClose()
            } label: {
                Label("Close", systemImage: "xmark")
            }
            .keyboardShortcut(.cancelAction)
        }
        .labelStyle(.titleAndIcon)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var canvas: some View {
        ScrollView([.horizontal, .vertical]) {
            Image(nsImage: model.displayImage)
                .resizable()
                .frame(width: model.pointSize.width, height: model.pointSize.height)
                .background(Color.black.opacity(0.05))
                .padding(24)
        }
    }
}
