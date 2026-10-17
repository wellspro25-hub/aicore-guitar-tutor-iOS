//
//  RiffPlayer.swift
//  AICore Guitar Tutor
//
//  Plays any tab pattern with a plucked-string sound so players can hear it
//  before they try it. The whole pattern is synthesized into one buffer and
//  played by AVAudioPlayerNode, so the highlighted note always matches the sound.
//

import AVFoundation
import Observation

@MainActor
@Observable
final class RiffPlayer {
    /// Identifies which tab on screen is playing.
    private(set) var activeKey: String?
    private(set) var isLooping = false
    var errorMessage: String?

    @ObservationIgnored private let engine = AVAudioEngine()
    @ObservationIgnored private let player = AVAudioPlayerNode()
    @ObservationIgnored private let sampleRate: Double = 44_100
    @ObservationIgnored private var isConfigured = false
    @ObservationIgnored private var stepStartFrames: [(stepIndex: Int, frame: Int)] = []
    @ObservationIgnored private var lengthFrames = 0
    @ObservationIgnored private var playToken = 0

    func isPlaying(_ key: String) -> Bool { activeKey == key }

    func play(_ pattern: TabPattern, key: String, speed: Double, loop: Bool) {
        stop()
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return }
        let bpm = Double(pattern.suggestedBPM) * speed
        guard let rendered = Self.render(pattern, bpm: bpm, sampleRate: sampleRate, format: format, loop: loop) else { return }
        stepStartFrames = rendered.starts
        lengthFrames = rendered.length

        do {
            try AudioSessionManager.activate()
            if !isConfigured {
                engine.attach(player)
                engine.connect(player, to: engine.mainMixerNode, format: format)
                isConfigured = true
            }
            if !engine.isRunning { try engine.start() }
        } catch {
            errorMessage = "Playback couldn't start: \(error.localizedDescription)"
            return
        }

        playToken += 1
        let token = playToken
        if loop {
            player.scheduleBuffer(rendered.buffer, at: nil, options: .loops, completionHandler: nil)
        } else {
            player.scheduleBuffer(rendered.buffer, at: nil, options: [], completionCallbackType: .dataPlayedBack) { [weak self] _ in
                Task { @MainActor in
                    guard let self, self.playToken == token else { return }
                    self.stop()
                }
            }
        }
        player.play()
        activeKey = key
        isLooping = loop
    }

    func stop() {
        playToken += 1
        if isConfigured { player.stop() }
        if engine.isRunning { engine.stop() }
        activeKey = nil
        isLooping = false
    }

    /// Index of the step sounding right now, read from the audio clock.
    func currentStepIndex() -> Int? {
        guard activeKey != nil, lengthFrames > 0,
              let nodeTime = player.lastRenderTime,
              let playerTime = player.playerTime(forNodeTime: nodeTime),
              playerTime.sampleTime >= 0 else { return nil }
        let frame = Int(playerTime.sampleTime) % lengthFrames
        var current: Int?
        for start in stepStartFrames {
            if start.frame <= frame { current = start.stepIndex } else { break }
        }
        return current
    }

    // MARK: - Synthesis

    private struct Rendered {
        let buffer: AVAudioPCMBuffer
        let starts: [(stepIndex: Int, frame: Int)]
        let length: Int
    }

    private static func render(_ pattern: TabPattern, bpm: Double, sampleRate: Double, format: AVAudioFormat, loop: Bool) -> Rendered? {
        let secondsPerBeat = 60 / max(20, bpm)
        let length = Int((pattern.totalBeats * secondsPerBeat * sampleRate).rounded())
        guard length > 0 else { return nil }
        // A looping buffer is exactly one pass long; a single pass lets the last note ring out.
        let total = loop ? length : length + Int(sampleRate * 1.5)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(total)),
              let out = buffer.floatChannelData?[0] else { return nil }
        buffer.frameLength = AVAudioFrameCount(total)
        for i in 0..<total { out[i] = 0 }

        var starts: [(stepIndex: Int, frame: Int)] = []
        var cursor = 0.0
        for (index, step) in pattern.steps.enumerated() where !step.isBar {
            let startFrame = Int(cursor * secondsPerBeat * sampleRate)
            starts.append((index, startFrame))
            let volume = 0.32 / Double(max(1, step.notes.count)).squareRoot()
            for (k, note) in step.notes.enumerated() {
                let strumOffset = Int(Double(k) * 0.014 * sampleRate)
                pluck(into: out, total: total, at: startFrame + strumOffset,
                      midi: note.midi, beats: step.beats, secondsPerBeat: secondsPerBeat,
                      sampleRate: sampleRate, volume: volume, wrap: loop)
            }
            cursor += step.beats
        }
        return Rendered(buffer: buffer, starts: starts, length: length)
    }

    private static func pluck(into out: UnsafeMutablePointer<Float>, total: Int, at start: Int, midi: Int,
                              beats: Double, secondsPerBeat: Double, sampleRate: Double, volume: Double, wrap: Bool) {
        let frequency = 440 * pow(2, (Double(midi) - 69) / 12)
        let seconds = min(2.4, max(0.35, beats * secondsPerBeat * 1.8))
        let count = Int(seconds * sampleRate)
        let twoPiF = 2 * Double.pi * frequency / sampleRate
        let decay = 4.6 / Double(count)          // ~ -40 dB by the end
        let attack = Int(0.005 * sampleRate)
        for i in 0..<count {
            var index = start + i
            if index >= total {
                guard wrap else { break }
                index %= total
            }
            let phase = twoPiF * Double(i)
            // Bright attack that mellows: higher harmonics fade faster.
            let env = exp(-decay * Double(i))
            let bright = exp(-decay * 3 * Double(i))
            var sample = sin(phase) + 0.5 * sin(2 * phase) * (0.4 + 0.6 * bright)
            sample += 0.28 * sin(3 * phase) * bright + 0.14 * sin(4 * phase) * bright
            let fadeIn = i < attack ? Double(i) / Double(attack) : 1
            out[index] += Float(sample * env * fadeIn * volume * 0.55)
        }
    }
}
