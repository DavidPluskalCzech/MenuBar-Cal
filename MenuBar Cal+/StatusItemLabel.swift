import SwiftUI
import Combine

struct StatusItemLabel: View {
    @State private var now = Date()

    @AppStorage("showWeekNumber") private var showWeekNumber = false
    @AppStorage("showTime") private var showTime = false
    @AppStorage("dateStyle") private var dateStyleRaw = 0  // 0 short, 1 medium, 2 long
    @AppStorage("showIcon") private var showIcon: Bool = true
    @AppStorage("showDate") private var showDate: Bool = true

    // REGION-safe calendar
    private var region: String {
        Locale.current.region?.identifier.lowercased() ?? "us"
    }

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.locale = Locale.current
        f.calendar = Calendar(identifier: .gregorian)

        switch dateStyleRaw {
        case 1:
            f.dateFormat = (region == "cz" || region == "sk")
                ? "d. M. yyyy"
                : "MMM d, yyyy"

        case 2:
            f.dateFormat = (region == "cz" || region == "sk")
                ? "d. MMMM yyyy"
                : "d MMMM yyyy"

        default:
            f.dateFormat = (region == "cz" || region == "sk")
                ? "d. M. yy"
                : "M/d/yy"
        }

        return f
    }

    private var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.locale = Locale.current
        f.calendar = Calendar(identifier: .gregorian)
        f.timeStyle = .short
        f.dateStyle = .none
        return f
    }

    private var title: String {
        var parts: [String] = []
        
        if showDate {
            parts.append(dateFormatter.string(from: now))
        }

        if showWeekNumber {
            let week = Calendar.current.component(.weekOfYear, from: now)
            let prefix = NSLocalizedString("week_short", comment: "Week number prefix")
            parts.append("\(prefix)\(week)")
        }

        if showTime {
            parts.append(timeFormatter.string(from: now))
        }
        

        return parts.joined(separator: " · ")
    }

    var body: some View {
        HStack(spacing: 4) {
            if showIcon {
                Image(systemName: "calendar")
                    .renderingMode(.template)
            }

            if !title.isEmpty {
                Text(title)
            }
        }
        .onReceive(
            Timer.publish(every: 1, on: .main, in: .common).autoconnect()
        ) { now = $0 }
        .padding(.horizontal, 4)
    }
}
