import AppKit
import os

@MainActor
final class TodoViewModel: ObservableObject {
    @Published var todos: [TodoItem] = []
    @Published var noteDate: String?
    @Published var greeting: String = Greetings.random()
    @Published var isVaultConfigured: Bool = false

    private let vaultAccess = VaultAccessManager.shared
    private let logger = Logger(subsystem: "com.ryu.HamsterTodo", category: "TodoViewModel")

    init() {
        isVaultConfigured = vaultAccess.isConfigured
        if isVaultConfigured {
            loadTodos()
        }
    }

    func loadTodos() {
        guard let path = vaultAccess.vaultURL?.path else { return }
        todos = DailyNoteParser.loadTodos(from: path)
        noteDate = DailyNoteParser.latestNoteDate(from: path)
        greeting = Greetings.random()
    }

    func selectVault() {
        let panel = NSOpenPanel()
        panel.title = Strings.VaultPanel.title
        panel.message = Strings.VaultPanel.message
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false

        guard panel.runModal() == .OK, let url = panel.url else { return }

        vaultAccess.saveAndAccess(url: url)
        isVaultConfigured = true
        loadTodos()
    }

    var incompleteTodoCount: Int {
        todos.filter { !$0.isCompleted }.count
    }
}
