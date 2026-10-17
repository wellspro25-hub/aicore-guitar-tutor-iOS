//
//  OnboardingView.swift
//  AICore Guitar Tutor
//
//  First launch: level, favorite music (typed or imported from Apple Music)
//  and a daily goal. Everything can be changed later on the You tab.
//

import SwiftUI

struct OnboardingView: View {
    @Environment(ProfileStore.self) private var profile

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Image(systemName: "guitars.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(Color.accentColor)
                    .padding(.top, 24)
                Text("Let's tune this app to you")
                    .font(.largeTitle.bold())
                Text("Three quick questions. We'll pick riffs from the styles you love and set a daily goal you can keep.")
                    .font(.title3)
                    .foregroundStyle(.secondary)

                TasteEditor()

                Button {
                    profile.data.onboarded = true
                } label: {
                    Text("Start playing")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button("Skip for now") { profile.data.onboarded = true }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 24)
            }
            .padding(.horizontal)
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

/// Level, styles, artists and daily goal. Used in onboarding and on the You tab.
struct TasteEditor: View {
    @Environment(ProfileStore.self) private var profile
    @State private var isImporting = false
    @State private var importMessage: String?

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 8)]

    var body: some View {
        @Bindable var profile = profile

        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Your level").font(.headline)
                Picker("Your level", selection: $profile.data.level) {
                    ForEach(SkillLevel.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Music you listen to").font(.headline)
                Button {
                    importFromAppleMusic()
                } label: {
                    HStack {
                        Image(systemName: "music.note")
                        Text(isImporting ? "Reading your Apple Music…" : "Use my Apple Music listening")
                        Spacer()
                        if isImporting { ProgressView() }
                    }
                }
                .buttonStyle(.bordered)
                .disabled(isImporting)

                if let importMessage {
                    Text(importMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                    ForEach(Genre.allCases) { genre in
                        let selected = profile.data.genres.contains(genre)
                        Button {
                            profile.toggleGenre(genre)
                        } label: {
                            Text(genre.label)
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(selected ? Color.accentColor : Color(.secondarySystemFill), in: Capsule())
                                .foregroundStyle(selected ? Color.white : Color.primary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(selected ? .isSelected : [])
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Favorite artists or songs (optional)").font(.headline)
                TextField("e.g. Metallica, Taylor Swift, the Star Wars score", text: $profile.data.artists)
                    .textFieldStyle(.roundedBorder)
                    .submitLabel(.done)
                Text("Used to pick riffs for you. Saved on this iPhone only.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Daily practice goal").font(.headline)
                Picker("Daily practice goal", selection: $profile.data.dailyGoalMinutes) {
                    ForEach([5, 10, 15, 20, 30], id: \.self) { Text("\($0) min").tag($0) }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private func importFromAppleMusic() {
        isImporting = true
        importMessage = nil
        Task { @MainActor in
            do {
                let taste = try await MusicTasteImporter.importTaste()
                for genre in taste.genres where !profile.data.genres.contains(genre) {
                    profile.data.genres.append(genre)
                }
                if !taste.artists.isEmpty {
                    profile.data.artists = taste.artists.joined(separator: ", ")
                }
                importMessage = taste.genres.isEmpty
                    ? "Found your artists. Pick a few styles below too."
                    : "Added \(taste.genres.map(\.label).joined(separator: ", ")) from your recent listening."
            } catch {
                importMessage = error.localizedDescription
            }
            isImporting = false
        }
    }
}
