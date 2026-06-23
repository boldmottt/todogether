# 01 공유방 (CloudKit Sharing)

## 레퍼런스 분석

### Donetick — Circle 개념
- 공유방을 "Circle"로 부름
- Owner가 초대 링크 생성 → 멤버가 수락
- 역할: owner / member (member는 완료 처리만, owner는 편집까지)
- **우리 적용**: Circle → "공유방(Space)"으로 이름 변경, 역할 구조는 동일하게

### Apple CloudKit 공유
- `CKShare`로 레코드 공유 → `UICloudSharingController`로 초대 링크 생성
- 공유받은 쪽은 `CKContainer.shared().fetchShareParticipant`로 참여
- iCloud 계정 필요 (Apple 로그인과 자연스럽게 연동)

## 우리 적용 방향

1. `Space` = CloudKit의 `CKShare` 단위
2. 초대: `UICloudSharingController` → AirDrop / 메시지 / 링크 복사
3. 권한: `CKShare.Participant.Permission` (.readWrite / .readOnly)
4. 오프라인: SwiftData 로컬 캐시 → 네트워크 복구 시 sync
