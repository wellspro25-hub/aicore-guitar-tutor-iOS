//
//  AICoreGuitarTutorApp.swift
//  AICore Guitar Tutor
//
//  © 2026 AICore LLC. All rights reserved.
//

import SwiftUI
import SwiftData

@main
struct AICoreGuitarTutorApp: App {
    @State private var store = StoreManager()
    @State private var metronome = Metronome()
    @State private var player = RiffPlayer()
    @State private var profile = ProfileStore()
    @State private var sponsors = SponsorService()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(metronome)
                .environment(player)
                .environment(profile)
                .environment(sponsors)
                .task { await store.start() }
                .task { await sponsors.refresh() }
        }
        .modelContainer(for: [LessonProgress.self, PracticeSession.self])
    }
}
