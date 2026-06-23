import CloudKit
import SwiftUI

// Space = 공유방 단위. CKShare 1개에 대응.
struct Space: Identifiable {
    let id: CKRecord.ID
    var name: String
    var share: CKShare?
}

// MARK: - 공유방 생성 & 초대 링크 발행
final class SpaceSharingManager {
    private let container = CKContainer.default()
    private let privateDB: CKDatabase

    init() {
        privateDB = container.privateCloudDatabase
    }

    /// Space 레코드를 생성하고 CKShare를 붙여 저장
    func createSpace(name: String) async throws -> (CKRecord, CKShare) {
        let spaceRecord = CKRecord(recordType: "Space")
        spaceRecord["name"] = name as CKRecordValue

        let share = CKShare(rootRecord: spaceRecord)
        share[CKShare.SystemFieldKey.title] = name as CKRecordValue
        share.publicPermission = .none  // 명시적 초대만 허용

        let (saveResults, _) = try await privateDB.modifyRecords(
            saving: [spaceRecord, share],
            deleting: []
        )
        _ = saveResults  // 에러 처리는 production에서 추가

        return (spaceRecord, share)
    }

    /// 공유 URL 가져오기 (UICloudSharingController 없이 직접 링크만 필요할 때)
    func sharingURL(for share: CKShare) -> URL? {
        share.url
    }
}

// MARK: - SwiftUI에서 UICloudSharingController 래핑
struct CloudSharingView: UIViewControllerRepresentable {
    let share: CKShare
    let container: CKContainer

    func makeUIViewController(context: Context) -> UICloudSharingController {
        let controller = UICloudSharingController(share: share, container: container)
        controller.availablePermissions = [.allowReadWrite, .allowPrivate]
        return controller
    }

    func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) {}
}

// MARK: - 초대 수락 (SceneDelegate / onOpenURL)
// App의 onOpenURL에서 CKShare URL을 처리
func handleIncomingShare(url: URL) async {
    let container = CKContainer.default()
    guard let shareMetadata = try? await container.shareMetadata(for: url) else { return }

    // 이미 참여 중인지 확인
    if shareMetadata.participantStatus == .accepted { return }

    try? await container.accept(shareMetadata)
}
