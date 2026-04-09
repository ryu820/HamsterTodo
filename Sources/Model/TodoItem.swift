import Foundation

struct TodoItem: Identifiable {
    let id = UUID()
    let text: String
    let isCompleted: Bool
}
