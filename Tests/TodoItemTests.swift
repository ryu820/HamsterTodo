import XCTest
@testable import HamsterTodo

final class TodoItemTests: XCTestCase {
    func testIncompleteItem() {
        let item = TodoItem(text: "코드 리뷰 피드백 반영", isCompleted: false)
        XCTAssertEqual(item.text, "코드 리뷰 피드백 반영")
        XCTAssertFalse(item.isCompleted)
    }

    func testCompletedItem() {
        let item = TodoItem(text: "설계서 작성", isCompleted: true)
        XCTAssertTrue(item.isCompleted)
    }

    func testIdentifiable() {
        let item1 = TodoItem(text: "A", isCompleted: false)
        let item2 = TodoItem(text: "A", isCompleted: false)
        XCTAssertNotEqual(item1.id, item2.id)
    }
}
