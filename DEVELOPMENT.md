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

## App Group ID 교체

`WidgetFeature/Sources/WidgetFeature/SharedStore.swift` 의
`appGroupID`를 실제 Apple Developer 콘솔에서 등록한 값으로 교체하세요.
