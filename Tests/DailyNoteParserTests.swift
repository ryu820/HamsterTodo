import XCTest
@testable import HamsterTodo

final class DailyNoteParserTests: XCTestCase {
    // MARK: - parseTodos from string

    func testParseTodosFromMarkdown() {
        let markdown = """
        ---
        date: 2026-04-09
        ---

        ## 오늘 한 일
        - [x] 일정 기능 완성

        ## 내일 할 일
        - [ ] [GGC-218] 조직도 API 연동 구현
        - [ ] 코드 리뷰 피드백 반영
        """

        let items = DailyNoteParser.parseTodos(from: markdown)
        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items[0].text, "[GGC-218] 조직도 API 연동 구현")
        XCTAssertFalse(items[0].isCompleted)
        XCTAssertEqual(items[1].text, "코드 리뷰 피드백 반영")
        XCTAssertFalse(items[1].isCompleted)
    }

    func testParseMixedCompletionStatus() {
        let markdown = """
        ## 내일 할 일
        - [x] 완료된 작업
        - [ ] 미완료 작업
        """

        let items = DailyNoteParser.parseTodos(from: markdown)
        XCTAssertEqual(items.count, 2)
        XCTAssertTrue(items[0].isCompleted)
        XCTAssertFalse(items[1].isCompleted)
    }

    func testParseStopsAtNextHeading() {
        let markdown = """
        ## 내일 할 일
        - [ ] 할 일 1

        ## 메모
        - 이건 할 일이 아님
        """

        let items = DailyNoteParser.parseTodos(from: markdown)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items[0].text, "할 일 1")
    }

    func testParseNoTodoSection() {
        let markdown = """
        ## 오늘 한 일
        - [x] 뭔가 함
        """

        let items = DailyNoteParser.parseTodos(from: markdown)
        XCTAssertTrue(items.isEmpty)
    }

    func testParseEmptyTodoSection() {
        let markdown = """
        ## 내일 할 일

        ## 메모
        """

        let items = DailyNoteParser.parseTodos(from: markdown)
        XCTAssertTrue(items.isEmpty)
    }

    // MARK: - findLatestNote

    func testFindLatestNoteSelectsMostRecent() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("HamsterTodoTest-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try "old note".write(
            to: tempDir.appendingPathComponent("2026-04-07.md"),
            atomically: true, encoding: .utf8
        )
        try "recent note".write(
            to: tempDir.appendingPathComponent("2026-04-09.md"),
            atomically: true, encoding: .utf8
        )
        try "middle note".write(
            to: tempDir.appendingPathComponent("2026-04-08.md"),
            atomically: true, encoding: .utf8
        )

        let latest = DailyNoteParser.findLatestNote(in: tempDir.path)
        XCTAssertNotNil(latest)
        XCTAssertTrue(latest!.hasSuffix("2026-04-09.md"))
    }

    func testFindLatestNoteEmptyDirectory() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("HamsterTodoTest-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let latest = DailyNoteParser.findLatestNote(in: tempDir.path)
        XCTAssertNil(latest)
    }
}
