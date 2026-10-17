//
//  PracticeView.swift
//  AICore Guitar Tutor
//
//  Metronome + practice timer with daily streaks.
//

import SwiftUI
import SwiftData

struct PracticeView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    MetronomeCard()
                    PracticeTimerCard()
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Practice")
        }
    }
}

// MARK: - Metronome

struct MetronomeCard: View {
    @Environment(Metronome.self) private var metronome

    var body: some View {
        @Bindable var metronome = metronome

        VStack(spacing: 18) {
            HStack {
                Label("Metronome", systemImage: "metronome.fill")
                    .font(.headline)
                Spacer()
                Text(Self.tempoName(for: metronome.bpm))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !metronome.isPlaying)) { _ in
                BeatDots(count: metronome.beatsPerBar, current: metronome.currentBeat())
            }
            .frame(height: 28)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(Int(metronome.bpm))")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Text("BPM")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 14) {
                StepButton(systemImage: "minus") { metronome.bpm -= 1 }
                Slider(value: $metronome.bpm, in: Metronome.bpmRange, step: 1)
                StepButton(systemImage: "plus") { metronome.bpm += 1 }
            }

            Picker("Beats per bar", selection: $metronome.beatsPerBar) {
                ForEach([2, 3, 4, 6], id: \.self) { beats in
                    Text("\(beats)/4").tag(beats)
                }
            }
            .pickerStyle(.segmented)

            Toggle("Accent first beat", isOn: $metronome.accentFirstBeat)
                .font(.subheadline)

            HStack(spacing: 12) {
                Button {
                    metronome.tap()
                } label: {
                    Text("Tap Tempo")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button {
                    metronome.toggle()
                } label: {
                    Label(metronome.isPlaying ? "Stop" : "Start",
                          systemImage: metronome.isPlaying ? "stop.fill" : "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }

            if let error = metronome.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    static func tempoName(for bpm: Double) -> String {
        switch bpm {
        case ..<60: return "Largo · slow"
        case ..<76: return "Adagio · relaxed"
        case ..<108: return "Andante · walking"
        case ..<120: return "Moderato · moderate"
        case ..<168: return "Allegro · fast"
        default: return "Presto · very fast"
        }
    }
}

private struct BeatDots: View {
    let count: Int
    let current: Int?

    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<count, id: \.self) { beat in
                Circle()
                    .fill(beat == current ? (beat == 0 ? Color.accentColor : Color.primary) : Color.secondary.opacity(0.25))
                    .frame(width: beat == 0 ? 22 : 18, height: beat == 0 ? 22 : 18)
                    .scaleEffect(beat == current ? 1.15 : 1)
            }
        }
        .accessibilityHidden(true)
    }
}

private struct StepButton: View {
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.headline)
                .frame(width: 40, height: 40)
                .background(Color(.tertiarySystemFill), in: Circle())
        }
        .buttonStyle(.plain)
        .buttonRepeatBehavior(.enabled)
    }
}

// MARK: - Practice timer

struct PracticeTimerCard: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ProfileStore.self) private var profile
    @Query(sort: \PracticeSession.startedAt, order: .reverse) private var sessions: [PracticeSession]

    /// Seconds since 1970 when the current session started; 0 = not running.
    /// Stored so the timer survives the app being closed.
    @AppStorage("practiceTimerStart") private var timerStart: Double = 0

    private var isRunning: Bool { timerStart > 0 }

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Label("Practice Timer", systemImage: "timer")
                    .font(.headline)
                Spacer()
            }

            TimelineView(.periodic(from: .now, by: 1)) { context in
                Text(PracticeStats.format(elapsed(at: context.date)))
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(isRunning ? Color.primary : Color.secondary)
            }

            Button {
                isRunning ? finishSession() : startSession()
            } label: {
                Label(isRunning ? "Finish & Save" : "Start Practicing",
                      systemImage: isRunning ? "checkmark.circle.fill" : "play.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(isRunning ? Color.green : Color.accentColor)
            .controlSize(.large)

            HStack(spacing: 12) {
                StatTile(value: PracticeStats.format(PracticeStats.seconds(on: .now, in: sessions)), label: "Today")
                StatTile(value: "\(PracticeStats.streak(in: sessions))", label: "Day streak")
                StatTile(value: "\(sessions.count)", label: "Sessions")
            }

            if !sessions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent")
                        .font(.subheadline.bold())
                    ForEach(sessions.prefix(5)) { session in
                        HStack {
                            Text(session.startedAt, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day().hour().minute())
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(PracticeStats.format(session.seconds))
                                .monospacedDigit()
                        }
                        .font(.subheadline)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func elapsed(at date: Date) -> Int {
        guard isRunning else { return 0 }
        return max(0, Int(date.timeIntervalSince1970 - timerStart))
    }

    private func startSession() {
        timerStart = Date().timeIntervalSince1970
    }

    private func finishSession() {
        let seconds = elapsed(at: .now)
        let start = Date(timeIntervalSince1970: timerStart)
        timerStart = 0
        // Ignore accidental taps.
        guard seconds >= 10 else { return }
        modelContext.insert(PracticeSession(startedAt: start, seconds: seconds))
        profile.addXP(max(1, seconds / 60), reason: "Practice saved")
        try? modelContext.save()
    }
}

private struct StatTile: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

#Preview {
    PracticeView()
        .environment(Metronome())
        .environment(ProfileStore())
        .modelContainer(for: [LessonProgress.self, PracticeSession.self], inMemory: true)
}
