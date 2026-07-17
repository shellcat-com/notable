import Foundation

/// Central identity constants and one-time migration from the Notable codename.
enum AppIdentity {
    static let displayName = "Parcel"
    static let bundleIdentifier = "dev.parable.Parcel"
    static let defaultsPrefix = "dev.parable"
    static let legacyDefaultsPrefix = "io.notable"
    static let legacyAppSupportComponent = "io.notable.Notable"
    static let appSupportComponent = "dev.parable.Parcel"
    static let migrationCompletedKey = "dev.parable.migrationFromNotableCompleted"

    /// Migrates UserDefaults keys and on-disk history from the Notable codename.
    static func migrateFromNotableIfNeeded() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: migrationCompletedKey) else { return }

        let keyPairs: [(String, String)] = [
            ("io.notable.hotkey.keyCode", "\(defaultsPrefix).hotkey.keyCode"),
            ("io.notable.hotkey.modifiers", "\(defaultsPrefix).hotkey.modifiers"),
            ("io.notable.upload.supabaseURL", "\(defaultsPrefix).upload.supabaseURL"),
            ("io.notable.upload.anonKey", "\(defaultsPrefix).upload.anonKey"),
            ("io.notable.upload.bucket", "\(defaultsPrefix).upload.bucket"),
            ("io.notable.upload.publicBase", "\(defaultsPrefix).upload.publicBase"),
            ("io.notable.recording.fps", "\(defaultsPrefix).recording.fps"),
            ("io.notable.brandKits", "\(defaultsPrefix).brandKits"),
            ("io.notable.lastSaveDirectory", "\(defaultsPrefix).lastSaveDirectory"),
        ]

        for (oldKey, newKey) in keyPairs {
            if defaults.object(forKey: newKey) == nil, let value = defaults.object(forKey: oldKey) {
                defaults.set(value, forKey: newKey)
            }
        }

        migrateHistoryDirectoryIfNeeded()
        defaults.set(true, forKey: migrationCompletedKey)
    }

    private static func migrateHistoryDirectoryIfNeeded() {
        let fileManager = FileManager.default
        guard let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return
        }
        let legacyRoot = appSupport.appendingPathComponent(legacyAppSupportComponent, isDirectory: true)
        let newRoot = appSupport.appendingPathComponent(appSupportComponent, isDirectory: true)
        guard fileManager.fileExists(atPath: legacyRoot.path),
              !fileManager.fileExists(atPath: newRoot.path) else { return }
        do {
            try fileManager.moveItem(at: legacyRoot, to: newRoot)
        } catch {
            NSLog("Parcel: could not migrate history from Notable — \(error)")
        }
    }
}
