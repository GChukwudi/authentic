# Authentic backend

Node + TypeScript API in front of the Solana registry. It checks tags, counts scans, scores risk, and submits registry writes.

## Run

```bash
cd backend
npm install
cp .env.example .env     # CHAIN=memory works with no Solana at all
npm start                # http://localhost:8787
```

Node 22.13+ (uses the built-in `node:sqlite`).

## Endpoints

| Method | Path | Auth | Body | Returns |
|---|---|---|---|---|
| POST | `/v1/producers` | signed | `{name}` | `{name, publicKey (base58), registeredAt}` |
| GET | `/v1/producers/:keyHex` | | | profile or 404 |
| GET | `/v1/producers/:keyHex/batches` | | | `BatchSummary[]`, newest first |
| POST | `/v1/producers/:keyHex/batches` | signed | `{productName, origin, quantity}` | `BatchSummary` |
| POST | `/v1/batches/:batchId/recall` | signed | `{reason}` | `BatchSummary` |
| GET | `/v1/batches/:batchId/custody` | | | `CustodyEvent[]` |
| POST | `/v1/verify` | | `{tag, clientId?}` | `Verdict` |

`batchId` is `<producerKeyHex>:<number>`, the same string the app uses. Field names and enum values (`genuineFirstScan`, `flagged`, ...) match the Dart models.

## Signed requests

Writes carry three headers. The producer's tag-signing key signs the request, so the same Ed25519 key is the identity.

```
x-producer:  <32-byte public key, hex>
x-timestamp: <unix ms, within 5 minutes>
x-signature: <base64url Ed25519 signature of the message below>

message = "AUTH1-REQ\n" + METHOD + "\n" + path + "\n" + timestamp + "\n" + sha256hex(rawBody)
```

`path` has no query string. `rawBody` is the exact JSON text sent (empty string if none).

## Verify

`/v1/verify` re-checks the signature, then looks the producer and batch up in the registry, checks the recall flag, increments the unit's scan counter and returns the verdict. Risk is a deterministic score (scan count, distinct phones, time between scans). If `ANTHROPIC_API_KEY` is set, Claude words the explanation in two short sentences; any failure falls back to a template. The AI never sets the score.

## Solana mode

1. Build and deploy the program from the repo root (`anchor build`, `anchor keys sync`, `anchor deploy --provider.cluster devnet`). `keys sync` rewrites the program id in `lib.rs` and `Anchor.toml`; copy it to `PROGRAM_ID`.
2. Create the relayer wallet and fund it: `solana-keygen new -o backend/relayer.json`, then `solana airdrop 2 $(solana address -k backend/relayer.json) --url devnet`.
3. `.env`: `CHAIN=solana`, `RELAYER_KEYPAIR=./relayer.json`, `PROGRAM_ID=<id>`.
4. `npm run init-registry` once.

## Trust model (MVP)

The relayer is the registry admin and pays fees. It only submits a write after verifying the producer's signed request, so a producer cannot be impersonated through the API, but a compromised relayer could write to the registry. The hardening step is to have the producer's key co-sign the Solana transaction, which the program already supports by checking `producer.key`.
Scan counts live in SQLite, not on-chain, to avoid a fee per scan.
