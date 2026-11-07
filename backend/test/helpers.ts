import { generateKeyPairSync, sign, type KeyObject } from 'node:crypto';
import { requestMessage } from '../src/auth.js';
import { buildApp } from '../src/app.js';
import { MemoryChain } from '../src/chain/memory.js';
import { loadConfig } from '../src/config.js';
import { toHex } from '../src/encoding.js';
import { ScanStore } from '../src/store.js';
import { signedMessage } from '../src/tag.js';

export class Producer {
  private priv: KeyObject;
  readonly key: Buffer;
  readonly hex: string;

  constructor() {
    const { publicKey, privateKey } = generateKeyPairSync('ed25519');
    this.priv = privateKey;
    this.key = publicKey.export({ format: 'der', type: 'spki' }).subarray(12);
    this.hex = toHex(this.key);
  }

  headers(method: string, path: string, body: unknown, ts = Date.now()) {
    const raw = body === undefined ? '' : JSON.stringify(body);
    const sig = sign(null, requestMessage(method, path, String(ts), raw), this.priv);
    return {
      'content-type': 'application/json',
      'x-producer': this.hex,
      'x-timestamp': String(ts),
      'x-signature': sig.toString('base64url'),
    };
  }

  tag(batchId: number, serial: number) {
    const sig = sign(null, signedMessage(this.key, BigInt(batchId), serial), this.priv);
    const id = Buffer.alloc(8);
    id.writeBigUInt64LE(BigInt(batchId));
    const sn = Buffer.alloc(4);
    sn.writeUInt32LE(serial);
    return 'AUTH1.' + Buffer.concat([this.key, id, sn, sig]).toString('base64url');
  }
}

export function testApp(fetchImpl?: typeof fetch, env: Record<string, string> = {}) {
  const config = loadConfig({ DB_PATH: ':memory:', ...env });
  const store = new ScanStore(':memory:');
  const app = buildApp({ config, chain: new MemoryChain(), store, fetchImpl });
  return { app, store };
}
