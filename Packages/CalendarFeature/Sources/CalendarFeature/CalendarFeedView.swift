import SwiftUI
import SwiftData
import SharedModels
import TodoFeature

// MARK: - 달력 + 피드 메인 뷰
public struct CalendarFeedView: View {
    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var showMonthGrid = false

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // H2: 주간 스트립 ↔ 월간 그리드 전환
            if showMonthGrid {
                MonthCalendarView(selectedDate: $selectedDate)
                    .padding(.vertical, 8)
            } else {
                WeekStripView(selectedDate: $selectedDate)
                    .padding(.vertical, 8)
                    // H2: 길게 눌러서도 전환 가능
                    .onLongPressGesture { withAnimation { showMonthGrid = true } }
            }
            Divider()
            // H1: 상대 날짜 섹션 피드
            DayFeedView(selectedDate: selectedDate)
        }
        .navigationTitle("캘린더")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation { showMonthGrid.toggle() }
                } label: {
                    Image(systemName: showMonthGrid ? "calendar.day.timeline.left" : "calendar")
                }
                .accessibilityLabel(showMonthGrid ? "주간 보기" : "월간 보기")
            }
        }
    }
}

// MARK: - 주간 날짜 스트립
struct WeekStripView: View {
    @Binding var selectedDate: Date
    @State private var weekOffset: Int = 0

    // 점 표시용: 날짜만 정렬해서 받아오고, 날짜별 매핑은 메모리에서 처리한다.
    @Query(sort: \TodoItem.dueDate) private var todos: [TodoItem]

    private var weekDates: [Date] {
        let cal = Calendar.current
        let base = cal.date(byAdding: .weekOfYear, value: weekOffset, to: Date()) ?? Date()
        // 월간 그리드와 동일하게 일요일 시작으로 고정 (locale firstWeekday 무시)
        let startOfBaseDay = cal.startOfDay(for: base)
        let weekdayIndex = cal.component(.weekday, from: startOfBaseDay) - 1 // 0=일
        let startOfWeek = cal.date(byAdding: .day, value: -weekdayIndex, to: startOfBaseDay) ?? startOfBaseDay
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: startOfWeek) }
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(weekDates, id: \.self) { date in
                    DayCell(
                        date: date,
                        isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                        dotColors: dotColors(for: date)
                    )
                    .onTapGesture { selectedDate = Calendar.current.startOfDay(for: date) }
                }
            }
            .padding(.horizontal)
        }
        .gesture(DragGesture().onEnded { value in
            weekOffset += value.translation.width < 0 ? 1 : -1
        })
    }

    // H3: 해당 날짜에 마감인 투두들의 공유방 색을 점으로
    private func dotColors(for date: Date) -> [Color] {
        FeedHelpers.dotColors(for: date, in: todos)
    }
}

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    var dotColors: [Color] = []

    private var isToday: Bool { Calendar.current.isDateInToday(date) }

    var body: some View {
        VStack(spacing: 4) {
            Text(date.formatted(.dateTime.weekday(.narrow)))
                .font(SketchTheme.caption)
                .foregroundStyle(.secondary)
            Text(date.formatted(.dateTime.day()))
                .font(.subheadline.weight(isToday ? .bold : .regular))
                .frame(width: 32, height: 32)
                .background(isSelected ? Color.blue : Color.clear, in: Circle())
                .foregroundStyle(isSelected ? .white : isToday ? .blue : .primary)
            DotRow(colors: dotColors)
                .frame(height: 6)
        }
        .frame(width: 40)
    }
}

// MARK: - 점 인디케이터 (최대 3개 표시)
struct DotRow: View {
    let colors: [Color]

    var body: some View {
        HStack(spacing: 2) {
            ForEach(Array(colors.prefix(3).enumerated()), id: \.offset) { _, color in
                Circle()
                    .fill(color)
                    .frame(width: 5, height: 5)
            }
        }
    }
}

// MARK: - H2: 월간 달력 그리드
struct MonthCalendarView: View {
    @Binding var selectedDate: Date
    @State private var monthAnchor: Date = Calendar.current.startOfDay(for: Date())

    @Query(sort: \TodoItem.dueDate) private var todos: [TodoItem]

    private let weekdaySymbols = ["일", "월", "화", "수", "목", "금", "토"]

    var body: some View {
        VStack(spacing: 8) {
            // 월 이동 헤더
            HStack {
                Button { shiftMonth(-1) } label: { Image(systemName: "chevron.left") }
                Spacer()
                Text(monthAnchor.formatted(.dateTime.year().month()))
                    .font(SketchTheme.headline)
                Spacer()
                Button { shiftMonth(1) } label: { Image(systemName: "chevron.right") }
            }
            .padding(.horizontal)

            // 요일 헤더
            HStack(spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { sym in
                    Text(sym)
                        .font(SketchTheme.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 4)

            // 날짜 그리드
            let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(Array(monthGridDates.enumerated()), id: \.offset) { _, day in
                    if let day {
                        MonthDayCell(
                            date: day,
                            isSelected: Calendar.current.isDate(day, inSameDayAs: selectedDate),
                            dotColors: FeedHelpers.dotColors(for: day, in: todos)
                        )
                        .onTapGesture { selectedDate = Calendar.current.startOfDay(for: day) }
                    } else {
                        Color.clear.frame(height: 44)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .gesture(DragGesture().onEnded { value in
            shiftMonth(value.translation.width < 0 ? 1 : -1)
        })
    }

    private func shiftMonth(_ delta: Int) {
        let cal = Calendar.current
        if let new = cal.date(byAdding: .month, value: delta, to: monthAnchor) {
            monthAnchor = new
        }
    }

    // 월 그리드: 앞쪽 빈칸(nil) + 실제 날짜. 일요일 시작 기준.
    private var monthGridDates: [Date?] {
        let cal = Calendar.current
        guard
            let monthInterval = cal.dateInterval(of: .month, for: monthAnchor),
            let range = cal.range(of: .day, in: .month, for: monthAnchor)
        else { return [] }

        let firstDay = monthInterval.start
        // weekday: 1=일 ... 7=토 → 앞쪽 빈칸 수 = weekday-1
        let leadingBlanks = cal.component(.weekday, from: firstDay) - 1

        var cells: [Date?] = Array(repeating: nil, count: leadingBlanks)
        for offset in 0..<range.count {
            if let d = cal.date(byAdding: .day, value: offset, to: firstDay) {
                cells.append(d)
            }
        }
        return cells
    }
}

struct MonthDayCell: View {
    let date: Date
    let isSelected: Bool
    let dotColors: [Color]

    private var isToday: Bool { Calendar.current.isDateInToday(date) }

    var body: some View {
        VStack(spacing: 2) {
            Text(date.formatted(.dateTime.day()))
                .font(.subheadline.weight(isToday ? .bold : .regular))
                .frame(width: 30, height: 30)
                .background(isSelected ? Color.blue : Color.clear, in: Circle())
                .foregroundStyle(isSelected ? .white : isToday ? .blue : .primary)
            DotRow(colors: dotColors)
                .frame(height: 6)
        }
        .frame(height: 44)
        .contentShape(Rectangle())
    }
}

// MARK: - H1: 상대 날짜 섹션 피드
struct DayFeedView: View {
    let selectedDate: Date

    // 옵셔널 dueDate를 #Predicate에서 다루지 않기 위해 전체를 정렬만 해서 가져오고,
    // 섹션 분류·필터는 모두 메모리에서 처리한다.
    @Query(sort: \TodoItem.dueDate) private var todos: [TodoItem]

    var body: some View {
        let sections = FeedHelpers.sections(for: todos, selectedDate: selectedDate)

        List {
            if sections.allSatisfy({ $0.items.isEmpty }) {
                ContentUnavailableView("할 일 없음", systemImage: "checkmark.circle")
            } else {
                ForEach(sections) { section in
                    if !section.items.isEmpty {
                        Section {
                            ForEach(section.items) { todo in
                                FeedRowView(todo: todo, isOverdue: section.kind == .overdue)
                            }
                        } header: {
                            Text(section.kind.title)
                                .foregroundStyle(section.kind == .overdue ? Color.red : .secondary)
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - 피드 행 (공유방 색 점 + 마감 강조)
struct FeedRowView: View {
    let todo: TodoItem
    let isOverdue: Bool

    var body: some View {
        HStack(spacing: 8) {
            // H3: 공유방 색 점
            if let space = todo.space {
                Circle()
                    .fill(Color(hex: space.colorHex))
                    .frame(width: 8, height: 8)
            } else {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 8, height: 8)
            }
            TodoRowView(todo: todo)
        }
        .listRowBackground(
            isOverdue
                ? RuledRowBackground(seed: todo.id.hashValue, paperColor: Color.red.opacity(0.05))
                : RuledRowBackground(seed: todo.id.hashValue)
        )
    }
}

// MARK: - 피드 분류 헬퍼 (테스트 가능하도록 분리)
enum FeedHelpers {
    enum SectionKind: Int {
        case overdue, today, tomorrow, thisWeek

        var title: String {
            switch self {
            case .overdue: return "마감 지남"
            case .today: return "오늘"
            case .tomorrow: return "내일"
            case .thisWeek: return "이번 주"
            }
        }
    }

    struct FeedSection: Identifiable {
        let kind: SectionKind
        let items: [TodoItem]
        var id: Int { kind.rawValue }
    }

    /// 선택한 날짜를 기준 "오늘"로 삼아 상대 섹션을 구성한다.
    /// - 마감 지남: 선택일 이전 마감의 미완료 항목
    /// - 오늘 / 내일: 해당 일자 마감 항목
    /// - 이번 주: 선택일 다음 주말까지(모레~주말) 마감 항목
    static func sections(for todos: [TodoItem], selectedDate: Date) -> [FeedSection] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: selectedDate)
        guard
            let tomorrow = cal.date(byAdding: .day, value: 1, to: today),
            let dayAfter = cal.date(byAdding: .day, value: 2, to: today)
        else { return [] }

        // 선택일이 속한 주의 마지막 날 다음(주 경계). 주 시작은 일요일 기준.
        let weekEndExclusive: Date = {
            if let interval = cal.dateInterval(of: .weekOfYear, for: today) {
                // interval.end는 다음 주 시작(배타적 상한)
                return interval.end
            }
            return cal.date(byAdding: .day, value: 7, to: today) ?? today
        }()

        var overdue: [TodoItem] = []
        var todayItems: [TodoItem] = []
        var tomorrowItems: [TodoItem] = []
        var thisWeek: [TodoItem] = []

        for todo in todos {
            guard let due = todo.dueDate else { continue }
            let dueDay = cal.startOfDay(for: due)

            if dueDay < today {
                if !todo.isCompleted { overdue.append(todo) }
            } else if dueDay == today {
                todayItems.append(todo)
            } else if dueDay == tomorrow {
                tomorrowItems.append(todo)
            } else if dueDay >= dayAfter && dueDay < weekEndExclusive {
                thisWeek.append(todo)
            }
        }

        return [
            FeedSection(kind: .overdue, items: overdue),
            FeedSection(kind: .today, items: todayItems),
            FeedSection(kind: .tomorrow, items: tomorrowItems),
            FeedSection(kind: .thisWeek, items: thisWeek),
        ]
    }

    /// 특정 날짜에 마감인 투두들의 공유방 색 목록(중복 제거, 정렬 안정).
    static func dotColors(for date: Date, in todos: [TodoItem]) -> [Color] {
        let cal = Calendar.current
        var seenHex: [String] = []
        var hasUncolored = false
        for todo in todos {
            guard let due = todo.dueDate, cal.isDate(due, inSameDayAs: date) else { continue }
            if let hex = todo.space?.colorHex {
                if !seenHex.contains(hex) { seenHex.append(hex) }
            } else {
                hasUncolored = true
            }
        }
        var colors = seenHex.map { Color(hex: $0) }
        if colors.isEmpty && hasUncolored {
            colors.append(.gray)
        }
        return colors
    }
}

// MARK: - H3: Color(hex:) 헬퍼 (SpaceFeature의 private 버전 접근 불가 → 로컬 정의)
extension Color {
    init(hex: String) {
        let trimmed = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var int: UInt64 = 0
        Scanner(string: trimmed).scanHexInt64(&int)
        let r, g, b, a: UInt64
        switch trimmed.count {
        case 3: // RGB (12-bit)
            (r, g, b, a) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17, 255)
        case 6: // RGB (24-bit)
            (r, g, b, a) = (int >> 16, int >> 8 & 0xFF, int & 0xFF, 255)
        case 8: // ARGB (32-bit)
            (r, g, b, a) = (int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF, int >> 24)
        default:
            (r, g, b, a) = (94, 92, 230, 255) // 기본값 #5E5CE6
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - H4: Preview
#if DEBUG
@MainActor
private func makePreviewContainer() -> ModelContainer {
    let container = try! ModelContainer(
        for: TodoItem.self, Space.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let ctx = container.mainContext
    let cal = Calendar.current
    let today = cal.startOfDay(for: Date())

    let work = Space(name: "회사", colorHex: "#FF3B30")
    let home = Space(name: "집", colorHex: "#34C759")
    ctx.insert(work)
    ctx.insert(home)

    func todo(_ title: String, dayOffset: Int, space: Space?, done: Bool = false) {
        let t = TodoItem(title: title, space: space)
        t.dueDate = cal.date(byAdding: .day, value: dayOffset, to: today)
        if done {
            t.isCompleted = true
            t.completedAt = Date()
            t.status = .completed
        }
        ctx.insert(t)
    }

    todo("지난 회의록 정리", dayOffset: -2, space: work)          // 마감 지남
    todo("어제 빨래", dayOffset: -1, space: home)                  // 마감 지남
    todo("이미 끝낸 일", dayOffset: -1, space: home, done: true)   // 마감 지남이지만 완료 → 제외
    todo("오늘 장보기", dayOffset: 0, space: home)                 // 오늘
    todo("오늘 보고서", dayOffset: 0, space: work)                 // 오늘
    todo("개인 운동", dayOffset: 0, space: nil)                    // 오늘(공유방 없음)
    todo("내일 발표 준비", dayOffset: 1, space: work)              // 내일
    todo("주말 청소", dayOffset: 3, space: home)                   // 이번 주(가능)

    return container
}

#Preview("주간 + 피드") {
    NavigationStack {
        CalendarFeedView()
    }
    .modelContainer(makePreviewContainer())
}

#Preview("월간 그리드") {
    MonthCalendarView(selectedDate: .constant(Calendar.current.startOfDay(for: Date())))
        .modelContainer(makePreviewContainer())
}
#endif
