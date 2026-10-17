//
//  TunerEngine.swift
//  AICore Guitar Tutor
//
//  Listens to the microphone and publishes the detected note.
//  Audio is analysed in memory only — nothing is recorded or saved.
//

import AVFoundation
import Observation

@MainActor
@Observable
final class TunerEngine {
    enum PermissionState { case unknown, granted, denied }

    // Published reading
    private(set) var frequency: Double?
    private(set) var noteName = "–"
    private(set) var octave: Int?
    /// −50…+50, how far the note is from the target.
    private(set) var cents: Double = 0
    /// True while a string is actually ringing.
    private(set) var hasSignal = false

    private(set) var isRunning = false
    private(set) var permission: PermissionState = .unknown
    var errorMessage: String?

    /// nil = auto-detect the closest string.
    var lockedString: GuitarString?

    /// The string the tuner is currently comparing against.
    private(set) var targetString: GuitarString?

    var isInTune: Bool { hasSignal && abs(cents) <= 5 }

    @ObservationIgnored private let engine = AVAudioEngine()
    @ObservationIgnored private var smoothedMidi: Double?
    @ObservationIgnored private var silentFrames = 0
    @ObservationIgnored private var isStarting = false
    @ObservationIgnored private var wantsToRun = false

    // MARK: - Control

    func start() async {
        wantsToRun = true
        guard !isRunning, !isStarting else { return }
        isStarting = true
        defer { isStarting = false }

        let granted = await AVAudioApplication.requestRecordPermission()
        permission = granted ? .granted : .denied
        guard granted, wantsToRun else { return }

        do {
            try AudioSessionManager.activate()

            let input = engine.inputNode
            let format = input.outputFormat(forBus: 0)
            guard format.sampleRate > 0, format.channelCount > 0 else {
                errorMessage = "No microphone input is available."
                return
            }

            let tap = Self.makeTap(sampleRate: format.sampleRate) { [weak self] frequency in
                Task { @MainActor in self?.ingest(frequency) }
            }
            input.removeTap(onBus: 0)
            input.installTap(onBus: 0, bufferSize: 4096, format: format, block: tap)

            engine.prepare()
            try engine.start()
            isRunning = true
            errorMessage = nil
        } catch {
            errorMessage = "The tuner couldn't start: \(error.localizedDescription)"
            stop()
        }
    }

    func stop() {
        wantsToRun = false
        if isRunning || engine.isRunning {
            engine.inputNode.removeTap(onBus: 0)
            engine.stop()
        }
        isRunning = false
        hasSignal = false
        smoothedMidi = nil
    }

    // MARK: - Analysis

    /// Built outside the main actor: the tap runs on a real-time audio thread.
    nonisolated private static func makeTap(
        sampleRate: Double,
        onPitch: @escaping @Sendable (Double?) -> Void
    ) -> AVAudioNodeTapBlock {
        let detector = PitchDetector()
        // iOS may deliver smaller buffers than requested; collect a full
        // 4096-sample window (enough for low E) with 50% overlap.
        let window = SampleWindow(size: 4096, hop: 2048)
        return { buffer, _ in
            guard let channel = buffer.floatChannelData?[0] else { return }
            let frames = Int(buffer.frameLength)
            guard frames > 0 else { return }
            window.add(UnsafeBufferPointer(start: channel, count: frames))
            while let samples = window.nextWindow() {
                onPitch(detector.detect(samples, sampleRate: sampleRate))
            }
        }
    }

    private func ingest(_ detected: Double?) {
        guard isRunning else { return }

        guard let detected else {
            silentFrames += 1
            if silentFrames > 10 {         // ~0.5 s of silence
                hasSignal = false
                smoothedMidi = nil
            }
            return
        }
        silentFrames = 0

        let midi = Notes.midi(for: detected)

        // Smooth small wobbles, but jump immediately when a new note is played.
        if let previous = smoothedMidi, abs(previous - midi) < 0.6 {
            smoothedMidi = previous * 0.7 + midi * 0.3
        } else {
            smoothedMidi = midi
        }
        guard let smooth = smoothedMidi else { return }

        let target: GuitarString
        if let lockedString {
            target = lockedString
        } else {
            target = GuitarString.allCases.min { abs(Double($0.midi) - smooth) < abs(Double($1.midi) - smooth) } ?? .lowE
        }
        targetString = target

        let nearest = Int(smooth.rounded())
        let note = Notes.name(forMidi: nearest)
        noteName = note.name
        octave = note.octave
        frequency = Notes.frequency(forMidi: smooth)

        // Against a locked string we show the distance to that string (clamped);
        // in auto mode we show the distance to the nearest note.
        let rawCents = lockedString != nil ? (smooth - Double(target.midi)) * 100 : (smooth - Double(nearest)) * 100
        cents = min(50, max(-50, rawCents))
        hasSignal = true
    }
}

/// Rolling sample buffer used only from the audio thread.
private final class SampleWindow: @unchecked Sendable {
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
        // Never let the backlog grow if analysis falls behind.
        if samples.count > size * 3 {
            samples.removeFirst(samples.count - size * 2)
        }
    }

    /// Returns the next full analysis window, advancing by `hop` samples.
    func nextWindow() -> [Float]? {
        guard samples.count >= size else { return nil }
        let window = Array(samples.prefix(size))
        samples.removeFirst(hop)
        return window
    }
}
