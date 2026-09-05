# CineTrekker Android QA Handoff

## Release artifacts

The refreshed signed release APK is available on the Windows machine at:

`F:\My Own Games\CineTrekker\cinetrekker android\build\app\outputs\flutter-apk\app-release.apk`

The APK is 60,453,421 bytes and its SHA-256 is:

`60009009395EFC419353C3DD35B00C79585B7DB704A954435633A9DD6FE6AAA6`

The refreshed signed release App Bundle is at:

`F:\My Own Games\CineTrekker\cinetrekker android\build\app\outputs\bundle\release\app-release.aab`

The AAB is 58,018,805 bytes and its SHA-256 is:

`FF52A1DBF4DD9A3EA058CE097E4D7486DC4F94287C7BE3BFE8BCE531D78EDB67`

Android release signing remains configured through `android/key.properties` and the private upload keystore `android/cinetrekker-upload-key.jks`. Keep both the keystore and its passwords backed up securely.

## Automated validation completed

`flutter analyze` completed with **No issues found** after the final OAuth and parity changes. The Flutter test suite also passed with `00:00 +13: All tests passed!` when the Windows process environment supplied `ProgramFiles(x86)=C:\Program Files (x86)`. Without that variable, the current Flutter/plugin environment exits before executing tests and reports a non-blocking environment warning.

The Supabase Auth redirect allowlist now contains both Android deep links:

- `cinetrekker://auth/reset`
- `cinetrekker://auth/callback`

## Direct installation with ADB

After enabling Developer options and USB debugging on a physical Android device, connect it to the Windows computer and accept the device authorization prompt. From PowerShell, run:

```powershell
$sdk = 'C:\Users\DELL\AppData\Local\Android\Sdk'
$adb = Join-Path $sdk 'platform-tools\adb.exe'
& $adb devices -l
& $adb install -r 'F:\My Own Games\CineTrekker\cinetrekker android\build\app\outputs\flutter-apk\app-release.apk'
```

If an older debug build with the same package is installed and Android rejects the update because of a certificate mismatch, uninstall the old build first. This removes local app data, so use it only before testing or after recording any data needed for the test.

## Required cross-platform test

Use a real account that already exists on the CineTrekker website. Sign in on Android with the same email address and password, then verify that the profile, watchlist, watched history, ratings, collections, notifications, following, comments, and television tracking are visible. Add one harmless test title to the watchlist on Android and confirm it appears on the website; then remove it and confirm the removal synchronizes.

Request a password reset from Android or the website and open the email link on the Android device. The link should resolve through `cinetrekker://auth/reset`, display the reset flow, and allow a new password to be saved. Supabase currently shows Google enabled with populated masked credentials. Test the Android **Continue with Google** button and confirm that the browser returns through `cinetrekker://auth/callback` and establishes a session. Sign out, force-stop the app, reopen it, and verify that protected routes require authentication while a successful re-login restores the shared account.

## Screenshots to capture

Capture genuine screenshots from the final release APK, without personal email addresses or private account data. Recommended screens are the sign-in screen, home/discover screen, movie or show details with the watchlist action, and profile/library screen. Use the final device screenshots in Play Console; do not use generated artwork as a substitute for product screenshots.

## Test result table

| Area | Result | Notes |
|---|---|---|
| Dart analysis | Passed | `flutter analyze` reported no issues. |
| Flutter unit tests | Passed with environment workaround | 13 tests passed after supplying `ProgramFiles(x86)` to the Windows process. |
| Release APK build | Passed | Signed APK generated and hash recorded above. |
| Release AAB build | Passed | Signed App Bundle generated and hash recorded above. |
| APK installation | Pending physical device | The latest ADB check found no authorized Android device. |
| Shared sign-in | Pending physical device and real account | Requires a real website account and hardware validation. |
| Session restore | Pending physical device | Test after sign-out, force-stop, restart, and re-login. |
| Watchlist and history sync | Pending physical device and website comparison | Use one reversible test item. |
| Password reset deep link | Allowlist configured; device test pending | Confirm the email link opens Android. |
| Google OAuth | Provider and code configured; device test pending | Supabase shows Google enabled with populated masked credentials; validate the browser-to-device round trip on hardware. |
| Screenshots | Pending physical device | Capture from the final signed release build. |
