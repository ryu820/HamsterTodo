# HamsterTodo - macOS 메뉴바 픽셀 햄스터 할 일 알리미

## 개요

macOS 메뉴바에 상주하는 픽셀 햄스터 캐릭터 앱. 매일 아침 9시에 Obsidian 일일노트의 할 일을 macOS 알림으로 알려주고, 클릭하면 말풍선 스타일 팝업으로 목록을 보여준다.

## 프로젝트 설정

- **별도 프로젝트**: 이 앱은 독립된 macOS 앱으로, 별도 폴더에 Xcode 프로젝트를 생성한다.
- **권장 경로**: `~/Documents/dev/HamsterTodo/`
- **언어/프레임워크**: Swift, SwiftUI
- **최소 지원**: macOS 13+ (Ventura) — `MenuBarExtra` API 필요
- **Xcode 프로젝트 타입**: macOS App (SwiftUI lifecycle)
- **서명**: Development 서명 (로컬 실행용, App Store 배포 불필요)

## 데이터 소스

- **Obsidian 볼트 경로**: `/Volumes/RYU/연구노트/`
- **일일노트 경로**: `/Volumes/RYU/연구노트/01-daily/`
- **파일명 패턴**: `YYYY-MM-DD.md` (예: `2026-04-09.md`)
- **파싱 대상**: `## 내일 할 일` 섹션 아래의 `- [ ] 항목` 라인들
- **노트 선택 로직**: 폴더 내 가장 최근 날짜 파일을 선택 (오늘 날짜 파일이 있으면 오늘 것, 없으면 직전 날짜 것)

### 마크다운 파싱 예시

```markdown
## 내일 할 일
- [ ] [GGC-218] 조직도 API 연동 구현 (설계 v4 확정, 미구현 — feature/GGC-218 브랜치)
- [ ] 코드 리뷰 피드백 반영
```

위에서 추출할 데이터:
- `[GGC-218] 조직도 API 연동 구현 (설계 v4 확정, 미구현 — feature/GGC-218 브랜치)`
- `코드 리뷰 피드백 반영`

## 구조

```
HamsterTodo/
├── HamsterTodoApp.swift          # @main, MenuBarExtra 진입점, 앱 라이프사이클
├── Model/
│   └── TodoItem.swift            # 할 일 데이터 모델
├── Service/
│   ├── DailyNoteParser.swift     # 마크다운 파싱 (내일 할 일 섹션 추출)
│   └── NotificationManager.swift # 매일 9시 알림 스케줄링
├── View/
│   ├── PopupView.swift           # 말풍선 팝업 (인사말 + 할 일 목록)
│   └── HamsterIcon.swift         # 메뉴바 픽셀 햄스터 애니메이션 관리
└── Assets.xcassets/
    └── hamster-frames/           # 픽셀 햄스터 스프라이트 PNG (3프레임)
```

## 컴포넌트 상세

### 1. HamsterTodoApp.swift

- `@main` 진입점, SwiftUI `App` 프로토콜
- `MenuBarExtra`로 메뉴바에 햄스터 아이콘 등록
- 앱 실행 시 알림 권한 요청 및 9시 알림 스케줄링
- `NSPopover`를 활용한 팝업 윈도우 표시 (MenuBarExtra의 window 스타일)

### 2. TodoItem.swift

```swift
struct TodoItem: Identifiable {
    let id = UUID()
    let text: String       // 할 일 내용 (마크다운 체크박스 제거된 텍스트)
    let isCompleted: Bool  // - [x] 여부
}
```

### 3. DailyNoteParser.swift

- 볼트 경로에서 가장 최근 일일노트 파일 탐색
- 파일 내용을 읽어 `## 내일 할 일` 섹션을 찾음
- 해당 섹션의 `- [ ]` / `- [x]` 라인을 `TodoItem` 배열로 변환
- 다음 `##` 헤딩이 나오면 섹션 종료로 판단
- 볼트 경로는 앱 내 상수로 설정 (추후 설정 화면 확장 가능)

### 4. NotificationManager.swift

- `UNUserNotificationCenter`로 매일 9시 반복 알림 스케줄링
- `UNCalendarNotificationTrigger`로 hour: 9, minute: 0 설정
- 알림 제목: 랜덤 귀여운 인사말 (예: "쪽쪽! 오늘 할 일이 있어요 🐹")
- 알림 본문: 할 일 항목 수 표시 (예: "3개의 할 일이 기다리고 있어요")
- 알림 클릭 시 앱 포커스 → 팝업 표시

### 5. PopupView.swift

- 말풍선 느낌의 SwiftUI 뷰 (둥근 모서리, 약간의 그림자)
- 상단: 랜덤 인사말 + 작은 햄스터 이모지/픽셀아트
- 중단: 할 일 목록 (체크박스 스타일)
- 하단: 날짜 표시 (어떤 노트에서 가져왔는지)
- 할 일이 없으면: "오늘은 쉬어도 돼요~ 🐹💤" 같은 메시지

### 6. HamsterIcon.swift

- 메뉴바용 16x16 (또는 18x18) 픽셀아트 햄스터 스프라이트 3프레임
  - 프레임 1: 기본 자세 (앉아있기)
  - 프레임 2: 볼 부풀리기
  - 프레임 3: 졸기 (눈 감기)
- `Timer`로 2-3초 간격 프레임 전환
- `NSImage`로 메뉴바 아이콘 업데이트

## 픽셀아트 에셋

- 3프레임 스프라이트 PNG 필요 (16x16 또는 18x18 픽셀)
- macOS 메뉴바 아이콘은 template 이미지 권장이지만, 컬러 픽셀아트를 쓸 것이므로 template: false 설정
- 에셋은 직접 픽셀아트 도구로 제작하거나, 간단한 도트 이미지를 코드로 생성
- Retina 대응: @2x 이미지도 함께 준비 (32x32, 36x36)

## 앱 동작 흐름

```
앱 실행
  ├→ 알림 권한 요청
  ├→ 매일 9시 알림 스케줄링
  └→ 메뉴바에 햄스터 아이콘 등록 + 애니메이션 시작

매일 9시
  └→ macOS 알림: "쪽쪽! 오늘 할 일이 있어요 🐹"

사용자가 햄스터 클릭 또는 알림 클릭
  ├→ DailyNoteParser가 최근 일일노트 파싱
  └→ PopupView에 인사말 + 할 일 목록 표시

팝업 외부 클릭
  └→ 팝업 닫힘
```

## 인사말 목록 (랜덤 선택)

- "좋은 아침이에요! 오늘도 화이팅 🐹"
- "쪽쪽! 오늘 할 일을 가져왔어요~"
- "햄찌가 할 일을 정리했어요! 🌻"
- "오늘도 멋진 하루 보내요~ 🐹✨"
- "볼에 할 일을 잔뜩 넣어왔어요!"

## 로그인 시 자동 실행

- Xcode 프로젝트 설정에서 "Launch at Login" 또는 `SMAppService.mainApp.register()` (macOS 13+) 로 로그인 시 자동 실행 등록

## 범위 밖 (향후 확장 가능)

- 볼트 경로 설정 UI
- 할 일 완료 체크 (앱에서 마크다운 파일 수정)
- 여러 볼트/노트 경로 지원
- 햄스터 스킨 변경
- 시간 설정 커스텀
