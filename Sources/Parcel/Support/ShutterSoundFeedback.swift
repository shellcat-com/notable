import AudioToolbox

enum ShutterSoundFeedback {
    static let captureCompleteSoundID: SystemSoundID = 1108

    @discardableResult
    static func playIfEnabled(
        _ enabled: Bool,
        player: (SystemSoundID) -> Void = AudioServicesPlaySystemSound
    ) -> Bool {
        guard enabled else { return false }
        player(captureCompleteSoundID)
        return true
    }
}
