import SwiftUI
import SwiftData
import SharedModels

// MARK: - 반응 히스토리 (D3) — 이번 주 서로의 기여/반응 가시화
public struct ReactionHistoryView: View {
    @Query private var reactions: [Reaction]

    public init() {
        // 이번 주 반응만: 전체를 시간순으로 가져와 메모리에서 주간 필터
        _reactions = Query(sort: \Reaction.createdAt, order: .reverse)
    }

    private var thisWeek: [Reaction] {
        let cal = Calendar.current
        guard let weekStart = cal.dateInterval(of: .weekOfYear, for: Date())?.start else { return [] }
        return reactions.filter { $0.createdAt >= weekStart }
    }

    // 사람별 받은/보낸 반응 집계
    private var byAuthor: [(name: String, emojiCounts: [(emoji: String, count: Int)])] {
        var dict: [String: [String: Int]] = [:]
        for r in thisWeek {
            dict[r.authorName, default: [:]][r.emoji, default: 0] += 1
        }
        return dict
            .map { (name, counts) in
                let sorted = Reaction.availableEmojis.compactMap { e -> (String, Int)? in
                    guard let c = counts[e], c > 0 else { return nil }
                    return (e, c)
                }
                return (name: name, emojiCounts: sorted)
            }
            .sorted { $0.emojiCounts.reduce(0) { $0 + $1.count } > $1.emojiCounts.reduce(0) { $0 + $1.count } }
    }

    public var body: some View {
        List {
            if thisWeek.isEmpty {
                ContentUnavailableView(
                    "이번 주 반응이 없어요",
                    systemImage: "hands.clap",
                    description: Text("완료된 할 일에 반응을 남겨보세요")
                )
            } else {
                Section("이번 주 반응") {
                    ForEach(byAuthor, id: \.name) { author in
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundStyle(.secondary)
                            Text(author.name)
                            Spacer()
                            HStack(spacing: 8) {
                                ForEach(author.emojiCounts, id: \.emoji) { item in
                                    HStack(spacing: 2) {
                                        Text(item.emoji)
                                        Text("\(item.count)")
                                            .font(.caption.weight(.medium))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("반응")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("반응 히스토리") {
    let container = try! ModelContainer(
        for: Reaction.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let ctx = container.mainContext
    let todoID = UUID()
    [("민지", "👍"), ("민지", "❤️"), ("지호", "🎉"), ("민지", "👍")].forEach {
        ctx.insert(Reaction(todoID: todoID, authorID: $0.0, authorName: $0.0, emoji: $0.1))
    }
    return NavigationStack { ReactionHistoryView() }
        .modelContainer(container)
}
