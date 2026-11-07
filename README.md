# Authentic

Scan a QR tag on a product and know in seconds whether it is genuine, where it came from, and whether it has been recalled. Producers sign one tag per unit; buyers verify the signature on their phone, even offline, then check the registry on Solana.

Built for the MLH Solana Hackathon, 6 to 8 Nov 2026.

## Repo layout

```text
authentic/
  mobile/      Flutter app
  backend/     Node + TypeScript API and relayer
  programs/    Anchor program (the registry on Solana)
```

## What the app does

- Verify tab with recent checks and a camera scanner. The tag's signature is checked on the phone first, then the backend checks the registry, recalls and scan history.
- Verdict screen with animated seal, tag details, scan-risk gauge and the risk explanation.
- Custody trail timeline for a batch.
- Producer mode: register (generates a key), create a batch, tag sheet of signed QR codes, recall a batch.

## MVVM structure

```text
lib/
  app/        theme, providers, shell, config
  core/       encoding and formatting helpers
  domain/     models, repository interfaces, tag codec (pure Dart)
  data/
    api/      backend client and repositories
    local/    scan history for this session
    sources/  crypto
  features/   one folder per screen: *_view.dart + *_view_model.dart
  shared/     custom-painted widgets and buttons
```

Views read state and send events. ViewModels (Riverpod `Notifier`s with immutable, sealed state) call repository interfaces, wired up in `lib/app/providers.dart`.

## Design

Paper and ink: flat white background, deep forest green, one ochre accent, hairline borders. No blur, glass or gradients. Everything distinctive is drawn in code: the scalloped verdict seal and its self-drawing glyphs, the ticket card with notches and a tear line, the risk gauge, the scan frame with a sweeping line, and the custody rail.

One typeface throughout: Inter, bundled in `mobile/assets/fonts` (SIL OFL).

## Run it

Start the backend first (see `backend/README.md`), then:

```bash
cd mobile
./tool/setup.sh        # first time only: creates android/ and ios/ around the existing code
flutter run --dart-define=API_URL=http://localhost:8787
```

`API_URL` is required. Without it the app shows a setup message instead of starting. On the Android emulator use `http://10.0.2.2:8787` for a local backend.

Deploying the program, backend and app is covered in `DEPLOY.md`.
