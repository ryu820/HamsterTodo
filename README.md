# HamsterTodo 🐹

macOS 메뉴바에 상주하는 픽셀 햄스터가 매일 아침 Obsidian 일일노트의 할 일을 알려주는 앱.

![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue) ![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange) ![SwiftUI](https://img.shields.io/badge/SwiftUI-MenuBarExtra-purple)

## 기능

- **메뉴바 픽셀 햄스터** — 3프레임 애니메이션 (앉기 / 볼 부풀리기 / 졸기)
- **Obsidian 일일노트 파싱** — `## 내일 할 일` 섹션의 `- [ ]` / `- [x]` 항목 자동 추출
- **말풍선 팝업** — 햄스터 클릭 시 인사말 + 할 일 목록 표시
- **매일 9시 알림** — macOS 알림으로 미완료 할 일 개수 안내
- **로그인 시 자동 실행**

## 스크린샷

```
┌─────────────────────────────────┐
│ 🐹 쪽쪽! 오늘 할 일을 가져왔어요~  │
│─────────────────────────────────│
│ ☐ [GGC-218] 조직도 API 연동 구현  │
│ ☐ 코드 리뷰 피드백 반영            │
│─────────────────────────────────│
│ 📅 2026-04-09              Quit │
└─────────────────────────────────┘
```

## 요구사항

- macOS 13 (Ventura) 이상
- Xcode 16+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

## 설치 및 빌드

```bash
# XcodeGen 설치
brew install xcodegen

# 프로젝트 생성 및 빌드
git clone https://github.com/ryu/HamsterTodo.git
cd HamsterTodo
xcodegen generate
xcodebuild -scheme HamsterTodo -configuration Debug build
```

## 실행

```bash
open "$(xcodebuild -scheme HamsterTodo -configuration Debug \
  -showBuildSettings 2>/dev/null \
  | grep -m1 'BUILT_PRODUCTS_DIR' | awk '{print $3}')/HamsterTodo.app"
```

첫 실행 시 햄스터를 클릭하면 **"폴더 선택..."** 버튼이 표시됩니다.
Obsidian 볼트의 일일노트 폴더 (예: `01-daily/`)를 선택해주세요.

## 일일노트 형식

앱이 파싱하는 마크다운 형식:

```markdown
## 내일 할 일
- [ ] 미완료 항목
- [x] 완료된 항목
```

- 파일명: `YYYY-MM-DD.md` (예: `2026-04-09.md`)
- 폴더 내 가장 최근 날짜 파일을 자동 선택

## 프로젝트 구조

```
Sources/
├── HamsterTodoApp.swift          # @main, MenuBarExtra 진입점
├── Model/
│   └── TodoItem.swift            # 할 일 데이터 모델
├── Service/
│   ├── DailyNoteParser.swift     # 마크다운 파싱
│   ├── NotificationManager.swift # 9시 알림 스케줄링
│   └── VaultAccessManager.swift  # Sandbox 볼트 접근 관리
└── View/
    ├── PopupView.swift           # 말풍선 팝업 UI
    └── PixelHamster.swift        # Core Graphics 픽셀 햄스터
```

## 보안

- **App Sandbox** 활성화 — Security-Scoped Bookmark으로 사용자가 선택한 폴더만 접근
- **Hardened Runtime** 활성화 — 런타임 코드 주입 방지
- 파일명 `YYYY-MM-DD.md` 정규식 검증
- 파일 크기 1MB 제한
- 네트워크 통신 없음, 읽기 전용

## 테스트

```bash
xcodegen generate
xcodebuild test -scheme HamsterTodoTests -configuration Debug
```

## License

MIT
