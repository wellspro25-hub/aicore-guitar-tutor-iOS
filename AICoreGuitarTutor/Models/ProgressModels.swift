//
//  ProgressModels.swift
//  AICore Guitar Tutor
//
//  Stored on-device with SwiftData. Nothing here leaves the phone.
//

import Foundation
import SwiftData

@Model
final class LessonProgress {
    @Attribute(.unique) var lessonID: String
    var completedAt: Date

    init(lessonID: String, completedAt: Date = .now) {
        self.lessonID = lessonID
        self.completedAt = completedAt
    }
}

@Model
final class PracticeSession {
    var startedAt: Date
    var seconds: Int

    init(startedAt: Date, seconds: Int) {
        self.startedAt = startedAt
        self.seconds = seconds
    }
}

enum PracticeStats {
    /// Total practice seconds on the given calendar day.
    static func seconds(on day: Date, in sessions: [PracticeSession], calendar: Calendar = .current) -> Int {
        sessions
            .filter { calendar.isDate($0.startedAt, inSameDayAs: day) }
            .reduce(0) { $0 + $1.seconds }
    }

    /// Number of consecutive days (ending today, or yesterday if nothing yet today) with practice.
    static func streak(in sessions: [PracticeSession], calendar: Calendar = .current, now: Date = .now) -> Int {
        let days = Set(sessions.map { calendar.startOfDay(for: $0.startedAt) })
        guard !days.isEmpty else { return 0 }

        var day = calendar.startOfDay(for: now)
        if !days.contains(day) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day), days.contains(yesterday) else {
                return 0
            }
            day = yesterday
        }

        var count = 0
        while days.contains(day) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return count
    }

    static func format(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%d:%02d", m, s)
    }
}
