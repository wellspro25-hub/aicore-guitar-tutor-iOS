//
//  StoreManager.swift
//  AICore Guitar Tutor
//
//  StoreKit 2 subscriptions. Apple requires in-app purchase for unlocking
//  digital content inside an iOS app, so Premium is sold through the App Store.
//
//  The product IDs below must match the subscriptions you create in
//  App Store Connect (and in Configuration.storekit for local testing).
//

import Foundation
import Observation
import StoreKit

@MainActor
@Observable
final class StoreManager {
    static let productIDs: [String] = [
        "com.aicore.guitartutor.premium.monthly",
        "com.aicore.guitartutor.premium.yearly"
    ]

    private(set) var products: [Product] = []
    private(set) var isPremium = false
    private(set) var hasLoaded = false
    var errorMessage: String?

    @ObservationIgnored private var updatesTask: Task<Void, Never>?

    /// Call once at launch.
    func start() async {
        if updatesTask == nil {
            updatesTask = Task { [weak self] in
                // Purchases made on other devices, renewals, refunds, Ask to Buy approvals…
                for await update in Transaction.updates {
                    await self?.process(update)
                }
            }
        }
        await loadProducts()
        await refreshEntitlements()
        hasLoaded = true
    }

    func loadProducts() async {
        do {
            let loaded = try await Product.products(for: Self.productIDs)
            products = loaded.sorted { $0.price < $1.price }
        } catch {
            errorMessage = "Couldn't load subscription options. Check your connection and try again."
        }
    }

    /// Called by the paywall after a successful purchase.
    func process(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = result else { return }
        await transaction.finish()
        await refreshEntitlements()
    }

    func refreshEntitlements() async {
        var active = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if Self.productIDs.contains(transaction.productID), transaction.revocationDate == nil {
                active = true
            }
        }
        isPremium = active
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
        } catch {
            errorMessage = "Restore didn't complete. \(error.localizedDescription)"
        }
        await refreshEntitlements()
    }

    func canOpen(_ lesson: Lesson) -> Bool {
        lesson.isFree || isPremium
    }
}
