import SwiftUI
import SwiftData
import CloudKit
import SharedModels

// MARK: - 공유방 목록 뷰
public struct SpaceListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Space.name) private var spaces: [Space]
    @State private var showCreateSheet = false
    @State private var showJoinSheet = false

    public init() {}

    public var body: some View {
        List(spaces) { space in
            NavigationLink(value: space) {
                SpaceRowView(space: space)
            }
        }
        .overlay {
            if spaces.isEmpty {
                ContentUnavailableView {
                    Label("함께할 사람을 초대해보세요", systemImage: "person.2")
                } description: {
                    Text("공유방을 만들거나 초대 코드로 참여해보세요")
                } actions: {
                    Button("공유방 만들기") { showCreateSheet = true }
                        .buttonStyle(.borderedProminent)
                    Button("코드로 참여") { showJoinSheet = true }
                        .buttonStyle(.bordered)
                }
            }
        }
        .navigationTitle("공유방")
        .toolbar {
            Menu {
                Button("새 공유방", systemImage: "plus") { showCreateSheet = true }
                Button("코드로 참여", systemImage: "qrcode") { showJoinSheet = true }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateSpaceView()
        }
        .sheet(isPresented: $showJoinSheet) {
            JoinByCodeView()
        }
        .navigationDestination(for: Space.self) { space in
            SpaceDetailView(space: space)
        }
    }
}

// MARK: - 공유방 행
struct SpaceRowView: View {
    let space: Space

    var body: some View {
        HStack {
            Circle()
                .fill(Color(hex: space.colorHex))
                .frame(width: 12, height: 12)
            Text(space.name)
            Spacer()
            Text("\(space.todos.filter { !$0.isCompleted }.count)")
                .font(SketchTheme.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - 공유방 생성
struct CreateSpaceView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var colorHex = "#5E5CE6"

    let palette = ["#5E5CE6", "#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4", "#FFEAA7"]

    var body: some View {
        NavigationStack {
            Form {
                Section("이름") {
                    TextField("공유방 이름", text: $name)
                }
                Section("색상") {
                    LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 6)) {
                        ForEach(palette, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 36, height: 36)
                                .overlay {
                                    if colorHex == hex {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.white)
                                            .fontWeight(.bold)
                                    }
                                }
                                .onTapGesture { colorHex = hex }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("새 공유방")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("만들기") { create() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func create() {
        let space = Space(name: name.trimmingCharacters(in: .whitespaces), colorHex: colorHex)
        context.insert(space)
        dismiss()
    }
}

// MARK: - CloudKit 공유 관리
public final class SpaceSharingManager {
    private let container = CKContainer.default()

    public init() {}

    public func share(_ space: Space) async throws -> CKShare {
        let record = CKRecord(recordType: "Space")
        record["name"] = space.name as CKRecordValue

        let share = CKShare(rootRecord: record)
        share[CKShare.SystemFieldKey.title] = space.name as CKRecordValue
        share.publicPermission = .none

        try await container.privateCloudDatabase.modifyRecords(saving: [record, share], deleting: [])
        return share
    }
}

// MARK: - Color hex 헬퍼
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
