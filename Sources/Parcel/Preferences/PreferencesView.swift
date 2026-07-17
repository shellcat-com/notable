import SwiftUI

/// Preferences: permissions, configurable Capture hotkey, and Supabase upload settings.
struct PreferencesView: View {
    @State private var hasScreenPermission = ScreenRecordingPermission.isGranted
    @State private var keyCode = HotKeyPreferences.keyCode
    @State private var modifiers = HotKeyPreferences.modifiers
    @State private var supabaseURL = UploadPreferences.supabaseURL
    @State private var anonKey = UploadPreferences.anonKey
    @State private var bucketName = UploadPreferences.bucketName
    @State private var publicBaseURL = UploadPreferences.publicBaseURL

    private let poll = Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()

    var body: some View {
        Form {
            Section("Permissions") {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Screen Recording")
                        Text("Required to capture your screen. After granting, quit and reopen Parcel.")
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
                HotKeyRecorder(keyCode: $keyCode, modifiers: $modifiers)
            }

            Section("Upload (Supabase)") {
                TextField("Project URL", text: $supabaseURL)
                    .textFieldStyle(.roundedBorder)
                SecureField("Anon key", text: $anonKey)
                    .textFieldStyle(.roundedBorder)
                TextField("Bucket name", text: $bucketName)
                    .textFieldStyle(.roundedBorder)
                TextField("Public base URL (optional)", text: $publicBaseURL)
                    .textFieldStyle(.roundedBorder)
                Text("Configure a public Supabase Storage bucket. Upload copies the object URL to your clipboard.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 480, height: 420)
        .task { await refreshPermissionStatus() }
        .onReceive(poll) { _ in Task { await refreshPermissionStatus() } }
        .onDisappear { persistUploadSettings() }
    }

    private func persistUploadSettings() {
        UploadPreferences.supabaseURL = supabaseURL
        UploadPreferences.anonKey = anonKey
        UploadPreferences.bucketName = bucketName
        UploadPreferences.publicBaseURL = publicBaseURL
    }

    @MainActor
    private func refreshPermissionStatus() async {
        let preflight = ScreenRecordingPermission.isGranted
        let captureAPIWorks = preflight ? true : await ScreenRecordingPermission.canUseCaptureAPI()
        hasScreenPermission = preflight || captureAPIWorks
    }
}
