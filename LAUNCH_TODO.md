# CineTrekker Android Google Play Launch Checklist

**Package:** `com.cinetrekker.android`  
**Version:** `1.0.0+1`  
**Last audited:** 21 August 2026

## Completed in the project

| Status | Item | Evidence |
|---|---|---|
| Done | Website feature parity audit and enhancements | Flutter source contains Android equivalents for all 34 audited website routes, plus enhanced discovery filters, public profiles, feedback, accessibility, reduced motion, followed-show Calendar enrichment, and printable-watchlist export. |
| Done | Shared Supabase account configuration | Android and website use the same Supabase project, so existing website email/password credentials are shared with Android. |
| Done | Android password-reset deep link | Manifest declares the `cinetrekker://auth` scheme/host and Supabase Auth Redirect URLs contains `cinetrekker://auth/reset`. |
| Done | Android Google OAuth callback | `app_links` is resolved; `OAuthCallbackHost` receives `cinetrekker://auth/callback`; the callback is completed through the shared Supabase session flow. |
| Done | Supabase Google OAuth redirect allowlist | `cinetrekker://auth/callback` was added successfully; Supabase now reports five total redirect URLs. |
| Done | Static analysis | `flutter analyze` reports **No issues found** after the final OAuth and parity changes. |
| Done | Flutter unit tests | All 13 tests pass when the Windows process supplies `ProgramFiles(x86)=C:\Program Files (x86)`. |
| Done | Release signing configuration | `android/key.properties` and the local upload keystore are present and ignored by version control. |
| Done | Signed release APK | `build/app/outputs/flutter-apk/app-release.apk` exists; SHA-256 is `60009009395EFC419353C3DD35B00C79585B7DB704A954435633A9DD6FE6AAA6`. |
| Done | Signed release App Bundle | `build/app/outputs/bundle/release/app-release.aab` exists; SHA-256 is `FF52A1DBF4DD9A3EA058CE097E4D7486DC4F94287C7BE3BFE8BCE531D78EDB67`. |
| Done | Privacy policy | In-app policy includes the canonical URL `https://cinetrekker.vercel.app/privacy`. |
| Done | Android branding | Branded launcher resource is installed and referenced by the manifest. |
| Done | Play Console handoff | `PLAY_CONSOLE_HANDOFF.md` contains listing copy, Data Safety preparation, asset notes, and official references. |
| Done | Play graphics | `play-store/play-icon-512.png` and `play-store/feature-graphic-1024x500.png` are available. |

## Required before production release

| Priority | Action | Owner |
|---|---|---|
| Critical | Back up `android/cinetrekker-upload-key.jks` and its passwords in a secure password manager or encrypted vault. | App owner |
| Critical | Upload the signed AAB to Play Console internal testing, or install the signed APK on a physical Android device. | App owner |
| Critical | Sign in with a real CineTrekker website account and verify profile, watchlist, history, ratings, collections, notifications, follows, comments, and TV tracking synchronize. | App owner / tester |
| Critical | Test password recovery end to end and confirm the email link opens the Android app via `cinetrekker://auth/reset`. | App owner / tester |
| Critical | Configure Supabase’s Google provider with a Google Cloud OAuth client ID and secret, then test the Android Google sign-in round trip. | App owner |
| Critical | Capture genuine Android screenshots from the final build for the Play listing. Do not use generated mockups as product screenshots. | App owner / tester |
| Critical | Complete the Play Console content-rating, target-audience, Data Safety, privacy-policy, and account-deletion declarations. | App owner |
| High | Review the Play pre-launch report and resolve blocking device, stability, accessibility, or policy findings. | App owner |
| High | Verify the public privacy policy and account-deletion path from a logged-out browser. | App owner |
| Medium | Decide whether to resolve or accept the non-blocking Flutter plugin default-implementation warnings. | Developer |

## Verification notes

The final Windows test run passed all 13 tests after supplying the missing `ProgramFiles(x86)` process variable. A plain `flutter test` in the current shell exits before test execution because of that environment issue and emits non-blocking plugin metadata warnings; this is a development-environment issue rather than an app test failure.

The latest ADB check found no authorized Android device and no usable AVD. A physical Android device or repaired emulator is therefore required for final authentication, synchronization, deep-link, and screenshot verification.
