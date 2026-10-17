//
//  TabPatternView.swift
//  AICore Guitar Tutor
//
//  Interactive tab: hear it (with notes lighting up), slow it down, loop it,
//  or practice it with the microphone.
//

import SwiftUI
import SwiftData

struct TabPatternView: View {
    let pattern: TabPattern
    /// Called after a successful mic practice run.
    var onTrained: (() -> Void)? = nil

    @Environment(RiffPlayer.self) private var player
    @Environment(Metronome.self) private var metronome
    @Environment(ProfileStore.self) private var profile
    @Environment(\.modelContext) private var modelContext
    @AppStorage("playbackSpeed") private var speed: Double = 1
    @State private var loop = false
    @State private var trainer = NoteTrainer()
    @State private var key = UUID().uuidString

    private var isPlaying: Bool { player.isPlaying(key) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(pattern.title)
                    .font(.headline)
                Spacer()
                Button {
                    togglePlay()
                } label: {
                    Label(isPlaying ? "Stop" : "Play", systemImage: isPlaying ? "stop.fill" : "play.fill")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }

            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isPlaying)) { _ in
                TabGrid(
                    steps: pattern.steps,
                    current: isPlaying ? player.currentStepIndex() : nil,
                    next: trainer.nextStep,
                    hits: trainer.hitSteps
                )
            }

            if !pattern.fingering.isEmpty {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("Picking:").fontWeight(.semibold)
                    Text(pattern.fingering).foregroundStyle(Color.accentColor)
                }
                .font(.footnote)
            }

            HStack(spacing: 8) {
                Picker("Speed", selection: $speed) {
                    Text("50%").tag(0.5)
                    Text("75%").tag(0.75)
                    Text("100%").tag(1.0)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 190)
                .onChange(of: speed) { _, _ in if isPlaying { startPlayback() } }

                Toggle(isOn: $loop) {
                    Image(systemName: "repeat")
                }
                .toggleStyle(.button)
                .accessibilityLabel("Loop")
                .onChange(of: loop) { _, _ in if isPlaying { startPlayback() } }

                Spacer(minLength: 0)
            }

            Button {
                toggleTrainer()
            } label: {
                Label(trainer.isActive ? "Stop practice" : "Practice with mic",
                      systemImage: trainer.isActive ? "stop.fill" : "mic.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(Color("BrandTeal"))

            statusText
        }
        .padding(14)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onAppear {
            trainer.onFinish = { seconds, _ in
                modelContext.insert(PracticeSession(startedAt: Date().addingTimeInterval(-Double(seconds)), seconds: seconds))
                try? modelContext.save()
                profile.addXP(15, reason: "Practice run")
                onTrained?()
            }
        }
        .onDisappear {
            if isPlaying { player.stop() }
            trainer.stop()
        }
        .sensoryFeedback(.success, trigger: trainer.hitSteps.count) { old, new in new > old }
    }

    @ViewBuilder
    private var statusText: some View {
        switch trainer.state {
        case .listening:
            Text(trainer.progressText)
                .font(.subheadline)
        case .finished(let seconds, let notes):
            Label("Nailed it — \(notes) notes in \(PracticeStats.format(seconds)). Try a faster speed next.", systemImage: "checkmark.seal.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.green)
        case .failed(let message):
            Text(message)
                .font(.footnote)
                .foregroundStyle(.red)
        case .idle:
            Text(isPlaying ? "Playing at \(Int(Double(pattern.suggestedBPM) * speed)) BPM" : "\(pattern.suggestedBPM) BPM at 100% · tap Play to hear it")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private func togglePlay() {
        if isPlaying { player.stop() } else { startPlayback() }
    }

    private func startPlayback() {
        trainer.reset()
        metronome.stop()
        player.play(pattern, key: key, speed: speed, loop: loop)
    }

    private func toggleTrainer() {
        if trainer.isActive {
            trainer.stop()
        } else {
            player.stop()
            metronome.stop()
            Task { await trainer.start(pattern) }
        }
    }
}

/// Six-string tab drawn as columns, so each step can be highlighted.
struct TabGrid: View {
    let steps: [TabStep]
    let current: Int?
    let next: Int?
    let hits: Set<Int>

    private let rowHeight: CGFloat = 26
    private let labels = ["e", "B", "G", "D", "A", "E"]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    VStack(spacing: 0) {
                        ForEach(labels, id: \.self) { label in
                            Text(label)
                                .font(.system(.footnote, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .frame(width: 20, height: rowHeight, alignment: .leading)
                        }
                    }
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        column(step, index: index)
                            .id(index)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
            }
            .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .onChange(of: current) { _, value in
                if let value { withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo(value, anchor: .center) } }
            }
            .onChange(of: next) { _, value in
                if let value { withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo(value, anchor: .center) } }
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Guitar tab with \(steps.filter { !$0.notes.isEmpty }.count) notes")
    }

    @ViewBuilder
    private func column(_ step: TabStep, index: Int) -> some View {
        if step.isBar {
            Rectangle()
                .fill(Color.secondary.opacity(0.5))
                .frame(width: 1.5, height: rowHeight * 6)
                .padding(.horizontal, 4)
        } else {
            let width = 18 + CGFloat(step.beats) * 22
            VStack(spacing: 0) {
                ForEach(1...6, id: \.self) { string in
                    ZStack {
                        Rectangle()
                            .fill(Color.secondary.opacity(0.45))
                            .frame(height: 1.5)
                        if let note = step.notes.first(where: { $0.string == string }) {
                            Text("\(note.fret)")
                                .font(.system(.callout, design: .monospaced).weight(.semibold))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(fill(for: index), in: RoundedRectangle(cornerRadius: 5))
                                .foregroundStyle(isMarked(index) ? Color.white : Color.primary)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(Color.accentColor, lineWidth: next == index ? 2 : 0)
                                )
                        }
                    }
                    .frame(width: width, height: rowHeight)
                }
            }
        }
    }

    private func isMarked(_ index: Int) -> Bool { current == index || hits.contains(index) }

    private func fill(for index: Int) -> Color {
        if current == index { return .accentColor }
        if hits.contains(index) { return .green }
        return Color(.tertiarySystemBackground)
    }
}
