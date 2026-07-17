import SwiftUI

/// The menu shown from Parcel's menu bar item.
struct MenuBarContent: View {
    @ObservedObject var coordinator: AppCoordinator
    var onCheckForUpdates: () -> Void

    var body: some View {
        Button("Capture Region") {
            coordinator.beginRegionCapture()
        }
        .keyboardShortcut("2", modifiers: [.command, .shift])

        Button("Capture All Displays") {
            coordinator.beginAllDisplaysCapture()
        }

        Menu("Capture with Delay") {
            Button("3 Seconds") { coordinator.beginRegionCapture(after: 3) }
            Button("5 Seconds") { coordinator.beginRegionCapture(after: 5) }
            Button("10 Seconds") { coordinator.beginRegionCapture(after: 10) }
        }
        .disabled(coordinator.isCapturing && coordinator.captureDelayRemaining == nil)

        if let remaining = coordinator.captureDelayRemaining {
            Text("Capturing in \(Int(ceil(remaining)))s…")
                .font(.caption)
                .foregroundStyle(.secondary)
                .disabled(true)
        }

        if coordinator.isScrollCapturing {
            Divider()
            Text("Scroll the source, then add a frame.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .disabled(true)
            Button("Add Scroll Frame (\(coordinator.scrollFrameCount))") {
                coordinator.appendScrollCaptureFrame()
            }
            .disabled(coordinator.isAddingScrollFrame)
            Button("Finish Scroll Capture") {
                coordinator.finishScrollCapture()
            }
            Button("Cancel Scroll Capture", role: .destructive) {
                coordinator.cancelScrollCapture()
            }
        } else {
            Button("Start Scroll Capture") {
                coordinator.beginScrollCapture()
            }
        }

        Button {
            coordinator.toggleRecording()
        } label: {
            Label(
                coordinator.isRecording ? "Stop Recording" : "Record Display…",
                systemImage: coordinator.isRecording ? "stop.fill" : "record.circle"
            )
        }
        .disabled(coordinator.isStartingRecording || coordinator.isCapturing)

        Menu("Recording FPS") {
            ForEach(RecordingFPS.allCases) { fps in
                Button {
                    RecordingFPS.current = fps
                } label: {
                    if RecordingFPS.current == fps {
                        Label(fps.label, systemImage: "checkmark")
                    } else {
                        Text(fps.label)
                    }
                }
            }
        }

        Divider()

        Button("Preferences…") {
            coordinator.openPreferences()
        }
        .keyboardShortcut(",", modifiers: .command)

        Button("Capture History…") {
            coordinator.openHistory()
        }
        .keyboardShortcut("h", modifiers: [.command, .shift])

        Button("Check for Updates…") {
            onCheckForUpdates()
        }

        Divider()

        Button("Quit Parcel") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }
}
