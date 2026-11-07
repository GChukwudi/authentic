import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { test } from 'node:test';
import { decodeBatch, decodeProducer, encodeString } from '../src/chain/solana.js';

const disc = (s: string) => createHash('sha256').update(s).digest().subarray(0, 8);

test('anchor discriminator for initialize matches the well-known value', () => {
  assert.deepEqual([...disc('global:initialize')], [175, 175, 109, 31, 13, 152, 155, 237]);
});

test('decodes the Borsh layout the Rust program writes', () => {
  const key = Buffer.alloc(32, 7);
  const i64 = (n: number) => {
    const b = Buffer.alloc(8);
    b.writeBigInt64LE(BigInt(n));
    return b;
  };
  const u32 = (n: number) => {
    const b = Buffer.alloc(4);
    b.writeUInt32LE(n);
    return b;
  };
  const u64 = (n: number) => {
    const b = Buffer.alloc(8);
    b.writeBigUInt64LE(BigInt(n));
    return b;
  };

  const producer = Buffer.concat([
    disc('account:Producer'), key, encodeString('Huye'), i64(1_700_000_000), Buffer.from([1, 254]),
  ]);
  const p = decodeProducer(producer);
  assert.equal(p.name, 'Huye');
  assert.equal(p.active, true);
  assert.equal(p.registeredAt.getTime(), 1_700_000_000_000);

  const batch = Buffer.concat([
    disc('account:Batch'), key, u64(1001), encodeString('Arabica'), encodeString('Huye'),
    u32(10), i64(1_700_000_100), Buffer.from([1]), i64(1_700_000_200), encodeString('Bad lot'), Buffer.from([255]),
  ]);
  const b = decodeBatch(batch);
  assert.equal(b.batchId, 1001n);
  assert.equal(b.quantity, 10);
  assert.equal(b.recalled, true);
  assert.equal(b.recallReason, 'Bad lot');
  assert.equal(b.recalledAt?.getTime(), 1_700_000_200_000);
});
