import SwiftUI

struct PopupView: View {
    @EnvironmentObject var viewModel: TodoViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            greetingSection
            Divider()
            if !viewModel.isVaultConfigured {
                vaultSetup
            } else if viewModel.todos.isEmpty {
                emptyState
            } else {
                todoList
            }
            Divider()
            footer
        }
        .padding(16)
        .frame(width: 300)
        .onAppear { viewModel.loadTodos() }
    }

    private var greetingSection: some View {
        HStack(spacing: 8) {
            Image(nsImage: PixelHamster.makeImage(frame: .cheeks, size: 32))
                .interpolation(.none)
            Text(viewModel.greeting)
                .font(.system(size: 13, weight: .medium))
        }
    }

    private var vaultSetup: some View {
        VStack(spacing: 8) {
            Text(Strings.Popup.vaultSetupMessage)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            Button(Strings.Popup.vaultSetupButton) {
                viewModel.selectVault()
            }
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
    }

    private var emptyState: some View {
        HStack {
            Spacer()
            Text(Strings.Popup.emptyState)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.vertical, 8)
    }

    private var todoList: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(viewModel.todos) { item in
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
            if let date = viewModel.noteDate {
                Text("📅 \(date)")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            Button(Strings.Popup.quit) {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .font(.system(size: 10))
            .foregroundStyle(.tertiary)
        }
    }
}
