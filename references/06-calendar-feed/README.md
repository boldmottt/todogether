# 06 달력뷰 / 피드뷰

## 레퍼런스 분석

### CalendarKit (MIT)
- 순수 SwiftUI 주간/일간 캘린더 라이브러리
- `EventDataSource` 프로토콜로 이벤트 데이터 주입
- 커스텀 셀 지원 → 투두 상태(완료/잠김) 뱃지 추가 가능
- **우리 적용**: 라이브러리 직접 사용 or 구조만 참고해서 직접 구현

### Fantastical UX 분석
- 상단: 월 달력 (날짜 탭 → 해당 날 피드로 스크롤)
- 하단: 날짜별 피드 (이벤트 + 할일 혼합)
- 투두와 캘린더 이벤트를 같은 타임라인에서 보여줌
- **우리 적용**: 공유방 색상 코딩으로 피드에서 출처 구분

## 구현 방향

### 달력뷰
- `month` 모드: 날짜별 dot indicator (투두 있으면 표시)
- `week` 모드: 수평 스크롤 주간 뷰

### 피드뷰
- 날짜 선택 → 해당 날 투두 리스트
- 섹션: "내 투두" / "공유방별"
- 잠긴 투두는 회색 + 자물쇠 아이콘

### 데이터 쿼리
```swift
// 특정 날짜 투두
@Query(filter: #Predicate<TodoItem> {
    $0.dueDate >= startOfDay && $0.dueDate < endOfDay
}, sort: \.dueDate)
var todayTodos: [TodoItem]
```
