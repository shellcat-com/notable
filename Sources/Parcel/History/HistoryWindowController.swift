import AppKit
import SwiftUI

@MainActor
final class HistoryWindowController: NSObject, NSWindowDelegate {
    private let window: NSWindow

    init(
        store: HistoryStore,
        onOpen: @escaping (UUID) -> Void,
        onPin: @escaping (UUID) -> Void = { _ in }
    ) {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 520),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        super.init()
        window.title = "Capture History"
        window.minSize = NSSize(width: 520, height: 320)
        window.tabbingMode = .disallowed
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(
            rootView: HistoryView(store: store, onOpen: onOpen, onPin: onPin)
        )
    }

    func show() {
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
}

private struct HistoryView: View {
    @ObservedObject var store: HistoryStore
    let onOpen: (UUID) -> Void
    let onPin: (UUID) -> Void
    @State private var filter = ""

    private var filtered: [HistoryEntry] {
        store.entries.filter { $0.matchesFilter(filter) }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Capture History").font(.title3.weight(.semibold))
                Spacer()
                TextField("Filter", text: $filter)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 220)
                if !store.entries.isEmpty {
                    Button("Clear All", role: .destructive) { store.removeAll() }
                }
            }
            .padding(16)

            if filtered.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)
                    Text(store.entries.isEmpty ? "No Captures Yet" : "No Matches")
                        .font(.headline)
                    Text(
                        store.entries.isEmpty
                            ? "New Captures are kept here for local re-editing."
                            : "Try a different filter."
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(filtered) { entry in
                    HStack(spacing: 12) {
                        if let preview = store.preview(for: entry) {
                            Image(nsImage: preview)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 116, height: 72)
                                .clipped()
                                .cornerRadius(4)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.displayDate).font(.headline)
                            Text("\(entry.pixelWidth) × \(entry.pixelHeight) pixels")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Open") { onOpen(entry.id) }
                        Button("Pin") { onPin(entry.id) }
                        Button(role: .destructive) { store.remove(entry.id) } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                        .help("Remove from local history")
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) { onOpen(entry.id) }
                    .contextMenu {
                        Button("Open in Editor") { onOpen(entry.id) }
                        Button("Pin to Screen") { onPin(entry.id) }
                        Divider()
                        Button("Delete", role: .destructive) { store.remove(entry.id) }
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
        .onAppear { store.pruneExpiredEntries() }
    }
}
