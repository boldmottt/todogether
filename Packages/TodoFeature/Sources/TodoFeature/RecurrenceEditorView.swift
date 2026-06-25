import SwiftUI
import SharedModels

// MARK: - 반복 편집 (B1, B2)
public struct RecurrenceEditorView: View {
    @Binding var rule: RecurrenceRule?
    @Environment(\.dismiss) private var dismiss

    // 편집용 로컬 상태
    @State private var enabled: Bool
    @State private var frequency: RecurrenceFrequency
    @State private var interval: Int
    @State private var weekdays: Set<Int>
    @State private var monthDay: Int
    @State private var hasEndDate: Bool
    @State private var endDate: Date

    public init(rule: Binding<RecurrenceRule?>) {
        _rule = rule
        let r = rule.wrappedValue
        _enabled = State(initialValue: r != nil)
        _frequency = State(initialValue: r?.frequency ?? .weekly)
        _interval = State(initialValue: r?.interval ?? 1)
        _weekdays = State(initialValue: Set(r?.weekdays ?? []))
        _monthDay = State(initialValue: r?.monthDay ?? 1)
        _hasEndDate = State(initialValue: r?.endDate != nil)
        _endDate = State(initialValue: r?.endDate ?? Date())
    }

    public var body: some View {
        Form {
            Section {
                Toggle("반복", isOn: $enabled.animation())
            }

            if enabled {
                Section("주기") {
                    Picker("반복 기준", selection: $frequency) {
                        Text("매일").tag(RecurrenceFrequency.daily)
                        Text("매주").tag(RecurrenceFrequency.weekly)
                        Text("매월").tag(RecurrenceFrequency.monthly)
                        Text("매년").tag(RecurrenceFrequency.yearly)
                        Text("완료 후").tag(RecurrenceFrequency.afterCompletion)
                    }
                    Stepper("간격: \(interval)\(intervalUnit)", value: $interval, in: 1...30)
                }

                // B2: 요일 선택 (weekly)
                if frequency == .weekly {
                    Section("요일") {
                        WeekdaySelector(selected: $weekdays)
                    }
                }

                // B2: 일자 선택 (monthly)
                if frequency == .monthly {
                    Section("날짜") {
                        Picker("매월", selection: $monthDay) {
                            ForEach(1...31, id: \.self) { Text("\($0)일").tag($0) }
                        }
                    }
                }

                Section {
                    Toggle("종료일", isOn: $hasEndDate.animation())
                    if hasEndDate {
                        DatePicker("종료", selection: $endDate, displayedComponents: .date)
                    }
                } footer: {
                    Text(previewText)
                }
            }
        }
        .sketchForm()
        .navigationTitle("반복")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("완료") { apply(); dismiss() }
            }
        }
    }

    private var intervalUnit: String {
        switch frequency {
        case .daily, .afterCompletion: return "일"
        case .weekly: return "주"
        case .monthly: return "개월"
        case .yearly: return "년"
        }
    }

    private var previewText: String {
        guard enabled else { return "반복 안 함" }
        return buildRule().displayText
    }

    private func buildRule() -> RecurrenceRule {
        var r = RecurrenceRule(frequency: frequency, interval: interval)
        r.weekdays = frequency == .weekly && !weekdays.isEmpty ? Array(weekdays) : nil
        r.monthDay = frequency == .monthly ? monthDay : nil
        r.endDate = hasEndDate ? endDate : nil
        return r
    }

    private func apply() {
        rule = enabled ? buildRule() : nil
    }
}

// MARK: - 요일 선택기
struct WeekdaySelector: View {
    @Binding var selected: Set<Int>
    private let weekdays = Array(1...7) // 1=일 ... 7=토

    var body: some View {
        HStack(spacing: 6) {
            ForEach(weekdays, id: \.self) { day in
                let isOn = selected.contains(day)
                Button {
                    if isOn { selected.remove(day) } else { selected.insert(day) }
                } label: {
                    Text(RecurrenceRule.weekdayShortName(day))
                        .font(.subheadline.weight(.medium))
                        .frame(width: 36, height: 36)
                        .background(isOn ? Color.accentColor : Color.secondary.opacity(0.15), in: Circle())
                        .foregroundStyle(isOn ? .white : .primary)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview("반복 편집") {
    struct Wrap: View {
        @State var rule: RecurrenceRule? = {
            var r = RecurrenceRule(frequency: .weekly, interval: 1)
            r.weekdays = [2, 4, 6]
            return r
        }()
        var body: some View { NavigationStack { RecurrenceEditorView(rule: $rule) } }
    }
    return Wrap()
}
