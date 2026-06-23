import SwiftUI
import SharedModels

// MARK: - 반복 규칙 선택 UI
public struct RecurrencePickerView: View {
    @Binding public var rule: RecurrenceRule?

    public init(rule: Binding<RecurrenceRule?>) {
        _rule = rule
    }

    public var body: some View {
        List {
            Section {
                Button("반복 없음") { rule = nil }
                    .foregroundStyle(rule == nil ? .primary : .secondary)
            }
            Section("자주 쓰는 옵션") {
                presetRow("매일", RecurrenceRule(frequency: .daily, interval: 1))
                presetRow("매주", RecurrenceRule(frequency: .weekly, interval: 1))
                presetRow("격주", RecurrenceRule(frequency: .weekly, interval: 2))
                presetRow("매월", RecurrenceRule(frequency: .monthly, interval: 1))
                presetRow("완료 후 1일", RecurrenceRule(frequency: .afterCompletion, interval: 1))
                presetRow("완료 후 3일", RecurrenceRule(frequency: .afterCompletion, interval: 3))
                presetRow("완료 후 7일", RecurrenceRule(frequency: .afterCompletion, interval: 7))
            }
        }
        .navigationTitle("반복")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func presetRow(_ label: String, _ preset: RecurrenceRule) -> some View {
        Button {
            rule = preset
        } label: {
            HStack {
                Text(label)
                    .foregroundStyle(.primary)
                Spacer()
                if isSelected(preset) {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.blue)
                }
            }
        }
    }

    private func isSelected(_ preset: RecurrenceRule) -> Bool {
        guard let rule else { return false }
        return rule.frequency == preset.frequency && rule.interval == preset.interval
    }
}

// MARK: - 반복 요약 텍스트
public extension RecurrenceRule {
    var displayText: String {
        switch frequency {
        case .daily:
            return interval == 1 ? "매일" : "\(interval)일마다"
        case .weekly:
            return interval == 1 ? "매주" : "\(interval)주마다"
        case .monthly:
            return interval == 1 ? "매월" : "\(interval)개월마다"
        case .yearly:
            return interval == 1 ? "매년" : "\(interval)년마다"
        case .afterCompletion:
            return "완료 후 \(interval)일"
        }
    }
}
