//
//  RootView.swift
//  AICore Guitar Tutor
//

import SwiftUI

struct RootView: View {
    enum Tab: String, Hashable { case today, learn, riffs, tools, you }

    @SceneStorage("selectedTab") private var selection: Tab = .today
    @Environment(Metronome.self) private var metronome
    @Environment(RiffPlayer.self) private var player
    @Environment(ProfileStore.self) private var profile

    var body: some View {
        @Bindable var profile = profile

        TabView(selection: $selection) {
            TodayView()
                .tabItem { Label("Today", systemImage: "house.fill") }
                .tag(Tab.today)

            LearnView()
                .tabItem { Label("Learn", systemImage: "book.fill") }
                .tag(Tab.learn)

            RiffsView()
                .tabItem { Label("Riffs", systemImage: "music.note.list") }
                .tag(Tab.riffs)

            ToolsView(isActive: selection == .tools)
                .tabItem { Label("Tools", systemImage: "tuningfork") }
                .tag(Tab.tools)

            SettingsView()
                .tabItem { Label("You", systemImage: "person.crop.circle") }
                .tag(Tab.you)
        }
        .onChange(of: selection) { _, _ in
            // Stop riff playback when leaving a screen; the metronome keeps going on purpose.
            player.stop()
        }
        .overlay(alignment: .bottom) {
            if metronome.isPlaying && selection != .tools {
                NowPlayingBar()
                    .padding(.horizontal)
                    .padding(.bottom, 58)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .overlay(alignment: .top) {
            if let toast = profile.toast {
                Text(toast)
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.regularMaterial, in: Capsule())
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .task(id: toast) {
                        try? await Task.sleep(for: .seconds(2.2))
                        withAnimation { profile.toast = nil }
                    }
            }
        }
        .animation(.snappy, value: profile.toast)
        .animation(.snappy, value: metronome.isPlaying)
        .sensoryFeedback(.success, trigger: profile.toast) { _, new in new != nil }
        .fullScreenCover(isPresented: Binding(
            get: { !profile.data.onboarded },
            set: { presented in if !presented { profile.data.onboarded = true } }
        )) {
            OnboardingView()
        }
    }
}

/// Keeps the metronome controllable from any screen.
private struct NowPlayingBar: View {
    @Environment(Metronome.self) private var metronome

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "metronome.fill")
            Text("\(Int(metronome.bpm)) BPM")
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
            Spacer()
            Button("Stop") { metronome.stop() }
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.thickMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
    }
}

#Preview {
    RootView()
        .environment(StoreManager())
        .environment(Metronome())
        .environment(RiffPlayer())
        .environment(ProfileStore())
        .environment(SponsorService())
        .modelContainer(for: [LessonProgress.self, PracticeSession.self], inMemory: true)
}
