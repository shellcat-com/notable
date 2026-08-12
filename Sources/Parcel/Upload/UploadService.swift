import Foundation

enum UploadError: LocalizedError {
    case notConfigured
    case encodeFailed
    case httpStatus(Int, String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Supabase is not configured. Open Preferences and add your project URL, anon key, and bucket name."
        case .encodeFailed:
            return "Could not encode the Capture for upload."
        case let .httpStatus(code, body):
            return "Upload failed (HTTP \(code)): \(body)"
        case .invalidResponse:
            return "Upload returned an unexpected response."
        }
    }
}

/// Uploads rendered Capture bytes to Supabase Storage via the REST API.
enum UploadService {
    typealias DataLoader = (URLRequest) async throws -> (Data, URLResponse)

    static func uploadPNG(
        data: Data,
        fileName: String,
        dataLoader: DataLoader = defaultDataLoader
    ) async throws -> URL {
        guard UploadPreferences.isConfigured else { throw UploadError.notConfigured }

        let base = UploadPreferences.supabaseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let bucket = UploadPreferences.bucketName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? UploadPreferences.bucketName
        let objectPath = fileName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? fileName
        guard let url = URL(string: "\(base)/storage/v1/object/\(bucket)/\(objectPath)") else {
            throw UploadError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(UploadPreferences.anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("image/png", forHTTPHeaderField: "Content-Type")
        request.setValue("true", forHTTPHeaderField: "x-upsert")
        request.httpBody = data

        let (responseData, response) = try await dataLoader(request)
        guard let http = response as? HTTPURLResponse else { throw UploadError.invalidResponse }
        guard (200...299).contains(http.statusCode) else {
            let body = String(data: responseData, encoding: .utf8) ?? ""
            throw UploadError.httpStatus(http.statusCode, body)
        }

        if !UploadPreferences.publicBaseURL.isEmpty {
            let publicBase = UploadPreferences.publicBaseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            guard let publicURL = URL(string: "\(publicBase)/\(objectPath)") else {
                throw UploadError.invalidResponse
            }
            return publicURL
        }

        guard let publicURL = URL(string: "\(base)/storage/v1/object/public/\(bucket)/\(objectPath)") else {
            throw UploadError.invalidResponse
        }
        return publicURL
    }

    private static func defaultDataLoader(_ request: URLRequest) async throws -> (Data, URLResponse) {
        try await URLSession.shared.data(for: request)
    }
}
