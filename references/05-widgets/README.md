# 05 위젯 (WidgetKit)

## 레퍼런스 분석

### Apple WidgetKit 공식 샘플
- iOS 17+: `Button` / `Toggle` in widget → AppIntent 실행 (인터랙티브 위젯)
- `TimelineProvider` → `TimelineEntry` → `View` 구조
- App Group으로 앱 ↔ 위젯 간 SwiftData / UserDefaults 공유

### Widgetsmith UX 분석
- 크기별(small/medium/large) 프리뷰를 편집 시 실시간으로 보여줌
- 위젯 탭 → 앱 딥링크로 해당 항목 바로 열기

## 구현 포인트

### 1. App Group 설정
- Target → Signing & Capabilities → App Groups → 동일 Group ID 공유
- SwiftData store URL을 App Group container 경로로 지정

### 2. 인터랙티브 토글 (iOS 17+)
```swift
Toggle(isOn: entry.todo.isCompleted) {
    Text(entry.todo.title)
}
.toggleStyle(.button)
.widgetURL(deepLinkURL(for: entry.todo))
```
→ `AppIntent`의 `perform()`에서 SwiftData 업데이트 + 위젯 타임라인 리로드

### 3. 위젯 크기별 콘텐츠
- **Small**: 가장 급한 투두 1개 + 완료 토글
- **Medium**: 오늘 투두 3~4개 리스트
- **Large**: 오늘 + 내일 / 공유방별 섹션

### 4. 타임라인 갱신 시점
- 투두 완료/추가 시: `WidgetCenter.shared.reloadAllTimelines()`
- 자정 자동 갱신: `TimelineReloadPolicy.atEnd` with 자정 entry
