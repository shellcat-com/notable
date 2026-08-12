import AppKit
@preconcurrency import AVFoundation
import SwiftUI

enum WebcamPiPGeometry {
    static let diameter: CGFloat = 168
    static let margin: CGFloat = 24

    static func bottomRightOrigin(
        screen: CGRect,
        windowSize: CGSize,
        margin: CGFloat = Self.margin
    ) -> CGPoint {
        CGPoint(
            x: screen.maxX - windowSize.width - margin,
            y: screen.minY + margin
        )
    }
}

/// Circular, draggable webcam preview that floats above other windows during recording.
@MainActor
final class WebcamPiPController: NSObject {

    private var window: NSPanel?
    private var session: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?

    func start() {
        guard RecordingPreferences.showsWebcam else { return }
        stop()

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            present()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                Task { @MainActor in
                    if granted { self?.present() }
                }
            }
        default:
            NSLog("Parcel: camera access denied — webcam PiP skipped")
        }
    }

    func stop() {
        session?.stopRunning()
        session = nil
        previewLayer = nil
        window?.orderOut(nil)
        window = nil
    }

    // MARK: Private

    private func present() {
        guard let device = AVCaptureDevice.default(for: .video) else {
            NSLog("Parcel: no camera available for webcam PiP")
            return
        }

        let session = AVCaptureSession()
        session.sessionPreset = .medium
        do {
            let input = try AVCaptureDeviceInput(device: device)
            guard session.canAddInput(input) else { return }
            session.addInput(input)
        } catch {
            NSLog("Parcel: webcam PiP failed — \(error)")
            return
        }

        let diameter = WebcamPiPGeometry.diameter
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: diameter, height: diameter),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .floating
        panel.isMovableByWindowBackground = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false

        let container = WebcamPiPContainerView(frame: NSRect(origin: .zero, size: CGSize(width: diameter, height: diameter)))
        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.cornerRadius = diameter / 2
        preview.masksToBounds = true
        preview.frame = container.bounds
        container.wantsLayer = true
        container.layer?.cornerRadius = diameter / 2
        container.layer?.masksToBounds = true
        container.layer?.borderWidth = 3
        container.layer?.borderColor = NSColor.white.withAlphaComponent(0.85).cgColor
        container.layer?.addSublayer(preview)
        panel.contentView = container

        self.session = session
        self.previewLayer = preview
        self.window = panel

        positionBottomRight()
        panel.orderFrontRegardless()

        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }

    private func positionBottomRight() {
        guard let window else { return }
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1280, height: 800)
        let origin = WebcamPiPGeometry.bottomRightOrigin(screen: screen, windowSize: window.frame.size)
        window.setFrameOrigin(origin)
    }
}

/// Resizes the preview layer when the panel is dragged/resized.
private final class WebcamPiPContainerView: NSView {
    override func layout() {
        super.layout()
        layer?.sublayers?.forEach { sub in
            if sub is AVCaptureVideoPreviewLayer {
                sub.frame = bounds
                sub.cornerRadius = min(bounds.width, bounds.height) / 2
            }
        }
        layer?.cornerRadius = min(bounds.width, bounds.height) / 2
    }
}
