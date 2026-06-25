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
        .sketchForm()
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
                        .foregroundStyle(SketchTheme.Color.ink)
                }
            }
        }
    }

    private func isSelected(_ preset: RecurrenceRule) -> Bool {
        guard let rule else { return false }
        return rule.frequency == preset.frequency && rule.interval == preset.interval
    }
}

// 반복 요약 텍스트(displayText)는 SharedModels.RecurrenceRule로 이동 — 양 패키지 공용.
