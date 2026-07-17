import AppKit
import SwiftUI

@MainActor
final class WelcomeWindowController {

    private var window: NSWindow?
    private let onOpenPreferences: () -> Void
    private let onFinish: () -> Void

    init(onOpenPreferences: @escaping () -> Void, onFinish: @escaping () -> Void) {
        self.onOpenPreferences = onOpenPreferences
        self.onFinish = onFinish
    }

    func show() {
        if window == nil {
            let view = WelcomeView(
                onGrantPermission: {
                    ScreenRecordingPermission.request()
                    ScreenRecordingPermission.openSystemSettings()
                },
                onOpenPreferences: { [weak self] in
                    self?.onOpenPreferences()
                },
                onQuitAndReopen: {
                    NSApplication.shared.terminate(nil)
                },
                onFinish: { [weak self] in
                    self?.onFinish()
                    self?.window?.close()
                }
            )
            let hosting = NSHostingView(rootView: view)
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 520, height: 440),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "Welcome to Parcel"
            window.contentView = hosting
            window.center()
            window.isReleasedWhenClosed = false
            self.window = window
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}

struct WelcomeView: View {
    @State private var step = 0
    @State private var hasPermission = ScreenRecordingPermission.isGranted

    let onGrantPermission: () -> Void
    let onOpenPreferences: () -> Void
    let onQuitAndReopen: () -> Void
    let onFinish: () -> Void

    private let poll = Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            switch step {
            case 0:
                welcomeStep
            case 1:
                permissionStep
            case 2:
                uploadStep
            default:
                finishStep
            }

            HStack {
                if step > 0 {
                    Button("Back") { step -= 1 }
                }
                Spacer()
                if step < 3 {
                    Button(step == 2 ? "Skip" : "Continue") { step += 1 }
                        .keyboardShortcut(.defaultAction)
                } else {
                    Button("Get Started") {
                        onFinish()
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onReceive(poll) { _ in
            Task { @MainActor in
                let preflight = ScreenRecordingPermission.isGranted
                let captureAPIWorks = preflight ? true : await ScreenRecordingPermission.canUseCaptureAPI()
                hasPermission = preflight || captureAPIWorks
            }
        }
    }

    private var welcomeStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Welcome to Parcel")
                .font(.title.bold())
            Text("Capture, mark up, and ship — entirely on your Mac.")
                .foregroundStyle(.secondary)
            Text("Parcel is local-first: OCR, face detection, translation, and redaction use Apple on-device frameworks only. Nothing leaves your Mac unless you choose to upload.")
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var permissionStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Screen Recording Permission")
                .font(.title2.bold())
            Text("macOS requires Screen Recording access before Parcel can Capture or record your display.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                if hasPermission {
                    Label("Granted", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Label("Not granted yet", systemImage: "exclamationmark.circle")
                        .foregroundStyle(.orange)
                }
            }
            HStack(spacing: 12) {
                Button("Grant Permission…") { onGrantPermission() }
                Button("Quit & Reopen") { onQuitAndReopen() }
            }
            Text("After granting in System Settings, quit and reopen Parcel so the permission takes effect.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var uploadStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Optional: Supabase Upload")
                .font(.title2.bold())
            Text("Configure a Supabase Storage bucket in Preferences to upload Captures and copy a public link from the Editor.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button("Open Preferences…") { onOpenPreferences() }
        }
    }

    private var finishStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("You're Ready")
                .font(.title2.bold())
            Text("Press ⌘⇧2 from anywhere to start a Capture. Parcel lives in your menu bar — look for the Parcel icon.")
                .fixedSize(horizontal: false, vertical: true)
            Text("You can change the shortcut anytime in Preferences.")
                .foregroundStyle(.secondary)
        }
    }
}
