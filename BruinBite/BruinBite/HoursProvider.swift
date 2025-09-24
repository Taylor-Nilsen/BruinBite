//
//  HoursProvider.swift
//  BruinBite
//
//  Created by You on 9/23/25.
//

import Foundation

// MARK: - Public API types

public struct ServiceWindow: Hashable {
    public let start: Date
    public let end: Date
    public let label: String? // e.g., "Breakfast", "Lunch", "Dinner"

    public init(start: Date, end: Date, label: String? = nil) {
        self.start = start
        self.end = end
        self.label = label
    }

    public func contains(_ date: Date) -> Bool {
        return (start ... end).contains(date)
    }
}

public struct DayWindows: Hashable {
    public let date: Date
    public let intervals: [ServiceWindow]
}

public enum HoursError: Error {
    case notFound
    case parseFailure
    case network
}

public struct HallStatus: Hashable {
    public let hallID: String
    public let openNow: Bool
    public let currentMeal: String?
    public let nextChangeAt: Date?
    public let nextChangeType: ChangeType?

    public enum ChangeType: String, Hashable {
        case open
        case close
        case mealSwitch
    }
}

// MARK: - HoursProvider

/// Provides parsed, normalized open/close windows for halls.
public final class HoursProvider {

    public init() {}

    // MARK: Public entry points

    /// Returns: open/closed *right now*, and the next time something changes (open/close/meal switch).
    public func statusNow(for hallID: String, now: Date = Date()) async throws -> HallStatus {
        // Get *today* intervals (sorted) and any labels you rely on for meals
        let today = try await windows(for: hallID, on: now)
        let intervals = today.intervals.sorted(by: { $0.start < $1.start })

        // Are we inside any interval?
        if let active = intervals.first(where: { $0.contains(now) }) {
            // Currently open. Next change is the CLOSE of this active window.
            let nextClose = active.end
            return HallStatus(
                hallID: hallID,
                openNow: true,
                currentMeal: active.label,
                nextChangeAt: nextClose,
                nextChangeType: .close
            )
        }

        // Currently closed. Find the next start > now (today), else the first start tomorrow/next open day.
        if let nextToday = intervals.first(where: { $0.start > now }) {
            return HallStatus(
                hallID: hallID,
                openNow: false,
                currentMeal: nil,
                nextChangeAt: nextToday.start,
                nextChangeType: .open
            )
        }

        // Nothing later today — look ahead day-by-day until we find an opening.
        if let nextStart = try await nextOpenStart(hallID: hallID, after: now) {
            return HallStatus(
                hallID: hallID,
                openNow: false,
                currentMeal: nil,
                nextChangeAt: nextStart,
                nextChangeType: .open
            )
        }

        // If we truly can't find anything (e.g., seasonal closure), return no upcoming change.
        return HallStatus(
            hallID: hallID,
            openNow: false,
            currentMeal: nil,
            nextChangeAt: nil,
            nextChangeType: nil
        )
    }

    /// Returns the normalized service windows for a given hall on a given day.
    public func windows(for hallID: String, on date: Date) async throws -> DayWindows {
        let intervals = parseWindows(for: hallID, on: date)
        return DayWindows(date: date, intervals: intervals)
    }

    // MARK: - Static hours data
    private static let staticHours: [String: [(label: String, start: String, end: String)]] = [
        // Residential locations
        "BruinCafe": [
            ("Breakfast", "7:00 AM", "10:00 AM"),
            ("Lunch", "11:00 AM", "4:00 PM"),
            ("Dinner", "5:00 PM", "9:00 PM")
        ],
        "BruinPlate": [
            ("Breakfast", "7:00 AM", "9:00 AM"),
            ("Lunch", "11:00 AM", "2:00 PM"),
            ("Dinner", "5:00 PM", "9:00 PM")
        ],
        "Cafe1919": [
            ("Lunch", "11:00 AM", "4:00 PM"),
            ("Dinner", "5:00 PM", "9:00 PM")
        ],
        "DeNeveDining": [
            ("Breakfast", "7:00 AM", "10:00 AM"),
            ("Lunch", "11:00 AM", "2:00 PM"),
            ("Dinner", "5:00 PM", "9:00 PM")
        ],
        "EpicuriaAtAckerman": [
            ("Lunch", "11:00 AM", "4:00 PM"),
            ("Dinner", "5:00 PM", "9:00 PM")
        ],
        "EpicuriaAtCovel": [
            ("Lunch", "11:00 AM", "2:00 PM"),
            ("Dinner", "5:00 PM", "9:00 PM")
        ],
        "FEASTAtRieber": [
            ("Lunch", "11:00 AM", "2:00 PM"),
            ("Dinner", "5:00 PM", "9:00 PM")
        ],
        "Rendezvous": [
            ("Lunch", "11:00 AM", "3:00 PM"),
            ("Dinner", "5:00 PM", "9:00 PM")
        ],
        "TheDrey": [
            ("Lunch", "11:00 AM", "3:00 PM"),
            ("Dinner", "5:00 PM", "9:00 PM")
        ],
        "TheStudyAtHedrick": [
            ("Breakfast", "7:00 AM", "10:00 AM"),
            ("Lunch", "11:00 AM", "3:00 PM"),
            ("Dinner", "5:00 PM", "9:00 PM")
        ],
        
        // Campus retail locations
        "LollicupFresh": [("", "8:00 AM", "7:00 PM")],
        "WetzelsPretzels": [("", "8:00 AM", "7:00 PM")],
        "Sweetspot": [("", "8:00 AM", "6:00 PM")],
        "PandaExpress": [("", "10:00 AM", "7:00 PM")],
        "Rubios": [("", "10:00 AM", "7:00 PM")],
        "VeggieGrill": [("", "10:00 AM", "8:00 PM")],
        "EpicuriaAck": [("", "10:00 AM", "7:00 PM")],
        "CORE": [("", "7:00 AM", "10:00 PM")],
        "JambaBlendid": [("", "8:00 AM", "8:00 PM")],
        "KerckhoffCoffee": [("", "7:00 AM", "9:00 PM")],
        "NorthernLights": [("", "7:00 AM", "8:00 PM")],
        "Cafe451": [("", "8:00 AM", "5:00 PM")],
        "LuValleCommons": [("", "7:00 AM", "7:00 PM")],
        "CourtOfSciences": [("", "7:00 AM", "7:00 PM")],
        "MusicCafe": [("", "8:00 AM", "5:00 PM")],
        "SouthCampusFood": [("", "7:00 AM", "3:00 PM")]
    ]

    private func parseWindows(for hallID: String, on date: Date) -> [ServiceWindow] {
        guard let windows = Self.staticHours[hallID] else { return [] }
        let cal = Calendar.current
        let day = cal.startOfDay(for: date)
        var result: [ServiceWindow] = []
        for w in windows {
            guard let start = parseTime(w.start, on: day), let end = parseTime(w.end, on: day) else { continue }
            result.append(ServiceWindow(start: start, end: end, label: w.label))
        }
        return result
    }

    private func parseTime(_ timeStr: String, on day: Date) -> Date? {
        let fmt = DateFormatter()
        fmt.dateFormat = "h:mm a"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        let cal = Calendar.current
        guard let t = fmt.date(from: timeStr) else { return nil }
        let comps = cal.dateComponents([.hour, .minute], from: t)
        return cal.date(bySettingHour: comps.hour ?? 0, minute: comps.minute ?? 0, second: 0, of: day)
    }

    // MARK: - Helpers

    /// Scan up to 2 weeks forward to find the next opening start time (covers holiday weeks, closures, etc).
    private func nextOpenStart(hallID: String, after date: Date, lookaheadDays: Int = 14) async throws -> Date? {
        let cal = Calendar(identifier: .gregorian)
        for offset in 1...lookaheadDays {
            guard let day = cal.date(byAdding: .day, value: offset, to: date) else { continue }
            let dw = try await windows(for: hallID, on: day)
            let sorted = dw.intervals.sorted(by: { $0.start < $1.start })
            if let first = sorted.first {
                return first.start
            }
        }
        return nil
    }
}

// MARK: - Formatting utilities (if you need them elsewhere)

public enum HoursFormat {
    public static func shortTime(_ date: Date, locale: Locale = .current) -> String {
        let f = DateFormatter()
        f.locale = locale
        f.timeStyle = .short
        f.dateStyle = .none
        return f.string(from: date)
    }
}
