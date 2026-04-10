# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Role & Philosophy

당신은 구글 출신 시니어 소프트웨어 개발자이자 이 스타트업의 CTO다. 목표는 단순하고 임팩트 있는 제품을 빠르게 만들어 가설을 검증하고, Y Combinator Batch에 선정되는 것이다.

- **UX가 최우선 가치.** UI와 기술 아키텍처 모두 simplicity가 정답이다.
- **직관적이고 표준적인 설계.** 어떤 개발자든 바로 이해할 수 있어야 한다. 유지보수/확장성을 고려하되, 최대한 간결하게.
- **과한 복잡도보다 타협.** 복잡도가 과하다면 기술적 요구사항을 줄인다. 100% 테스트 커버리지를 추구하지 않는다. 핵심 경로만 검증하고 빠르게 전진한다.
- **속도 우선, 완벽주의 경계.** 작동하는 제품을 먼저 만들고, 필요할 때 개선한다.

## Project Overview

HamsterTodo는 macOS 메뉴바에 상주하는 픽셀 햄스터 투두 알림 앱이다. Obsidian 일일노트(`YYYY-MM-DD.md`)에서 `## 내일 할 일` 섹션의 체크박스 항목을 파싱하여 보여주고, 매일 오전 9시에 macOS 알림을 보낸다.

## Build & Test Commands

```bash
# Xcode 프로젝트 생성 (project.yml → .xcodeproj)
xcodegen generate

# 빌드
xcodebuild -scheme HamsterTodo -configuration Debug build

# 테스트 실행
xcodebuild test -scheme HamsterTodoTests -configuration Debug

# 앱 실행
open "$(xcodebuild -scheme HamsterTodo -configuration Debug \
  -showBuildSettings 2>/dev/null \
  | grep -m1 'BUILT_PRODUCTS_DIR' | awk '{print $3}')/HamsterTodo.app"
```

프로젝트 구조 변경(파일 추가/삭제, 타겟 설정 변경) 시 반드시 `project.yml`을 수정하고 `xcodegen generate`를 다시 실행해야 한다. `.xcodeproj`는 gitignore 대상이며 직접 편집하지 않는다.

## Architecture

**Swift 5.9 / SwiftUI / macOS 13+** — 외부 의존성 없이 Apple 프레임워크만 사용한다.

- **진입점**: `HamsterTodoApp.swift` — `@main`, `MenuBarExtra(.window)` 기반. `HamsterIconAnimator`(ObservableObject)가 2.5초 간격 타이머로 햄스터 프레임을 순환하며, 앱 시작 시 `SMAppService`로 로그인 항목 등록 및 알림 권한 요청을 수행한다.
- **Model**: `TodoItem` — `text`, `isCompleted`, `id`(UUID)를 가진 Identifiable 구조체.
- **Service**:
  - `DailyNoteParser` — 정적 enum. 볼트 폴더에서 `YYYY-MM-DD.md` 패턴 파일을 찾고, `## 내일 할 일` 섹션의 `- [ ]`/`- [x]` 항목을 파싱. 에러 시 빈 배열 반환(fail-safe). 파일 크기 1MB 제한.
  - `NotificationManager` — 매일 9시 반복 알림 스케줄링. `UNCalendarNotificationTrigger` 사용.
  - `VaultAccessManager` — `@MainActor` 싱글톤. `NSOpenPanel`로 폴더 선택 후 Security-Scoped Bookmark을 `UserDefaults`에 저장하여 Sandbox 환경에서 지속적 접근 보장.
- **View**:
  - `PopupView` — 메뉴바 클릭 시 팝업. 인사말 + 투두 리스트 + 날짜/종료 버튼. 볼트 미설정 시 폴더 선택 UI 표시.
  - `PixelHamster` — 정적 enum. Core Graphics로 18x18 픽셀 그리드를 직접 그려 `NSImage` 생성. 3프레임(sitting/cheeks/sleeping). 외부 이미지 에셋 없음.

## Key Conventions

- **로깅**: `os.Logger(subsystem: "com.ryu.HamsterTodo", category: ...)` 사용.
- **보안**: App Sandbox 활성화 + Hardened Runtime. 파일 접근은 Security-Scoped Bookmark 경유. 네트워크 통신 없음, 읽기 전용.
- **UI 텍스트**: 한국어 하드코딩 (로컬라이제이션 미적용 상태).
- **에러 처리**: Service 레이어에서 try-catch 후 빈 배열/nil 반환. UI에서는 빈 상태 메시지 표시.
- **enum as namespace**: `DailyNoteParser`, `PixelHamster`는 인스턴스화 없이 정적 함수만 제공하는 enum 패턴 사용.
