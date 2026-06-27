import Foundation

protocol DogGoClock {
    var now: Date { get }
}

struct SystemClock: DogGoClock {
    var now: Date { Date() }
}

struct FixedClock: DogGoClock {
    var now: Date
}

struct TimeWindowResolver {
    let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func timeWindow(at date: Date) -> TimeWindow {
        switch calendar.component(.hour, from: date) {
        case 5..<9: .morning
        case 9..<17: .daytime
        case 17..<22: .evening
        default: .night
        }
    }

    func windowStart(containing date: Date) -> Date {
        let hour = calendar.component(.hour, from: date)
        let startHour: Int
        let dayOffset: Int

        switch hour {
        case 5..<9:
            startHour = 5
            dayOffset = 0
        case 9..<17:
            startHour = 9
            dayOffset = 0
        case 17..<22:
            startHour = 17
            dayOffset = 0
        case 22...23:
            startHour = 22
            dayOffset = 0
        default:
            startHour = 22
            dayOffset = -1
        }

        let startOfDay = calendar.startOfDay(for: date)
        let adjustedDay = calendar.date(byAdding: .day, value: dayOffset, to: startOfDay) ?? startOfDay
        return calendar.date(byAdding: .hour, value: startHour, to: adjustedDay) ?? adjustedDay
    }
}
