import SwiftUI

/// Bare-minimum Preferences for Phase 1: permission status + the current shortcut. Deliberately
/// no more than the prompt allows (permissions plumbing only).
struct PreferencesView: View {
    @State private var hasScreenPermission = ScreenRecordingPermission.isGranted

    private let poll = Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()

    var body: some View {
        Form {
            Section("Permissions") {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Screen Recording")
                        Text("Required to capture your screen. After granting, quit and reopen Notable.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if hasScreenPermission {
                        Label("Granted", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .labelStyle(.titleAndIcon)
                    } else {
                        Button("Grant…") {
                            ScreenRecordingPermission.request()
                            ScreenRecordingPermission.openSystemSettings()
                        }
                    }
                }
            }

            Section("Shortcut") {
                LabeledContent("Capture Region") {
                    Text("⌘⇧2").font(.system(.body, design: .monospaced))
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 440, height: 260)
        .onReceive(poll) { _ in
            hasScreenPermission = ScreenRecordingPermission.isGranted
        }
    }
}
