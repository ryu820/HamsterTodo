# 3-Tier Layered Architecture Refactoring Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 현재 MVP 코드를 TRD에 정의된 3-Tier Layered Architecture (Presentation / Logic / Data) 구조로 리팩토링한다. 기능 변경 없이 구조만 정리.

**Architecture:** PopupView가 DailyNoteParser/VaultAccessManager를 직접 호출하는 현재 구조를 TodoViewModel(Logic Layer)을 중간에 두는 3-tier 구조로 전환. VaultAccessManager에서 UI(NSOpenPanel) 제거, NotificationManager에서 Parser 직접 호출 제거.

**Tech Stack:** Swift 5.9, SwiftUI, XcodeGen

---

### File Map

| Action | Path | Layer | 역할 |
|--------|------|-------|------|
| Create | `Sources/Model/Greetings.swift` | Model | 인사말 목록 (PopupView.swift에서 분리) |
| Create | `Sources/ViewModel/TodoViewModel.swift` | Logic | 앱 상태 관리, 단일 진실 공급원 |
| Modify | `Sources/Service/VaultAccessManager.swift` | Data | UI 제거, 북마크 저장/복원만 담당 |
| Modify | `Sources/Service/NotificationManager.swift` | Logic | Parser 직접 호출 제거, count를 받아 스케줄링 |
| Modify | `Sources/View/PopupView.swift` | Presentation | ViewModel 관찰로 전환 |
| Modify | `Sources/HamsterTodoApp.swift` | Presentation | ViewModel 생성 및 주입 |

---

### Task 1: Extract Greetings to Model/Greetings.swift

**Files:**
- Create: `Sources/Model/Greetings.swift`
- Modify: `Sources/View/PopupView.swift` (Greetings enum 제거)

- [ ] **Step 1: Create Model/Greetings.swift**

```swift
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
```

- [ ] **Step 2: Remove Greetings enum from PopupView.swift**

PopupView.swift 하단의 `enum Greetings { ... }` 블록 전체를 삭제한다 (line 107-119).

- [ ] **Step 3: Build verification**

Run: `cd /Users/ryu/Documents/dev/HamsterTodo && xcodegen generate && xcodebuild -scheme HamsterTodo -configuration Debug build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Run tests**

Run: `xcodebuild test -scheme HamsterTodoTests -configuration Debug 2>&1 | tail -10`
Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
git add Sources/Model/Greetings.swift Sources/View/PopupView.swift
git commit -m "refactor: extract Greetings enum to Model layer"
```

---

### Task 2: Create TodoViewModel + Refactor VaultAccessManager + Update PopupView + Update App

이 4개 파일은 서로 의존하므로 하나의 atomic 변경으로 처리한다.

**Files:**
- Create: `Sources/ViewModel/TodoViewModel.swift`
- Modify: `Sources/Service/VaultAccessManager.swift`
- Modify: `Sources/View/PopupView.swift`
- Modify: `Sources/HamsterTodoApp.swift`

- [ ] **Step 1: Refactor VaultAccessManager — UI 제거, 북마크 전용으로 축소**

VaultAccessManager에서 변경:
- `ObservableObject` 제거 (더 이상 View가 직접 관찰하지 않음)
- `@Published` 제거 → 일반 프로퍼티로 변경
- `selectVault()` 메서드 삭제 (NSOpenPanel 로직은 TodoViewModel로 이동)
- `saveBookmark(for:)` → public `saveAndAccess(url:)` 메서드로 변경

```swift
import Foundation
import os

@MainActor
final class VaultAccessManager {
    static let shared = VaultAccessManager()

    private let logger = Logger(subsystem: "com.ryu.HamsterTodo", category: "VaultAccess")
    private static let bookmarkKey = "vaultBookmarkData"

    private(set) var vaultURL: URL?
    var isConfigured: Bool { vaultURL != nil }

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
        } catch {
            logger.error("Failed to resolve bookmark: \(error.localizedDescription)")
        }
    }

    func saveAndAccess(url: URL) {
        saveBookmark(for: url)

        guard url.startAccessingSecurityScopedResource() else {
            logger.error("Failed to access selected directory")
            return
        }

        vaultURL = url
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
```

- [ ] **Step 2: Create TodoViewModel — Logic Layer의 핵심**

```swift
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
        panel.title = "Obsidian 일일노트 폴더 선택"
        panel.message = "할 일을 가져올 일일노트 폴더를 선택하세요"
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
```

- [ ] **Step 3: Update PopupView — ViewModel 관찰로 전환**

변경 사항:
- `@EnvironmentObject var vaultAccess: VaultAccessManager` → `@EnvironmentObject var viewModel: TodoViewModel`
- `@State private var todos/noteDate/greeting` 제거 (ViewModel의 @Published로 대체)
- `loadData()` 삭제 → `viewModel.loadTodos()` 호출
- `vaultAccess.selectVault()` → `viewModel.selectVault()`
- `vaultAccess.isConfigured` → `viewModel.isVaultConfigured`

```swift
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
            Text("일일노트 폴더를 선택해주세요")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            Button("폴더 선택...") {
                viewModel.selectVault()
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
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .font(.system(size: 10))
            .foregroundStyle(.tertiary)
        }
    }
}
```

- [ ] **Step 4: Update HamsterTodoApp — ViewModel 생성 및 주입**

변경 사항:
- `@StateObject private var vaultAccess` 제거
- `@StateObject private var viewModel = TodoViewModel()` 추가
- `.environmentObject(vaultAccess)` → `.environmentObject(viewModel)`
- `NotificationManager` 호출을 ViewModel 기반으로 변경

```swift
import SwiftUI
import ServiceManagement
import os

@main
struct HamsterTodoApp: App {
    @StateObject private var iconAnimator = HamsterIconAnimator()
    @StateObject private var viewModel = TodoViewModel()

    private static let logger = Logger(subsystem: "com.ryu.HamsterTodo", category: "App")

    init() {
        NotificationManager.requestPermissionAndSchedule(
            todosPath: VaultAccessManager.shared.vaultURL?.path
        )

        do {
            try SMAppService.mainApp.register()
        } catch {
            Self.logger.error("Failed to register login item: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        MenuBarExtra {
            PopupView()
                .environmentObject(viewModel)
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

- [ ] **Step 5: Build verification**

Run: `cd /Users/ryu/Documents/dev/HamsterTodo && xcodegen generate && xcodebuild -scheme HamsterTodo -configuration Debug build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 6: Run tests**

Run: `xcodebuild test -scheme HamsterTodoTests -configuration Debug 2>&1 | tail -10`
Expected: All tests pass

- [ ] **Step 7: Commit**

```bash
git add Sources/ViewModel/TodoViewModel.swift Sources/Service/VaultAccessManager.swift Sources/View/PopupView.swift Sources/HamsterTodoApp.swift
git commit -m "refactor: introduce TodoViewModel as Logic Layer, separate concerns across 3-tier architecture"
```

---

### Task 3: Refactor NotificationManager — Parser 직접 호출 제거

**Files:**
- Modify: `Sources/Service/NotificationManager.swift`
- Modify: `Sources/HamsterTodoApp.swift`

- [ ] **Step 1: Refactor NotificationManager to receive count**

변경: `requestPermissionAndSchedule(todosPath:)` → `requestPermissionAndSchedule(incompleteTodoCount:)`
Parser 호출 제거. 외부에서 미완료 개수를 전달받는다.

```swift
import UserNotifications
import os

enum NotificationManager {
    private static let logger = Logger(subsystem: "com.ryu.HamsterTodo", category: "NotificationManager")

    static func requestPermissionAndSchedule(incompleteTodoCount: Int) {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound]
        ) { granted, error in
            if let error = error {
                logger.error("Notification permission error: \(error.localizedDescription)")
                return
            }

            guard granted else {
                logger.info("Notification permission denied by user")
                return
            }

            scheduleDailyReminder(incompleteTodoCount: incompleteTodoCount)
        }
    }

    private static func scheduleDailyReminder(incompleteTodoCount count: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(
            withIdentifiers: ["hamster-daily-reminder"]
        )

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
                logger.error("Failed to schedule notification: \(error.localizedDescription)")
            }
        }
    }
}
```

- [ ] **Step 2: Update HamsterTodoApp init to pass count**

HamsterTodoApp.init()의 NotificationManager 호출을 변경:

```swift
// Before:
NotificationManager.requestPermissionAndSchedule(
    todosPath: VaultAccessManager.shared.vaultURL?.path
)

// After:
let todoCount: Int
if let path = VaultAccessManager.shared.vaultURL?.path {
    todoCount = DailyNoteParser.loadTodos(from: path)
        .filter { !$0.isCompleted }
        .count
} else {
    todoCount = 0
}
NotificationManager.requestPermissionAndSchedule(incompleteTodoCount: todoCount)
```

- [ ] **Step 3: Build verification**

Run: `cd /Users/ryu/Documents/dev/HamsterTodo && xcodegen generate && xcodebuild -scheme HamsterTodo -configuration Debug build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Run tests**

Run: `xcodebuild test -scheme HamsterTodoTests -configuration Debug 2>&1 | tail -10`
Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
git add Sources/Service/NotificationManager.swift Sources/HamsterTodoApp.swift
git commit -m "refactor: NotificationManager receives todo count instead of calling Parser directly"
```
