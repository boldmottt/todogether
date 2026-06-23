# 04 템플릿 ★ (자체 설계)

기존 레퍼런스 없음 — todogether의 핵심 차별점.

## 개념

반복되는 투두 묶음(체크리스트)을 템플릿으로 저장하고, 원클릭으로 인스턴스화.

## 사용 시나리오

1. **주간 팀 스프린트**: 월요일마다 동일한 태스크 묶음 생성
2. **이사 체크리스트**: 한 번 만들어두고 친구 이사 때 공유
3. **요리 레시피**: 재료 구매 → 준비 → 조리 체인을 템플릿화

## 데이터 모델

```
TodoTemplate
  ├── id: UUID
  ├── name: String ("주간 청소", "여행 준비" 등)
  ├── items: [TemplateItem]
  │     ├── title: String
  │     ├── relativeDeadline: Int?  // 인스턴스 생성일 기준 +N일
  │     ├── assigneeRole: String?   // "나" | "공유방 멤버"
  │     └── prerequisiteIndex: Int? // items 배열 내 인덱스로 체인 표현
  └── isShared: Bool  // 커뮤니티 공유 여부 (나중에)
```

## 인스턴스화 흐름

1. 사용자가 템플릿 선택
2. 기준일(startDate) 입력 (오늘 / 특정 날짜)
3. 각 TemplateItem → TodoItem 생성
   - dueDate = startDate + relativeDeadline
   - prerequisiteIDs = 선행 TemplateItem의 생성된 TodoItem.id
4. 공유방에 일괄 추가 (선택)
