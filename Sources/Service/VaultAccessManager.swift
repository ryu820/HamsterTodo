import AppKit
import os

@MainActor
final class VaultAccessManager: ObservableObject {
    static let shared = VaultAccessManager()

    private let logger = Logger(subsystem: "com.ryu.HamsterTodo", category: "VaultAccess")
    private static let bookmarkKey = "vaultBookmarkData"

    @Published var vaultURL: URL?
    @Published var isConfigured = false

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
            isConfigured = true
        } catch {
            logger.error("Failed to resolve bookmark: \(error.localizedDescription)")
        }
    }

    func selectVault() {
        let panel = NSOpenPanel()
        panel.title = "Obsidian 일일노트 폴더 선택"
        panel.message = "할 일을 가져올 일일노트 폴더를 선택하세요"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false

        guard panel.runModal() == .OK, let url = panel.url else { return }

        saveBookmark(for: url)

        guard url.startAccessingSecurityScopedResource() else {
            logger.error("Failed to access selected directory")
            return
        }

        vaultURL = url
        isConfigured = true
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
