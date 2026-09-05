# CineTrekker Android Launch-Readiness Report

**Assessment date:** 21 August 2026  
**Package:** `com.cinetrekker.android`  
**Version:** `1.0.0+1`

## Executive assessment

The CineTrekker Android project has completed the source-level website parity audit and the final native OAuth integration. It now has a successful signed release APK and App Bundle, clean Dart analysis, passing Flutter tests when the Windows test environment is supplied with its missing `ProgramFiles(x86)` variable, shared Supabase authentication configuration, the Android OAuth callback deep link, an in-app privacy policy, branded launcher assets, and Play Store artwork.

The app is **ready for Play Console internal testing and owner-led launch preparation**. It is not yet possible to certify production publication because real-device authentication and synchronization testing, genuine Play listing screenshots, Google Play declarations, and upload-key backup are necessarily owner-side or device-side actions. The Android OAuth button is implemented, the redirect URL is allowlisted, and Supabase currently shows the Google provider as enabled with populated masked credentials; the browser-to-device sign-in round trip remains unverified.

## Verified and completed

| Area | Result | Evidence or detail |
|---|---|---|
| Website feature parity | Complete in source | Android equivalents exist for all 34 audited website routes, including discovery, movies, TV, genres, decades, awards, following, notifications, trending, recommendations, calendar, upcoming, stats, enhanced stats, watch history, printable watchlist, profile, feedback, login, signup, auth callback, and accessibility. |
| Feature enhancements | Complete in source | Added filterable genre/decade/award discovery, followed-show Calendar enrichment, printable-watchlist clipboard export, public profiles with privacy filtering and follow/unfollow, feedback submission with website fallback, dedicated accessibility settings, and persisted reduced-motion behavior. |
| Shared authentication | Configured | Android and website use the same Supabase project and account system, so email/password credentials are shared across both platforms. |
| Password-reset deep link | Complete | `cinetrekker://auth/reset` is allowlisted and handled by the Android auth flow. |
| Google OAuth callback | Complete in source | `app_links: ^6.4.1` is resolved; `OAuthCallbackHost` listens for `cinetrekker://auth/callback`; the app completes the Supabase session from the callback URI. |
| Supabase OAuth redirect allowlist | Complete | `cinetrekker://auth/callback` was successfully added. Supabase reports **Successfully added 1 URL** and the persisted list contains five URLs. |
| Dart analysis | Complete | `flutter analyze` completed with **No issues found** after the final OAuth and parity changes. |
| Flutter unit tests | Complete with environment workaround | All tests passed: `00:00 +13: All tests passed!`. The Windows shell must provide `ProgramFiles(x86)=C:\Program Files (x86)` because the current Flutter/plugin environment otherwise exits before running tests. |
| Release signing | Complete locally | Upload keystore: `android/cinetrekker-upload-key.jks`, alias `cinetrekker-upload`; ignored `android/key.properties` configures release signing. Back up the key and passwords securely. |
| Signed release APK | Complete | `build/app/outputs/flutter-apk/app-release.apk`; 60,453,421 bytes; SHA-256 `60009009395EFC419353C3DD35B00C79585B7DB704A954435633A9DD6FE6AAA6`. |
| Signed release App Bundle | Complete | `build/app/outputs/bundle/release/app-release.aab`; 58,018,805 bytes; SHA-256 `FF52A1DBF4DD9A3EA058CE097E4D7486DC4F94287C7BE3BFE8BCE531D78EDB67`. |
| Android SDK target | Complete | `compileSdk` and `targetSdk` are 36; `minSdk` is 24; NDK is 28.2.13676358. |
| Privacy policy | Complete in app | In-app policy includes collection, use, third-party services, retention/deletion, user choices, children, and canonical URL: `https://cinetrekker.vercel.app/privacy`. |
| Launcher branding | Complete in project | Branded launcher asset is installed as `drawable-nodpi/ic_launcher.png`; the manifest references `@drawable/ic_launcher`. |
| Play feature graphic | Prepared | `play-store/feature-graphic-1024x500.png` is present at the required 1024×500 dimensions. |
| Play product icon | Prepared | `play-store/play-icon-512.png` is present at 512×512 pixels. |
| Play Console handoff | Complete | `PLAY_CONSOLE_HANDOFF.md` contains listing copy, asset notes, Data Safety preparation notes, and official Google references. |

## Remaining owner actions before production publication

| Priority | Action | Why it remains manual |
|---|---|---|
| Critical | Back up the upload keystore and passwords securely | The keystore is private, ignored by version control, and cannot be recovered from the repository if lost. |
| Critical | Install the signed AAB in Play Console internal testing and run real-device QA | No physical Android device was connected during this audit, so login, deep links, cross-platform synchronization, and release-runtime behavior were not exercised on hardware. |
| Critical | Capture genuine Android screenshots for the Play listing | Screenshots must show the actual released app. Recommended screens are sign-in, home/discover, title details with watchlist action, and profile/library. |
| Critical | Complete Google Play Data Safety, content rating, target-audience, and account-deletion declarations | These answers must be confirmed by the owner against the production backend, retention behavior, and actual Play Console account settings. |
| High | Test Google sign-in on a physical device | Supabase shows Google as **Enabled** with populated masked credentials and the Android button/callback are implemented; the browser-to-device round trip remains unverified. |
| High | Test account deletion and privacy-policy reachability from an external browser | Play Console requires the final public policy and deletion experience to be usable and accurately reflect the deployed service. |
| High | Upload the App Bundle and enroll in Play App Signing if prompted | Play Console performs the final bundle validation and signing enrollment. |
| Medium | Decide whether to address plugin metadata warnings | Release builds succeed. Flutter currently prints non-blocking default-plugin metadata warnings for `path_provider`, `flutter_secure_storage`, and `url_launcher` in the Windows environment. |
| Medium | Consider a later parity refinement for Calendar filters | The Android Calendar now includes followed-show enrichment, but the website’s full week/month/agenda, network, rating, and followed-only filter controls remain a possible future refinement. |

## Authentication smoke-test script

1. Create or use a real account on `https://cinetrekker.vercel.app`.
2. Install the signed APK on a physical Android device, or distribute the AAB through Play internal testing.
3. Sign in with the same email and password used on the website.
4. Confirm that profile data, watchlist, watched history, ratings, collections, notifications, following, comments, and TV tracking are visible and that changes made on either platform synchronize.
5. Request a password reset and verify that the email link opens the Android app through `cinetrekker://auth/reset`.
6. From the Android sign-in screen, test Google sign-in with the enabled and configured Supabase Google provider; verify that the browser returns to `cinetrekker://auth/callback` and that the session is established.
7. Sign out, restart the app, sign back in, and verify session restoration and protected-route behavior.
8. Test account deletion and confirm that the website and Android app no longer expose deleted application data.

## Artifact locations

- Signed APK: `build/app/outputs/flutter-apk/app-release.apk`
- Signed AAB: `build/app/outputs/bundle/release/app-release.aab`
- Upload keystore: `android/cinetrekker-upload-key.jks` — keep private and backed up
- Signing configuration: `android/key.properties` — keep private and backed up
- Store feature graphic: `play-store/feature-graphic-1024x500.png`
- Play product icon: `play-store/play-icon-512.png`
- Play handoff: `PLAY_CONSOLE_HANDOFF.md`
- Canonical privacy policy: `https://cinetrekker.vercel.app/privacy`

## Final status

**Source and build readiness: complete.**  
**Play internal-test readiness: complete.**  
**Production publication certification: pending physical-device QA and owner-only Play Console declarations.**
