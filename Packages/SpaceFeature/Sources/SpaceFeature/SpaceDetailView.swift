import SwiftUI
import SwiftData
import CloudKit
import SharedModels

// MARK: - 공유방 상세 (C1, C2)
public struct SpaceDetailView: View {
    @Bindable var space: Space
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var share: CKShare?
    @State private var showShareSheet = false
    @State private var showDeleteConfirm = false
    @State private var sharingError: String?

    private let sharingManager = SpaceSharingManager()

    public init(space: Space) {
        self.space = space
    }

    public var body: some View {
        Form {
            // 이름/색상
            Section {
                TextField("공유방 이름", text: $space.name)
                ColorPickerRow(colorHex: $space.colorHex)
            }

            // 멤버 (C1)
            Section("멤버") {
                ForEach(participants, id: \.id) { p in
                    MemberRow(participant: p)
                }
                Button {
                    Task { await startSharing() }
                } label: {
                    Label(share == nil ? "iCloud로 초대" : "초대 관리", systemImage: "person.badge.plus")
                }
            }

            // 초대 코드 섹션 (코드 생성 + 공유)
            InviteCodeSection(space: space)

            // 위험 구역
            Section {
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Label("공유방 삭제", systemImage: "trash")
                }
            } footer: {
                Text("삭제하면 이 공유방의 모든 할 일이 사라져요. 멤버 전원에게서 제거돼요.")
            }
        }
        .navigationTitle(space.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShareSheet) {
            if let share {
                CloudSharingView(share: share, container: CKContainer.default()) { error in
                    sharingError = error.localizedDescription
                }
                .ignoresSafeArea()
            }
        }
        .alert("공유방 삭제", isPresented: $showDeleteConfirm) {
            Button("삭제", role: .destructive) { deleteSpace() }
            Button("취소", role: .cancel) {}
        } message: {
            Text("‘\(space.name)’을(를) 삭제할까요?")
        }
        .alert("공유 오류", isPresented: Binding(
            get: { sharingError != nil },
            set: { if !$0 { sharingError = nil } }
        )) {
            Button("확인") {}
        } message: {
            Text(sharingError ?? "")
        }
    }

    // CKShare가 있으면 참가자, 없으면 나(소유자)만
    private var participants: [SpaceParticipant] {
        if let share {
            return share.participants.map { SpaceParticipant(from: $0) }
        }
        return [SpaceParticipant.localOwner]
    }

    private func startSharing() async {
        do {
            if share == nil {
                share = try await sharingManager.share(space)
                space.cloudKitShareID = share?.recordID.recordName
            }
            showShareSheet = true
        } catch {
            sharingError = error.localizedDescription
        }
    }

    private func deleteSpace() {
        context.delete(space)
        dismiss()
    }
}

// MARK: - 멤버 표현 (CKShare.Participant 래핑)
struct SpaceParticipant: Identifiable {
    let id: String
    let name: String
    let role: String       // "소유자" / "멤버"
    let isPending: Bool

    init(id: String, name: String, role: String, isPending: Bool) {
        self.id = id; self.name = name; self.role = role; self.isPending = isPending
    }

    init(from p: CKShare.Participant) {
        let comps = p.userIdentity.nameComponents
        let formatted = comps.map { PersonNameComponentsFormatter().string(from: $0) } ?? "이름 없음"
        id = p.userIdentity.userRecordID?.recordName ?? UUID().uuidString
        name = formatted.isEmpty ? "이름 없음" : formatted
        role = p.role == .owner ? "소유자" : "멤버"
        isPending = p.acceptanceStatus == .pending
    }

    static let localOwner = SpaceParticipant(id: "local", name: "나", role: "소유자", isPending: false)
}

struct MemberRow: View {
    let participant: SpaceParticipant

    var body: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 1) {
                Text(participant.name)
                Text(participant.role)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if participant.isPending {
                Text("대기 중")
                    .font(.caption2)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(.yellow.opacity(0.25), in: Capsule())
            }
        }
    }
}

// MARK: - 색상 선택 행
struct ColorPickerRow: View {
    @Binding var colorHex: String
    private let palette = ["#5E5CE6", "#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4", "#FFEAA7"]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(palette, id: \.self) { hex in
                Circle()
                    .fill(Color(hex: hex))
                    .frame(width: 30, height: 30)
                    .overlay {
                        if colorHex == hex {
                            Image(systemName: "checkmark")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                        }
                    }
                    .onTapGesture { colorHex = hex }
            }
        }
    }
}

// MARK: - UICloudSharingController 래퍼 (C2)
struct CloudSharingView: UIViewControllerRepresentable {
    let share: CKShare
    let container: CKContainer
    var onError: ((Error) -> Void)? = nil

    func makeCoordinator() -> Coordinator { Coordinator(share: share, onError: onError) }

    func makeUIViewController(context: Context) -> UICloudSharingController {
        let controller = UICloudSharingController(share: share, container: container)
        controller.availablePermissions = [.allowReadWrite, .allowPrivate]
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: UICloudSharingController, context: Context) {}

    final class Coordinator: NSObject, UICloudSharingControllerDelegate {
        let share: CKShare
        let onError: ((Error) -> Void)?

        init(share: CKShare, onError: ((Error) -> Void)?) {
            self.share = share
            self.onError = onError
        }

        func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
            onError?(error)
        }

        func itemTitle(for csc: UICloudSharingController) -> String? {
            share[CKShare.SystemFieldKey.title] as? String
        }
    }
}

#Preview("공유방 상세") {
    let container = try! ModelContainer(
        for: Space.self, TodoItem.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let space = Space(name: "우리집", colorHex: "#FF6B6B")
    container.mainContext.insert(space)
    return NavigationStack { SpaceDetailView(space: space) }
        .modelContainer(container)
}
