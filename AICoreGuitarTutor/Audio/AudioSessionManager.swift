//
//  AudioSessionManager.swift
//  AICore Guitar Tutor
//

import AVFoundation

enum AudioSessionManager {
    /// One shared configuration for the tuner (input) and metronome (output).
    /// `.defaultToSpeaker` keeps the click on the loudspeaker instead of the earpiece.
    static func activate() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(
            .playAndRecord,
            mode: .default,
            options: [.defaultToSpeaker, .allowBluetoothA2DP, .mixWithOthers]
        )
        try session.setActive(true)
    }
}
