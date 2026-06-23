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
- [ ] C1. 공유방 상세 (멤버 목록, 권한 표시)
- [ ] C2. 초대 시트(UICloudSharingController) 연결
- [ ] C3. 공유방 색상 코딩을 투두 행에 반영
- [ ] C4. Preview + 리뷰

## D. 완료 반응 (Reaction) — 부분 구현됨
- [x] D1. Reaction 모델 + 피커/요약 뷰
- [ ] D2. 완료 애니메이션 → 반응 유도 흐름 다듬기
- [ ] D3. 반응 히스토리(주간 기여) 뷰
- [ ] D4. Preview + 리뷰

## E. 알림 (Notification) — 부분 구현됨
- [x] E1. NotificationKind/Settings/Batcher/Manager
- [ ] E2. 콕 찌르기(Nudge) 액션 + 1일 1회 제한
- [ ] E3. 알림 설정 화면 (종류별·공유방별·방해금지)
- [ ] E4. 리뷰

## F. 템플릿 (Template)
- [ ] F1. 템플릿 항목에 선행/상대마감 편집 UI
- [ ] F2. 인스턴스화 시트 (기준일·대상 공유방 선택)
- [ ] F3. 기본 제공 템플릿 시드
- [ ] F4. Preview + 리뷰

## G. 위젯 (Widget)
- [ ] G1. Small/Medium 뷰 분기 + entryView
- [ ] G2. 앱→위젯 동기화 훅 (완료/추가 시 SharedStore.sync)
- [ ] G3. 딥링크(widgetURL) 처리
- [ ] G4. 리뷰

## H. 달력/피드 (Calendar)
- [ ] H1. 마감 지남/오늘/내일 섹션 분리
- [ ] H2. 월간 dot 인디케이터
- [ ] H3. 공유방 색상 점
- [ ] H4. Preview + 리뷰

## I. 통합/마감
- [ ] I1. 온보딩 3단계
- [ ] I2. 빈 상태 뷰 일괄
- [ ] I3. 앱 잠금(Face ID) 옵션
- [ ] I4. 최종 통합 리뷰
