import CoreGraphics
import Foundation
import Vision

struct VisionTextObservation: Identifiable, Equatable {
    let id = UUID()
    let string: String
    /// Capture-point coordinates, top-left origin: directly usable by Censor Annotations.
    let rect: CGRect
}

struct VisionFaceObservation: Identifiable, Equatable {
    let id = UUID()
    /// Capture-point coordinates, top-left origin: directly usable by Censor Annotations.
    let rect: CGRect
}

struct VisionQRCode: Identifiable, Equatable {
    let id = UUID()
    let payload: String
}

struct VisionAnalysis: Equatable {
    var text: [VisionTextObservation] = []
    var faces: [VisionFaceObservation] = []
    var qrCodes: [VisionQRCode] = []

    var recognizedText: String { text.map(\.string).joined(separator: "\n") }
    var piiText: [VisionTextObservation] { text.filter { Self.isSensitive($0.string) } }

    private static func isSensitive(_ string: String) -> Bool {
        let patterns = [
            #"(?i)\b[\w.+-]+@[\w.-]+\.[a-z]{2,}\b"#,
            #"\b(?:\+?\d[\d .()-]{7,}\d)\b"#,
            #"\b(?:\d[ -]*?){13,16}\b"#,
        ]
        return patterns.contains { pattern in
            string.range(of: pattern, options: .regularExpression) != nil
        }
    }
}

/// On-device Vision inspection for a Capture. No request or pixel data leaves the Mac.
enum VisionAnalyzer {
    static func analyze(image: CGImage, pointSize: CGSize) async -> VisionAnalysis {
        await Task.detached(priority: .userInitiated) {
            let textRequest = VNRecognizeTextRequest()
            textRequest.recognitionLevel = .accurate
            textRequest.usesLanguageCorrection = true

            let faceRequest = VNDetectFaceRectanglesRequest()
            let barcodeRequest = VNDetectBarcodesRequest()
            let handler = VNImageRequestHandler(cgImage: image, orientation: .up)

            do {
                try handler.perform([textRequest, faceRequest, barcodeRequest])
            } catch {
                NSLog("Notable: Vision inspection failed — \(error)")
                return VisionAnalysis()
            }

            let text = (textRequest.results ?? []).compactMap { observation -> VisionTextObservation? in
                guard let candidate = observation.topCandidates(1).first else { return nil }
                return VisionTextObservation(
                    string: candidate.string,
                    rect: captureRect(fromVision: observation.boundingBox, pointSize: pointSize)
                )
            }
            let faces = (faceRequest.results ?? []).map {
                VisionFaceObservation(rect: captureRect(fromVision: $0.boundingBox, pointSize: pointSize))
            }
            let qrCodes = (barcodeRequest.results ?? []).compactMap { observation -> VisionQRCode? in
                guard observation.symbology == .QR, let payload = observation.payloadStringValue else { return nil }
                return VisionQRCode(payload: payload)
            }
            return VisionAnalysis(text: text, faces: faces, qrCodes: qrCodes)
        }.value
    }

    private static func captureRect(fromVision rect: CGRect, pointSize: CGSize) -> CGRect {
        CGRect(
            x: rect.minX * pointSize.width,
            y: (1 - rect.maxY) * pointSize.height,
            width: rect.width * pointSize.width,
            height: rect.height * pointSize.height
        ).integral
    }
}
