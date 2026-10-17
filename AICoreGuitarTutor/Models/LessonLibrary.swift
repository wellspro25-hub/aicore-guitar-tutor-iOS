//
//  LessonLibrary.swift
//  AICore Guitar Tutor
//
//  The beginner fingerstyle course. All lesson text and the "Morning Light"
//  study are original content owned by AICore LLC.
//
//  String numbers used in the tab helpers: 1 = high e (thinnest) … 6 = low E (thickest).
//

import Foundation

extension TabPattern {
    /// Builds evenly spaced tab (eighth notes) from a list of steps. Each step lists
    /// (string, fret) pairs played together. An empty step is a rest / held note.
    static func make(_ title: String, fingering: String, bpm: Int, steps: [[(Int, String)]]) -> TabPattern {
        let built = steps.enumerated().map { index, step in
            TabStep(id: index, notes: step.map { TabNote(string: $0.0, fret: Int($0.1) ?? 0) }, beats: 0.5)
        }
        return TabPattern(title: title, fingering: fingering, suggestedBPM: bpm, steps: built)
    }
}

enum LessonLibrary {

    // MARK: - Tab patterns

    static let thumbAlternating = TabPattern.make(
        "Alternating thumb", fingering: "p  .  p  .  p  .  p  .", bpm: 60,
        steps: [[(6, "0")], [], [(4, "0")], [], [(6, "0")], [], [(4, "0")], []]
    )

    static let pimaOpen = TabPattern.make(
        "p-i-m-a on open strings", fingering: "p  i  m  a  p  i  m  a", bpm: 60,
        steps: [[(6, "0")], [(3, "0")], [(2, "0")], [(1, "0")],
                [(6, "0")], [(3, "0")], [(2, "0")], [(1, "0")]]
    )

    static let pinch = TabPattern.make(
        "The pinch", fingering: "p+a  i  m  i  p+a  i  m  i", bpm: 60,
        steps: [[(6, "0"), (1, "0")], [(3, "0")], [(2, "0")], [(3, "0")],
                [(6, "0"), (1, "0")], [(3, "0")], [(2, "0")], [(3, "0")]]
    )

    static let emAm = TabPattern.make(
        "Em to Am", fingering: "p  i  m  a  p  i  m  a", bpm: 66,
        steps: [[(6, "0")], [(3, "0")], [(2, "0")], [(1, "0")],
                [(5, "0")], [(3, "2")], [(2, "1")], [(1, "0")]]
    )

    static let cG = TabPattern.make(
        "C to G", fingering: "p  i  m  a  p  i  m  a", bpm: 66,
        steps: [[(5, "3")], [(3, "0")], [(2, "1")], [(1, "0")],
                [(6, "3")], [(3, "0")], [(2, "0")], [(1, "3")]]
    )

    static let fourChordLoop = TabPattern.make(
        "Am – C – G – Em", fingering: "p  i  m  a  (each chord)", bpm: 70,
        steps: [[(5, "0")], [(3, "2")], [(2, "1")], [(1, "0")],
                [(5, "3")], [(3, "0")], [(2, "1")], [(1, "0")],
                [(6, "3")], [(3, "0")], [(2, "0")], [(1, "3")],
                [(6, "0")], [(3, "0")], [(2, "0")], [(1, "0")]]
    )

    static let travisC = TabPattern.make(
        "Travis pattern on C", fingering: "p+m  i  p  m  p  i  p  a", bpm: 60,
        steps: [[(5, "3"), (2, "1")], [(3, "0")], [(4, "2")], [(2, "1")],
                [(5, "3")], [(3, "0")], [(4, "2")], [(1, "0")]]
    )

    static let travisG = TabPattern.make(
        "Travis pattern on G", fingering: "p+m  i  p  m  p  i  p  a", bpm: 60,
        steps: [[(6, "3"), (2, "0")], [(3, "0")], [(4, "0")], [(2, "0")],
                [(6, "3")], [(3, "0")], [(4, "0")], [(1, "3")]]
    )

    static let morningLightA = TabPattern.make(
        "Morning Light — part A", fingering: "p  i  m  a  m  i", bpm: 72,
        steps: [[(5, "0")], [(3, "2")], [(2, "1")], [(1, "0")], [(2, "1")], [(3, "2")],
                [(5, "3")], [(3, "0")], [(2, "1")], [(1, "0")], [(2, "1")], [(3, "0")]]
    )

    static let morningLightB = TabPattern.make(
        "Morning Light — part B", fingering: "p+a  i  m  i  (then ring out)", bpm: 72,
        steps: [[(6, "3"), (1, "3")], [(3, "0")], [(2, "0")], [(3, "0")],
                [(6, "0"), (1, "0")], [(3, "0")], [(2, "0")], [(3, "0")],
                [(5, "0"), (1, "0"), (2, "1"), (3, "2"), (4, "2")], [], [], []]
    )

    // MARK: - Units

    static let units: [LessonUnit] = [
        LessonUnit(id: 1, title: "First Steps", subtitle: "Set up, tune up, meet your picking hand", lessons: [
            Lesson(
                id: "u1-guitar", unit: 1, title: "Meet Your Guitar",
                summary: "The parts of the guitar and a relaxed playing posture.", minutes: 5, isFree: true,
                sections: [
                    LessonSection(
                        heading: "The parts that matter",
                        body: "The headstock holds the tuning pegs. The neck has metal frets — pressing a string just behind a fret changes the note. The body's sound hole is where your picking hand works. The six strings are numbered 1 to 6 from the thinnest (high e) to the thickest (low E)."
                    ),
                    LessonSection(
                        heading: "Sitting position",
                        body: "Sit near the front of a chair without arms. Rest the guitar's waist on your right leg (left leg if you play left-handed). Keep the neck angled slightly upward and the guitar's back close to your body.",
                        tips: ["Shoulders loose — shrug and drop them.", "Don't tilt the guitar to see the strings; lean your head instead."]
                    ),
                    LessonSection(
                        heading: "Hands",
                        body: "Your fretting hand thumb sits behind the neck, roughly behind your middle finger. Your picking forearm rests on the edge of the body so your hand hangs naturally over the sound hole."
                    )
                ]
            ),
            Lesson(
                id: "u1-tuning", unit: 1, title: "Tuning Up",
                summary: "Use the built-in tuner to get every string in standard tuning.", minutes: 5, isFree: true,
                sections: [
                    LessonSection(
                        heading: "Standard tuning",
                        body: "From thickest to thinnest the strings are E – A – D – G – B – E. A handy way to remember it: Eddie Ate Dynamite, Good Bye Eddie."
                    ),
                    LessonSection(
                        heading: "Using the tuner",
                        body: "Open the Tuner tab and allow microphone access. Pluck one string and let it ring. If the needle is left of center, the string is flat — tighten it slowly. If it's right, it's sharp — loosen it. When the display turns green you're in tune.",
                        tips: ["Tune up to the note: if you go past it, loosen below and come back up.", "Tap a string name in the tuner to lock onto that string.", "Tune in a quiet room for the steadiest reading."]
                    )
                ]
            ),
            Lesson(
                id: "u1-pima", unit: 1, title: "Your Picking Hand: p-i-m-a",
                summary: "The finger names fingerstyle players use, and which strings each one plays.", minutes: 8, isFree: true,
                sections: [
                    LessonSection(
                        heading: "The four letters",
                        body: "Fingerstyle music labels the picking fingers with letters from Spanish: p = thumb (pulgar), i = index (índice), m = middle (medio), a = ring (anular). The pinky usually rests."
                    ),
                    LessonSection(
                        heading: "Home position",
                        body: "Thumb covers the three bass strings (6, 5, 4). Index plays string 3, middle plays string 2, ring plays string 1. Rest each finger lightly on its string before you play.",
                        tab: pimaOpen,
                        tips: ["Pluck with the fingertip and a little nail, moving from the knuckle — not the whole hand.", "Thumb moves down and slightly forward; fingers curl up into your palm."]
                    )
                ]
            ),
            Lesson(
                id: "u1-thumb", unit: 1, title: "Thumb Independence",
                summary: "A steady alternating bass — the heartbeat of fingerstyle.", minutes: 8, isFree: true,
                sections: [
                    LessonSection(
                        heading: "Alternating bass",
                        body: "Your thumb will often keep a steady beat while your fingers play melody. Start by alternating the thumb between the low E string and the D string on every beat.",
                        tab: thumbAlternating,
                        tips: ["Turn on the metronome at 60 BPM and play one thumb note per click.", "Keep your fingers resting on strings 1–3 so only the thumb moves."]
                    )
                ]
            )
        ]),
        LessonUnit(id: 2, title: "Core Patterns", subtitle: "Pinches, arpeggios and your first chords", lessons: [
            Lesson(
                id: "u2-pinch", unit: 2, title: "The Pinch",
                summary: "Thumb and ring finger together — instantly sounds like fingerstyle.", minutes: 8, isFree: true,
                sections: [
                    LessonSection(
                        heading: "What a pinch is",
                        body: "A pinch plays a bass note with p and a treble note with a (or m) at exactly the same time, like gently pinching the strings together.",
                        tab: pinch,
                        tips: ["Listen for one sound, not two. If you hear a flam, slow down.", "The motion is small: thumb pushes down, ring finger pulls up."]
                    )
                ]
            ),
            Lesson(
                id: "u2-em-am", unit: 2, title: "First Chords: Em and Am",
                summary: "Two easy chord shapes, picked as arpeggios.", minutes: 10, isFree: false,
                sections: [
                    LessonSection(
                        heading: "E minor (022000)",
                        body: "Middle finger on string 5, fret 2. Ring finger on string 4, fret 2. All six strings ring. Your thumb starts on string 6."
                    ),
                    LessonSection(
                        heading: "A minor (x02210)",
                        body: "Index on string 2, fret 1. Middle on string 4, fret 2. Ring on string 3, fret 2. Don't play string 6 — your thumb starts on string 5."
                    ),
                    LessonSection(
                        heading: "Picking through the chords",
                        body: "Play p-i-m-a once over Em, then switch to Am and play it again. Notice that the middle finger only slides across one string between the two shapes.",
                        tab: emAm,
                        tips: ["Press just behind the fret, not on top of it.", "Arch your fingers so they don't mute the open strings."]
                    )
                ]
            ),
            Lesson(
                id: "u2-c-g", unit: 2, title: "Chords: C and G",
                summary: "Two essential shapes and where the thumb starts for each.", minutes: 12, isFree: false,
                sections: [
                    LessonSection(
                        heading: "C major (x32010)",
                        body: "Ring finger on string 5, fret 3. Middle on string 4, fret 2. Index on string 2, fret 1. Thumb starts on string 5."
                    ),
                    LessonSection(
                        heading: "G major (320003)",
                        body: "Middle finger on string 6, fret 3. Index on string 5, fret 2. Ring on string 1, fret 3. Thumb starts on string 6.",
                        tab: cG,
                        tips: ["The bass note is the chord's root — make sure the thumb lands on the right string.", "If C buzzes, roll your index finger slightly onto its tip."]
                    )
                ]
            ),
            Lesson(
                id: "u2-changes", unit: 2, title: "Smooth Chord Changes",
                summary: "Change shapes without breaking the rhythm.", minutes: 12, isFree: false,
                sections: [
                    LessonSection(
                        heading: "The one-minute change drill",
                        body: "Pick two chords. Set a one-minute timer and switch back and forth, strumming once per shape. Count your changes and try to beat your score tomorrow."
                    ),
                    LessonSection(
                        heading: "Keep the hand moving",
                        body: "In fingerstyle, the picking hand never stops. If your fretting hand is late, let an open string ring rather than pausing. Loop the four chords below with the metronome.",
                        tab: fourChordLoop,
                        tips: ["Look ahead: move the finger that has the farthest to travel first.", "Keep fingers close to the strings between shapes."]
                    )
                ]
            )
        ]),
        LessonUnit(id: 3, title: "Travis Picking & Songs", subtitle: "Put it together into real music", lessons: [
            Lesson(
                id: "u3-travis-c", unit: 3, title: "Travis Picking on C",
                summary: "The classic folk pattern: steady thumb, fingers in between.", minutes: 15, isFree: false,
                sections: [
                    LessonSection(
                        heading: "How the pattern works",
                        body: "The thumb plays every beat, alternating between the root (string 5) and string 4. The fingers fill the off-beats. Start with the thumb alone, then add one finger at a time.",
                        tab: travisC,
                        tips: ["Practice at 50 BPM until it feels automatic.", "Say it out loud: “thumb-and-thumb-and”."]
                    )
                ]
            ),
            Lesson(
                id: "u3-travis-g", unit: 3, title: "Travis Picking on G",
                summary: "Move the pattern to G and switch between the two chords.", minutes: 15, isFree: false,
                sections: [
                    LessonSection(
                        heading: "Same hand, new bass",
                        body: "On G, the thumb alternates between string 6 and string 4. The fingers keep the same job. Play two bars of C, then two bars of G, and repeat.",
                        tab: travisG,
                        tips: ["Change chords on the last off-beat of the bar so the next downbeat is clean."]
                    )
                ]
            ),
            Lesson(
                id: "u3-morning-light", unit: 3, title: "Song Study: Morning Light",
                summary: "An original beginner piece using everything you've learned.", minutes: 20, isFree: false,
                sections: [
                    LessonSection(
                        heading: "Part A",
                        body: "Part A rolls through Am and C with a six-note arpeggio that goes up and back down. Play it four times.",
                        tab: morningLightA
                    ),
                    LessonSection(
                        heading: "Part B",
                        body: "Part B uses pinches on G and Em, then ends on a full Am chord. Let the last chord ring for a whole bar.",
                        tab: morningLightB,
                        tips: ["Form: A A B A, then finish on the Am chord.", "Once it's comfortable, nudge the metronome up by 4 BPM at a time."]
                    )
                ]
            ),
            Lesson(
                id: "u3-plan", unit: 3, title: "Your Daily Practice Plan",
                summary: "A 15-minute routine that keeps you improving.", minutes: 5, isFree: false,
                sections: [
                    LessonSection(
                        heading: "15 minutes a day",
                        body: "2 min — tune up.\n3 min — p-i-m-a on open strings with the metronome.\n4 min — chord change drill.\n4 min — Travis pattern or today's lesson.\n2 min — play something you enjoy, just for fun."
                    ),
                    LessonSection(
                        heading: "Track it",
                        body: "Use the timer on the Practice tab. Short daily sessions beat one long session a week — watch your streak grow.",
                        tips: ["Stop before your fingers hurt; calluses take a couple of weeks.", "Record yourself once a week to hear your progress."]
                    )
                ]
            )
        ])
    ]

    static var allLessons: [Lesson] { units.flatMap(\.lessons) }

    static func lesson(id: String) -> Lesson? { allLessons.first { $0.id == id } }
}
