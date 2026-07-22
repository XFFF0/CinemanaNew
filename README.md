# CinemanaNew

SwiftUI iOS client for the Cinemana/Shabakaty streaming platform, built from
reverse-engineered API documentation (`docs/cinemana-api.md`,
`docs/cinemana-reverse-engineering.md`).

## Stack
- SwiftUI, iOS 16+, MVVM
- `URLSession` + async/await networking (`Services/APIClient.swift`)
- OAuth2 auth against `account.shabakaty.com` with Keychain token storage (`Services/AuthService.swift`)
- `AVPlayer`-based video playback with intro/recap skip support

## Building
No local Mac needed — the app is built entirely through GitHub Actions:

1. `scripts/generate_project.py` generates `CinemanaNew.xcodeproj/project.pbxproj`
   from the source tree (not committed, to avoid binary/UUID diffs).
2. `.github/workflows/build.yml` runs on `macos-15` with Xcode 16, builds an
   **unsigned** `.ipa` for sideloading, and uploads it as a workflow artifact.

Trigger manually via the Actions tab (`workflow_dispatch`) or on push to `main`.

## Status
Initial scaffold: models, networking, auth, and core screens (Home, Browse,
Search, Profile, Video Detail, Player) are implemented per the RE report.
Not yet done: download manager, casting (Cast/DLNA), push notifications
(OneSignal), Room-DB-equivalent local caching.
