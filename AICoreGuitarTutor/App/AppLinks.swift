//
//  AppLinks.swift
//  AICore Guitar Tutor
//
//  ⚠️ BEFORE SUBMITTING: replace the privacy and support URLs with your real,
//  publicly reachable pages (see AppStore/privacy-policy.md in the project
//  folder — you can host it free with GitHub Pages). App Review checks these.
//

import Foundation

enum AppLinks {
    /// Your hosted privacy policy. REQUIRED by App Review.
    static let privacyPolicy = URL(string: "https://example.com/aicore-guitar-tutor/privacy")!

    /// A page (or email form) where users can get help. REQUIRED by App Review.
    static let support = URL(string: "https://example.com/aicore-guitar-tutor/support")!

    /// Apple's standard Terms of Use (EULA). Fine to keep unless you write your own.
    static let termsOfUse = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!

    /// Sponsor cards feed — the sponsors.json file from the web version, hosted on
    /// your GitHub Pages site. Edit that file to sell or change ad space.
    static let sponsorsFeed = URL(string: "https://wellspro25-hub.github.io/guitar-tutor/sponsors.json")!

    /// Your "advertise with us" page (rate card + contact).
    static let advertise = URL(string: "https://example.com/advertise")!

    /// Affiliate gear link. Replace YOURTAG-20 with your Amazon Associates tag.
    static let gearAffiliate = URL(string: "https://www.amazon.com/s?k=beginner+guitar+accessories&tag=YOURTAG-20")!

    static let companyName = "AICore LLC"
}
