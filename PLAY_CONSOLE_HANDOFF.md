# CineTrekker Google Play Console Handoff

**Package:** `com.cinetrekker.android`  
**Release:** `1.0.0+1`  
**Canonical privacy policy:** [https://cinetrekker.vercel.app/privacy](https://cinetrekker.vercel.app/privacy)

## Publication status

The signed App Bundle and Android release configuration are complete. Google’s current guidance requires developers to provide accurate listing metadata and preview assets, and to complete the Data safety form for apps published on Google Play.[1] [2] The materials below are a prepared starting point; the owner must confirm all declarations against the production backend and final app behavior before submission.

## Main store listing copy

### App name

`CineTrekker`

### Suggested category

`Entertainment`

### Short description

> Track movies and TV shows, build your watchlist, and discover what to watch.

This copy is intentionally concise and describes the primary experience without promising a service that is not implemented.

### Full description

> CineTrekker is your personal movie and TV companion for discovering what to watch and keeping your viewing life organized.
>
> Explore movies and television shows, search by title or person, and open detailed pages with artwork, ratings, genres, cast, and release information. Save titles to your watchlist, mark movies and shows as watched, rate what you have seen, and keep your library synchronized with the CineTrekker website.
>
> Follow television shows and track episodes, receive notifications, organize titles into collections, and review your watch history and personal statistics. Social features let you follow people, read and write comments, and see activity connected to your CineTrekker account.
>
> Sign in on Android with the same CineTrekker credentials you use on the website. Your profile, watchlist, history, ratings, collections, following, comments, and TV-tracking data are designed to remain available across both platforms through the shared CineTrekker account.
>
> CineTrekker uses The Movie Database (TMDB) for movie and television metadata and imagery. TMDB attribution and third-party terms apply.
>
> Privacy policy: https://cinetrekker.vercel.app/privacy

### Suggested store tags and content notes

| Field | Prepared value or action |
|---|---|
| Primary category | Entertainment |
| Account requirement | Yes; users can create or use an existing CineTrekker account |
| Audience | General audience; owner must complete Play’s target-audience questionnaire |
| Child-directed status | No; verify against the final product and policy position |
| Content rating | Complete the Play content-rating questionnaire; the app includes movie/TV discovery and user-generated comments |
| Ads | Confirm whether the production build contains ads or third-party ad SDKs; the current audited Android source did not establish an ad requirement |
| Privacy policy | Use `https://cinetrekker.vercel.app/privacy` and verify it is reachable without login |
| Account deletion | Verify that the in-app deletion/request flow and public support path are usable before submission |

## Required and prepared visual assets

Google’s current icon guidance specifies a 512×512 32-bit PNG in sRGB for the Play listing icon and says Google Play applies the rounded mask and shadow dynamically; the source asset should not include a forced rounded corner.[3] The Android project has a branded launcher resource, but the owner should also upload a separately verified 512×512 Play product icon in Play Console.

The prepared feature graphic is `play-store/feature-graphic-1024x500.png`. It is exactly 1024×500 and contains no text, ranking claims, install incentives, or Google Play branding. Google’s preview-asset guidance states that feature graphics, screenshots, short descriptions, and videos are used across Play listings and promotional surfaces, and that assets must accurately represent the app.[2]

The remaining required visual action is to capture genuine screenshots from the released Android build. Recommended captures are the sign-in screen, home/discover screen, movie or show details screen with watchlist action, and profile/library screen. Do not submit generated mockups as if they were app screenshots.

## Data Safety worksheet draft

Google states that every developer publishing on Google Play must complete the Data safety form, including apps on closed or open testing tracks, and that the developer is responsible for accurate and complete declarations.[1] This worksheet is not a final legal or Play policy determination.

| Play Console question | Draft answer | Verification required |
|---|---|---|
| Does the app collect or share user data? | Yes, it collects account and application data. | Confirm against the production backend and all enabled SDKs. |
| Is all collected data encrypted in transit? | Yes, network traffic uses HTTPS/Supabase TLS. | Confirm every production endpoint and any external SDK endpoint. |
| Can users request deletion of their data? | Yes, through the app settings or CineTrekker feedback/deletion path. | Test the flow without relying on an internal account or developer intervention. |
| Does the app share data with third parties? | Draft: no account data is intentionally sold or shared; Supabase processes hosted account data and TMDB supplies metadata. | Confirm how Play classifies service providers and inspect all analytics, crash, support, and SDK integrations. |
| Is an account required? | Yes for synchronized library, profile, social, and tracking features. | Confirm guest-accessible screens and the final onboarding flow. |
| Is the app directed to children? | Draft: no. | Confirm target audience and content-rating answers before submission. |

### Data types to review in the form

| Likely Play data category | CineTrekker examples | Likely purpose |
|---|---|---|
| Personal info: Email address | Account sign-in and password recovery | Account management |
| App activity: App interactions | Searches, browsing, watchlist actions, watched status, ratings, collections, follows, comments, notifications, and TV tracking | App functionality and personalization |
| User-generated content | Comments, collection names/items, profile details, and library metadata | App functionality and social features |
| App info and performance | Only if diagnostics, crash reporting, or analytics are enabled in the final build | Analytics, fraud prevention, or app functionality |
| Device or other identifiers | Only if used by enabled SDKs or backend tooling | App functionality, security, or analytics |

The owner should not select a category solely because it appears in this draft. Review the final `.env`, production services, SDK documentation, and backend behavior, then submit the form from **Play Console → App content → Data safety** as described in Google’s instructions.[1]

## Release handoff

| Artifact or action | Location or destination |
|---|---|
| Signed AAB | `build/app/outputs/bundle/release/app-release.aab` |
| Upload keystore | `android/cinetrekker-upload-key.jks`; back it up securely and never commit it |
| Signing properties | `android/key.properties`; keep private and never commit it |
| Feature graphic | `play-store/feature-graphic-1024x500.png` |
| Privacy policy | `https://cinetrekker.vercel.app/privacy` |
| Auth reset redirect | `cinetrekker://auth/reset` in Supabase Auth Redirect URLs |
| First release track | Internal testing, followed by closed testing after real-device QA |

## References

[1]: https://support.google.com/googleplay/android-developer/answer/10787469?hl=en "Google Play Help — Provide information for Google Play’s Data safety section"

[2]: https://support.google.com/googleplay/android-developer/answer/9866151?hl=en "Google Play Help — Add preview assets to showcase your app"

[3]: https://developer.android.com/distribute/google-play/resources/icon-design-specifications "Android Developers — Google Play icon design specifications"

[4]: https://developer.android.com/distribute/best-practices/launch/store-listing "Android Developers — Build a high-quality app or game"
