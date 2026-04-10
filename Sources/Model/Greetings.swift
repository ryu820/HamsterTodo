import Foundation

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
