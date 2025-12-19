import SwiftUI
import AppKit


struct CalendarPopoverView: View {
    @State private var displayedMonth: Date = Date()
    @State private var monthChangeDirection: Int = 0
    @Environment(\.openSettings) private var openSettings
    @State private var settingsFlash = false
    @State private var settingsHover = false
    @Environment(\.openWindow) private var openWindow
   

    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale.current
        cal.timeZone = .current
        cal.firstWeekday = 2
        return cal
    }
    
    
struct IconButton: View {
        let systemName: String
        let action: () -> Void

        @State private var isPressed = false

        var body: some View {
            Button(action: action) {
                Image(systemName: systemName)
                    .font(.title3)
                    .padding(6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isPressed ? Color.secondary.opacity(0.30) : Color.clear)
                    )
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
                withAnimation(.easeOut(duration: 0.12)) {
                    isPressed = pressing
                }
            }, perform: {})
        }
    }
    
    struct PressableIconLabel: View {
        let systemName: String
        @State private var isPressed = false

        var body: some View {
            Image(systemName: systemName)
                .font(.title3)
                .padding(6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isPressed ? Color.secondary.opacity(0.30) : Color.clear)
                )
                .contentShape(Rectangle())
                .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
                    withAnimation(.easeOut(duration: 0.12)) {
                        isPressed = pressing
                    }
                }, perform: {})
        }
    }
    
    //Header title
    private var monthYearTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.calendar = calendar
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: displayedMonth)
    }

    //Weekday symbols
    private var daysOfWeekSymbols: [String] {
        var symbols = calendar.shortStandaloneWeekdaySymbols
        if calendar.firstWeekday == 2 {
            let sunday = symbols.removeFirst()
            symbols.append(sunday)
        }
        return symbols
    }

    //Days Grid
    private var daysGrid: [Int?] {
        guard let range = calendar.range(of: .day, in: .month, for: displayedMonth),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)) else {
            return []
        }

        let weekdayOfFirst = calendar.component(.weekday, from: firstOfMonth)
        let firstWeekdayIndex = calendar.firstWeekday
        let leadingEmptyDays = (weekdayOfFirst - firstWeekdayIndex + 7) % 7

        var result: [Int?] = Array(repeating: nil, count: leadingEmptyDays)
        result.append(contentsOf: range.map { Int?($0) })
        return result
    }

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    }

    

    //Popover view body
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            //Week/month movement controls
            HStack {
                IconButton(systemName: "chevron.left.2") {
                    changeMonth(by: -12)
                }
                IconButton(systemName: "chevron.left") {
                    changeMonth(by: -1)
                }

                Spacer()

                Text(monthYearTitle)
                    .font(.headline)

                Spacer()

                IconButton(systemName: "chevron.right") {
                    changeMonth(by: 1)
                }
                IconButton(systemName: "chevron.right.2") {
                    changeMonth(by: 12)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 15)

            //Calendar - week days grid
            ZStack {
                VStack(spacing: 8) {

                    LazyVGrid(columns: columns, spacing: 4) {
                        ForEach(daysOfWeekSymbols, id: \.self) { symbol in
                            Text(symbol.uppercased())
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 6)
                    .padding(.bottom, 2)

                    LazyVGrid(columns: columns, spacing: 4) {
                        ForEach(Array(daysGrid.enumerated()), id: \.offset) { _, day in
                            if let day = day {
                                DayCell(
                                    day: day,
                                    monthDate: displayedMonth,
                                    calendar: calendar
                                )
                            } else {
                                Text(" ")
                                    .frame(maxWidth: .infinity, minHeight: 20)
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 4)
                    .padding(.bottom, 20)
                }
                .transition(
                    monthChangeDirection == -1
                    ? .move(edge: .leading)
                    : .move(edge: .trailing)
                )
            }

            // Bottom bar – Today, open native cal, settings buttons
            HStack(spacing: 8) {

                Button("today_button") {
                    goToToday()
                }
                .buttonStyle(.borderedProminent)

                IconButton(systemName: "calendar") {
                    let config = NSWorkspace.OpenConfiguration()
                    config.activates = true   // přivede aplikaci dopředu

                    if let url = NSWorkspace.shared.urlForApplication(
                        withBundleIdentifier: "com.apple.iCal"
                    ) {
                        NSWorkspace.shared.openApplication(
                            at: url,
                            configuration: config,
                            completionHandler: nil
                        )
                    }
                }

                Spacer()

                //Settings gearshape window opener
                IconButton(systemName: "gearshape") {
                    NSApp.activate(ignoringOtherApps: true)
                    openWindow(id: "preferences")
                }
                
                
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(radius: 8)
        )
        .padding(8)
    }

    //Change month
    private func changeMonth(by value: Int) {
        guard monthChangeDirection == 0 else { return }

        if let newDate = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            monthChangeDirection = value < 0 ? -1 : 1

            withAnimation(.easeInOut(duration: 0.25)) {
                displayedMonth = newDate
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                monthChangeDirection = 0
            }
        }
    }

    //Go to Today
    private func goToToday() {
        guard monthChangeDirection == 0 else { return }

        let today = Date()

        guard
            let currentMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)),
            let todayMonthStart   = calendar.date(from: calendar.dateComponents([.year, .month], from: today))
        else {
            displayedMonth = today
            return
        }

        let diff = calendar.dateComponents([.month], from: currentMonthStart, to: todayMonthStart).month ?? 0

        if diff == 0 {
            displayedMonth = today
            return
        }

        changeMonth(by: diff)
    }
}


// MARK: - DayCell

struct DayCell: View {
    let day: Int
    let monthDate: Date
    let calendar: Calendar

    private var date: Date? {
        calendar.date(from: DateComponents(
            year: calendar.component(.year, from: monthDate),
            month: calendar.component(.month, from: monthDate),
            day: day
        ))
    }

    private var isToday: Bool {
        guard let date else { return false }
        return calendar.isDateInToday(date)
    }

    private var isWeekend: Bool {
        guard let date else { return false }
        let weekday = calendar.component(.weekday, from: date)
        return weekday == 7 || weekday == 1
    }

    var body: some View {
        Text("\(day)")
            .font(.body)
            .frame(maxWidth: .infinity, minHeight: 22)
            .padding(4)
            .background(
                Group {
                    if isToday {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.accentColor.opacity(0.25))
                    } else if isWeekend {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.secondary.opacity(0.15))
                    } else {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.secondary.opacity(0.05))
                    }
                }
            )
    }
}
