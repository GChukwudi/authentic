import { createHash } from 'node:crypto';
import { b64urlDecode, fromHex } from './encoding.js';
import { verifyEd25519 } from './tag.js';

export const REQUEST_PREFIX = 'AUTH1-REQ';

/**
 * Message a producer signs to authorise a write:
 *   "AUTH1-REQ\n<METHOD>\n<path>\n<timestamp ms>\n<sha256 hex of raw body>"
 * Sent as headers x-producer (hex key), x-timestamp, x-signature (base64url).
 */
export function requestMessage(
  method: string,
  path: string,
  timestamp: string,
  rawBody: string,
): Buffer {
  const bodyHash = createHash('sha256').update(rawBody).digest('hex');
  return Buffer.from(
    [REQUEST_PREFIX, method.toUpperCase(), path, timestamp, bodyHash].join('\n'),
  );
}

export type AuthResult =
  | { ok: true; producerHex: string }
  | { ok: false; reason: string };

export function authenticate(
  headers: Record<string, string | string[] | undefined>,
  method: string,
  path: string,
  rawBody: string,
  maxSkewMs: number,
  now = Date.now(),
): AuthResult {
  const one = (name: string) => {
    const v = headers[name];
    return typeof v === 'string' ? v : undefined;
  };
  const producer = one('x-producer');
  const timestamp = one('x-timestamp');
  const signature = one('x-signature');
  if (!producer || !timestamp || !signature) {
    return { ok: false, reason: 'missing auth headers' };
  }
  const key = fromHex(producer);
  if (!key || key.length !== 32) return { ok: false, reason: 'bad producer key' };
  const ts = Number(timestamp);
  if (!Number.isFinite(ts) || Math.abs(now - ts) > maxSkewMs) {
    return { ok: false, reason: 'stale or invalid timestamp' };
  }
  const sig = b64urlDecode(signature);
  if (sig.length !== 64) return { ok: false, reason: 'bad signature' };
  const ok = verifyEd25519(key, requestMessage(method, path, timestamp, rawBody), sig);
  return ok
    ? { ok: true, producerHex: producer.toLowerCase() }
    : { ok: false, reason: 'signature does not match' };
}
