//
//  RiffDetailView.swift
//  AICore Guitar Tutor
//

import SwiftUI

struct RiffDetailView: View {
    let riff: Riff
    @Environment(ProfileStore.self) private var profile

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(riff.origin.uppercased())
                        .font(.caption.weight(.bold))
                        .tracking(0.6)
                        .foregroundStyle(Color.accentColor)
                    Text(riff.why)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 8) {
                        GenrePills(tags: riff.tags, highlighted: profile.data.genres)
                        DifficultyDots(level: riff.level)
                    }
                }

                TabPatternView(pattern: riff.pattern)

                VStack(alignment: .leading, spacing: 8) {
                    Label("How to learn it fast", systemImage: "lightbulb.fill")
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.accentColor)
                    Text("1. Tap Play at 50% and follow the highlighted notes.")
                    Text("2. Turn on loop and play along until it feels easy.")
                    Text("3. Tap Practice with mic. The app listens and lights up each note you hit.")
                }
                .font(.subheadline)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                Button {
                    profile.toggleLearned(riff.id)
                } label: {
                    Label(profile.isLearned(riff.id) ? "Learned" : "I've learned this · +40 XP",
                          systemImage: profile.isLearned(riff.id) ? "checkmark.circle.fill" : "checkmark.circle")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .tint(profile.isLearned(riff.id) ? Color.green : Color.accentColor)
                .controlSize(.large)
            }
            .padding()
        }
        .navigationTitle(riff.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    profile.toggleFavorite(riff.id)
                } label: {
                    Image(systemName: profile.isFavorite(riff.id) ? "heart.fill" : "heart")
                }
                .accessibilityLabel(profile.isFavorite(riff.id) ? "Remove from favorites" : "Add to favorites")
            }
        }
        .sensoryFeedback(.success, trigger: profile.data.learned.count) { old, new in new > old }
    }
}
