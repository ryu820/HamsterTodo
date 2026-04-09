import SwiftUI

struct PopupView: View {
    @EnvironmentObject var vaultAccess: VaultAccessManager
    @State private var todos: [TodoItem] = []
    @State private var noteDate: String?
    @State private var greeting: String = Greetings.random()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            greetingSection
            Divider()
            if !vaultAccess.isConfigured {
                vaultSetup
            } else if todos.isEmpty {
                emptyState
            } else {
                todoList
            }
            Divider()
            footer
        }
        .padding(16)
        .frame(width: 300)
        .onAppear { loadData() }
        .onChange(of: vaultAccess.isConfigured) { configured in
            if configured { loadData() }
        }
    }

    private func loadData() {
        guard let path = vaultAccess.vaultURL?.path else { return }
        todos = DailyNoteParser.loadTodos(from: path)
        noteDate = DailyNoteParser.latestNoteDate(from: path)
        greeting = Greetings.random()
    }

    private var greetingSection: some View {
        HStack(spacing: 8) {
            Image(nsImage: PixelHamster.makeImage(frame: .cheeks, size: 32))
                .interpolation(.none)
            Text(greeting)
                .font(.system(size: 13, weight: .medium))
        }
    }

    private var vaultSetup: some View {
        VStack(spacing: 8) {
            Text("일일노트 폴더를 선택해주세요")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            Button("폴더 선택...") {
                vaultAccess.selectVault()
            }
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
    }

    private var emptyState: some View {
        HStack {
            Spacer()
            Text("오늘은 쉬어도 돼요~ 🐹💤")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.vertical, 8)
    }

    private var todoList: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(todos) { item in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: item.isCompleted
                          ? "checkmark.square.fill"
                          : "square")
                        .foregroundStyle(item.isCompleted ? .green : .secondary)
                        .font(.system(size: 13))
                    Text(item.text)
                        .font(.system(size: 12))
                        .strikethrough(item.isCompleted)
                        .foregroundStyle(item.isCompleted ? .secondary : .primary)
                }
            }
        }
    }

    private var footer: some View {
        HStack {
            if let date = noteDate {
                Text("📅 \(date)")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .font(.system(size: 10))
            .foregroundStyle(.tertiary)
        }
    }
}

enum Greetings {
    private static let list = [
        "좋은 아침이에요! 오늘도 화이팅 🐹",
        "쪽쪽! 오늘 할 일을 가져왔어요~",
        "햄찌가 할 일을 정리했어요! 🌻",
        "오늘도 멋진 하루 보내요~ 🐹✨",
        "볼에 할 일을 잔뜩 넣어왔어요!",
    ]

    static func random() -> String {
        list.randomElement()!
    }
}
