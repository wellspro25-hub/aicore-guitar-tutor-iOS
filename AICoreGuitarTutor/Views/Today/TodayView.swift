//
//  TodayView.swift
//  AICore Guitar Tutor
//
//  The home screen: level, daily goal, streak, what to do next, and riffs
//  picked from the music the player likes.
//

import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(ProfileStore.self) private var profile
    @Environment(StoreManager.self) private var store
    @Query private var progress: [LessonProgress]
    @Query private var sessions: [PracticeSession]
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        return hour < 12 ? "Good morning" : hour < 18 ? "Good afternoon" : "Good evening"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ProgressHero(
                        greeting: greeting,
                        level: profile.levelInfo,
                        todaySeconds: PracticeStats.seconds(on: .now, in: sessions),
                        goalMinutes: profile.data.dailyGoalMinutes,
                        streak: PracticeStats.streak(in: sessions),
                        lessonsDone: Set(progress.map(\.lessonID)).count,
                        riffsLearned: profile.data.learned.count
                    )

                    if let next = nextLesson {
                        NavigationLink(value: next) {
                            HomeFeatureRow(icon: "book.fill", eyebrow: "Continue course", title: next.title,
                                       detail: "\(next.minutes) min · Unit \(next.unit)")
                        }
                        .buttonStyle(.plain)
                    }

                    if let daily = dailyRiff {
                        NavigationLink(value: daily) {
                            HomeFeatureRow(icon: "flame.fill", eyebrow: "Today's riff challenge", title: daily.title,
                                       detail: "Play it through with the mic for +15 XP")
                        }
                        .buttonStyle(.plain)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(profile.data.genres.isEmpty ? "Popular riffs" : "Picked for you")
                                .font(.title3.bold())
                            Spacer()
                        }
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(profile.rankedRiffs.dropFirst().prefix(7)) { riff in
                                    NavigationLink(value: riff) {
                                        RiffCard(riff: riff, highlighted: profile.data.genres)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .scrollTargetLayout()
                        }
                        .scrollTargetBehavior(.viewAligned)
                        if !profile.data.genres.isEmpty {
                            Text(basedOn)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    SponsorCard(slot: 0)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Today")
            .navigationDestination(for: Lesson.self) { LessonDetailView(lesson: $0) }
            .navigationDestination(for: Riff.self) { riff in
                if store.isPremium || riff.isFree || riff.id == dailyRiff?.id {
                    RiffDetailView(riff: riff)
                } else {
                    LockedRiffView(riff: riff)
                }
            }
        }
    }

    private var nextLesson: Lesson? {
        let done = Set(progress.map(\.lessonID))
        return LessonLibrary.allLessons.first { !done.contains($0.id) && store.canOpen($0) }
    }

    private var basedOn: String {
        let styles = profile.data.genres.map(\.label).joined(separator: ", ")
        return profile.data.artists.isEmpty ? "Based on \(styles)" : "Based on \(styles) · \(profile.data.artists)"
    }

    /// The daily challenge is always free, even for non-Premium players.
    private var dailyRiff: Riff? { profile.rankedRiffs.first }
}

private struct ProgressHero: View {
    let greeting: String
    let level: LevelInfo
    let todaySeconds: Int
    let goalMinutes: Int
    let streak: Int
    let lessonsDone: Int
    let riffsLearned: Int

    private var fraction: Double { min(1, Double(todaySeconds) / Double(max(1, goalMinutes * 60))) }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Level \(level.number) · \(level.name)")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.22), in: Capsule())
                        .foregroundStyle(Color(red: 0.96, green: 0.64, blue: 0.28))
                    Text(greeting)
                        .font(.title2.bold())
                    Text(fraction >= 1 ? "Daily goal done. Anything extra is a bonus."
                                       : "\(max(1, goalMinutes - todaySeconds / 60)) min left in today's \(goalMinutes)-minute goal")
                        .font(.subheadline)
                        .opacity(0.85)
                }
                Spacer(minLength: 0)
                ZStack {
                    Circle().stroke(.white.opacity(0.2), lineWidth: 7)
                    Circle()
                        .trim(from: 0, to: fraction)
                        .stroke(Color(red: 0.96, green: 0.64, blue: 0.28), style: StrokeStyle(lineWidth: 7, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 0) {
                        Text("\(todaySeconds / 60)/\(goalMinutes)").font(.caption.bold()).monospacedDigit()
                        Text("min").font(.caption2)
                    }
                }
                .frame(width: 70, height: 70)
            }

            ProgressView(value: level.progress)
                .tint(Color(red: 0.96, green: 0.64, blue: 0.28))
                .accessibilityLabel("\(level.xpToNext) XP to the next level")

            HStack(spacing: 8) {
                HeroStat(value: "\(streak)", label: "day streak")
                HeroStat(value: "\(lessonsDone)/\(LessonLibrary.allLessons.count)", label: "lessons")
                HeroStat(value: "\(riffsLearned)", label: "riffs learned")
            }
        }
        .foregroundStyle(.white)
        .padding(20)
        .background(
            LinearGradient(colors: [Color("BrandTeal"), Color("BrandDark")], startPoint: .topTrailing, endPoint: .bottomLeading),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
    }
}

private struct HeroStat: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.headline).monospacedDigit()
            Text(label).font(.caption2).opacity(0.75)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct HomeFeatureRow: View {
    let icon: String
    let eyebrow: String
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(width: 46, height: 46)
                .background(Color.accentColor.opacity(0.13), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(eyebrow.uppercased())
                    .font(.caption2.weight(.bold))
                    .tracking(0.6)
                    .foregroundStyle(Color.accentColor)
                Text(title).font(.headline)
                Text(detail).font(.footnote).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contentShape(Rectangle())
    }
}

struct RiffCard: View {
    let riff: Riff
    let highlighted: [Genre]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(riff.isOriginal ? "ORIGINAL" : "PUBLIC DOMAIN")
                    .font(.caption2.weight(.bold))
                    .tracking(0.5)
                    .foregroundStyle(Color.accentColor)
                Spacer()
                DifficultyDots(level: riff.level)
            }
            Text(riff.title)
                .font(.headline)
                .lineLimit(2)
            Text(riff.why)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            GenrePills(tags: Array(riff.tags.prefix(3)), highlighted: highlighted)
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(width: 240, height: 170, alignment: .topLeading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct DifficultyDots: View {
    let level: Int

    var body: some View {
        HStack(spacing: 3) {
            ForEach(1...3, id: \.self) { i in
                Circle()
                    .fill(i <= level ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(width: 7, height: 7)
            }
        }
        .accessibilityLabel(["Easy", "Medium", "Harder"][max(0, min(2, level - 1))])
    }
}

struct GenrePills: View {
    let tags: [Genre]
    let highlighted: [Genre]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(tags) { tag in
                let mine = highlighted.contains(tag)
                Text(tag.label)
                    .font(.caption2.weight(.bold))
                    .lineLimit(1)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background((mine ? Color.accentColor : Color("BrandTeal")).opacity(0.14), in: Capsule())
                    .foregroundStyle(mine ? Color.accentColor : Color("BrandTeal"))
            }
        }
    }
}
