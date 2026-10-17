//
//  RiffsView.swift
//  AICore Guitar Tutor
//

import SwiftUI

struct RiffsView: View {
    enum Filter: Hashable {
        case forYou, all, easiest, favorites, learned
        case genre(Genre)

        var label: String {
            switch self {
            case .forYou: "For you"
            case .all: "All"
            case .easiest: "Easiest"
            case .favorites: "Favorites"
            case .learned: "Learned"
            case .genre(let g): g.label
            }
        }
    }

    @Environment(ProfileStore.self) private var profile
    @Environment(StoreManager.self) private var store
    @State private var filter: Filter = .forYou
    @State private var query = ""

    private let filters: [Filter] = [.forYou, .all, .genre(.movieTV), .easiest, .favorites, .learned]
        + Genre.allCases.filter { $0 != .movieTV }.map { Filter.genre($0) }

    private var riffs: [Riff] {
        var items: [Riff]
        switch filter {
        case .forYou: items = profile.rankedRiffs
        case .all: items = RiffLibrary.all
        case .easiest: items = RiffLibrary.all.filter { $0.level == 1 }
        case .favorites: items = RiffLibrary.all.filter { profile.isFavorite($0.id) }
        case .learned: items = RiffLibrary.all.filter { profile.isLearned($0.id) }
        case .genre(let g): items = RiffLibrary.all.filter { $0.tags.contains(g) }
        }
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        if !q.isEmpty {
            items = items.filter { riff in
                (riff.title + " " + riff.origin + " " + riff.why + " " + riff.tags.map(\.label).joined(separator: " "))
                    .lowercased().contains(q)
            }
        }
        return items
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(filters, id: \.self) { f in
                                Button(f.label) { filter = f }
                                    .buttonStyle(.bordered)
                                    .tint(filter == f ? Color.accentColor : Color.secondary)
                                    .fontWeight(filter == f ? .bold : .regular)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                    .listRowBackground(Color.clear)
                }

                Section {
                    if riffs.isEmpty {
                        ContentUnavailableView(emptyTitle, systemImage: "music.note.list", description: Text(emptyText))
                    }
                    ForEach(Array(riffs.enumerated()), id: \.element.id) { index, riff in
                        NavigationLink(value: riff) {
                            RiffRow(riff: riff,
                                    learned: profile.isLearned(riff.id),
                                    favorite: profile.isFavorite(riff.id),
                                    locked: !(store.isPremium || riff.isFree),
                                    highlighted: profile.data.genres)
                        }
                        if index == 5 {
                            SponsorCard(slot: 1)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        }
                    }
                } footer: {
                    Text("Every melody here is public domain or an original by AICore, so it's yours to play anywhere.")
                }
            }
            .searchable(text: $query, prompt: "Search riffs, composers, styles")
            .navigationTitle("Riffs")
            .navigationDestination(for: Riff.self) { riff in
                if store.isPremium || riff.isFree || riff.id == profile.rankedRiffs.first?.id {
                    RiffDetailView(riff: riff)
                } else {
                    LockedRiffView(riff: riff)
                }
            }
        }
    }

    private var emptyTitle: String {
        switch filter {
        case .favorites: "No favorites yet"
        case .learned: "Nothing learned yet"
        default: "No riffs found"
        }
    }

    private var emptyText: String {
        switch filter {
        case .favorites: "Tap the heart on any riff to save it here."
        case .learned: "Riffs you mark as learned show up here."
        default: "Try a different search or filter."
        }
    }
}

private struct RiffRow: View {
    let riff: Riff
    let learned: Bool
    let favorite: Bool
    let locked: Bool
    let highlighted: [Genre]

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(learned ? Color.green.opacity(0.18) : Color.accentColor.opacity(0.14))
                    .frame(width: 40, height: 40)
                Image(systemName: learned ? "checkmark" : (locked ? "lock.fill" : "music.note"))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(learned ? Color.green : (locked ? Color.secondary : Color.accentColor))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(riff.title).font(.body.weight(.semibold))
                Text(riff.origin).font(.footnote).foregroundStyle(.secondary)
                GenrePills(tags: Array(riff.tags.prefix(2)), highlighted: highlighted)
            }
            Spacer(minLength: 4)
            VStack(alignment: .trailing, spacing: 6) {
                DifficultyDots(level: riff.level)
                Text("\(riff.bpm) BPM").font(.caption).foregroundStyle(.secondary).monospacedDigit()
                if favorite {
                    Image(systemName: "heart.fill").font(.caption).foregroundStyle(Color.accentColor)
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityHint(locked ? "Requires Premium" : "")
    }
}

/// Shown instead of the riff when it needs Premium.
struct LockedRiffView: View {
    let riff: Riff
    @State private var showPaywall = false

    var body: some View {
        ContentUnavailableView {
            Label(riff.title, systemImage: "lock.fill")
        } description: {
            Text("\(riff.why)\n\nThis riff is part of Premium, along with every lesson and new riffs as they're added.")
        } actions: {
            Button("See Premium") { showPaywall = true }
                .buttonStyle(.borderedProminent)
        }
        .navigationTitle(riff.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }
}
