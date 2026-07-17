import AppKit
import SwiftUI

@MainActor
final class HistoryWindowController: NSObject, NSWindowDelegate {
    private let window: NSWindow

    init(store: HistoryStore, onOpen: @escaping (UUID) -> Void) {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 680, height: 480),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        super.init()
        window.title = "Capture History"
        window.minSize = NSSize(width: 520, height: 320)
        window.tabbingMode = .disallowed
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: HistoryView(store: store, onOpen: onOpen))
    }

    func show() {
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
}

private struct HistoryView: View {
    @ObservedObject var store: HistoryStore
    let onOpen: (UUID) -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Capture History").font(.title3.weight(.semibold))
                Spacer()
                if !store.entries.isEmpty {
                    Button("Clear All", role: .destructive) { store.removeAll() }
                }
            }
            .padding(16)

            if store.entries.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)
                    Text("No Captures Yet").font(.headline)
                    Text("New Captures are kept here for local re-editing.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(store.entries) { entry in
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
                        Button(role: .destructive) { store.remove(entry.id) } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                        .help("Remove from local history")
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
    }
}
