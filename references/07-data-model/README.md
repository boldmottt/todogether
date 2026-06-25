# 07 전체 데이터 모델

모든 기능을 통합한 SwiftData 모델 설계입니다.

## 엔티티 관계

```
Space (공유방)
  └── [TodoItem] (투두 목록)
        ├── RecurrenceRule? (반복 규칙)
        ├── prerequisiteIDs: [UUID] (연계형)
        └── templateID: UUID? (어떤 템플릿에서 생성됐는지)

TodoTemplate (템플릿)
  └── [TemplateItem]

User (로컬 프로필)
  └── assignedTodos → TodoItem.assigneeID
```

## 핵심 설계 결정

1. **prerequisiteIDs를 UUID 배열로** (관계 대신): SwiftData CloudKit sync에서 to-many 관계가 불안정 — UUID로 직접 참조하면 동기화 충돌 감소
2. **RecurrenceRule을 JSON Data로**: SwiftData에서 중첩 Codable 구조체를 Data로 저장하면 마이그레이션이 단순
3. **Space = CKShare 단위**: Space별로 CloudKit 공유 → 공유방 멤버가 해당 Space의 투두만 접근
4. **WidgetTodo는 별도 경량 구조체**: App Group JSON에 저장, TodoItem과 sync는 앱에서 담당

## CloudKit sync 주의사항

- SwiftData + CloudKit: `ModelContainer` 초기화 시 `.cloudKitContainerIdentifier` 지정
- 공유 레코드 존(zone): `CKRecordZone.ID(zoneName: space.id.uuidString)` 패턴 권장
- 오프라인 쓰기 → CloudKit이 자동으로 나중에 sync (NSPersistentCloudKitContainer 동작 방식과 동일)
