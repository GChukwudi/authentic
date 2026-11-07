# Deploy

Order matters: program, then backend, then app.

## 1. Solana program (devnet), from your machine

Needs Solana CLI (Agave 2.1+) and Anchor 0.31.1 (`avm install 0.31.1 && avm use 0.31.1`).

```bash
solana config set --url devnet
solana-keygen new -o ~/.config/solana/id.json      # deployer wallet, skip if you have one
# Fund it with about 4 SOL at https://faucet.solana.com (the CLI airdrop is often rate limited)

anchor build
anchor keys sync          # writes the real program id into lib.rs and Anchor.toml
anchor build              # rebuild with the new id
anchor deploy --provider.cluster devnet
```

Note the program id it prints.

## 2. Relayer wallet and registry

The relayer pays fees and is the registry admin.

```bash
solana-keygen new -o backend/relayer.json          # gitignored
solana airdrop 2 $(solana address -k backend/relayer.json) --url devnet   # or use the faucet site

cd backend && npm install
CHAIN=solana RELAYER_KEYPAIR=./relayer.json PROGRAM_ID=<program id> npm run init-registry
```

## 3. Backend on Render

1. Push the repo to GitHub (render.yaml is at the root).
2. Render: New > Blueprint > select the repo.
3. When asked for secrets set:
   - `PROGRAM_ID`: the program id
   - `RELAYER_KEYPAIR`: the full contents of `backend/relayer.json` (the `[12,34,...]` array)
   - `ANTHROPIC_API_KEY`: optional, for the AI-worded risk explanation
4. After it deploys, open `https://<service>.onrender.com/health`. It should say `"chain":"solana"`.

The blueprint uses the Starter plan with a 1 GB disk. Scan counts live in SQLite on that disk, so on the free plan they would reset whenever the service restarts, and it also sleeps after 15 idle minutes, so the first scan after a quiet spell would time out.

## 4. App

```bash
cd mobile
flutter pub get
flutter run
flutter build apk --release
```

The backend URL is set in `lib/app/app_config.dart`. If the Render service URL changes, update it there.
