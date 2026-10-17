//
//  TunerView.swift
//  AICore Guitar Tutor
//

import SwiftUI
import UIKit

struct TunerView: View {
    /// True while the tuner is on screen — the mic only runs then.
    let isActive: Bool

    @State private var tuner = TunerEngine()
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL

    var body: some View {
        Group {
            if tuner.permission == .denied {
                permissionDenied
            } else {
                tunerContent
            }
        }
        .onAppear { updateRunning() }
        .onChange(of: isActive) { _, _ in updateRunning() }
        .onChange(of: scenePhase) { _, _ in updateRunning() }
        .onDisappear { tuner.stop() }
        .sensoryFeedback(.success, trigger: tuner.isInTune) { wasInTune, isInTune in
            !wasInTune && isInTune
        }
    }

    private func updateRunning() {
        if isActive && scenePhase == .active {
            Task { await tuner.start() }
        } else {
            tuner.stop()
        }
    }

    // MARK: - Main content

    private var tunerContent: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 0)

            noteDisplay

            TunerGauge(cents: tuner.hasSignal ? tuner.cents : 0,
                       isActive: tuner.hasSignal,
                       isInTune: tuner.isInTune)
                .frame(height: 170)
                .padding(.horizontal, 24)

            statusLabel

            stringPicker
                .padding(.horizontal)

            Spacer(minLength: 0)

            if let error = tuner.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Text("Standard tuning · A4 = 440 Hz")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.bottom, 12)
        }
    }

    private var noteDisplay: some View {
        VStack(spacing: 4) {
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(tuner.hasSignal ? tuner.noteName : "–")
                    .font(.system(size: 96, weight: .bold, design: .rounded))
                if tuner.hasSignal, let octave = tuner.octave {
                    Text("\(octave)")
                        .font(.system(size: 32, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(tuner.isInTune ? Color.green : Color.primary)
            .contentTransition(.numericText())
            .animation(.snappy, value: tuner.noteName)

            Text(frequencyText)
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var frequencyText: String {
        guard tuner.hasSignal, let f = tuner.frequency else { return tuner.isRunning ? "Listening…" : " " }
        let sign = tuner.cents >= 0 ? "+" : "−"
        return String(format: "%.1f Hz  ·  %@%.0f ¢", f, sign, abs(tuner.cents))
    }

    private var statusLabel: some View {
        Group {
            if !tuner.hasSignal {
                Label("Pluck a string", systemImage: "waveform")
                    .foregroundStyle(.secondary)
            } else if tuner.isInTune {
                Label("In tune", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else if tuner.cents < 0 {
                Label("Too low — tighten", systemImage: "arrow.up.circle.fill")
                    .foregroundStyle(.orange)
            } else {
                Label("Too high — loosen", systemImage: "arrow.down.circle.fill")
                    .foregroundStyle(.orange)
            }
        }
        .font(.headline)
        .animation(.default, value: tuner.isInTune)
    }

    private var stringPicker: some View {
        HStack(spacing: 8) {
            StringChip(title: "Auto", isSelected: tuner.lockedString == nil, isTarget: false) {
                tuner.lockedString = nil
            }
            ForEach(GuitarString.lowToHigh) { string in
                StringChip(
                    title: string.label,
                    isSelected: tuner.lockedString == string,
                    isTarget: tuner.hasSignal && tuner.targetString == string
                ) {
                    tuner.lockedString = (tuner.lockedString == string) ? nil : string
                }
                .accessibilityLabel("String \(string.rawValue), \(string.label)")
            }
        }
    }

    // MARK: - Permission

    private var permissionDenied: some View {
        ContentUnavailableView {
            Label("Microphone Access Needed", systemImage: "mic.slash.fill")
        } description: {
            Text("The tuner listens to your guitar to find the note. Audio stays on your iPhone and is never recorded.")
        } actions: {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

// MARK: - Components

private struct StringChip: View {
    let title: String
    let isSelected: Bool
    let isTarget: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(minWidth: 36, minHeight: 36)
                .padding(.horizontal, title.count > 1 ? 8 : 0)
                .background(
                    Capsule().fill(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
                )
                .overlay(
                    Capsule().stroke(Color.green, lineWidth: isTarget && !isSelected ? 2 : 0)
                )
                .foregroundStyle(isSelected ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
    }
}

struct TunerGauge: View {
    let cents: Double
    let isActive: Bool
    let isInTune: Bool

    private var needleColor: Color {
        guard isActive else { return .secondary }
        return isInTune ? .green : .orange
    }

    var body: some View {
        GeometryReader { geo in
            let radius = max(40, min(geo.size.width / 2, geo.size.height) - 10)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height - 4)

            ZStack {
                // In-tune zone
                Circle()
                    .trim(from: 0, to: 12.0 / 360.0)
                    .stroke(Color.green.opacity(0.25), style: StrokeStyle(lineWidth: 14))
                    .frame(width: radius * 2 - 30, height: radius * 2 - 30)
                    .rotationEffect(.degrees(-96))
                    .position(center)

                // Tick marks every 5 cents
                ForEach(-10...10, id: \.self) { i in
                    let major = i % 5 == 0
                    Capsule()
                        .fill(i == 0 ? Color.green : Color.secondary.opacity(major ? 0.9 : 0.45))
                        .frame(width: major ? 3 : 2, height: major ? 18 : 10)
                        .offset(y: -radius + (major ? 9 : 5))
                        .rotationEffect(.degrees(Double(i) * 6))
                        .position(center)
                }

                Text("♭")
                    .font(.title2.bold())
                    .foregroundStyle(.secondary)
                    .position(x: center.x - radius * 0.95, y: center.y - radius * 0.35)
                Text("♯")
                    .font(.title2.bold())
                    .foregroundStyle(.secondary)
                    .position(x: center.x + radius * 0.95, y: center.y - radius * 0.35)

                // Needle
                Capsule()
                    .fill(needleColor)
                    .frame(width: 4, height: radius - 14)
                    .offset(y: -(radius - 14) / 2)
                    .rotationEffect(.degrees(cents / 50 * 60))
                    .position(center)
                    .animation(.interpolatingSpring(stiffness: 170, damping: 18), value: cents)

                Circle()
                    .fill(needleColor)
                    .frame(width: 16, height: 16)
                    .position(center)
            }
        }
        .accessibilityElement()
        .accessibilityLabel(isActive ? String(format: "%.0f cents %@", abs(cents), cents < 0 ? "flat" : "sharp") : "No note detected")
    }
}

#Preview {
    NavigationStack { TunerView(isActive: false) }
}
