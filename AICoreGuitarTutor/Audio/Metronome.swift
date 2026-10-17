//
//  Metronome.swift
//  AICore Guitar Tutor
//
//  Sample-accurate metronome: one bar of clicks is synthesized into a buffer
//  and looped by AVAudioPlayerNode, so timing never drifts.
//

import AVFoundation
import Observation

@MainActor
@Observable
final class Metronome {
    static let bpmRange: ClosedRange<Double> = 40...200

    var bpm: Double = 80 {
        didSet {
            let clamped = min(Self.bpmRange.upperBound, max(Self.bpmRange.lowerBound, bpm.rounded()))
            if clamped != bpm { bpm = clamped; return }
            if isPlaying && oldValue != bpm { reschedule() }
        }
    }

    var beatsPerBar: Int = 4 {
        didSet { if isPlaying && oldValue != beatsPerBar { reschedule() } }
    }

    var accentFirstBeat = true {
        didSet { if isPlaying && oldValue != accentFirstBeat { reschedule() } }
    }

    private(set) var isPlaying = false
    var errorMessage: String?

    @ObservationIgnored private let engine = AVAudioEngine()
    @ObservationIgnored private let player = AVAudioPlayerNode()
    @ObservationIgnored private let sampleRate: Double = 44_100
    @ObservationIgnored private var framesPerBeat: AVAudioFramePosition = 0
    @ObservationIgnored private var isConfigured = false
    @ObservationIgnored private var tapTimes: [Date] = []

    private var format: AVAudioFormat? {
        AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)
    }

    // MARK: - Control

    func toggle() {
        isPlaying ? stop() : start()
    }

    func start() {
        guard !isPlaying else { return }
        do {
            try AudioSessionManager.activate()
            try configureIfNeeded()
            if !engine.isRunning { try engine.start() }
            schedule()
            player.play()
            isPlaying = true
            errorMessage = nil
        } catch {
            errorMessage = "The metronome couldn't start: \(error.localizedDescription)"
        }
    }

    func stop() {
        guard isPlaying else { return }
        player.stop()
        engine.stop()
        isPlaying = false
    }

    /// Start at a specific tempo (used by lesson play-along buttons).
    func play(at tempo: Int) {
        bpm = Double(tempo)
        if !isPlaying { start() }
    }

    /// Tap tempo: averages the last few taps.
    func tap() {
        let now = Date()
        if let last = tapTimes.last, now.timeIntervalSince(last) > 2 { tapTimes.removeAll() }
        tapTimes.append(now)
        if tapTimes.count > 5 { tapTimes.removeFirst() }
        guard tapTimes.count >= 2, let first = tapTimes.first, let last = tapTimes.last else { return }
        let interval = last.timeIntervalSince(first) / Double(tapTimes.count - 1)
        guard interval > 0 else { return }
        bpm = 60 / interval
    }

    /// The beat (0-based) currently sounding, read from the audio clock.
    func currentBeat() -> Int? {
        guard isPlaying, framesPerBeat > 0,
              let nodeTime = player.lastRenderTime,
              let playerTime = player.playerTime(forNodeTime: nodeTime),
              playerTime.sampleTime >= 0 else { return nil }
        return Int((playerTime.sampleTime / framesPerBeat) % AVAudioFramePosition(beatsPerBar))
    }

    // MARK: - Audio

    private func configureIfNeeded() throws {
        guard !isConfigured else { return }
        guard let format else { throw MetronomeError.format }
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        isConfigured = true
    }

    private func reschedule() {
        player.stop()
        schedule()
        player.play()
    }

    private func schedule() {
        guard let buffer = makeBarBuffer() else { return }
        player.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
    }

    private func makeBarBuffer() -> AVAudioPCMBuffer? {
        guard let format else { return nil }
        let beatFrames = AVAudioFramePosition((sampleRate * 60 / bpm).rounded())
        framesPerBeat = beatFrames
        let totalFrames = AVAudioFrameCount(beatFrames * AVAudioFramePosition(beatsPerBar))
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: totalFrames),
              let data = buffer.floatChannelData?[0] else { return nil }
        buffer.frameLength = totalFrames

        for i in 0..<Int(totalFrames) { data[i] = 0 }

        let clickFrames = Int(sampleRate * 0.035)
        for beat in 0..<beatsPerBar {
            let accented = accentFirstBeat && beat == 0
            let pitch: Double = accented ? 1_760 : 1_200
            let amplitude: Double = accented ? 0.9 : 0.6
            let start = Int(beatFrames) * beat
            for i in 0..<clickFrames where start + i < Int(totalFrames) {
                let t = Double(i) / sampleRate
                let envelope = exp(-t / 0.007)
                data[start + i] = Float(sin(2 * .pi * pitch * t) * envelope * amplitude)
            }
        }
        return buffer
    }

    enum MetronomeError: LocalizedError {
        case format
        var errorDescription: String? { "Unsupported audio format." }
    }
}
