//
//  SettingsView.swift
//  AICore Guitar Tutor
//

import SwiftUI
import SwiftData
import StoreKit

struct SettingsView: View {
    @Environment(StoreManager.self) private var store
    @Environment(ProfileStore.self) private var profile
    @Environment(\.modelContext) private var modelContext
    @Query private var progress: [LessonProgress]

    @State private var showPaywall = false
    @State private var showManageSubscriptions = false
    @State private var confirmReset = false
    @State private var isRestoring = false

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    let info = profile.levelInfo
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Level \(info.number) · \(info.name)")
                                .font(.headline)
                            Spacer()
                            Text("\(profile.data.xp) XP")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        ProgressView(value: info.progress)
                        Text("\(info.xpToNext) XP to the next level. Earn XP by finishing lessons (+50), learning riffs (+40), mic practice runs (+15) and every minute you practice.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section("Your music") {
                    TasteEditor()
                        .padding(.vertical, 8)
                }

                Section("Premium") {
                    if store.isPremium {
                        Label("Premium is active", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                        Button("Manage Subscription") { showManageSubscriptions = true }
                    } else {
                        Button {
                            showPaywall = true
                        } label: {
                            Label("Upgrade to Premium", systemImage: "star.fill")
                        }
                    }

                    Button {
                        Task {
                            isRestoring = true
                            await store.restorePurchases()
                            isRestoring = false
                        }
                    } label: {
                        HStack {
                            Text("Restore Purchases")
                            if isRestoring {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isRestoring)

                    if let error = store.errorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }

                Section("Progress") {
                    LabeledContent("Lessons completed", value: "\(progress.count) of \(LessonLibrary.allLessons.count)")
                    Button("Reset All Progress", role: .destructive) { confirmReset = true }
                        .disabled(progress.isEmpty && profile.data.xp == 0 && profile.data.learned.isEmpty)
                }

                Section {
                    Link(destination: AppLinks.advertise) {
                        Label("Advertise in Guitar Tutor", systemImage: "megaphone")
                    }
                } header: {
                    Text("For businesses")
                } footer: {
                    Text("Guitar shops, teachers and gear brands can sponsor a card on the Today and Riffs screens.")
                }

                Section("About") {
                    Link(destination: AppLinks.support) {
                        Label("Help & Support", systemImage: "questionmark.circle")
                    }
                    Link(destination: AppLinks.privacyPolicy) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }
                    Link(destination: AppLinks.termsOfUse) {
                        Label("Terms of Use", systemImage: "doc.text")
                    }
                    LabeledContent("Version", value: appVersion)
                }

                Section {
                    EmptyView()
                } footer: {
                    Text("AICore Guitar Tutor · © 2026 \(AppLinks.companyName)")
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                }
            }
            .navigationTitle("You")
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .manageSubscriptionsSheet(isPresented: $showManageSubscriptions)
            .confirmationDialog("Reset all progress?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Reset Progress", role: .destructive) { resetProgress() }
            } message: {
                Text("Completed lessons, learned riffs, favorites and XP will be cleared. Practice history is kept.")
            }
        }
    }

    private func resetProgress() {
        for item in progress { modelContext.delete(item) }
        try? modelContext.save()
        profile.resetProgress()
    }
}

#Preview {
    SettingsView()
        .environment(StoreManager())
        .environment(ProfileStore())
        .modelContainer(for: [LessonProgress.self, PracticeSession.self], inMemory: true)
}
