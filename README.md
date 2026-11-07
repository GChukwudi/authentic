# Authentic

Scan a QR tag on a product and know in seconds whether it is genuine, where it came from, and whether it has been recalled. Producers sign one tag per unit; buyers verify the signature on their phone, even offline, then check the registry on Solana.

Built for the MLH Solana Hackathon, 6 to 8 Nov 2026.

## Repo layout

```text
authentic/
  mobile/      Flutter app (this is what exists today)
  backend/     Node + TypeScript relayer (next)
  programs/    Anchor program (next)
```

## Mobile status

UI and view models only. There is no network. A seeded in-memory world (`lib/data/mock/`) stands in for the backend and the Solana program. Signatures are real Ed25519, so tags made in Producer mode verify in the scanner, and a tag shown on one phone can be scanned by another.

What works today:

- Verify tab with recent checks, and a camera scanner with a **Try a demo tag** sheet (six sample tags, plus a no-signal switch).
- Verdict screen with animated seal, tag details, scan-risk gauge and an AI-style explanation (mock text for now).
- Custody trail timeline for a batch.
- Producer mode: register (generates a key), create a batch, tag sheet of signed QR codes, recall a batch.

## MVVM structure

```text
lib/
  app/        theme, providers, shell
  core/       encoding and formatting helpers
  domain/     models, repository interfaces, tag codec (pure Dart)
  data/
    sources/  crypto
    mock/     in-memory chain and mock repositories (replaced by the API)
  features/   one folder per screen: *_view.dart + *_view_model.dart
  shared/     custom-painted widgets and buttons
```

Views read state and send events. ViewModels (Riverpod `Notifier`s with immutable, sealed state) call repository interfaces. Swapping the mock for the real API means writing new classes in `data/` that implement the same interfaces and changing `lib/app/providers.dart`. No screen changes.

## Design

Paper and ink: flat bone background, deep forest green, one ochre accent, hairline borders. No blur, glass or gradients. Everything distinctive is drawn in code: the scalloped verdict seal and its self-drawing glyphs, the ticket card with notches and a tear line, the risk gauge, the scan frame with a sweeping line, and the custody rail.

Fonts are bundled in `mobile/assets/fonts` (all SIL OFL): Instrument Serif for display, Barlow for text, IBM Plex Mono for codes.

## Run it

This was written without a Flutter SDK available, so it has not been compiled or run yet. Expect to fix a few small things on first build.

```bash
cd mobile
./tool/setup.sh        # creates android/ and ios/ around the existing code
flutter run
flutter test
```

Two manual steps after setup:

1. **iOS**: add `NSCameraUsageDescription` to `ios/Runner/Info.plist`, for example "Authentic scans QR tags on products."
2. **Android**: if the build complains, set `minSdk` to 23 in `android/app/build.gradle(.kts)`, and make sure the `CAMERA` permission is in `AndroidManifest.xml`.

Package versions in `pubspec.yaml` were picked without access to pub.dev. Run `flutter pub outdated` and adjust if resolution fails.

## Next

1. Compile, fix, run the tests.
2. Anchor program and backend (see the architecture doc).
3. Add `data/repositories/*_impl.dart` that call the backend, switch providers, delete `data/mock/`.
