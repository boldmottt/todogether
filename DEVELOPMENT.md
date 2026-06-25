# 개발 가이드

## 패키지 구조

```
Packages/
├── SharedModels/       ← 데이터 모델 (모든 패키지의 공통 의존)
├── SpaceFeature/       ← 공유방 UI + CloudKit 공유
├── TodoFeature/        ← 투두 CRUD + 연계형 체인 + 완료 반응(이모지)
├── RecurringFeature/   ← 반복 규칙 선택 UI
├── TemplateFeature/    ← 템플릿 생성 + 인스턴스화
├── WidgetFeature/      ← WidgetKit + App Group 공유 저장소
├── CalendarFeature/    ← 달력뷰 + 피드뷰
└── NotificationFeature/← 알림(마감/연계 해제/완료/반응/콕 찌르기)
```

## 의존 관계

```
SharedModels
    ↑
SpaceFeature ─┐
NotificationFeature ─┴→ TodoFeature ← RecurringFeature
                                    ← TemplateFeature
                                    ← CalendarFeature
SharedModels ← WidgetFeature (TodoFeature 의존 없음 — 경량 유지)
SharedModels ← NotificationFeature
```

## 병렬 작업 브랜치 전략

1. `feature/shared-models` — **먼저 머지** (다른 모든 브랜치의 전제)
2. 이후 동시에 진행 가능:
   - `feature/space` → SpaceFeature
   - `feature/todo` → TodoFeature
   - `feature/recurring` → RecurringFeature
   - `feature/template` → TemplateFeature
   - `feature/widget` → WidgetFeature
   - `feature/calendar` → CalendarFeature

## Xcode 프로젝트에서 패키지 추가하는 법

1. Xcode → File → Add Package Dependencies
2. "Add Local..." → 각 `Packages/<이름>` 폴더 선택
3. 앱 타겟에서 필요한 패키지 링크

## 각 패키지 단독 빌드 & 테스트

```bash
# 예시: SharedModels만 테스트
cd Packages/SharedModels
swift test

# RecurringFeature 테스트
cd Packages/RecurringFeature
swift test
```

## 위젯 익스텐션 설정 (Xcode에서)

- `TodogetherWidgetBundle`(WidgetFeature)에는 `@main`이 없음 — 의도된 것.
  `@main`은 **위젯 Extension 타겟**에 두어야 함. 라이브러리에 두면 앱·익스텐션
  양쪽에 entry point가 중복되어 빌드 실패. 익스텐션 타겟에 아래 같은 thin 파일 추가:
  ```swift
  import WidgetKit
  import WidgetFeature

  @main
  struct TodogetherWidgets: WidgetBundle {
      var body: some Widget { TodogetherWidget() }
  }
  ```
- 딥링크 스킴 `todogether://todo/<uuid>` — 앱 타겟 Info에 URL Scheme `todogether` 등록.
  앱의 `onOpenURL`이 `WidgetDeepLink.todoID(from:)`로 파싱.
- 위젯과 앱이 같은 App Group을 공유해야 `SharedStore`(JSON)와 `NudgeStore`가 동작.

## App Group ID 교체

`WidgetFeature/Sources/WidgetFeature/SharedStore.swift` 의
`appGroupID`를 실제 Apple Developer 콘솔에서 등록한 값으로 교체하세요.
