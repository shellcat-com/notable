import SwiftUI

/// Preferences: permissions, Capture Overlay, recording, hotkey, and Supabase upload.
struct PreferencesView: View {
    @State private var hasScreenPermission = ScreenRecordingPermission.isGranted
    @State private var keyCode = HotKeyPreferences.keyCode
    @State private var modifiers = HotKeyPreferences.modifiers
    @State private var supabaseURL = UploadPreferences.supabaseURL
    @State private var anonKey = UploadPreferences.anonKey
    @State private var bucketName = UploadPreferences.bucketName
    @State private var publicBaseURL = UploadPreferences.publicBaseURL

    @State private var useQuickAccess = CapturePreferences.useQuickAccess
    @State private var quickAccessAutoClose = CapturePreferences.quickAccessAutoCloseSeconds
    @State private var askForName = CapturePreferences.askForName
    @State private var afterCopy = CapturePreferences.afterCaptureCopy
    @State private var afterEditor = CapturePreferences.afterCaptureOpenEditor
    @State private var afterPin = CapturePreferences.afterCapturePin
    @State private var afterUpload = CapturePreferences.afterCaptureUpload
    @State private var afterSave = CapturePreferences.afterCaptureSave
    @State private var playShutter = CapturePreferences.playShutterSound
    @State private var convertSRGB = CapturePreferences.convertToSRGB
    @State private var urlSchemeEnabled = CapturePreferences.urlSchemeEnabled
    @State private var fileNameTemplate = CapturePreferences.fileNameTemplate
    @State private var scaleDownRetina = CapturePreferences.scaleDownRetina
    @State private var showCrosshair = CapturePreferences.showCrosshair
    @State private var showMagnifier = CapturePreferences.showMagnifier
    @State private var hideDesktopIcons = CapturePreferences.hideDesktopIcons
    @State private var showAllInOneBar = CapturePreferences.showAllInOneBar
    @State private var ocrStripLineBreaks = CapturePreferences.ocrStripLineBreaks

    @State private var showsCursor = RecordingPreferences.showsCursor
    @State private var capturesMicrophone = RecordingPreferences.capturesMicrophone
    @State private var showsMouseClicks = RecordingPreferences.showsMouseClicks
    @State private var showsKeystrokes = RecordingPreferences.showsKeystrokes
    @State private var keystrokesCommandOnly = RecordingPreferences.keystrokesCommandOnly
    @State private var showsWebcam = RecordingPreferences.showsWebcam
    @State private var enableDND = RecordingPreferences.enableDoNotDisturb
    @State private var countdown = RecordingPreferences.countdownSeconds
    @State private var monoAudio = RecordingPreferences.recordMonoAudio
    @State private var recordingFPS = RecordingFPS.current
    @State private var maxResolution = RecordingMaxResolution.current
    @State private var hudPosition = RecordingHUDPosition.current
    @State private var historyRetention = HistoryRetention.current

    private let poll = Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()

    var body: some View {
        Form {
            Section("Permissions") {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Screen Recording")
                        Text(permissionFootnote)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                    if hasScreenPermission {
                        Label("Granted", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .labelStyle(.titleAndIcon)
                    } else {
                        VStack(alignment: .trailing, spacing: 6) {
                            Button("Grant Access…") {
                                _ = ScreenRecordingPermission.request()
                                hasScreenPermission = ScreenRecordingPermission.isGranted
                                if !hasScreenPermission {
                                    ScreenRecordingPermission.openSystemSettings()
                                }
                            }
                            .accessibilityIdentifier("preferences.grantScreenRecording")
                            Button("Open System Settings…") {
                                ScreenRecordingPermission.openSystemSettings()
                            }
                            Button("Show App in Finder…") {
                                ScreenRecordingPermission.revealAppInFinder()
                            }
                        }
                    }
                }
            }

            Section("Shortcut") {
                HotKeyRecorder(keyCode: $keyCode, modifiers: $modifiers)
                Text("Additional Capture Area shortcuts are registered automatically (Copy ⌥⌘⇧C, Annotate ⌥⌘⇧A, Pin ⌥⌘⇧P, Previous ⌘⇧5).")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("After Capture") {
                Toggle("Show Quick Access panel", isOn: $useQuickAccess)
                if useQuickAccess {
                    Picker("Auto-close", selection: $quickAccessAutoClose) {
                        Text("Stay open").tag(0.0)
                        Text("5 seconds").tag(5.0)
                        Text("10 seconds").tag(10.0)
                        Text("30 seconds").tag(30.0)
                    }
                }
                Toggle("Ask for name before Save", isOn: $askForName)
                Toggle("Copy to clipboard", isOn: $afterCopy)
                Toggle("Open Editor", isOn: $afterEditor)
                Toggle("Pin to screen", isOn: $afterPin)
                Toggle("Upload", isOn: $afterUpload)
                Toggle("Save to disk", isOn: $afterSave)
                Toggle("Play shutter sound", isOn: $playShutter)
                Toggle("Convert exports to sRGB", isOn: $convertSRGB)
                TextField("File name template", text: $fileNameTemplate)
                    .textFieldStyle(.roundedBorder)
                Text("Tokens: {date} {time} {month} {index} {app} {window}")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Capture Overlay") {
                Toggle("All-in-One mode bar", isOn: $showAllInOneBar)
                Toggle("Show crosshair", isOn: $showCrosshair)
                Toggle("Show magnifier", isOn: $showMagnifier)
                Toggle("Scale down Retina Captures", isOn: $scaleDownRetina)
                Toggle("Hide desktop icons while capturing", isOn: $hideDesktopIcons)
                Toggle("Enable parcel:// URL scheme", isOn: $urlSchemeEnabled)
                Toggle("OCR without line breaks", isOn: $ocrStripLineBreaks)
                Text("Hold ⇧ while dragging to temporarily ignore aspect presets.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Recording") {
                Picker("Frame rate", selection: $recordingFPS) {
                    ForEach(RecordingFPS.allCases) { fps in
                        Text(fps.label).tag(fps)
                    }
                }
                Picker("Max resolution", selection: $maxResolution) {
                    ForEach(RecordingMaxResolution.allCases) { Text($0.label).tag($0) }
                }
                Picker("Countdown", selection: $countdown) {
                    Text("None").tag(0.0)
                    Text("3 seconds").tag(3.0)
                    Text("5 seconds").tag(5.0)
                    Text("10 seconds").tag(10.0)
                }
                Picker("Controls position", selection: $hudPosition) {
                    ForEach(RecordingHUDPosition.allCases) { Text($0.label).tag($0) }
                }
                Toggle("Show cursor", isOn: $showsCursor)
                Toggle("Capture microphone (macOS 15+)", isOn: $capturesMicrophone)
                Toggle("Record mono audio", isOn: $monoAudio)
                Toggle("Highlight mouse clicks (macOS 15+)", isOn: $showsMouseClicks)
                Toggle("Show keystroke HUD", isOn: $showsKeystrokes)
                if showsKeystrokes {
                    Toggle("Only modifier shortcuts", isOn: $keystrokesCommandOnly)
                }
                Toggle("Show webcam (PiP)", isOn: $showsWebcam)
                Toggle("Do Not Disturb while recording", isOn: $enableDND)
            }

            Section("Capture History") {
                Picker("Retention", selection: $historyRetention) {
                    ForEach(HistoryRetention.allCases) { Text($0.label).tag($0) }
                }
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
            }
        }
        .formStyle(.grouped)
        .frame(width: 540, height: 760)
        .task { await refreshPermissionStatus() }
        .onReceive(poll) { _ in Task { await refreshPermissionStatus() } }
        .onDisappear { persistSettings() }
        .onChange(of: useQuickAccess) { CapturePreferences.useQuickAccess = $0 }
        .onChange(of: quickAccessAutoClose) { CapturePreferences.quickAccessAutoCloseSeconds = $0 }
        .onChange(of: askForName) { CapturePreferences.askForName = $0 }
        .onChange(of: afterCopy) { CapturePreferences.afterCaptureCopy = $0 }
        .onChange(of: afterEditor) { CapturePreferences.afterCaptureOpenEditor = $0 }
        .onChange(of: afterPin) { CapturePreferences.afterCapturePin = $0 }
        .onChange(of: afterUpload) { CapturePreferences.afterCaptureUpload = $0 }
        .onChange(of: afterSave) { CapturePreferences.afterCaptureSave = $0 }
        .onChange(of: playShutter) { CapturePreferences.playShutterSound = $0 }
        .onChange(of: convertSRGB) { CapturePreferences.convertToSRGB = $0 }
        .onChange(of: urlSchemeEnabled) { CapturePreferences.urlSchemeEnabled = $0 }
        .onChange(of: fileNameTemplate) { CapturePreferences.fileNameTemplate = $0 }
        .onChange(of: scaleDownRetina) { CapturePreferences.scaleDownRetina = $0 }
        .onChange(of: showCrosshair) { CapturePreferences.showCrosshair = $0 }
        .onChange(of: showMagnifier) { CapturePreferences.showMagnifier = $0 }
        .onChange(of: hideDesktopIcons) { CapturePreferences.hideDesktopIcons = $0 }
        .onChange(of: showAllInOneBar) { CapturePreferences.showAllInOneBar = $0 }
        .onChange(of: ocrStripLineBreaks) { CapturePreferences.ocrStripLineBreaks = $0 }
        .onChange(of: showsCursor) { RecordingPreferences.showsCursor = $0 }
        .onChange(of: capturesMicrophone) { RecordingPreferences.capturesMicrophone = $0 }
        .onChange(of: showsMouseClicks) { RecordingPreferences.showsMouseClicks = $0 }
        .onChange(of: showsKeystrokes) { RecordingPreferences.showsKeystrokes = $0 }
        .onChange(of: keystrokesCommandOnly) { RecordingPreferences.keystrokesCommandOnly = $0 }
        .onChange(of: showsWebcam) { RecordingPreferences.showsWebcam = $0 }
        .onChange(of: enableDND) { RecordingPreferences.enableDoNotDisturb = $0 }
        .onChange(of: countdown) { RecordingPreferences.countdownSeconds = $0 }
        .onChange(of: monoAudio) { RecordingPreferences.recordMonoAudio = $0 }
        .onChange(of: recordingFPS) { RecordingFPS.current = $0 }
        .onChange(of: maxResolution) { RecordingMaxResolution.current = $0 }
        .onChange(of: hudPosition) { RecordingHUDPosition.current = $0 }
        .onChange(of: historyRetention) { HistoryRetention.current = $0 }
    }

    private var permissionFootnote: String {
        if hasScreenPermission {
            return "Required to capture your screen. After granting, quit and reopen Parcel."
        }
        if ScreenRecordingPermission.likelyNeedsRebuildRegrant {
            return """
            macOS ties Screen Recording to each build. If Parcel is already toggled ON in System Settings \
            but Capture still fails, remove Parcel from the list, click +, and choose this app in Finder.
            """
        }
        return "Required to capture your screen. After granting, quit and reopen Parcel."
    }

    private func persistSettings() {
        CapturePreferences.useQuickAccess = useQuickAccess
        CapturePreferences.quickAccessAutoCloseSeconds = quickAccessAutoClose
        CapturePreferences.askForName = askForName
        CapturePreferences.afterCaptureCopy = afterCopy
        CapturePreferences.afterCaptureOpenEditor = afterEditor
        CapturePreferences.afterCapturePin = afterPin
        CapturePreferences.afterCaptureUpload = afterUpload
        CapturePreferences.afterCaptureSave = afterSave
        CapturePreferences.playShutterSound = playShutter
        CapturePreferences.convertToSRGB = convertSRGB
        CapturePreferences.urlSchemeEnabled = urlSchemeEnabled
        CapturePreferences.fileNameTemplate = fileNameTemplate
        CapturePreferences.scaleDownRetina = scaleDownRetina
        CapturePreferences.showCrosshair = showCrosshair
        CapturePreferences.showMagnifier = showMagnifier
        CapturePreferences.hideDesktopIcons = hideDesktopIcons
        CapturePreferences.showAllInOneBar = showAllInOneBar
        CapturePreferences.ocrStripLineBreaks = ocrStripLineBreaks
        RecordingPreferences.showsCursor = showsCursor
        RecordingPreferences.capturesMicrophone = capturesMicrophone
        RecordingPreferences.showsMouseClicks = showsMouseClicks
        RecordingPreferences.showsKeystrokes = showsKeystrokes
        RecordingPreferences.keystrokesCommandOnly = keystrokesCommandOnly
        RecordingPreferences.showsWebcam = showsWebcam
        RecordingPreferences.enableDoNotDisturb = enableDND
        RecordingPreferences.countdownSeconds = countdown
        RecordingPreferences.recordMonoAudio = monoAudio
        RecordingFPS.current = recordingFPS
        RecordingMaxResolution.current = maxResolution
        RecordingHUDPosition.current = hudPosition
        HistoryRetention.current = historyRetention
        UploadPreferences.supabaseURL = supabaseURL
        UploadPreferences.anonKey = anonKey
        UploadPreferences.bucketName = bucketName
        UploadPreferences.publicBaseURL = publicBaseURL
    }

    @MainActor
    private func refreshPermissionStatus() async {
        hasScreenPermission = ScreenRecordingPermission.isGranted
    }
}
