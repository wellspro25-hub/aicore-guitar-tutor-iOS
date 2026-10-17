//
//  Riff.swift
//  AICore Guitar Tutor
//
//  Riff library. Every melody here is public domain (pre-1929 compositions,
//  traditional tunes) or an original written for AICore LLC. Copyrighted songs
//  need a publisher license before they can be added note by note.
//

import Foundation

enum Genre: String, CaseIterable, Identifiable, Codable {
    case rock, blues, metal, folk, country, pop, classical, movieTV, latin

    var id: String { rawValue }

    var label: String {
        switch self {
        case .rock: "Rock"
        case .blues: "Blues"
        case .metal: "Metal"
        case .folk: "Folk"
        case .country: "Country"
        case .pop: "Pop"
        case .classical: "Classical"
        case .movieTV: "Movie & TV"
        case .latin: "Latin"
        }
    }

    /// Maps an Apple Music genre name to one of the app's styles.
    static func match(_ name: String) -> Genre? {
        let n = name.lowercased()
        if n.contains("metal") { return .metal }
        if n.contains("soundtrack") || n.contains("film") || n.contains("tv") || n.contains("score") { return .movieTV }
        if n.contains("classical") || n.contains("opera") { return .classical }
        if n.contains("blues") || n.contains("jazz") { return .blues }
        if n.contains("country") || n.contains("bluegrass") { return .country }
        if n.contains("folk") || n.contains("singer/songwriter") || n.contains("americana") { return .folk }
        if n.contains("latin") || n.contains("reggaeton") || n.contains("flamenco") || n.contains("salsa") { return .latin }
        if n.contains("rock") || n.contains("alternative") || n.contains("punk") || n.contains("grunge") { return .rock }
        if n.contains("pop") || n.contains("indie") || n.contains("dance") || n.contains("electronic") || n.contains("hip-hop") || n.contains("r&b") { return .pop }
        return nil
    }
}

struct Riff: Identifiable, Hashable {
    let id: String
    let title: String
    let origin: String
    let why: String
    let tags: [Genre]
    /// 1 easy · 2 medium · 3 harder
    let level: Int
    let bpm: Int
    /// Free riffs are available without Premium.
    let isFree: Bool
    let pattern: TabPattern

    var isOriginal: Bool { origin.contains("AICore") }

    init(_ id: String, _ title: String, origin: String, why: String, tags: [Genre], level: Int, bpm: Int, free: Bool, notes: String) {
        self.id = id
        self.title = title
        self.origin = origin
        self.why = why
        self.tags = tags
        self.level = level
        self.bpm = bpm
        self.isFree = free
        self.pattern = TabPattern(title: title, fingering: "", suggestedBPM: bpm, steps: TabParser.parse(notes))
    }
}

/// Reads compact tab text: "6.0+5.2/0.5" = string 6 open with string 5 fret 2,
/// half a beat long. "r/1" = one-beat rest. "|" = bar line.
enum TabParser {
    static func parse(_ text: String) -> [TabStep] {
        var steps: [TabStep] = []
        for (index, token) in text.split(separator: " ").enumerated() {
            if token == "|" {
                steps.append(TabStep(id: index, notes: [], beats: 0, isBar: true))
                continue
            }
            let parts = token.split(separator: "/")
            guard parts.count == 2, let beats = Double(parts[1]) else { continue }
            if parts[0] == "r" {
                steps.append(TabStep(id: index, notes: [], beats: beats))
                continue
            }
            let notes: [TabNote] = parts[0].split(separator: "+").compactMap { piece in
                let sf = piece.split(separator: ".")
                guard sf.count == 2, let s = Int(sf[0]), let f = Int(sf[1]) else { return nil }
                return TabNote(string: s, fret: f)
            }
            steps.append(TabStep(id: index, notes: notes, beats: beats))
        }
        return steps
    }
}

enum RiffLibrary {
    static let all: [Riff] = [
        Riff("ode", "Ode to Joy", origin: "Beethoven, 1824",
             why: "The big tune from his Ninth Symphony, heard in films like Die Hard. Five notes, all near the top strings.",
             tags: [.classical, .movieTV], level: 1, bpm: 100, free: true,
             notes: "1.0/1 1.0/1 1.1/1 1.3/1 | 1.3/1 1.1/1 1.0/1 2.3/1 | 2.1/1 2.1/1 2.3/1 1.0/1 | 1.0/1.5 2.3/0.5 2.3/2 | 1.0/1 1.0/1 1.1/1 1.3/1 | 1.3/1 1.1/1 1.0/1 2.3/1 | 2.1/1 2.1/1 2.3/1 1.0/1 | 2.3/1.5 2.1/0.5 2.1/2"),
        Riff("mountain", "In the Hall of the Mountain King", origin: "Grieg, 1875",
             why: "The sneaky theme that speeds up — a film-trailer favorite and a staple of rock and metal covers.",
             tags: [.classical, .movieTV, .metal, .rock], level: 2, bpm: 110, free: false,
             notes: "4.2/0.5 4.4/0.5 3.0/0.5 3.2/0.5 2.0/0.5 3.0/0.5 2.0/1 | 3.3/0.5 4.4/0.5 3.3/1 3.2/0.5 4.3/0.5 3.2/1 | 4.2/0.5 4.4/0.5 3.0/0.5 3.2/0.5 2.0/0.5 3.0/0.5 2.0/0.5 1.0/0.5 | 2.3/0.5 2.0/0.5 3.0/0.5 2.0/0.5 2.3/2"),
        Riff("tell", "William Tell Overture (finale)", origin: "Rossini, 1829 · simplified",
             why: "The galloping theme famous as The Lone Ranger's TV theme. Great for fast repeated notes.",
             tags: [.classical, .movieTV], level: 2, bpm: 120, free: false,
             notes: "3.0/0.5 3.0/0.5 3.0/1 | 3.0/0.5 3.0/0.5 3.0/1 | 3.0/0.5 3.0/0.5 2.1/1 | 2.3/1 1.0/2"),
        Riff("diesirae", "Dies Irae", origin: "Medieval chant, 13th century",
             why: "Eight notes of doom. It opens The Shining and hides in countless horror and fantasy scores.",
             tags: [.classical, .movieTV, .metal], level: 1, bpm: 70, free: true,
             notes: "2.1/1 2.0/1 2.1/1 3.2/1 | 2.0/1 3.0/1 3.2/1 3.2/1"),
        Riff("furelise", "Für Elise (opening)", origin: "Beethoven, 1810",
             why: "Instantly recognizable from films, TV and old ringtones. Trains quick moves between strings 1 and 2.",
             tags: [.classical, .movieTV, .pop], level: 2, bpm: 80, free: false,
             notes: "1.0/0.5 2.4/0.5 1.0/0.5 2.4/0.5 1.0/0.5 2.0/0.5 2.3/0.5 2.1/0.5 | 3.2/1 r/0.5 5.3/0.5 4.2/0.5 3.2/0.5 | 2.0/1 r/0.5 4.2/0.5 3.1/0.5 2.0/0.5 | 2.1/1 r/0.5 1.0/0.5 2.4/0.5 1.0/0.5 | 2.4/0.5 1.0/0.5 2.0/0.5 2.3/0.5 2.1/0.5 3.2/1"),
        Riff("greensleeves", "Greensleeves", origin: "English folk tune, 16th century",
             why: "A slow waltz that shows up in holiday films and period dramas. Lovely with fingers.",
             tags: [.folk, .classical, .movieTV], level: 2, bpm: 90, free: false,
             notes: "3.2/1 | 2.1/2 2.3/1 | 1.0/1.5 1.1/0.5 1.0/1 | 2.3/2 2.0/1 | 3.0/1.5 3.2/0.5 2.0/1 | 2.1/2 3.2/1 | 3.2/1.5 3.1/0.5 3.2/1 | 2.0/2 3.1/1 | 4.2/2"),
        Riff("amazing", "Amazing Grace", origin: "Hymn, 1779",
             why: "Played on bagpipes at Spock's funeral in Star Trek II. Mostly open strings — a perfect first melody.",
             tags: [.folk, .country, .movieTV], level: 1, bpm: 80, free: true,
             notes: "4.0/1 | 3.0/2 2.0/0.5 3.0/0.5 | 2.0/2 3.2/1 | 3.0/2 4.2/1 | 4.0/2 4.0/1 | 3.0/2 2.0/0.5 3.0/0.5 | 2.0/2 3.2/1 | 2.3/3"),
        Riff("saints", "When the Saints Go Marching In", origin: "New Orleans traditional",
             why: "The brass-band anthem. Four notes on the top two strings and a big singalong payoff.",
             tags: [.folk, .blues, .country], level: 1, bpm: 110, free: true,
             notes: "r/1 2.1/1 1.0/1 1.1/1 | 1.3/4 | r/1 2.1/1 1.0/1 1.1/1 | 1.3/4 | r/1 2.1/1 1.0/1 1.1/1 | 1.3/2 1.0/2 | 2.1/2 1.0/2 | 2.3/4"),
        Riff("twinkle", "Twinkle Twinkle Little Star", origin: "French folk tune, 1761",
             why: "The easiest win in the app. Play it for the kids in your life.",
             tags: [.folk, .pop], level: 1, bpm: 100, free: true,
             notes: "3.0/1 3.0/1 2.3/1 2.3/1 | 1.0/1 1.0/1 2.3/2 | 2.1/1 2.1/1 2.0/1 2.0/1 | 3.2/1 3.2/1 3.0/2"),
        Riff("risingsun", "House of the Rising Sun (chords)", origin: "American folk song, traditional",
             why: "The classic minor arpeggio over Am, C, D, F and E. Thumb on the bass, fingers roll up and back.",
             tags: [.folk, .rock, .blues], level: 2, bpm: 96, free: false,
             notes: "5.0/0.5 3.2/0.5 2.1/0.5 1.0/0.5 2.1/0.5 3.2/0.5 | 5.3/0.5 3.0/0.5 2.1/0.5 1.0/0.5 2.1/0.5 3.0/0.5 | 4.0/0.5 3.2/0.5 2.3/0.5 1.2/0.5 2.3/0.5 3.2/0.5 | 4.3/0.5 3.2/0.5 2.1/0.5 1.1/0.5 2.1/0.5 3.2/0.5 | 5.0/0.5 3.2/0.5 2.1/0.5 1.0/0.5 2.1/0.5 3.2/0.5 | 5.3/0.5 3.0/0.5 2.1/0.5 1.0/0.5 2.1/0.5 3.0/0.5 | 6.0/0.5 3.1/0.5 2.0/0.5 1.0/0.5 2.0/0.5 3.1/0.5 | 6.0/0.5 3.1/0.5 2.0/0.5 1.0/0.5 2.0/0.5 3.1/0.5"),
        Riff("boogie", "Boogie Shuffle in E", origin: "Original · AICore",
             why: "The rocking two-string shuffle behind decades of blues and early rock and roll. Swing it.",
             tags: [.blues, .rock, .country], level: 1, bpm: 90, free: true,
             notes: "6.0+5.2/0.5 6.0+5.2/0.5 6.0+5.4/0.5 6.0+5.4/0.5 6.0+5.2/0.5 6.0+5.2/0.5 6.0+5.4/0.5 6.0+5.4/0.5 | 5.0+4.2/0.5 5.0+4.2/0.5 5.0+4.4/0.5 5.0+4.4/0.5 5.0+4.2/0.5 5.0+4.2/0.5 5.0+4.4/0.5 5.0+4.4/0.5 | 6.0+5.2/0.5 6.0+5.2/0.5 6.0+5.4/0.5 6.0+5.4/0.5 6.0+5.2/2"),
        Riff("stomp", "Power Chord Stomp", origin: "Original · AICore",
             why: "Two-finger power chords with a palm-muted chug. The core move of rock, punk and grunge.",
             tags: [.rock, .metal, .pop], level: 2, bpm: 100, free: false,
             notes: "6.0+5.2/0.5 6.0+5.2/0.5 r/0.5 6.0+5.2/0.5 6.3+5.5/1 5.0+4.2/1 | 6.0+5.2/0.5 6.0+5.2/0.5 r/0.5 6.0+5.2/0.5 5.3+4.5/1 6.3+5.5/1"),
        Riff("gallop", "Gallop Engine", origin: "Original · AICore",
             why: "The galloping low-E rhythm heard all over heavy metal. Down-down-down with your pick or thumb.",
             tags: [.metal, .rock], level: 3, bpm: 110, free: false,
             notes: "6.0/0.5 6.0/0.25 6.0/0.25 6.0/0.5 6.0/0.25 6.0/0.25 6.0/0.5 6.0/0.25 6.0/0.25 6.3+5.5/0.5 6.5+5.7/0.5 | 6.0/0.5 6.0/0.25 6.0/0.25 6.0/0.5 6.0/0.25 6.0/0.25 6.0/0.5 6.0/0.25 6.0/0.25 6.3+5.5/0.5 6.1+5.3/0.5"),
        Riff("penta", "A Minor Pentatonic Lick", origin: "Original · AICore",
             why: "Your first lead-guitar lick from the box shape every blues and rock soloist uses.",
             tags: [.blues, .rock], level: 2, bpm: 80, free: false,
             notes: "1.5/0.5 2.8/0.5 2.5/0.5 3.7/0.5 3.5/0.5 4.7/1.5 | r/0.5 3.7/0.5 4.7/2"),
        Riff("boomchick", "Campfire Boom-Chick", origin: "Original · AICore",
             why: "Bass note, strum, bass note, strum — the backbone of country and campfire songs.",
             tags: [.country, .folk], level: 1, bpm: 90, free: false,
             notes: "6.3/1 4.0+3.0+2.0+1.3/1 4.0/1 4.0+3.0+2.0+1.3/1 | 5.3/1 4.2+3.0+2.1+1.0/1 4.2/1 4.2+3.0+2.1+1.0/1"),
        Riff("sparkle", "Indie Sparkle Arpeggio", origin: "Original · AICore",
             why: "Two top strings stay pinned while the bass moves — that shimmering sound from indie and pop ballads.",
             tags: [.pop, .folk, .rock], level: 2, bpm: 96, free: false,
             notes: "5.3/0.5 4.2/0.5 3.0/0.5 2.3/0.5 1.3/0.5 2.3/0.5 | 6.3/0.5 4.0/0.5 3.0/0.5 2.3/0.5 1.3/0.5 2.3/0.5 | 6.0/0.5 4.2/0.5 3.0/0.5 2.3/0.5 1.3/0.5 2.3/0.5 | 4.0/0.5 3.2/0.5 2.3/0.5 1.3/0.5 2.3/0.5 3.2/0.5"),
        Riff("flame", "Spanish Flame", origin: "Original · AICore",
             why: "The half-step E-to-F twist that makes flamenco and Latin guitar sound fiery, ending on a bright E chord.",
             tags: [.latin, .classical], level: 2, bpm: 100, free: false,
             notes: "1.0/0.5 1.1/0.5 1.0/0.5 2.3/0.5 2.1/0.5 2.0/0.5 3.1/1 | 6.0+5.2+4.2+3.1+2.0+1.0/2"),
        Riff("surf", "Surf Rider", origin: "Original · AICore",
             why: "A fast low-string run with a 1960s surf-rock attitude. Builds speed and accuracy on string 6.",
             tags: [.rock, .pop], level: 1, bpm: 140, free: true,
             notes: "6.0/0.5 6.0/0.5 6.3/0.5 6.0/0.5 6.5/0.5 6.0/0.5 6.3/0.5 6.2/0.5 | 6.0/0.5 6.0/0.5 6.3/0.5 6.0/0.5 6.5/0.5 6.6/0.5 6.5/0.5 6.3/0.5")
    ]

    static func riff(id: String) -> Riff? { all.first { $0.id == id } }

    /// Ranks riffs for the player: favorite styles first, right difficulty, not learned yet.
    /// A small daily shuffle keeps the list fresh.
    static func ranked(for genres: [Genre], level: SkillLevel, learned: Set<String>, date: Date = .now) -> [Riff] {
        let cap = level.riffCap
        let day = Int(date.timeIntervalSince1970 / 86_400)
        func score(_ r: Riff) -> Double {
            let overlap = Double(r.tags.filter { genres.contains($0) }.count)
            var s = overlap * 3
            s += r.level <= cap ? 2 : -1
            s += r.level == cap ? 1 : 0
            s -= learned.contains(r.id) ? 6 : 0
            var h = 0
            for c in (r.id + String(day)).unicodeScalars { h = (h &* 31 &+ Int(c.value)) & 0x7fff_ffff }
            return s + Double(h % 100) / 100
        }
        return all.sorted { score($0) > score($1) }
    }
}
