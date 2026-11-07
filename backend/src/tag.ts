import { createPublicKey, verify } from 'node:crypto';
import { toHex, b64urlDecode } from './encoding.js';

export const TAG_PREFIX = 'AUTH1.';
const RAW_LENGTH = 108;
const SPKI_PREFIX = Buffer.from('302a300506032b6570032100', 'hex');

export interface ParsedTag {
  producerKey: Buffer; // 32
  producerHex: string;
  batchId: bigint;
  serial: number;
  signature: Buffer; // 64
  batchRef: string; // "<producerHex>:<batchId>"
}

/** Mirrors the app's TagCodec: key(32) + batchId u64 LE + serial u32 LE + sig(64). */
export function parseTag(raw: string): ParsedTag | null {
  const text = raw.trim();
  if (!text.startsWith(TAG_PREFIX)) return null;
  const body = text.slice(TAG_PREFIX.length);
  if (!/^[A-Za-z0-9_-]+$/.test(body)) return null;
  const bytes = b64urlDecode(body);
  if (bytes.length !== RAW_LENGTH) return null;
  const producerKey = bytes.subarray(0, 32);
  const batchId = bytes.readBigUInt64LE(32);
  const serial = bytes.readUInt32LE(40);
  const producerHex = toHex(producerKey);
  return {
    producerKey: Buffer.from(producerKey),
    producerHex,
    batchId,
    serial,
    signature: Buffer.from(bytes.subarray(44, 108)),
    batchRef: `${producerHex}:${batchId}`,
  };
}

export function signedMessage(
  producerKey: Uint8Array,
  batchId: bigint,
  serial: number,
): Buffer {
  const id = Buffer.alloc(8);
  id.writeBigUInt64LE(batchId);
  const sn = Buffer.alloc(4);
  sn.writeUInt32LE(serial);
  return Buffer.concat([Buffer.from('AUTH1', 'ascii'), producerKey, id, sn]);
}

export function verifyEd25519(
  publicKey: Uint8Array,
  message: Uint8Array,
  signature: Uint8Array,
): boolean {
  try {
    const key = createPublicKey({
      key: Buffer.concat([SPKI_PREFIX, publicKey]),
      format: 'der',
      type: 'spki',
    });
    return verify(null, message, key, signature);
  } catch {
    return false;
  }
}

export function tagSignatureIsValid(tag: ParsedTag): boolean {
  return verifyEd25519(
    tag.producerKey,
    signedMessage(tag.producerKey, tag.batchId, tag.serial),
    tag.signature,
  );
}
