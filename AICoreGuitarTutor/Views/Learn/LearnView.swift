//
//  LearnView.swift
//  AICore Guitar Tutor
//

import SwiftUI
import SwiftData

struct LearnView: View {
    @Environment(StoreManager.self) private var store
    @Query private var progress: [LessonProgress]
    @State private var showPaywall = false

    private var completedIDs: Set<String> { Set(progress.map(\.lessonID)) }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    CourseProgressCard(
                        completed: completedIDs.count,
                        total: LessonLibrary.allLessons.count,
                        nextLesson: nextLesson
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }

                ForEach(LessonLibrary.units) { unit in
                    Section {
                        ForEach(unit.lessons) { lesson in
                            lessonRow(lesson)
                        }
                    } header: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Unit \(unit.id): \(unit.title)")
                                .font(.headline)
                                .foregroundStyle(.primary)
                                .textCase(nil)
                            Text(unit.subtitle)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .textCase(nil)
                        }
                        .padding(.vertical, 4)
                    }
                }

                if !store.isPremium {
                    Section {
                        Button {
                            showPaywall = true
                        } label: {
                            Label("Unlock all lessons with Premium", systemImage: "lock.open.fill")
                                .font(.headline)
                        }
                    }
                }
            }
            .navigationTitle("Learn")
            .navigationDestination(for: Lesson.self) { lesson in
                LessonDetailView(lesson: lesson)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    private var nextLesson: Lesson? {
        LessonLibrary.allLessons.first { !completedIDs.contains($0.id) }
    }

    @ViewBuilder
    private func lessonRow(_ lesson: Lesson) -> some View {
        if store.canOpen(lesson) {
            NavigationLink(value: lesson) {
                LessonRow(lesson: lesson, isCompleted: completedIDs.contains(lesson.id), isLocked: false)
            }
        } else {
            Button {
                showPaywall = true
            } label: {
                LessonRow(lesson: lesson, isCompleted: false, isLocked: true)
            }
            .buttonStyle(.plain)
        }
    }
}

private struct LessonRow: View {
    let lesson: Lesson
    let isCompleted: Bool
    let isLocked: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(isCompleted ? Color.green.opacity(0.18) : Color.accentColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: isCompleted ? "checkmark" : (isLocked ? "lock.fill" : "play.fill"))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(isCompleted ? Color.green : (isLocked ? Color.secondary : Color.accentColor))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(lesson.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(isLocked ? Color.secondary : Color.primary)
                Text(lesson.summary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 4)

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(lesson.minutes) min")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if lesson.isFree {
                    Text("FREE")
                        .font(.caption2.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.15), in: Capsule())
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityHint(isLocked ? "Requires Premium" : "")
    }
}

private struct CourseProgressCard: View {
    let completed: Int
    let total: Int
    let nextLesson: Lesson?

    private var fraction: Double { total == 0 ? 0 : Double(completed) / Double(total) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Beginner Fingerstyle")
                        .font(.title3.bold())
                    Text("\(completed) of \(total) lessons complete")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                }
                Spacer()
                ZStack {
                    Circle().stroke(.white.opacity(0.25), lineWidth: 6)
                    Circle()
                        .trim(from: 0, to: fraction)
                        .stroke(.white, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(Int(fraction * 100))%")
                        .font(.caption.bold())
                }
                .frame(width: 54, height: 54)
            }

            if let nextLesson {
                Text("Up next: \(nextLesson.title)")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.white.opacity(0.9))
            } else {
                Text("Course complete — great work! 🎸")
                    .font(.footnote.weight(.medium))
            }
        }
        .foregroundStyle(.white)
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [Color("BrandDark"), Color.accentColor.opacity(0.85)],
                           startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .padding(.vertical, 6)
    }
}

#Preview {
    LearnView()
        .environment(StoreManager())
        .environment(Metronome())
        .environment(RiffPlayer())
        .environment(ProfileStore())
        .modelContainer(for: [LessonProgress.self, PracticeSession.self], inMemory: true)
}
