import Foundation

enum Strings {
    enum Popup {
        static let vaultSetupMessage = "일일노트 폴더를 선택해주세요"
        static let vaultSetupButton = "폴더 선택..."
        static let emptyState = "오늘은 쉬어도 돼요~ 🐹💤"
        static let quit = "Quit"
    }

    enum VaultPanel {
        static let title = "Obsidian 일일노트 폴더 선택"
        static let message = "할 일을 가져올 일일노트 폴더를 선택하세요"
    }

    enum Notification {
        static let identifier = "hamster-daily-reminder"
        static func bodyWithCount(_ count: Int) -> String {
            "\(count)개의 할 일이 기다리고 있어요"
        }
        static let bodyEmpty = "오늘은 할 일이 없어요~ 푹 쉬세요 🐹💤"
    }

    enum Parser {
        static let todoSectionHeading = "## 내일 할 일"
    }
}
