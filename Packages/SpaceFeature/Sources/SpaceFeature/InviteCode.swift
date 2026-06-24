import SwiftUI
import SwiftData
import SharedModels

// MARK: - 초대 코드 관리
// 6자리 영숫자 코드를 생성하고 UserDefaults에 저장한다.
// 실제 프로덕션에서는 CloudKit Public Database에 저장해야 함.
public enum InviteCodeStore {
    private static let udKey = "inviteCodes"   // [code: spaceIDString]

    public static func generate(for space: Space) -> String {
        var dict = load()
        // 충돌 방지: 이미 존재하는 코드가 나오면 재생성
        var code = randomCode()
        while dict[code] != nil { code = randomCode() }
        dict[code] = space.id.uuidString
        save(dict)
        return code
    }

    /// 기존에 발급된 코드가 있으면 반환, 없으면 새로 발급
    public static func code(for space: Space) -> String {
        let dict = load()
        if let existing = dict.first(where: { $0.value == space.id.uuidString })?.key {
            return existing
        }
        return generate(for: space)
    }

    public static func spaceID(for code: String) -> UUID? {
        guard let str = load()[code.uppercased()] else { return nil }
        return UUID(uuidString: str)
    }

    // MARK: - Private
    private static func load() -> [String: String] {
        (UserDefaults.standard.dictionary(forKey: udKey) as? [String: String]) ?? [:]
    }

    private static func save(_ dict: [String: String]) {
        UserDefaults.standard.set(dict, forKey: udKey)
    }

    private static func randomCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"  // 혼동 문자(0/O/1/I) 제외
        return String((0..<6).map { _ in chars.randomElement() ?? "A" })
    }
}

// MARK: - 초대 코드 표시 뷰 (공유방 상세에 삽입)
public struct InviteCodeSection: View {
    let space: Space
    @State private var code: String = ""
    @State private var copied = false

    public init(space: Space) { self.space = space }

    public var body: some View {
        Section("초대 코드") {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 0) {
                    // 6자리 코드를 3+3으로 끊어 표시
                    let parts = codeParts
                    Text(parts.0)
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundStyle(.primary)
                    Text(" - ")
                        .font(.system(size: 24, weight: .light, design: .monospaced))
                        .foregroundStyle(.secondary)
                    Text(parts.1)
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundStyle(.primary)
                    Spacer()
                    Button {
                        UIPasteboard.general.string = code
                        withAnimation { copied = true }
                        Task {
                            try? await Task.sleep(for: .seconds(2))
                            withAnimation { copied = false }
                        }
                    } label: {
                        Image(systemName: copied ? "checkmark.circle.fill" : "doc.on.doc")
                            .foregroundStyle(copied ? .green : .blue)
                    }
                    .buttonStyle(.plain)
                }

                Text("이 코드를 멤버에게 알려주세요. 코드로 공유방에 바로 참여할 수 있어요.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)

            // 공유 시트 버튼
            ShareLink(item: shareText) {
                Label("초대 링크 공유", systemImage: "square.and.arrow.up")
            }
        }
        .onAppear { code = InviteCodeStore.code(for: space) }
    }

    private var codeParts: (String, String) {
        guard code.count == 6 else { return (code, "") }
        let mid = code.index(code.startIndex, offsetBy: 3)
        return (String(code[..<mid]), String(code[mid...]))
    }

    private var shareText: String {
        "todogether 공유방 '\(space.name)'에 초대받았어요!\n초대 코드: \(code)\ntodogether 앱에서 [코드로 참여]를 눌러 입력하세요."
    }
}

// MARK: - 코드로 참여하기 시트
public struct JoinByCodeView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var allSpaces: [Space]

    @State private var code = ""
    @State private var errorMessage: String?
    @State private var joined = false

    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("초대 코드 입력 (예: ABC-DEF)", text: $code)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .font(.system(.body, design: .monospaced))
                        .onChange(of: code) { _, v in
                            // 자동 대문자 + 하이픈 제거
                            code = v.uppercased().filter { $0 != "-" }
                            if code.count > 6 { code = String(code.prefix(6)) }
                        }
                } header: {
                    Text("초대 코드")
                } footer: {
                    if let err = errorMessage {
                        Text(err).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("코드로 참여")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("참여") { join() }
                        .disabled(code.count < 6)
                }
            }
            .alert("참여 완료!", isPresented: $joined) {
                Button("확인") { dismiss() }
            } message: {
                Text("공유방에 참여했어요.")
            }
        }
    }

    private func join() {
        let clean = code.uppercased()
        guard let spaceID = InviteCodeStore.spaceID(for: clean) else {
            errorMessage = "유효하지 않은 코드예요. 다시 확인해주세요."
            return
        }

        // 이미 참여한 공유방인지 확인
        if allSpaces.contains(where: { $0.id == spaceID }) {
            errorMessage = "이미 참여한 공유방이에요."
            return
        }

        // TODO: 크로스 디바이스 참여는 CloudKit Public Database 조회 필요.
        // 현재는 같은 기기에서 생성된 코드만 동작 (로컬 UserDefaults 기반).
        // 다른 기기의 코드는 아직 지원하지 않으므로 명확한 안내를 표시.
        errorMessage = "이 기기에서 생성되지 않은 코드는 아직 지원되지 않아요.\nCloudKit 연동 후 지원 예정입니다."
    }
}
