# References

iOS 네이티브(SwiftUI + SwiftData + WidgetKit + CloudKit) 기준으로 구성한 레퍼런스 폴더입니다.

## 기능 ↔ 레퍼런스 매핑

| 폴더 | 기능 | 핵심 레퍼런스 |
|------|------|--------------|
| 01-sharing | 공유방 (CloudKit 공유) | CloudSharingController, CKShare |
| 02-recurring | 루틴/예약 반복 | Taska, Reminders 앱 패턴 |
| 03-chained-todos | 연계형 투두 ★ | 자체 설계 |
| 04-templates | 템플릿 ★ | 자체 설계 |
| 05-widgets | 위젯 (WidgetKit) | WidgetKit 공식 샘플, Widgetsmith |
| 06-calendar-feed | 달력뷰 / 피드뷰 | CalendarKit, Fantastical UX 분석 |
| 07-data-model | 전체 데이터 모델 | 통합 설계 |

★ = 기존 레퍼런스 부재 → 처음부터 설계한 차별점

## 전제 스택

- **UI**: SwiftUI
- **로컬 DB**: SwiftData
- **위젯**: WidgetKit (iOS 17+ 인터랙티브 위젯)
- **공유/클라우드**: CloudKit + CKShare
- **최소 지원**: iOS 17

스택이 변경되면 05(위젯)·01(공유) 폴더 내용을 교체하면 됩니다. 02~04 로직은 스택 무관하게 재사용 가능합니다.
