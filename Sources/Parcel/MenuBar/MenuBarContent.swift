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

        Button("Capture Previous Area") {
            coordinator.beginPreviousAreaCapture()
        }
        .keyboardShortcut("5", modifiers: [.command, .shift])
        .disabled(!CapturePreferences.hasPreviousArea)

        Button("Capture Window") {
            coordinator.beginWindowCapture()
        }

        Button("Capture Display") {
            coordinator.beginFullscreenCapture()
        }

        Button("Capture All Displays") {
            coordinator.beginAllDisplaysCapture()
        }

        Button("Copy Text (OCR)") {
            coordinator.beginOCRCapture()
        }

        Menu("Capture with Delay") {
            Button("3 Seconds") { coordinator.beginRegionCapture(after: 3) }
            Button("5 Seconds") { coordinator.beginRegionCapture(after: 5) }
            Button("10 Seconds") { coordinator.beginRegionCapture(after: 10) }
        }
        .disabled(coordinator.isCapturing && coordinator.captureDelayRemaining == nil)

        if let remaining = coordinator.captureDelayRemaining {
            Text(CountdownDisplay.captureLabel(remaining: remaining))
                .font(.caption)
                .foregroundStyle(.secondary)
                .disabled(true)
        }

        if let remaining = coordinator.recordingCountdownRemaining {
            Text(CountdownDisplay.recordingLabel(remaining: remaining))
                .font(.caption)
                .foregroundStyle(.secondary)
                .disabled(true)
        }

        if let banner = coordinator.statusBanner {
            Text(banner)
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
                coordinator.isRecording
                    ? (coordinator.isPausedRecording ? "Resume / Stop Recording" : "Stop Recording")
                    : "Record Region…",
                systemImage: coordinator.isRecording ? "stop.fill" : "record.circle"
            )
        }
        .disabled(coordinator.isStartingRecording || coordinator.isCapturing)

        Button("Record Previous Area") {
            coordinator.beginPreviousRecordingArea()
        }
        .disabled(
            coordinator.isStartingRecording
                || coordinator.isCapturing
                || coordinator.isRecording
                || !CapturePreferences.hasPreviousRecordingArea
        )

        if coordinator.isRecording {
            Button(coordinator.isPausedRecording ? "Resume Recording" : "Pause Recording") {
                coordinator.pauseOrResumeRecording()
            }
            Button("Restart Recording") {
                coordinator.restartRecording()
            }
        }

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

        Button("Open from Clipboard") {
            coordinator.openFromClipboard()
        }

        Button("Restore Recently Closed") {
            coordinator.restoreRecentlyClosed()
        }

        Button(coordinator.pinsHidden ? "Show Overlays" : "Hide Overlays") {
            coordinator.hideAllOverlays()
        }

        Button("Close All Pins", role: .destructive) {
            coordinator.closeAllPins()
        }

        Button("Annotate Last Capture") {
            coordinator.annotateLastCapture()
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
