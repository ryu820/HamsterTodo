# HamsterTodo Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** macOS 메뉴바에 상주하는 픽셀 햄스터가 매일 9시에 Obsidian 일일노트의 할 일을 알려주는 앱을 만든다.

**Architecture:** SwiftUI App lifecycle + MenuBarExtra(.window style)로 메뉴바 상주. DailyNoteParser가 Obsidian 볼트의 최근 일일노트를 파싱하고, UNUserNotificationCenter로 매일 9시 알림. 픽셀 햄스터는 Core Graphics로 프로그래밍 방식으로 생성하여 3프레임 애니메이션.

**Tech Stack:** Swift, SwiftUI, AppKit (NSImage), UserNotifications, ServiceManagement (Launch at Login), XcodeGen

**Design Spec:** `docs/superpowers/specs/2026-04-09-hamster-todo-design.md` (이 파일과 같은 리포에 있음. 새 프로젝트에서 작업 시 해당 설계서를 참고할 것)

**Obsidian 볼트 경로:** `/Volumes/RYU/연구노트/01-daily/`
**일일노트 파일명 패턴:** `YYYY-MM-DD.md`
**파싱 대상 섹션:** `## 내일 할 일` 아래 `- [ ]` / `- [x]` 라인

---

## File Structure

```
HamsterTodo/
├── project.yml                              # XcodeGen 프로젝트 정의
├── Sources/
│   ├── HamsterTodoApp.swift                 # @main 진입점, MenuBarExtra
│   ├── Model/
│   │   └── TodoItem.swift                   # 할 일 데이터 모델
│   ├── Service/
│   │   ├── DailyNoteParser.swift            # 마크다운 파싱
│   │   └── NotificationManager.swift        # 9시 알림 스케줄링
│   └── View/
│       ├── PopupView.swift                  # 말풍선 팝업 UI
│       └── PixelHamster.swift               # 픽셀 햄스터 생성 + 애니메이션
├── Tests/
│   ├── DailyNoteParserTests.swift           # 파서 유닛 테스트
│   └── TodoItemTests.swift                  # 모델 테스트
└── Info.plist                               # LSUIElement 등 앱 설정
```

---

### Task 1: 프로젝트 스캐폴딩

**Files:**
- Create: `project.yml`
- Create: `Info.plist`
- Create: `Sources/HamsterTodoApp.swift` (빈 앱 셸)

- [ ] **Step 1: XcodeGen 설치 확인**

Run: `brew list xcodegen || brew install xcodegen`

- [ ] **Step 2: 프로젝트 디렉토리 생성**

Run: `mkdir -p Sources/Model Sources/Service Sources/View Tests`

- [ ] **Step 3: project.yml 작성**

Create `project.yml`:
```yaml
name: HamsterTodo
options:
  bundleIdPrefix: com.ryu
  deploymentTarget:
    macOS: "13.0"
  xcodeVersion: "16.0"
settings:
  base:
    SWIFT_VERSION: "5.9"
    MACOSX_DEPLOYMENT_TARGET: "13.0"
targets:
  HamsterTodo:
    type: application
    platform: macOS
    sources:
      - path: Sources
    info:
      path: Info.plist
    settings:
      base:
        CODE_SIGN_IDENTITY: "-"
        CODE_SIGN_STYLE: Automatic
        PRODUCT_BUNDLE_IDENTIFIER: com.ryu.HamsterTodo
        INFOPLIST_KEY_LSUIElement: true
    entitlements:
      path: HamsterTodo.entitlements
      properties:
        com.apple.security.app-sandbox: false
  HamsterTodoTests:
    type: bundle.unit-test
    platform: macOS
    sources:
      - path: Tests
    dependencies:
      - target: HamsterTodo
    settings:
      base:
        BUNDLE_LOADER: "$(TEST_HOST)"
        TEST_HOST: "$(BUILT_PRODUCTS_DIR)/HamsterTodo.app/Contents/MacOS/HamsterTodo"
```

- [ ] **Step 4: Info.plist 작성**

Create `Info.plist`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>LSUIElement</key>
    <true/>
    <key>CFBundleName</key>
    <string>HamsterTodo</string>
    <key>CFBundleDisplayName</key>
    <string>HamsterTodo</string>
    <key>CFBundleIdentifier</key>
    <string>com.ryu.HamsterTodo</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>HamsterTodo</string>
    <key>NSUserNotificationAlertStyle</key>
    <string>alert</string>
</dict>
</plist>
```

- [ ] **Step 5: Entitlements 파일 작성**

Create `HamsterTodo.entitlements`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <false/>
</dict>
</plist>
```

Note: Sandbox를 끄는 이유 — 외부 볼트 경로(`/Volumes/RYU/연구노트/`)를 자유롭게 읽어야 함.

- [ ] **Step 6: 최소 앱 셸 작성**

Create `Sources/HamsterTodoApp.swift`:
```swift
import SwiftUI

@main
struct HamsterTodoApp: App {
    var body: some Scene {
        MenuBarExtra("HamsterTodo", systemImage: "hare.fill") {
            Text("Hello, Hamster!")
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}
```

- [ ] **Step 7: Xcode 프로젝트 생성 및 빌드 확인**

Run:
```bash
xcodegen generate
xcodebuild -project HamsterTodo.xcodeproj -scheme HamsterTodo -configuration Debug build
```

Expected: BUILD SUCCEEDED. 메뉴바에 토끼 아이콘이 표시되는 최소 앱.

- [ ] **Step 8: Commit**

```bash
git init
git add .
git commit -m "feat: initial project scaffolding with XcodeGen and minimal menu bar app"
```

---

### Task 2: TodoItem 모델

**Files:**
- Create: `Sources/Model/TodoItem.swift`
- Create: `Tests/TodoItemTests.swift`

- [ ] **Step 1: 테스트 작성**

Create `Tests/TodoItemTests.swift`:
```swift
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
```

- [ ] **Step 2: 테스트 실패 확인**

Run: `xcodebuild test -project HamsterTodo.xcodeproj -scheme HamsterTodoTests -configuration Debug`
Expected: FAIL — `TodoItem` 타입 없음.

- [ ] **Step 3: 모델 구현**

Create `Sources/Model/TodoItem.swift`:
```swift
import Foundation

struct TodoItem: Identifiable {
    let id = UUID()
    let text: String
    let isCompleted: Bool
}
```

- [ ] **Step 4: 테스트 통과 확인**

Run: `xcodebuild test -project HamsterTodo.xcodeproj -scheme HamsterTodoTests -configuration Debug`
Expected: All tests PASSED.

- [ ] **Step 5: Commit**

```bash
git add Sources/Model/TodoItem.swift Tests/TodoItemTests.swift
git commit -m "feat: add TodoItem model with tests"
```

---

### Task 3: DailyNoteParser

**Files:**
- Create: `Sources/Service/DailyNoteParser.swift`
- Create: `Tests/DailyNoteParserTests.swift`

- [ ] **Step 1: 테스트 작성**

Create `Tests/DailyNoteParserTests.swift`:
```swift
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
```

- [ ] **Step 2: 테스트 실패 확인**

Run: `xcodebuild test -project HamsterTodo.xcodeproj -scheme HamsterTodoTests -configuration Debug`
Expected: FAIL — `DailyNoteParser` 타입 없음.

- [ ] **Step 3: DailyNoteParser 구현**

Create `Sources/Service/DailyNoteParser.swift`:
```swift
import Foundation

enum DailyNoteParser {
    static let dailyNotesPath = "/Volumes/RYU/연구노트/01-daily"

    static func parseTodos(from markdown: String) -> [TodoItem] {
        let lines = markdown.components(separatedBy: .newlines)
        var inTodoSection = false
        var items: [TodoItem] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("## ") {
                if trimmed == "## 내일 할 일" {
                    inTodoSection = true
                    continue
                } else if inTodoSection {
                    break
                }
            }

            guard inTodoSection else { continue }

            if trimmed.hasPrefix("- [ ] ") {
                let text = String(trimmed.dropFirst(6))
                items.append(TodoItem(text: text, isCompleted: false))
            } else if trimmed.hasPrefix("- [x] ") {
                let text = String(trimmed.dropFirst(6))
                items.append(TodoItem(text: text, isCompleted: true))
            }
        }

        return items
    }

    static func findLatestNote(in directoryPath: String) -> String? {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(atPath: directoryPath) else {
            return nil
        }

        let mdFiles = files
            .filter { $0.hasSuffix(".md") }
            .sorted()

        guard let latest = mdFiles.last else { return nil }
        return (directoryPath as NSString).appendingPathComponent(latest)
    }

    static func loadTodos() -> [TodoItem] {
        guard let notePath = findLatestNote(in: dailyNotesPath),
              let content = try? String(contentsOfFile: notePath, encoding: .utf8) else {
            return []
        }
        return parseTodos(from: content)
    }

    static func latestNoteDate() -> String? {
        guard let notePath = findLatestNote(in: dailyNotesPath) else { return nil }
        let filename = (notePath as NSString).lastPathComponent
        return filename.replacingOccurrences(of: ".md", with: "")
    }
}
```

- [ ] **Step 4: 테스트 통과 확인**

Run: `xcodebuild test -project HamsterTodo.xcodeproj -scheme HamsterTodoTests -configuration Debug`
Expected: All tests PASSED.

- [ ] **Step 5: Commit**

```bash
git add Sources/Service/DailyNoteParser.swift Tests/DailyNoteParserTests.swift
git commit -m "feat: add DailyNoteParser with markdown parsing and latest note lookup"
```

---

### Task 4: 픽셀 햄스터 생성

**Files:**
- Create: `Sources/View/PixelHamster.swift`

픽셀아트를 Core Graphics로 프로그래밍 방식 생성. 외부 에셋 파일 불필요.

- [ ] **Step 1: PixelHamster 구현**

Create `Sources/View/PixelHamster.swift`:
```swift
import AppKit

enum PixelHamster {
    enum Frame: Int, CaseIterable {
        case sitting = 0
        case cheeks = 1
        case sleeping = 2
    }

    // 18x18 pixel grid, each row is a string of hex chars
    // Colors: 0=transparent, 1=outline(#4a3728), 2=body(#f5c67a), 3=cheek(#ff9a9a),
    //         4=belly(#fff4d6), 5=eye(#1a1a1a), 6=nose(#d4845a), 7=ear-inner(#ffb6b6)
    private static let palette: [Character: (CGFloat, CGFloat, CGFloat, CGFloat)] = [
        "0": (0, 0, 0, 0),           // transparent
        "1": (0.29, 0.22, 0.16, 1),  // outline brown
        "2": (0.96, 0.78, 0.48, 1),  // body tan
        "3": (1.0, 0.60, 0.60, 1),   // cheek pink
        "4": (1.0, 0.96, 0.84, 1),   // belly cream
        "5": (0.1, 0.1, 0.1, 1),     // eye black
        "6": (0.83, 0.52, 0.35, 1),  // nose brown
        "7": (1.0, 0.71, 0.71, 1),   // ear inner pink
    ]

    // Frame 0: sitting (기본 자세)
    private static let sittingPixels: [String] = [
        "000000000000000000",
        "000011000000110000",
        "000172100001721000",
        "001222210012222100",
        "012222221222222210",
        "012252212212522210",
        "012222212212222210",
        "012232162261232210",
        "012232222222232210",
        "001224222222422100",
        "001224444444422100",
        "000124444444421000",
        "000012444444210000",
        "000012222222210000",
        "000011222222110000",
        "000001211112100000",
        "000001100011000000",
        "000000000000000000",
    ]

    // Frame 1: cheeks puffed (볼 부풀리기)
    private static let cheeksPixels: [String] = [
        "000000000000000000",
        "000011000000110000",
        "000172100001721000",
        "001222210012222100",
        "012222221222222210",
        "012252212212522210",
        "012222212212222210",
        "013332162261333210",
        "013332222222333210",
        "001334222222433100",
        "001224444444422100",
        "000124444444421000",
        "000012444444210000",
        "000012222222210000",
        "000011222222110000",
        "000001211112100000",
        "000001100011000000",
        "000000000000000000",
    ]

    // Frame 2: sleeping (졸기 - 눈 감기)
    private static let sleepingPixels: [String] = [
        "000000000000000000",
        "000011000000110000",
        "000172100001721000",
        "001222210012222100",
        "012222221222222210",
        "012212212212122210",
        "012252212212522210",
        "012232162261232210",
        "012232222222232210",
        "001224222222422100",
        "001224444444422100",
        "000124444444421000",
        "000012444444210000",
        "000012222222210000",
        "000011222222110000",
        "000001211112100000",
        "000001100011000000",
        "000000000000000000",
    ]

    static func makeImage(frame: Frame, size: CGFloat = 18) -> NSImage {
        let pixels: [String]
        switch frame {
        case .sitting: pixels = sittingPixels
        case .cheeks: pixels = cheeksPixels
        case .sleeping: pixels = sleepingPixels
        }

        let scale = NSScreen.main?.backingScaleFactor ?? 2.0
        let pixelSize = size * scale
        let dotSize = pixelSize / 18.0

        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()

        guard let context = NSGraphicsContext.current?.cgContext else {
            image.unlockFocus()
            return image
        }

        for (row, line) in pixels.enumerated() {
            for (col, char) in line.enumerated() {
                guard let color = palette[char], color.3 > 0 else { continue }
                context.setFillColor(
                    CGColor(red: color.0, green: color.1, blue: color.2, alpha: color.3)
                )
                let rect = CGRect(
                    x: CGFloat(col) * (size / 18.0),
                    y: size - CGFloat(row + 1) * (size / 18.0),
                    width: size / 18.0 + 0.5,
                    height: size / 18.0 + 0.5
                )
                context.fill(rect)
            }
        }

        image.unlockFocus()
        image.isTemplate = false
        return image
    }
}
```

- [ ] **Step 2: 빌드 확인**

Run: `xcodebuild -project HamsterTodo.xcodeproj -scheme HamsterTodo -configuration Debug build`
Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Commit**

```bash
git add Sources/View/PixelHamster.swift
git commit -m "feat: add programmatic pixel hamster sprite generation (3 frames)"
```

---

### Task 5: 메뉴바 햄스터 애니메이션

**Files:**
- Modify: `Sources/HamsterTodoApp.swift`

MenuBarExtra에 픽셀 햄스터 아이콘을 연결하고 Timer로 프레임 전환 애니메이션 추가.

- [ ] **Step 1: HamsterTodoApp 업데이트**

Replace `Sources/HamsterTodoApp.swift` with:
```swift
import SwiftUI

@main
struct HamsterTodoApp: App {
    @StateObject private var iconAnimator = HamsterIconAnimator()

    var body: some Scene {
        MenuBarExtra {
            PopupView()
        } label: {
            Image(nsImage: iconAnimator.currentImage)
        }
        .menuBarExtraStyle(.window)
    }
}

@MainActor
final class HamsterIconAnimator: ObservableObject {
    @Published var currentImage: NSImage

    private var timer: Timer?
    private var frameIndex = 0
    private let frames = PixelHamster.Frame.allCases

    init() {
        self.currentImage = PixelHamster.makeImage(frame: .sitting)
        startAnimation()
    }

    private func startAnimation() {
        timer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.advanceFrame()
            }
        }
    }

    private func advanceFrame() {
        frameIndex = (frameIndex + 1) % frames.count
        currentImage = PixelHamster.makeImage(frame: frames[frameIndex])
    }
}
```

- [ ] **Step 2: 임시 PopupView 스텁 작성**

Create `Sources/View/PopupView.swift`:
```swift
import SwiftUI

struct PopupView: View {
    var body: some View {
        Text("Coming soon...")
            .padding()
            .frame(width: 280)
    }
}
```

- [ ] **Step 3: 빌드 및 실행 확인**

Run: `xcodebuild -project HamsterTodo.xcodeproj -scheme HamsterTodo -configuration Debug build`
Expected: BUILD SUCCEEDED. 메뉴바에 픽셀 햄스터가 표시되고, 2.5초 간격으로 프레임 전환.

- [ ] **Step 4: Commit**

```bash
git add Sources/HamsterTodoApp.swift Sources/View/PopupView.swift
git commit -m "feat: add menu bar hamster icon with frame animation"
```

---

### Task 6: 팝업 뷰 구현

**Files:**
- Modify: `Sources/View/PopupView.swift`

말풍선 스타일 팝업에 인사말 + 할 일 목록 + 날짜 표시.

- [ ] **Step 1: PopupView 전체 구현**

Replace `Sources/View/PopupView.swift` with:
```swift
import SwiftUI

struct PopupView: View {
    @State private var todos: [TodoItem] = []
    @State private var noteDate: String?
    @State private var greeting: String = Greetings.random()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            greetingSection
            Divider()
            if todos.isEmpty {
                emptyState
            } else {
                todoList
            }
            Divider()
            footer
        }
        .padding(16)
        .frame(width: 300)
        .onAppear {
            todos = DailyNoteParser.loadTodos()
            noteDate = DailyNoteParser.latestNoteDate()
            greeting = Greetings.random()
        }
    }

    private var greetingSection: some View {
        HStack(spacing: 8) {
            Image(nsImage: PixelHamster.makeImage(frame: .cheeks, size: 32))
                .interpolation(.none)
            Text(greeting)
                .font(.system(size: 13, weight: .medium))
        }
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
```

- [ ] **Step 2: 빌드 및 실행 확인**

Run: `xcodebuild -project HamsterTodo.xcodeproj -scheme HamsterTodo -configuration Debug build`
Expected: BUILD SUCCEEDED. 햄스터 클릭 시 팝업에 인사말과 할 일 목록이 표시됨.

- [ ] **Step 3: Commit**

```bash
git add Sources/View/PopupView.swift
git commit -m "feat: add popup view with greeting, todo list, and empty state"
```

---

### Task 7: 알림 매니저

**Files:**
- Create: `Sources/Service/NotificationManager.swift`
- Modify: `Sources/HamsterTodoApp.swift` (앱 시작 시 알림 등록)

- [ ] **Step 1: NotificationManager 구현**

Create `Sources/Service/NotificationManager.swift`:
```swift
import UserNotifications

enum NotificationManager {
    static func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound]
        ) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }

    static func scheduleDailyReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(
            withIdentifiers: ["hamster-daily-reminder"]
        )

        let todos = DailyNoteParser.loadTodos()
            .filter { !$0.isCompleted }
        let count = todos.count

        let content = UNMutableNotificationContent()
        content.title = Greetings.random()
        content.body = count > 0
            ? "\(count)개의 할 일이 기다리고 있어요"
            : "오늘은 할 일이 없어요~ 푹 쉬세요 🐹💤"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 9
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )

        let request = UNNotificationRequest(
            identifier: "hamster-daily-reminder",
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }
}
```

- [ ] **Step 2: HamsterTodoApp에 알림 초기화 추가**

In `Sources/HamsterTodoApp.swift`, add an `init()` to `HamsterTodoApp`:
```swift
@main
struct HamsterTodoApp: App {
    @StateObject private var iconAnimator = HamsterIconAnimator()

    init() {
        NotificationManager.requestPermission()
        NotificationManager.scheduleDailyReminder()
    }

    var body: some Scene {
        MenuBarExtra {
            PopupView()
        } label: {
            Image(nsImage: iconAnimator.currentImage)
        }
        .menuBarExtraStyle(.window)
    }
}
```

`HamsterIconAnimator` 클래스는 기존 코드 그대로 유지.

- [ ] **Step 3: 빌드 확인**

Run: `xcodebuild -project HamsterTodo.xcodeproj -scheme HamsterTodo -configuration Debug build`
Expected: BUILD SUCCEEDED.

- [ ] **Step 4: Commit**

```bash
git add Sources/Service/NotificationManager.swift Sources/HamsterTodoApp.swift
git commit -m "feat: add notification manager with daily 9am reminder"
```

---

### Task 8: 로그인 시 자동 실행

**Files:**
- Modify: `Sources/HamsterTodoApp.swift`

- [ ] **Step 1: SMAppService를 사용한 자동 실행 등록**

In `Sources/HamsterTodoApp.swift`, update the `init()`:
```swift
import SwiftUI
import ServiceManagement

@main
struct HamsterTodoApp: App {
    @StateObject private var iconAnimator = HamsterIconAnimator()

    init() {
        NotificationManager.requestPermission()
        NotificationManager.scheduleDailyReminder()

        try? SMAppService.mainApp.register()
    }

    var body: some Scene {
        MenuBarExtra {
            PopupView()
        } label: {
            Image(nsImage: iconAnimator.currentImage)
        }
        .menuBarExtraStyle(.window)
    }
}
```

`HamsterIconAnimator` 클래스는 기존 코드 그대로 유지.

- [ ] **Step 2: 빌드 확인**

Run: `xcodebuild -project HamsterTodo.xcodeproj -scheme HamsterTodo -configuration Debug build`
Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Commit**

```bash
git add Sources/HamsterTodoApp.swift
git commit -m "feat: add launch at login via SMAppService"
```

---

### Task 9: 최종 통합 테스트

- [ ] **Step 1: 전체 테스트 실행**

Run: `xcodebuild test -project HamsterTodo.xcodeproj -scheme HamsterTodoTests -configuration Debug`
Expected: All tests PASSED.

- [ ] **Step 2: 앱 실행 확인**

Run: `open "$(xcodebuild -project HamsterTodo.xcodeproj -scheme HamsterTodo -configuration Debug -showBuildSettings | grep -m1 'BUILT_PRODUCTS_DIR' | awk '{print $3}')/HamsterTodo.app"`

확인 사항:
1. 메뉴바에 픽셀 햄스터가 표시되는가
2. 2.5초 간격으로 애니메이션이 전환되는가
3. 햄스터 클릭 시 팝업이 표시되는가
4. 팝업에 인사말과 할 일 목록이 보이는가
5. macOS 알림 권한 요청이 뜨는가

- [ ] **Step 3: Commit**

```bash
git add .
git commit -m "chore: final integration verification"
```
