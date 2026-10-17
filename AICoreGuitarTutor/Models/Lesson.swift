//
//  Lesson.swift
//  AICore Guitar Tutor
//

import Foundation

/// A single lesson in the fingerstyle course. Lesson content ships inside the app.
struct Lesson: Identifiable, Hashable {
    let id: String
    let unit: Int
    let title: String
    let summary: String
    let minutes: Int
    /// Free lessons are available without Premium.
    let isFree: Bool
    let sections: [LessonSection]
}

struct LessonSection: Hashable, Identifiable {
    let id = UUID()
    let heading: String
    let body: String
    var tab: TabPattern? = nil
    var tips: [String] = []
}

/// One note on the fretboard. Strings: 1 = high e (thinnest) … 6 = low E (thickest).
struct TabNote: Hashable {
    let string: Int
    let fret: Int

    /// MIDI note number in standard tuning.
    var midi: Int { TabNote.openMidi[min(6, max(1, string))] + fret }
    static let openMidi = [0, 64, 59, 55, 50, 45, 40]
}

/// One column of tab: the notes played together, how long they last (in beats),
/// or a bar line.
struct TabStep: Hashable, Identifiable {
    let id: Int
    let notes: [TabNote]
    let beats: Double
    var isBar: Bool = false

    var isRest: Bool { !isBar && notes.isEmpty }
}

/// Playable guitar tab used by lessons and riffs.
struct TabPattern: Hashable {
    let title: String
    let fingering: String
    let suggestedBPM: Int
    let steps: [TabStep]

    var totalBeats: Double { steps.reduce(0) { $0 + $1.beats } }
}

struct LessonUnit: Identifiable {
    let id: Int
    let title: String
    let subtitle: String
    let lessons: [Lesson]
}
