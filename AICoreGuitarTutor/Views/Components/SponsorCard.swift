//
//  SponsorCard.swift
//  AICore Guitar Tutor
//

import SwiftUI

/// A clearly labeled sponsor or affiliate card. Hidden for Premium members.
struct SponsorCard: View {
    let slot: Int

    @Environment(SponsorService.self) private var service
    @Environment(StoreManager.self) private var store

    var body: some View {
        if !store.isPremium, let sponsor = service.sponsor(slot: slot), let link = sponsor.link {
            VStack(alignment: .leading, spacing: 8) {
                Text((sponsor.label ?? "Sponsored").uppercased())
                    .font(.caption2.weight(.bold))
                    .tracking(0.6)
                    .foregroundStyle(.secondary)
                Text(sponsor.title)
                    .font(.headline)
                if let text = sponsor.text {
                    Text(text)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Link(destination: link) {
                    Text(sponsor.cta ?? "Learn more")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.secondary.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
            )
            .accessibilityElement(children: .contain)
        }
    }
}
