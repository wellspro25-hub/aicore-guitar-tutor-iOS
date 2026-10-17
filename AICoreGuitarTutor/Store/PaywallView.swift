//
//  PaywallView.swift
//  AICore Guitar Tutor
//
//  Uses Apple's SubscriptionStoreView, which shows prices, trial terms,
//  Restore Purchases and the legal links App Review expects.
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(StoreManager.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        SubscriptionStoreView(productIDs: StoreManager.productIDs) {
            PaywallHeader()
        }
        .subscriptionStoreControlStyle(.picker)
        .storeButton(.visible, for: .restorePurchases)
        .storeButton(.visible, for: .cancellation)
        .subscriptionStorePolicyDestination(url: AppLinks.termsOfUse, for: .termsOfService)
        .subscriptionStorePolicyDestination(url: AppLinks.privacyPolicy, for: .privacyPolicy)
        .onInAppPurchaseCompletion { [store] _, result in
            if case .success(.success(let verification)) = result {
                await store.process(verification)
            }
        }
        // Closes the sheet as soon as Premium becomes active.
        .onChange(of: store.isPremium) { _, isPremium in
            if isPremium { dismiss() }
        }
    }
}

private struct PaywallHeader: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "guitars.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.accentColor)
                .padding(.top, 32)

            Text("Guitar Tutor Premium")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 10) {
                FeatureRow(icon: "book.fill", text: "Every lesson, from first chords to Travis picking")
                FeatureRow(icon: "music.note.list", text: "All 18 riffs: movie, TV and classical themes plus originals")
                FeatureRow(icon: "mic.fill", text: "Play-along tab and mic practice on every riff")
                FeatureRow(icon: "sparkles", text: "No sponsor cards, plus new riffs as they're added")
            }
            .padding(.horizontal, 24)
        }
        .padding(.bottom, 8)
    }
}

private struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.accentColor)
                .frame(width: 24)
            Text(text)
                .font(.body)
        }
    }
}

#Preview {
    PaywallView()
        .environment(StoreManager())
}
