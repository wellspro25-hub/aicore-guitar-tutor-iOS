//
//  NoteTrainer.swift
//  AICore Guitar Tutor
//
//  "Practice with mic": listens to the guitar and moves through a tab one note
//  at a time, lighting up each note the player hits. Audio is analysed in memory
//  only — nothing is recorded.
//

import AVFoundation
import Observation

@MainActor
@Observable
final class NoteTrainer {
    enum State: Equatable { case idle, listening, finished(seconds: Int, notes: Int), failed(String) }

    private(set) var state: State = .idle
    /// Index into `pattern.steps` of the note to play next.
    private(set) var nextStep: Int?
    private(set) var hitSteps: Set<Int> = []

    var isActive: Bool { state == .listening }

    @ObservationIgnored private let engine = AVAudioEngine()
    @ObservationIgnored private var pattern: TabPattern?
    @ObservationIgnored private var order: [Int] = []
    @ObservationIgnored private var position = 0
    @ObservationIgnored private var matchCount = 0
    @ObservationIgnored private var needsNewAttack = false
    @ObservationIgnored private var armed = true
    @ObservationIgnored private var lastLevel: Float = 0
    @ObservationIgnored private var startedAt = Date()

    /// Called when the player finishes the whole pattern (seconds, notes).
    @ObservationIgnored var onFinish: ((Int, Int) -> Void)?

    var progressText: String {
        guard let pattern, let nextStep, order.indices.contains(position) else { return "" }
        let step = pattern.steps[nextStep]
        let what: String
        if step.notes.count == 1, let n = step.notes.first {
            what = "string \(n.string), fret \(n.fret) (\(Notes.name(forMidi: n.midi).name))"
        } else {
            what = "chord " + step.notes.map { "\($0.string)/\($0.fret)" }.joined(separator: " ")
        }
        return "Note \(position + 1) of \(order.count) · play \(what)"
    }

    func start(_ pattern: TabPattern) async {
        stop()
        let granted = await AVAudioApplication.requestRecordPermission()
        guard granted else {
            state = .failed("Microphone access is off. Turn it on in Settings → Guitar Tutor → Microphone.")
            return
        }
        self.pattern = pattern
        order = pattern.steps.indices.filter { !pattern.steps[$0].notes.isEmpty }
        guard !order.isEmpty else { return }
        position = 0
        hitSteps = []
        matchCount = 0
        needsNewAttack = false
        armed = true
        nextStep = order[0]

        do {
            try AudioSessionManager.activate()
            let input = engine.inputNode
            let format = input.outputFormat(forBus: 0)
            guard format.sampleRate > 0, format.channelCount > 0 else {
                state = .failed("No microphone input is available.")
                return
            }
            let tap = Self.makeTap(sampleRate: format.sampleRate) { [weak self] frequency, level in
                Task { @MainActor in self?.ingest(frequency, level: level) }
            }
            input.removeTap(onBus: 0)
            input.installTap(onBus: 0, bufferSize: 4096, format: format, block: tap)
            engine.prepare()
            try engine.start()
            startedAt = Date()
            state = .listening
        } catch {
            state = .failed("The microphone couldn't start: \(error.localizedDescription)")
        }
    }

    func stop() {
        if engine.isRunning {
            engine.inputNode.removeTap(onBus: 0)
            engine.stop()
        }
        if state == .listening { state = .idle }
        nextStep = nil
    }

    func reset() {
        stop()
        state = .idle
        hitSteps = []
    }

    nonisolated private static func makeTap(
        sampleRate: Double,
        onPitch: @escaping @Sendable (Double?, Float) -> Void
    ) -> AVAudioNodeTapBlock {
        let detector = PitchDetector()
        let window = TrainerWindow(size: 4096, hop: 2048)
        return { buffer, _ in
            guard let channel = buffer.floatChannelData?[0] else { return }
            let frames = Int(buffer.frameLength)
            guard frames > 0 else { return }
            window.add(UnsafeBufferPointer(start: channel, count: frames))
            while let samples = window.nextWindow() {
                var energy: Float = 0
                for s in samples { energy += s * s }
                let level = (energy / Float(samples.count)).squareRoot()
                onPitch(detector.detect(samples, sampleRate: sampleRate), level)
            }
        }
    }

    private func ingest(_ frequency: Double?, level: Float) {
        guard state == .listening, let pattern, order.indices.contains(position) else { return }

        // A new pluck (sudden jump in level) or silence re-arms repeated notes.
        if level > lastLevel * 1.5 + 0.004 || level < 0.006 { armed = true }
        lastLevel = level

        guard let frequency else { matchCount = 0; return }
        let played = Notes.midi(for: frequency)
        let step = pattern.steps[order[position]]
        // Accept the right note in any octave — pitch trackers sometimes jump an octave.
        let matches = step.notes.contains { note in
            [0.0, 12, -12].contains { abs(played - Double(note.midi) - $0) < 0.5 }
        }
        guard matches else { matchCount = 0; return }
        if needsNewAttack && !armed { return }
        matchCount += 1
        guard matchCount >= 2 else { return }

        hitSteps.insert(order[position])
        matchCount = 0
        position += 1
        guard order.indices.contains(position) else {
            finish()
            return
        }
        let next = pattern.steps[order[position]]
        needsNewAttack = next.notes.contains { n in step.notes.contains { ($0.midi - n.midi) % 12 == 0 } }
        armed = false
        nextStep = order[position]
    }

    private func finish() {
        let seconds = max(1, Int(Date().timeIntervalSince(startedAt)))
        let notes = order.count
        if engine.isRunning {
            engine.inputNode.removeTap(onBus: 0)
            engine.stop()
        }
        nextStep = nil
        state = .finished(seconds: seconds, notes: notes)
        onFinish?(seconds, notes)
    }
}

/// Rolling sample buffer used only on the audio thread.
private final class TrainerWindow: @unchecked Sendable {
    private var samples: [Float] = []
    private let size: Int
    private let hop: Int

    init(size: Int, hop: Int) {
        self.size = size
        self.hop = hop
        samples.reserveCapacity(size * 3)
    }

    func add(_ input: UnsafeBufferPointer<Float>) {
        samples.append(contentsOf: input)
        if samples.count > size * 3 { samples.removeFirst(samples.count - size * 2) }
    }

    func nextWindow() -> [Float]? {
        guard samples.count >= size else { return nil }
        let window = Array(samples.prefix(size))
        samples.removeFirst(hop)
        return window
    }
}
