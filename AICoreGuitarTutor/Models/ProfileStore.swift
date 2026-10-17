//
//  ProfileStore.swift
//  AICore Guitar Tutor
//
//  The player's taste, goal, XP, learned riffs and favorites.
//  Saved on the device (UserDefaults). Nothing is sent anywhere.
//

import Foundation
import Observation

enum SkillLevel: String, Codable, CaseIterable, Identifiable {
    case new, some, plays

    var id: String { rawValue }

    var label: String {
        switch self {
        case .new: "Brand new"
        case .some: "Know a few chords"
        case .plays: "I play a bit"
        }
    }

    /// Hardest riff level to recommend.
    var riffCap: Int {
        switch self {
        case .new: 1
        case .some: 2
        case .plays: 3
        }
    }
}

struct LevelInfo {
    let number: Int
    let name: String
    let progress: Double
    let xpToNext: Int
}

@MainActor
@Observable
final class ProfileStore {
    struct Profile: Codable {
        var level: SkillLevel = .new
        var genres: [Genre] = []
        var artists: String = ""
        var dailyGoalMinutes: Int = 15
        var onboarded = false
        var xp = 0
        var learned: [String] = []
        var favorites: [String] = []
    }

    var data: Profile {
        didSet { save() }
    }

    /// A short message shown briefly at the bottom of the screen (XP earned, level up).
    var toast: String?

    @ObservationIgnored private let key = "profile.v2"

    init() {
        if let raw = UserDefaults.standard.data(forKey: "profile.v2"),
           let decoded = try? JSONDecoder().decode(Profile.self, from: raw) {
            data = decoded
        } else {
            data = Profile()
        }
    }

    private func save() {
        if let raw = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(raw, forKey: key)
        }
    }

    // MARK: XP

    static let levels: [(xp: Int, name: String)] = [
        (0, "Open Strings"), (200, "First Chords"), (500, "Fingerpicker"), (900, "Riff Runner"),
        (1400, "Stage Ready"), (2000, "Session Player"), (2800, "Headliner")
    ]

    var levelInfo: LevelInfo { Self.levelInfo(for: data.xp) }

    static func levelInfo(for xp: Int) -> LevelInfo {
        var i = 0
        while i + 1 < levels.count && xp >= levels[i + 1].xp { i += 1 }
        let floor = levels[i].xp
        let next = i + 1 < levels.count ? levels[i + 1].xp : floor + 1000
        return LevelInfo(number: i + 1, name: levels[i].name,
                         progress: min(1, Double(xp - floor) / Double(next - floor)),
                         xpToNext: max(0, next - xp))
    }

    func addXP(_ amount: Int, reason: String?) {
        let before = levelInfo.number
        data.xp += amount
        let after = levelInfo
        if after.number > before {
            toast = "Level \(after.number): \(after.name)!"
        } else if let reason {
            toast = "+\(amount) XP · \(reason)"
        }
    }

    // MARK: Riffs

    func isLearned(_ id: String) -> Bool { data.learned.contains(id) }
    func isFavorite(_ id: String) -> Bool { data.favorites.contains(id) }

    func toggleLearned(_ id: String) {
        if let i = data.learned.firstIndex(of: id) {
            data.learned.remove(at: i)
        } else {
            data.learned.append(id)
            addXP(40, reason: "Riff learned")
        }
    }

    func toggleFavorite(_ id: String) {
        if let i = data.favorites.firstIndex(of: id) {
            data.favorites.remove(at: i)
        } else {
            data.favorites.append(id)
        }
    }

    func toggleGenre(_ genre: Genre) {
        if let i = data.genres.firstIndex(of: genre) {
            data.genres.remove(at: i)
        } else {
            data.genres.append(genre)
        }
    }

    var rankedRiffs: [Riff] {
        RiffLibrary.ranked(for: data.genres, level: data.level, learned: Set(data.learned))
    }

    func resetProgress() {
        data.xp = 0
        data.learned = []
        data.favorites = []
    }
}
