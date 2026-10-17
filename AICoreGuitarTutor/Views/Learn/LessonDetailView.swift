//
//  LessonDetailView.swift
//  AICore Guitar Tutor
//

import SwiftUI
import SwiftData

struct LessonDetailView: View {
    let lesson: Lesson

    @Environment(\.modelContext) private var modelContext
    @Environment(Metronome.self) private var metronome
    @Environment(ProfileStore.self) private var profile
    @Query private var progress: [LessonProgress]

    private var isCompleted: Bool { progress.contains { $0.lessonID == lesson.id } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Unit \(lesson.unit) · \(lesson.minutes) min")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.accentColor)
                    Text(lesson.summary)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                ForEach(lesson.sections) { section in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(section.heading)
                            .font(.title2.bold())
                        Text(section.body)
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)

                        if let tab = section.tab {
                            TabPatternView(pattern: tab)
                        }

                        if !section.tips.isEmpty {
                            TipsBox(tips: section.tips)
                        }
                    }
                }

                Button {
                    toggleComplete()
                } label: {
                    Label(isCompleted ? "Completed" : "Mark lesson complete",
                          systemImage: isCompleted ? "checkmark.circle.fill" : "checkmark.circle")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .tint(isCompleted ? Color.green : Color.accentColor)
                .controlSize(.large)
                .padding(.top, 8)
            }
            .padding()
        }
        .navigationTitle(lesson.title)
        .navigationBarTitleDisplayMode(.large)
        .onDisappear { metronome.stop() }
    }

    private func toggleComplete() {
        if let existing = progress.first(where: { $0.lessonID == lesson.id }) {
            modelContext.delete(existing)
        } else {
            modelContext.insert(LessonProgress(lessonID: lesson.id))
            profile.addXP(50, reason: "Lesson complete")
        }
        try? modelContext.save()
    }
}

private struct TipsBox: View {
    let tips: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Tips", systemImage: "lightbulb.fill")
                .font(.subheadline.bold())
                .foregroundStyle(Color.accentColor)
            ForEach(tips, id: \.self) { tip in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("•")
                    Text(tip)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .font(.subheadline)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        LessonDetailView(lesson: LessonLibrary.allLessons[2])
    }
    .environment(Metronome())
    .environment(RiffPlayer())
    .environment(ProfileStore())
    .modelContainer(for: [LessonProgress.self, PracticeSession.self], inMemory: true)
}
