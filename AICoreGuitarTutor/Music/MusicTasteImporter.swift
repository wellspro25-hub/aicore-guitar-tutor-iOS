//
//  MusicTasteImporter.swift
//  AICore Guitar Tutor
//
//  Optional: reads what the player has recently listened to in Apple Music
//  (only after they allow it) and turns it into favorite styles and artists.
//  Nothing leaves the device.
//
//  Setup: enable the MusicKit app service for com.aicore.guitartutor at
//  developer.apple.com → Certificates, IDs & Profiles → Identifiers → App Services.
//

import Foundation
import MusicKit

enum MusicTasteImporter {
    struct Taste {
        let genres: [Genre]
        let artists: [String]
    }

    enum ImportError: LocalizedError {
        case notAllowed
        case nothingFound

        var errorDescription: String? {
            switch self {
            case .notAllowed: "Apple Music access is off. You can turn it on in Settings → Guitar Tutor."
            case .nothingFound: "We couldn't find recent listening in Apple Music. Pick your styles below instead."
            }
        }
    }

    static func importTaste() async throws -> Taste {
        let status = await MusicAuthorization.request()
        guard status == .authorized else { throw ImportError.notAllowed }

        var request = MusicRecentlyPlayedRequest<Song>()
        request.limit = 30
        let response = try await request.response()

        var genreCounts: [Genre: Int] = [:]
        var artistCounts: [String: Int] = [:]
        for song in response.items {
            artistCounts[song.artistName, default: 0] += 1
            for name in song.genreNames {
                if let genre = Genre.match(name) { genreCounts[genre, default: 0] += 1 }
            }
        }
        guard !genreCounts.isEmpty || !artistCounts.isEmpty else { throw ImportError.nothingFound }

        let genres = genreCounts.sorted { $0.value > $1.value }.prefix(4).map(\.key)
        let artists = artistCounts.sorted { $0.value > $1.value }.prefix(5).map(\.key)
        return Taste(genres: Array(genres), artists: Array(artists))
    }
}
