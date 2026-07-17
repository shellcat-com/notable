import CoreMedia
import Foundation

enum RecordingFPS: Int, CaseIterable, Identifiable {
    case fps30 = 30
    case fps60 = 60
    case fps120 = 120

    var id: Int { rawValue }

    var label: String { "\(rawValue) fps" }

    var frameInterval: CMTime {
        CMTime(value: 1, timescale: CMTimeScale(rawValue))
    }

    private static let storageKey = "\(AppIdentity.defaultsPrefix).recording.fps"

    static var current: RecordingFPS {
        get {
            let stored = UserDefaults.standard.integer(forKey: storageKey)
            return RecordingFPS(rawValue: stored) ?? .fps60
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: storageKey) }
    }
}
