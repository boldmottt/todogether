import SwiftUI
import SwiftData
import SharedModels
import TodoFeature

// MARK: - 달력 + 피드 메인 뷰
public struct CalendarFeedView: View {
    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            WeekStripView(selectedDate: $selectedDate)
                .padding(.vertical, 8)
            Divider()
            DayFeedView(date: selectedDate)
        }
        .navigationTitle("캘린더")
    }
}

// MARK: - 주간 날짜 스트립
struct WeekStripView: View {
    @Binding var selectedDate: Date
    @State private var weekOffset: Int = 0

    private var weekDates: [Date] {
        let base = Calendar.current.date(byAdding: .weekOfYear, value: weekOffset, to: Date()) ?? Date()
        let startOfWeek = Calendar.current.date(
            from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: base)
        ) ?? base
        return (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: startOfWeek) }
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(weekDates, id: \.self) { date in
                    DayCell(date: date, isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate))
                        .onTapGesture { selectedDate = date }
                }
            }
            .padding(.horizontal)
        }
        .gesture(DragGesture().onEnded { value in
            weekOffset += value.translation.width < 0 ? 1 : -1
        })
    }
}

struct DayCell: View {
    let date: Date
    let isSelected: Bool

    private var isToday: Bool { Calendar.current.isDateInToday(date) }

    var body: some View {
        VStack(spacing: 4) {
            Text(date.formatted(.dateTime.weekday(.narrow)))
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(date.formatted(.dateTime.day()))
                .font(.subheadline.weight(isToday ? .bold : .regular))
                .frame(width: 32, height: 32)
                .background(isSelected ? Color.blue : Color.clear, in: Circle())
                .foregroundStyle(isSelected ? .white : isToday ? .blue : .primary)
        }
        .frame(width: 40)
    }
}

// MARK: - 선택된 날짜의 투두 피드
struct DayFeedView: View {
    let date: Date

    private var startOfDay: Date { Calendar.current.startOfDay(for: date) }
    private var endOfDay: Date { Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay }

    @Query private var todos: [TodoItem]

    init(date: Date) {
        self.date = date
        let start = Calendar.current.startOfDay(for: date)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? start
        _todos = Query(
            filter: #Predicate { todo in
                (todo.dueDate ?? Date.distantFuture) >= start &&
                (todo.dueDate ?? Date.distantFuture) < end
            },
            sort: \.dueDate
        )
    }

    var body: some View {
        List {
            if todos.isEmpty {
                ContentUnavailableView("할 일 없음", systemImage: "checkmark.circle")
            } else {
                ForEach(todos) { todo in
                    TodoRowView(todo: todo)
                }
            }
        }
        .listStyle(.plain)
    }
}
