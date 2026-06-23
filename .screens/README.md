# 화면 렌더링 (시각 검증 산출물)

> ⚠️ **이 이미지들은 컴파일된 iOS 앱을 시뮬레이터에서 캡처한 것이 아닙니다.**
> 이 작업 환경(Linux)에는 Swift/Xcode/iOS 시뮬레이터가 없어 앱을 실행할 수 없습니다.
> 대신 `render.py`(Pillow)로 **SwiftUI 뷰 코드의 레이아웃을 재현해 렌더링한 이미지**입니다.
> 실제 디바이스/시뮬레이터 캡처는 macOS+Xcode에서 Phase 0 이후 가능합니다.

각 이미지는 해당 SwiftUI 뷰의 구조(섹션·행·배지·색상·이모지 반응 등)를 반영합니다.

| 파일 | 대응 화면 / 코드 |
|------|------------------|
| 01_todo_list.png | TodoListView — 연계 잠김·반복 배지·공유방 색점·완료 섹션·반응 칩 |
| 02_todo_detail.png | TodoDetailView — 마감·반복·선행 조건 |
| 03_calendar.png | CalendarFeedView — 주간 스트립·점·마감지남/오늘/내일 섹션 |
| 04_widget.png | TodoWidgetMediumView — 홈 위젯(토글·완료) |
| 05_onboarding.png | OnboardingView — 3단계 온보딩 |
| 06_space_detail.png | SpaceDetailView — 멤버·초대·색상·삭제 |
| 07_reaction.png | ReactionPicker — 완료 투두 이모지 반응 |
| 08_notif_settings.png | NotificationSettingsView — 종류별·방해금지 |

재생성: `python3 render.py` (Pillow + Nanum/NotoColorEmoji 폰트 필요)
