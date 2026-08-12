import Foundation
import NaturalLanguage

#if canImport(Translation)
import Translation
#endif

enum TranslationService {
    /// On-device translation via Apple Translation (macOS 26+). Returns nil when unavailable.
    @MainActor
    static func translate(_ text: String, to target: Locale.Language = .init(identifier: "en")) async -> String? {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        guard #available(macOS 26.0, *) else { return nil }

        #if canImport(Translation) && compiler(>=6.2)
        guard let source = detectLanguage(text) else { return nil }
        do {
            let session = TranslationSession(installedSource: source, target: target)
            try await session.prepareTranslation()
            let response = try await session.translate(text)
            return response.targetText
        } catch {
            NSLog("Parcel: on-device translation failed — \(error)")
            return nil
        }
        #else
        return nil
        #endif
    }

    static var isAvailable: Bool {
        if #available(macOS 26.0, *) {
            #if canImport(Translation) && compiler(>=6.2)
            return true
            #endif
        }
        return false
    }

    private static func detectLanguage(_ text: String) -> Locale.Language? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        guard let language = recognizer.dominantLanguage else { return nil }
        return Locale.Language(identifier: language.rawValue)
    }
}
