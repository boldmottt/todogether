# 02 루틴 / 예약 반복

## 레퍼런스 분석

### Vikunja — 반복 모델
- `repeat_after` (초 단위 숫자) + `repeat_mode` (default / month / from_current_date)
- from_current_date: 완료한 날짜 기준으로 다음 날짜 계산 (습관 트래킹에 적합)
- **우리 적용**: 동일 개념, 단위는 enum으로 가독성 향상

### Apple Reminders — 반복 옵션 UX
- 매일 / 매주(요일 선택) / 매월(일 선택) / 매년 / 커스텀
- 커스텀: "2주마다", "매월 마지막 금요일" 등
- **우리 적용**: 위 옵션 + "완료 후 N일" (from_current_date)

### Taska (MIT)
- SwiftData `@Model`에 반복 규칙 저장
- `nextOccurrence()` 함수로 다음 날짜 계산

## 반복 규칙 설계

```
RecurrenceRule
  ├── frequency: daily | weekly | monthly | yearly | afterCompletion
  ├── interval: Int (2 = "2주마다")
  ├── weekdays: [Weekday]? (weekly일 때)
  ├── monthDay: Int? (monthly일 때)
  └── endDate: Date?
```

`afterCompletion` = Vikunja의 `from_current_date` — 완료 시점 기준 N일 후 재생성
