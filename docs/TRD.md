# HamsterTodo — Technical Requirements Document

## Overview

이 문서는 HamsterTodo의 기술 아키텍처를 정의한다. PRD에서 정의한 제품 요구사항을 **어떻게 구현할 것인가**에 대한 기술적 결정을 담고 있다.

**설계 원칙**: Simplicity first. 어떤 개발자든 10분 안에 전체 구조를 파악할 수 있어야 한다.

## Tech Stack

| 항목 | 선택 | 이유 |
|------|------|------|
| Language | Swift 5.9 | macOS 네이티브, 타입 안정성 |
| UI | SwiftUI (MenuBarExtra) | macOS 13+ 메뉴바 앱의 표준 방식 |
| Rendering | Core Graphics | 픽셀아트 직접 렌더링, 외부 에셋 불필요 |
| Notification | UserNotifications | macOS 네이티브 알림 |
| Login Item | ServiceManagement (SMAppService) | macOS 13+ 표준 로그인 항목 등록 |
| Project Gen | XcodeGen | project.yml 기반, .xcodeproj를 git에서 제외 |
| 외부 의존성 | 없음 | Apple 프레임워크만 사용 |

## Architecture: 3-Tier Layered

```
┌──────────────────────────────────────────────────┐
│  Presentation Layer                              │
│  사용자가 보고 상호작용하는 모든 것                    │
│                                                  │
│  HamsterTodoApp    PopupView    PixelHamster     │
├──────────────────────────────────────────────────┤
│  Logic Layer                                     │
│  데이터를 가공하고, 언제 무엇을 할지 결정하는 두뇌      │
│                                                  │
│  TodoViewModel     NotificationManager           │
├──────────────────────────────────────────────────┤
│  Data Layer                                      │
│  외부 시스템(파일, OS)과 직접 소통하는 계층            │
│                                                  │
│  DailyNoteParser   VaultAccessManager            │
├──────────────────────────────────────────────────┤
│  Model (전 레이어 공유)                             │
│                                                  │
│  TodoItem          Greetings                     │
└──────────────────────────────────────────────────┘
```

### 레이어 규칙

1. **Presentation → Logic → Data** 순서로만 호출한다. 역방향 호출 금지.
2. **Presentation은 Data를 직접 호출하지 않는다.** 반드시 Logic Layer를 거친다.
3. **Data Layer는 UI를 모른다.** SwiftUI, AppKit 의존 없이 Foundation만 사용한다.
4. **Model은 어디서든 사용 가능.** 순수 데이터 구조이므로 레이어 제약 없음.

## Layer별 컴포넌트 설계

### Presentation Layer

화면 표시와 사용자 입력 처리만 담당한다. 비즈니스 로직을 포함하지 않는다.

**HamsterTodoApp.swift** — 앱 진입점
- `@main`, `MenuBarExtra(.window)` 등록
- `HamsterIconAnimator`: 2.5초 간격 프레임 순환 (sitting → cheeks → sleeping)
- TodoViewModel을 생성하여 PopupView에 주입

**PopupView.swift** — 메뉴바 클릭 시 팝업
- TodoViewModel을 `@ObservedObject`로 관찰
- 표시 전용 — 데이터 로드, 가공 로직을 직접 수행하지 않음
- 볼트 미설정 시: 폴더 선택 UI → ViewModel의 selectVault() 호출
- 섹션 구성: 인사말 + 햄스터 | 투두 리스트 | 날짜 + Quit

**PixelHamster.swift** — 픽셀아트 렌더링
- 정적 enum. Core Graphics로 18x18 그리드 → NSImage 생성
- 3프레임 스프라이트. 외부 이미지 에셋 없음

### Logic Layer

데이터를 가공하고, 앱의 상태를 관리한다.

**TodoViewModel** (신규) — 앱 상태의 단일 진실 공급원
- `ObservableObject`. PopupView가 관찰하는 유일한 객체
- 데이터 흐름을 한 곳에서 관리:
  - `loadTodos()`: Data Layer를 통해 투두 로드
  - `selectVault()`: 폴더 선택 팝업 → Data Layer에 저장 위임
  - `todos`, `noteDate`, `greeting`: Published 프로퍼티
- VaultAccessManager, DailyNoteParser를 조합하여 데이터 제공

**NotificationManager.swift** — 알림 스케줄링
- 매일 9시 반복 알림 (`UNCalendarNotificationTrigger`)
- TodoViewModel에서 투두 개수를 받아 알림 본문 구성
- 자체적으로 Data Layer를 호출하지 않음 — ViewModel이 데이터를 전달

### Data Layer

외부 시스템(파일 시스템, UserDefaults, OS API)과 직접 소통한다. UI 프레임워크에 의존하지 않는다.

**DailyNoteParser.swift** — 마크다운 파싱
- 정적 enum. 순수 함수로 구성
- `findLatestNote(in:)` → 폴더에서 `YYYY-MM-DD.md` 패턴의 최신 파일 탐색
- `parseTodos(from:)` → `## 내일 할 일` 섹션의 체크박스 항목 추출
- `loadTodos(from:)` → 파일 탐색 + 읽기 + 파싱 통합
- 파일 크기 1MB 제한, 에러 시 빈 배열 반환 (fail-safe)

**VaultAccessManager.swift** — 볼트 경로 관리
- 싱글톤. Security-Scoped Bookmark을 UserDefaults에 저장/복원
- `saveBookmark(for:)`: URL → 북마크 데이터 저장
- `loadBookmark()`: 저장된 북마크 → URL 복원
- `vaultURL`, `isConfigured`: 현재 볼트 상태
- **UI를 직접 띄우지 않음** — NSOpenPanel 호출은 ViewModel이 담당

### Model (공유)

순수 데이터 구조. 로직 없음, 의존성 없음.

**TodoItem.swift**
```swift
struct TodoItem: Identifiable {
    let id: UUID
    let text: String
    let isCompleted: Bool
}
```

**Greetings.swift** (기존 PopupView.swift에서 분리)
```swift
enum Greetings {
    static func random() -> String { ... }
}
```
PopupView와 NotificationManager 양쪽에서 사용하므로 독립 파일로 분리한다.

## 데이터 흐름

### 팝업 표시 플로우

```
사용자: 햄스터 클릭
  │
  ▼
PopupView.onAppear
  │
  ▼
TodoViewModel.loadTodos()          ← Logic Layer
  ├─ VaultAccessManager.vaultURL   ← Data Layer (저장된 경로 반환)
  ├─ DailyNoteParser.loadTodos()   ← Data Layer (파일 읽기 + 파싱)
  └─ Greetings.random()            ← Model (인사말 선택)
  │
  ▼
PopupView가 @Published 프로퍼티 변경 감지 → UI 갱신
```

### 알림 플로우

```
앱 시작 (HamsterTodoApp.init)
  │
  ▼
NotificationManager.requestPermission()
  │
  ▼
TodoViewModel.scheduleDailyNotification()   ← Logic Layer
  ├─ DailyNoteParser.loadTodos()            ← Data Layer
  └─ NotificationManager.schedule(count:)   ← Logic Layer
  │
  ▼
매일 9시 → macOS 알림: "쪽쪽! 할 일 N개가 기다려요"
```

### 첫 설정 플로우

```
사용자: "폴더 선택..." 클릭
  │
  ▼
PopupView → TodoViewModel.selectVault()        ← Logic Layer
  ├─ NSOpenPanel 표시 (ViewModel에서 UI 호출)
  ├─ 사용자가 폴더 선택
  └─ VaultAccessManager.saveBookmark(for:)      ← Data Layer
  │
  ▼
TodoViewModel.loadTodos() 자동 실행 → UI 갱신
```

## 디렉토리 구조

```
Sources/
├── HamsterTodoApp.swift              # Presentation — 앱 진입점
├── Model/
│   ├── TodoItem.swift                # Model — 데이터 구조
│   └── Greetings.swift               # Model — 인사말 목록 (PopupView에서 분리)
├── View/
│   ├── PopupView.swift               # Presentation — 팝업 UI
│   └── PixelHamster.swift            # Presentation — 픽셀아트 렌더링
├── ViewModel/
│   └── TodoViewModel.swift           # Logic — 앱 상태 관리
└── Service/
    ├── DailyNoteParser.swift         # Data — 마크다운 파싱
    ├── NotificationManager.swift     # Logic — 알림 스케줄링
    └── VaultAccessManager.swift      # Data — 볼트 경로 관리
```

## 설계 결정 기록

| 결정 | 선택 | 대안 | 이유 |
|------|------|------|------|
| ViewModel 도입 | 채택 | View에서 직접 호출 유지 | 레이어 분리 확보. 기능 추가 시 View 비대화 방지 |
| 데이터 접근 통합 | ViewModel로 일원화 | 각 컴포넌트가 독립적으로 읽기 | 데이터 흐름 단순화, 불일치 방지 |
| VaultAccess UI 분리 | NSOpenPanel을 ViewModel로 이동 | Data Layer에서 직접 표시 | Data Layer의 UI 의존 제거 |
| Protocol 추상화 | 미도입 | Parser, VaultAccess에 Protocol 적용 | 현재 규모에서 과한 복잡도. 필요 시 추가 |
| 외부 의존성 | 없음 유지 | RxSwift, Combine 등 | Apple 프레임워크만으로 충분. 의존성 관리 비용 제거 |
| 이미지 에셋 | Core Graphics 코드 생성 | PNG 파일 번들 | 에셋 관리 불필요, 프로그래밍으로 완전 제어 |

## 보안 요구사항

- **App Sandbox**: 활성화. 사용자가 선택한 폴더만 접근 가능
- **Security-Scoped Bookmark**: 볼트 경로를 앱 재시작 후에도 유지
- **Hardened Runtime**: 코드 주입 방지
- **읽기 전용**: 마크다운 파일을 수정하지 않음
- **파일 검증**: `YYYY-MM-DD.md` 정규식 매칭, 1MB 크기 제한
- **네트워크 없음**: 로컬 파일 시스템만 사용

## 리팩토링 범위 (현재 코드 → TRD 구조)

현재 MVP가 동작하는 상태이므로, 기능 변경 없이 구조만 정리한다.

| 작업 | 변경 내용 |
|------|----------|
| TodoViewModel 생성 | PopupView의 `loadData()` 로직을 ViewModel로 이동 |
| PopupView 정리 | ViewModel 관찰로 전환. 직접 Parser 호출 제거 |
| VaultAccessManager 정리 | `selectVault()`의 NSOpenPanel 부분을 ViewModel로 이동. 북마크 저장/복원만 담당 |
| NotificationManager 정리 | 자체 Parser 호출 제거. ViewModel에서 투두 개수를 받아 스케줄링 |
| Greetings 분리 | PopupView.swift에서 Model/Greetings.swift로 이동 |
| HamsterTodoApp 정리 | ViewModel 생성 및 주입 책임만 수행 |
