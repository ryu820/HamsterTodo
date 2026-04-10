import Foundation
import os

@MainActor
final class VaultAccessManager {
    static let shared = VaultAccessManager()

    private let logger = Logger(subsystem: "com.ryu.HamsterTodo", category: "VaultAccess")
    private static let bookmarkKey = "vaultBookmarkData"

    private(set) var vaultURL: URL?
    var isConfigured: Bool { vaultURL != nil }

    private init() {
        loadBookmark()
    }

    private func loadBookmark() {
        guard let data = UserDefaults.standard.data(forKey: Self.bookmarkKey) else {
            return
        }

        var isStale = false
        do {
            let url = try URL(
                resolvingBookmarkData: data,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )

            guard url.startAccessingSecurityScopedResource() else {
                logger.error("Failed to start accessing security-scoped resource")
                return
            }

            if isStale {
                saveBookmark(for: url)
            }

            vaultURL = url
        } catch {
            logger.error("Failed to resolve bookmark: \(error.localizedDescription)")
        }
    }

    func saveAndAccess(url: URL) {
        saveBookmark(for: url)

        guard url.startAccessingSecurityScopedResource() else {
            logger.error("Failed to access selected directory")
            return
        }

        vaultURL = url
    }

    private func saveBookmark(for url: URL) {
        do {
            let data = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            UserDefaults.standard.set(data, forKey: Self.bookmarkKey)
        } catch {
            logger.error("Failed to save bookmark: \(error.localizedDescription)")
        }
    }
}
