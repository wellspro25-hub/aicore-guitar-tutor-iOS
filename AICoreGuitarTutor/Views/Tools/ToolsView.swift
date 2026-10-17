//
//  ToolsView.swift
//  AICore Guitar Tutor
//
//  Tuner, metronome and practice timer in one place.
//

import SwiftUI

struct ToolsView: View {
    enum Tool: String, CaseIterable, Identifiable {
        case tuner = "Tuner", metronome = "Metronome", timer = "Timer"
        var id: String { rawValue }
    }

    /// True while the Tools tab is selected.
    let isActive: Bool

    @AppStorage("selectedTool") private var tool: Tool = .tuner
    @Environment(Metronome.self) private var metronome

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Picker("Tool", selection: $tool) {
                    ForEach(Tool.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                switch tool {
                case .tuner:
                    TunerView(isActive: isActive && tool == .tuner)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .metronome:
                    ScrollView { MetronomeCard().padding() }
                case .timer:
                    ScrollView { PracticeTimerCard().padding() }
                }
            }
            .padding(.top, 4)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Tools")
            .onChange(of: tool) { _, newTool in
                // The tuner needs a quiet room.
                if newTool == .tuner { metronome.stop() }
            }
        }
    }
}
