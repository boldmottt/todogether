import SwiftUI
import SwiftData
import SharedModels

// MARK: - 이모지 반응 피커 (길게 탭 시 나타나는 버블)
public struct ReactionPicker: View {
    let todo: TodoItem
    let currentUserID: String
    let currentUserName: String
    @Environment(\.modelContext) private var context
    @Binding var isPresented: Bool

    public init(
        todo: TodoItem,
        currentUserID: String,
        currentUserName: String,
        isPresented: Binding<Bool>
    ) {
        self.todo = todo
        self.currentUserID = currentUserID
        self.currentUserName = currentUserName
        _isPresented = isPresented
    }

    public var body: some View {
        HStack(spacing: 4) {
            ForEach(Reaction.availableEmojis, id: \.self) { emoji in
                EmojiButton(
                    emoji: emoji,
                    isSelected: hasReacted(emoji: emoji)
                ) {
                    toggleReaction(emoji: emoji)
                    isPresented = false
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.regularMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
    }

    private func hasReacted(emoji: String) -> Bool {
        existingReaction(emoji: emoji) != nil
    }

    private func existingReaction(emoji: String) -> Reaction? {
        let todoID = todo.id
        let descriptor = FetchDescriptor<Reaction>(
            filter: #Predicate {
                $0.todoID == todoID &&
                $0.authorID == currentUserID &&
                $0.emoji == emoji
            }
        )
        return try? context.fetch(descriptor).first
    }

    private func toggleReaction(emoji: String) {
        if let existing = existingReaction(emoji: emoji) {
            context.delete(existing)
        } else {
            let reaction = Reaction(
                todoID: todo.id,
                authorID: currentUserID,
                authorName: currentUserName,
                emoji: emoji
            )
            context.insert(reaction)
        }
    }
}

// MARK: - 개별 이모지 버튼
private struct EmojiButton: View {
    let emoji: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(emoji)
                .font(SketchTheme.headline)
                .frame(width: 44, height: 44)
                .background(
                    isSelected ? Color.blue.opacity(0.15) : Color.clear,
                    in: Circle()
                )
                .scaleEffect(isSelected ? 1.15 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 반응 요약 뷰 (투두 행 하단)
public struct ReactionSummaryView: View {
    let todoID: UUID
    let currentUserID: String
    @Query private var reactions: [Reaction]

    public init(todoID: UUID, currentUserID: String) {
        self.todoID = todoID
        self.currentUserID = currentUserID
        _reactions = Query(
            filter: #Predicate { $0.todoID == todoID },
            sort: \.createdAt
        )
    }

    // 이모지별 그룹: ["👍": [Reaction, ...], ...]
    private var grouped: [(emoji: String, reactions: [Reaction])] {
        var dict: [String: [Reaction]] = [:]
        for r in reactions {
            dict[r.emoji, default: []].append(r)
        }
        return Reaction.availableEmojis
            .compactMap { emoji in
                guard let group = dict[emoji], !group.isEmpty else { return nil }
                return (emoji: emoji, reactions: group)
            }
    }

    public var body: some View {
        if !grouped.isEmpty {
            HStack(spacing: 4) {
                ForEach(grouped, id: \.emoji) { item in
                    ReactionBubble(
                        emoji: item.emoji,
                        count: item.reactions.count,
                        names: item.reactions.map(\.authorName),
                        isMine: item.reactions.contains { $0.authorID == currentUserID }
                    )
                }
                Spacer()
            }
            .padding(.leading, 36) // 체크버튼 너비만큼 들여쓰기
        }
    }
}

// MARK: - 개별 반응 버블
private struct ReactionBubble: View {
    let emoji: String
    let count: Int
    let names: [String]
    let isMine: Bool
    @State private var showTooltip = false

    var body: some View {
        Button {
            showTooltip.toggle()
        } label: {
            HStack(spacing: 3) {
                Text(emoji)
                    .font(SketchTheme.caption)
                if count > 1 {
                    Text("\(count)")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(isMine ? .white : .primary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                isMine ? Color.blue : Color.secondary.opacity(0.12),
                in: Capsule()
            )
            .foregroundStyle(isMine ? .white : .primary)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showTooltip) {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(names, id: \.self) { name in
                    Text(name)
                        .font(SketchTheme.body)
                }
            }
            .padding(12)
            .presentationCompactAdaptation(.popover)
        }
    }
}

// MARK: - 반응 포함 투두 행 래퍼
public struct ReactableTodoRow: View {
    let todo: TodoItem
    let currentUserID: String
    let currentUserName: String
    @State private var showReactionPicker = false

    public init(todo: TodoItem, currentUserID: String, currentUserName: String) {
        self.todo = todo
        self.currentUserID = currentUserID
        self.currentUserName = currentUserName
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            TodoRowView(todo: todo)

            // 공유방 투두이고 완료된 것만 반응 표시
            if todo.space != nil && todo.isCompleted {
                ReactionSummaryView(todoID: todo.id, currentUserID: currentUserID)
            }
        }
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 0.4) {
            guard todo.space != nil && todo.isCompleted else { return }
            withAnimation(.spring(response: 0.3)) {
                showReactionPicker = true
            }
        }
        .overlay(alignment: .bottom) {
            if showReactionPicker {
                ReactionPicker(
                    todo: todo,
                    currentUserID: currentUserID,
                    currentUserName: currentUserName,
                    isPresented: $showReactionPicker
                )
                .offset(y: -50)
                .transition(.scale(scale: 0.8).combined(with: .opacity))
                .zIndex(1)
            }
        }
        .onChange(of: showReactionPicker) { _, isShowing in
            // 피커가 열리면 2초 후 자동으로 닫힘 (강요 아님)
            if isShowing {
                Task {
                    try? await Task.sleep(for: .seconds(2))
                    if showReactionPicker {
                        withAnimation { showReactionPicker = false }
                    }
                }
            }
        }
    }
}
