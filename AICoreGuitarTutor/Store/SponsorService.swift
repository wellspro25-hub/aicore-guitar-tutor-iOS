//
//  SponsorService.swift
//  AICore Guitar Tutor
//
//  Direct-sold sponsor cards. The list is a small JSON file you host
//  (the same sponsors.json the web version uses), so you can sell and change
//  ad space without shipping an app update. No tracking, no ad network.
//  Premium subscribers never see sponsor cards.
//

import Foundation
import Observation

struct Sponsor: Codable, Hashable {
    var label: String?
    var title: String
    var text: String?
    var cta: String?
    var url: String

    var link: URL? {
        guard let u = URL(string: url), u.scheme == "https" else { return nil }
        return u
    }
}

@MainActor
@Observable
final class SponsorService {
    private(set) var sponsors: [Sponsor] = SponsorService.builtIn

    static let builtIn: [Sponsor] = [
        Sponsor(label: "Sponsored", title: "Reach new guitar players",
                text: "Put your guitar shop, lessons or gear in front of beginners who practice every day.",
                cta: "Advertise here", url: AppLinks.advertise.absoluteString),
        Sponsor(label: "Affiliate", title: "Starter gear checklist",
                text: "Clip-on tuner, capo, picks and fresh strings: the four things that make week one easier.",
                cta: "See the gear", url: AppLinks.gearAffiliate.absoluteString)
    ]

    private struct Feed: Decodable { let sponsors: [Sponsor] }

    func refresh() async {
        do {
            var request = URLRequest(url: AppLinks.sponsorsFeed)
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.timeoutInterval = 10
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return }
            let feed = try JSONDecoder().decode(Feed.self, from: data)
            let valid = feed.sponsors.filter { $0.link != nil }
            if !valid.isEmpty { sponsors = valid }
        } catch {
            // Offline or feed not set up yet: keep the built-in cards.
        }
    }

    /// Rotates daily so each sponsor gets equal time.
    func sponsor(slot: Int, date: Date = .now) -> Sponsor? {
        guard !sponsors.isEmpty else { return nil }
        let day = Int(date.timeIntervalSince1970 / 86_400)
        return sponsors[(day + slot) % sponsors.count]
    }
}
