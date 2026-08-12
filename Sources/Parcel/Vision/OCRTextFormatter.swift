import Foundation

enum OCRTextFormatter {
    static func outputText(from recognizedText: String, stripLineBreaks: Bool) -> String {
        let trimmedText = recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard stripLineBreaks else { return trimmedText }

        return trimmedText
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
