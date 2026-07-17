import Foundation

/// Supabase Storage configuration. Values are stored in UserDefaults; never commit secrets.
enum UploadPreferences {
    private static let urlKey = "\(AppIdentity.defaultsPrefix).upload.supabaseURL"
    private static let anonKeyKey = "\(AppIdentity.defaultsPrefix).upload.anonKey"
    private static let bucketKey = "\(AppIdentity.defaultsPrefix).upload.bucket"
    private static let publicBaseKey = "\(AppIdentity.defaultsPrefix).upload.publicBase"

    static var supabaseURL: String {
        get { UserDefaults.standard.string(forKey: urlKey) ?? "" }
        set { UserDefaults.standard.set(newValue.trimmingCharacters(in: .whitespacesAndNewlines), forKey: urlKey) }
    }

    static var anonKey: String {
        get { UserDefaults.standard.string(forKey: anonKeyKey) ?? "" }
        set { UserDefaults.standard.set(newValue.trimmingCharacters(in: .whitespacesAndNewlines), forKey: anonKeyKey) }
    }

    static var bucketName: String {
        get { UserDefaults.standard.string(forKey: bucketKey) ?? "captures" }
        set { UserDefaults.standard.set(newValue.trimmingCharacters(in: .whitespacesAndNewlines), forKey: bucketKey) }
    }

    /// Optional CDN or custom domain prefix for public object URLs.
    static var publicBaseURL: String {
        get { UserDefaults.standard.string(forKey: publicBaseKey) ?? "" }
        set { UserDefaults.standard.set(newValue.trimmingCharacters(in: .whitespacesAndNewlines), forKey: publicBaseKey) }
    }

    static var isConfigured: Bool {
        !supabaseURL.isEmpty && !anonKey.isEmpty && !bucketName.isEmpty
    }
}
