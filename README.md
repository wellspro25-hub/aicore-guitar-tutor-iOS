# AICore Guitar Tutor — iPhone App

Beginner fingerstyle guitar lessons, a riff library with play-along tab and mic practice, a tuner, metronome and practice timer — personalized to the music each player likes.
Native SwiftUI app for iPhone (iOS 17 and newer). Published by **AICore LLC**.

| Setting | Value |
|---|---|
| App name (App Store) | AICore Guitar Tutor |
| Name under the icon | Guitar Tutor |
| Bundle ID | `com.aicore.guitartutor` |
| Seller | AICore LLC |
| Version / Build | 1.1 (1) |
| Subscriptions | `com.aicore.guitartutor.premium.monthly`, `com.aicore.guitartutor.premium.yearly` |
| Free content | Tuner, metronome, timer, first 5 lessons, 7 riffs, the daily riff challenge |
| Premium content | Lessons 6–12, all 18 riffs, no sponsor cards |

## What's new in 1.1

- **Today tab**: level + XP, daily goal ring, streak, continue-course card, daily riff challenge, "Picked for you" riffs.
- **Riffs tab**: 18 riffs (public-domain movie/TV/classical themes + AICore originals) with search and filters.
- **Interactive tab** everywhere (lessons too): Play with notes lighting up, 50/75/100% speed, loop, and **Practice with mic** — the app listens and moves on as you hit each note.
- **Personalization**: first-launch setup (level, styles, artists, daily goal) plus optional **Apple Music import** of recently played music.
- **XP and 7 levels**: lessons +50, riffs learned +40, mic runs +15, +1 per practice minute.
- **Tools tab**: tuner, metronome and timer together; a now-playing bar controls the metronome from any screen.
- **Sponsor cards** (labeled "Sponsored"/"Affiliate", hidden for Premium) loaded from your hosted `sponsors.json`.
- New app icon.

---

## 1. Open the project

1. Install **Xcode** (free) from the Mac App Store. You need Xcode 16 or newer.
2. Unzip `AICoreGuitarTutor.zip`.
3. Double-click **`AICoreGuitarTutor.xcodeproj`**. Xcode opens with every file already in place.

## 2. Try it on the simulator (no Apple account needed)

1. At the top of Xcode, pick an iPhone simulator (e.g. *iPhone 16*).
2. Press **▶ Run** (or ⌘R).
3. To test the Premium purchase without paying: **Product → Scheme → Edit Scheme… → Run → Options → StoreKit Configuration → `Configuration.storekit`**. Run again — the paywall now shows test prices and fake purchases work.

The tuner uses your Mac's microphone in the simulator.

## 3. Sign it with AICore LLC

1. Enroll in the **Apple Developer Program as an Organization** at developer.apple.com/programs ($99/year). You'll need a free **D-U-N-S number** for AICore LLC (Apple links to the lookup during enrollment).
2. In Xcode: **Xcode → Settings → Accounts → +** and sign in with the Apple ID used for enrollment.
3. Click the blue **AICoreGuitarTutor** project icon in the left sidebar → target **AICoreGuitarTutor** → **Signing & Capabilities** → set **Team** to *AICore LLC*. Leave "Automatically manage signing" on.

To run on your own iPhone: plug it in, pick it at the top of Xcode, press ▶. The first time, iPhone asks you to turn on **Settings → Privacy & Security → Developer Mode**.

## 4. Before you submit (required)

- [ ] **Sponsor feed + links.** In `App/AppLinks.swift`, set `sponsorsFeed` to your GitHub Pages `sponsors.json` address, `advertise` to your advertise page, and replace `YOURTAG-20` in `gearAffiliate` with your Amazon Associates tag.
- [ ] **Apple Music import.** At developer.apple.com → Certificates, IDs & Profiles → Identifiers → `com.aicore.guitartutor` → **App Services**, turn on **MusicKit**. (The permission message is already in the project.) If you skip this, the rest of the app works; only the import button shows an error.

- [ ] **Privacy policy + support pages.** Host `AppStore/privacy-policy.md` and a support page online (free option: GitHub Pages). Then put the real links in `AICoreGuitarTutor/App/AppLinks.swift`.
- [ ] Fill in your support email in `AppStore/privacy-policy.md`.
- [ ] Take screenshots (simulator: **⌘S** saves one to your desktop). You need 6.9" (iPhone 16 Pro Max) screenshots; Apple scales them for other sizes.

Already done for you in the project:

- Microphone permission message (`NSMicrophoneUsageDescription`) — without it Apple rejects the app.
- Privacy manifest (`PrivacyInfo.xcprivacy`): no tracking, no data collected.
- Encryption export answer set to "No" (`ITSAppUsesNonExemptEncryption`), so no export paperwork.
- 1024×1024 app icon, portrait-only iPhone layout, Music category.
- Restore Purchases, Terms of Use and Privacy Policy links on the paywall and in Settings (App Review checks these for subscriptions).

## 5. Set up the app in App Store Connect

Go to appstoreconnect.apple.com:

1. **Agreements, Tax, and Banking** → accept the **Paid Apps** agreement and add AICore LLC's bank and tax info. Subscriptions won't work until this is done.
2. **Apps → + → New App**: Platform iOS, Name *AICore Guitar Tutor*, Primary language English (U.S.), Bundle ID `com.aicore.guitartutor`, SKU `aicore-guitartutor`.
3. **Monetization → Subscriptions** → create a subscription group named **Guitar Tutor Premium**, then add two subscriptions with these exact Product IDs:

   | Reference name | Product ID | Duration | Suggested price | Intro offer |
   |---|---|---|---|---|
   | Premium Yearly | `com.aicore.guitartutor.premium.yearly` | 1 year | $29.99 | 1-week free trial |
   | Premium Monthly | `com.aicore.guitartutor.premium.monthly` | 1 month | $4.99 | 1-week free trial |

   Add a display name, description and a review screenshot (a screenshot of the paywall) for each. Prices are suggestions — change them freely; the app reads prices from Apple.
4. Fill in the listing using `AppStore/listing.md`.
5. **App Privacy** → answer **"No, we do not collect data from this app."** (Apple Music listening is read on the device and never sent anywhere; sponsor cards are a plain file download with no tracking.)

## 6. Upload and submit

1. At the top of Xcode choose **Any iOS Device (arm64)**.
2. **Product → Archive**. When the Organizer opens, click **Distribute App → App Store Connect → Upload**.
3. After processing (10–30 min), the build appears in App Store Connect under **TestFlight**. Install it on your iPhone with the TestFlight app and test a purchase (TestFlight purchases are free).
4. In the app's version page, select the build, attach both subscriptions under **In-App Purchases and Subscriptions**, paste the review notes from `listing.md`, and click **Add for Review → Submit**.

For each update, raise **Build** (and **Version** for a new release) in the target's **General** tab before archiving.

---

## Project layout

```
AICoreGuitarTutor.xcodeproj     ← open this
Configuration.storekit          ← test subscriptions (simulator only)
AICoreGuitarTutor/
  App/        app entry point, tabs, legal/support/ad links
  Models/     lessons, riffs (RiffLibrary), player profile + XP, saved progress (SwiftData)
  Audio/      tuner (YIN pitch detection), riff player, mic note-trainer, metronome
  Music/      Apple Music taste import (MusicKit)
  Store/      StoreKit 2 subscriptions, paywall, sponsor cards feed
  Views/      Today, Learn, Riffs, Tools, You (settings), onboarding
  Assets.xcassets, PrivacyInfo.xcprivacy
AppStore/     listing text, privacy policy, review notes
```

Adding lessons: edit `Models/LessonLibrary.swift`. Set `isFree: true` for anything that should be free.

Adding riffs: edit `Models/Riff.swift`. Notes are written like `6.0+5.2/0.5` (string 6 open + string 5 fret 2, half a beat), `r/1` for a rest and `|` for a bar line. Only add public-domain melodies or your own originals — copyrighted songs need a publisher license.

Changing the brand name later: change **Display Name** in the target's General tab, the name in App Store Connect, and the text in `AppLinks.swift`/`SettingsView.swift`. The bundle ID can't change after the first upload.

© 2026 AICore LLC
