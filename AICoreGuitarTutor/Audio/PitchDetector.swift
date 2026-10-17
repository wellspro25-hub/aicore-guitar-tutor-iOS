//
//  PitchDetector.swift
//  AICore Guitar Tutor
//
//  YIN pitch detection (de Cheveigné & Kawahara, 2002), tuned for guitar:
//  roughly 60 Hz (below low E) up to 1,100 Hz.
//

import Foundation

struct PitchDetector: Sendable {
    var threshold: Float = 0.12
    var minFrequency: Double = 60
    var maxFrequency: Double = 1100
    /// Signals quieter than this (RMS) are treated as silence.
    var noiseGate: Float = 0.008

    /// Returns the fundamental frequency in Hz, or nil if no clear pitch was found.
    func detect(_ samples: [Float], sampleRate: Double) -> Double? {
        let count = samples.count
        guard count > 256, sampleRate > 0 else { return nil }

        // Noise gate
        var energy: Float = 0
        for s in samples { energy += s * s }
        let rms = (energy / Float(count)).squareRoot()
        guard rms >= noiseGate else { return nil }

        let minTau = max(2, Int(sampleRate / maxFrequency))
        let maxTau = min(count / 2, Int(sampleRate / minFrequency))
        guard maxTau > minTau + 2 else { return nil }
        let window = count - maxTau

        // 1. Difference function
        var diff = [Float](repeating: 0, count: maxTau + 1)
        samples.withUnsafeBufferPointer { x in
            for tau in 1...maxTau {
                var sum: Float = 0
                var j = 0
                while j < window {
                    let d = x[j] - x[j + tau]
                    sum += d * d
                    j += 1
                }
                diff[tau] = sum
            }
        }

        // 2. Cumulative mean normalized difference
        var cmnd = [Float](repeating: 1, count: maxTau + 1)
        var runningSum: Float = 0
        for tau in 1...maxTau {
            runningSum += diff[tau]
            cmnd[tau] = runningSum > 0 ? diff[tau] * Float(tau) / runningSum : 1
        }

        // 3. Absolute threshold — first dip below threshold, then walk to its local minimum
        var bestTau = -1
        var tau = minTau
        while tau < maxTau {
            if cmnd[tau] < threshold {
                while tau + 1 < maxTau && cmnd[tau + 1] < cmnd[tau] { tau += 1 }
                bestTau = tau
                break
            }
            tau += 1
        }
        guard bestTau > 0 else { return nil }

        // 4. Parabolic interpolation for sub-sample accuracy
        var refined = Double(bestTau)
        if bestTau > 1 && bestTau < maxTau {
            let s0 = Double(cmnd[bestTau - 1])
            let s1 = Double(cmnd[bestTau])
            let s2 = Double(cmnd[bestTau + 1])
            let denominator = 2 * (2 * s1 - s2 - s0)
            if abs(denominator) > 1e-9 {
                refined += (s2 - s0) / denominator
            }
        }

        let frequency = sampleRate / refined
        guard frequency >= minFrequency, frequency <= maxFrequency else { return nil }
        return frequency
    }
}

/// Musical note helpers (A4 = 440 Hz, equal temperament).
enum Notes {
    static let names = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]

    static func midi(for frequency: Double, a4: Double = 440) -> Double {
        69 + 12 * log2(frequency / a4)
    }

    static func frequency(forMidi midi: Double, a4: Double = 440) -> Double {
        a4 * pow(2, (midi - 69) / 12)
    }

    static func name(forMidi midi: Int) -> (name: String, octave: Int) {
        let index = ((midi % 12) + 12) % 12
        return (names[index], midi / 12 - 1)
    }

    static func cents(_ frequency: Double, relativeTo target: Double) -> Double {
        1200 * log2(frequency / target)
    }
}

enum GuitarString: Int, CaseIterable, Identifiable {
    case lowE = 6, a = 5, d = 4, g = 3, b = 2, highE = 1

    var id: Int { rawValue }

    /// MIDI note in standard tuning.
    var midi: Int {
        switch self {
        case .lowE: 40   // E2
        case .a: 45      // A2
        case .d: 50      // D3
        case .g: 55      // G3
        case .b: 59      // B3
        case .highE: 64  // E4
        }
    }

    var label: String {
        switch self {
        case .lowE: "E"
        case .a: "A"
        case .d: "D"
        case .g: "G"
        case .b: "B"
        case .highE: "e"
        }
    }

    var frequency: Double { Notes.frequency(forMidi: Double(midi)) }

    /// Low E first, as the strings appear when you look down at the guitar.
    static let lowToHigh: [GuitarString] = [.lowE, .a, .d, .g, .b, .highE]
}
