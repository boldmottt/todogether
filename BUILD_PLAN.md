# 빌드 플랜 — 기능별 세부 단계

> 각 단계: 구현 → SwiftUI Preview 추가 → 에이전트 코드리뷰 → 문제 수정 → 커밋 → 다음 단계
>
> ⚠️ 이 레포는 Linux 환경에서 작성됨. iOS 빌드/시뮬레이터 검증은 macOS+Xcode에서 수행해야 함.
> 시각 검증은 각 뷰의 `#Preview`로 대체 (Xcode Canvas에서 렌더).

## 범례
- [ ] 미착수  · [~] 진행중  · [x] 완료(리뷰 통과)

---

## A. Todo 코어 (spine)
- [x] A1. 투두 상세/편집 화면 (제목·메모·마감)
- [x] A2. 선행 조건(연계) 설정 UI + 사이클 방지
- [x] A3. 스와이프 완료/삭제 + Undo
- [x] A4. 완료됨 섹션 (최근 7일) + 정렬/필터
- [x] A5. Preview + 에이전트 리뷰 통과 (Critical 2 + Should-fix 2 수정)

## B. 반복 (Recurring)
- [x] B1. 상세 화면에 반복 편집 연결 (의존방향 위해 TodoFeature에 배치)
- [x] B2. 요일/일자 커스텀 (weekly 요일선택, monthly 일선택)
- [x] B3. 반복 요약 배지 표시 (displayText는 SharedModels로 이동)
- [x] B4. Preview + 에이전트 리뷰 통과
- 알려진 한계: nextOccurrence가 weekdays/monthDay를 날짜계산에 미반영 (후속)

## C. 공유방 (Space)
- [x] C1. 공유방 상세 (멤버 목록, 권한 표시, 삭제)
- [x] C2. 초대 시트(UICloudSharingController + delegate) 연결
- [x] C3. 공유방 색상 점을 투두 행에 반영
- [x] C4. Preview + 에이전트 리뷰 통과 (Critical 1 + Should-fix 1 수정)
- 알려진 한계: SwiftData↔CloudKit 공유 레코드 연결은 스캐폴딩 수준(orphan record)

## D. 완료 반응 (Reaction)
- [x] D1. Reaction 모델 + 피커/요약 뷰
- [x] D2. 완료된 공유 투두 long-press → 피커 노출 + 자동 닫힘
- [x] D3. 반응 히스토리(이번 주 기여) ReactionHistoryView
- [x] D4. Preview + 최종 리뷰 일괄

## E. 알림 (Notification)
- [x] E1. NotificationKind/Settings/Batcher/Manager
- [x] E2. 콕 찌르기(Nudge) 액션 + 1일 1회 제한(NudgeStore) + 스와이프 UI
- [x] E3. 알림 설정 화면(종류별·방해금지 자정넘김)
- [x] E4. 독립 리뷰 통과 (F/H와 일괄; Critical 없음)

## F. 템플릿 (Template) — 병렬 에이전트
- [x] F1. 항목 편집(선행 인덱스·상대마감) TemplateItemEditorView
- [x] F2. 인스턴스화 시트(기준일·대상 공유방)
- [x] F3. 기본 템플릿 시드 seedDefaultTemplatesIfNeeded
- [x] F4. Preview (독립 리뷰는 G/H와 함께 일괄 예정)

## G. 위젯 (Widget) — 병렬 에이전트
- [x] G1. Small/Medium/Large 뷰 + widgetFamily 분기 entryView
- [x] G2. WidgetSyncing.refresh 훅 + 앱 scenePhase active 시 동기화
- [x] G3. 딥링크: TodoRow는 체크=토글 / 제목=Link, 앱 onOpenURL 파싱
- [x] G4. 에이전트 리뷰 통과 (중복심볼 없음; Button+widgetURL 충돌 수정; @main은 익스텐션 타겟에 — 문서화)

## H. 달력/피드 (Calendar) — 병렬 에이전트
- [x] H1. 마감지남/오늘/내일/이번주 섹션 (메모리 분류)
- [x] H2. 월간 그리드 + dot 인디케이터 + 주↔월 전환
- [x] H3. 공유방 색상 점
- [x] H4. Preview + 에이전트 리뷰 (주 시작 일요일 통일 수정)

## I. 통합/마감
- [x] I1. 온보딩 3단계 (OnboardingView, AppStorage didOnboard)
- [x] I2. 빈 상태 뷰 (투두/공유방/템플릿/캘린더/반응)
- [x] I3. 앱 잠금(Face ID/Touch ID) AppLockController + LockScreenView
- [x] I4. 최종 통합 리뷰 통과 (Critical 1 + Should-fix 1 수정: 백그라운드 인증 가드)
- 후속: 설정 탭(알림설정·앱잠금 토글) 노출, 딥링크 라우팅 실제 연결
