# 03 연계형 투두 ★ (자체 설계)

기존 레퍼런스 없음 — todogether의 핵심 차별점.

## 개념

"A 완료 → B 자동 활성화"

- 투두 간에 **선행 조건(prerequisite)** 관계를 설정
- 선행 투두가 완료되기 전까지 후속 투두는 `locked` 상태
- 선행 완료 시 후속이 `available`로 전환 → 담당자에게 알림

## 사용 시나리오

1. **순서 있는 팀 업무**: "디자인 확정 → 개발 시작 → QA → 배포"
2. **습관 체인**: "운동 → 단백질 섭취" (당일 운동 완료 후 활성화)
3. **의존성 있는 장보기**: "장 봄 → 요리 → 설거지"

## 데이터 모델

```
TodoItem
  ├── id: UUID
  ├── prerequisiteIDs: [UUID]   // 이것들이 모두 완료되어야 활성화
  ├── status: locked | available | completed
  └── ...

ChainStatus 계산 로직:
  - prerequisiteIDs가 비어있거나 전부 completed → available
  - 하나라도 미완료 → locked
```

## 주의사항

- **순환 참조 방지**: A→B→A 같은 사이클 생성 시 에러 처리 필요
- **삭제 처리**: 선행 투두 삭제 시 후속의 prerequisiteIDs에서 제거
- **공유방 내 cross-user 체인**: 담당자가 다를 수 있음 → 완료 시 push 알림
