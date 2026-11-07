import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import {
  Connection,
  Keypair,
  PublicKey,
  SystemProgram,
  Transaction,
  TransactionInstruction,
  sendAndConfirmTransaction,
} from '@solana/web3.js';
import type { Config } from '../config.js';
import { fromHex, toBase58, toHex } from '../encoding.js';
import { ChainError, type BatchRecord, type Chain, type ProducerRecord } from './types.js';

// Anchor discriminators: first 8 bytes of sha256("<namespace>:<name>").
const disc = (ns: 'global' | 'account', name: string) =>
  createHash('sha256').update(`${ns}:${name}`).digest().subarray(0, 8);

const IX = {
  initialize: disc('global', 'initialize'),
  registerProducer: disc('global', 'register_producer'),
  createBatch: disc('global', 'create_batch'),
  recallBatch: disc('global', 'recall_batch'),
};
const ACC = {
  producer: disc('account', 'Producer'),
  batch: disc('account', 'Batch'),
};

// Borsh helpers (little endian).
export const encodeString = (s: string) => {
  const body = Buffer.from(s, 'utf8');
  const len = Buffer.alloc(4);
  len.writeUInt32LE(body.length);
  return Buffer.concat([len, body]);
};
const u64 = (n: bigint) => {
  const b = Buffer.alloc(8);
  b.writeBigUInt64LE(n);
  return b;
};
const u32 = (n: number) => {
  const b = Buffer.alloc(4);
  b.writeUInt32LE(n);
  return b;
};

class Reader {
  private o = 8; // skip account discriminator
  constructor(private buf: Buffer) {}
  pubkey() {
    const v = this.buf.subarray(this.o, this.o + 32);
    this.o += 32;
    return toHex(v);
  }
  u64() {
    const v = this.buf.readBigUInt64LE(this.o);
    this.o += 8;
    return v;
  }
  i64() {
    const v = this.buf.readBigInt64LE(this.o);
    this.o += 8;
    return v;
  }
  u32() {
    const v = this.buf.readUInt32LE(this.o);
    this.o += 4;
    return v;
  }
  bool() {
    return this.buf.readUInt8(this.o++) === 1;
  }
  u8() {
    return this.buf.readUInt8(this.o++);
  }
  string() {
    const len = this.u32();
    const v = this.buf.toString('utf8', this.o, this.o + len);
    this.o += len;
    return v;
  }
}

const date = (secs: bigint) => new Date(Number(secs) * 1000);

export function decodeProducer(data: Buffer): ProducerRecord {
  const r = new Reader(data);
  const keyHex = r.pubkey();
  const name = r.string();
  const registeredAt = date(r.i64());
  const active = r.bool();
  return { keyHex, name, registeredAt, active };
}

export function decodeBatch(data: Buffer): BatchRecord {
  const r = new Reader(data);
  const producerHex = r.pubkey();
  const batchId = r.u64();
  const productName = r.string();
  const origin = r.string();
  const quantity = r.u32();
  const createdAt = date(r.i64());
  const recalled = r.bool();
  const recalledAt = r.i64();
  const reason = r.string();
  return {
    producerHex,
    batchId,
    productName,
    origin,
    quantity,
    createdAt,
    recalled,
    recalledAt: recalled ? date(recalledAt) : null,
    recallReason: recalled ? reason : null,
  };
}

export class SolanaChain implements Chain {
  private registry: PublicKey;

  constructor(
    private connection: Connection,
    private relayer: Keypair,
    private programId: PublicKey,
  ) {
    this.registry = PublicKey.findProgramAddressSync([Buffer.from('registry')], programId)[0];
  }

  static fromConfig(config: Config): SolanaChain {
    if (!config.relayerKeypair) throw new Error('RELAYER_KEYPAIR is required when CHAIN=solana');
    const text = config.relayerKeypair.trim().startsWith('[')
      ? config.relayerKeypair
      : readFileSync(config.relayerKeypair, 'utf8');
    const relayer = Keypair.fromSecretKey(Uint8Array.from(JSON.parse(text) as number[]));
    return new SolanaChain(
      new Connection(config.rpcUrl, 'confirmed'),
      relayer,
      new PublicKey(config.programId),
    );
  }

  private producerPda(keyHex: string) {
    return PublicKey.findProgramAddressSync(
      [Buffer.from('producer'), fromHex(keyHex)!],
      this.programId,
    )[0];
  }

  private batchPda(producerHex: string, batchId: bigint) {
    return PublicKey.findProgramAddressSync(
      [Buffer.from('batch'), fromHex(producerHex)!, u64(batchId)],
      this.programId,
    )[0];
  }

  private async send(ix: TransactionInstruction) {
    try {
      await sendAndConfirmTransaction(this.connection, new Transaction().add(ix), [this.relayer], {
        commitment: 'confirmed',
      });
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      if (/already in use|custom program error: 0x0\b/.test(msg)) {
        throw new ChainError('already exists', 'conflict');
      }
      throw new ChainError(`chain unavailable: ${msg.slice(0, 160)}`, 'unavailable');
    }
  }

  /** One-time setup: creates the registry account with the relayer as admin. */
  async initialize() {
    await this.send(
      new TransactionInstruction({
        programId: this.programId,
        keys: [
          { pubkey: this.registry, isSigner: false, isWritable: true },
          { pubkey: this.relayer.publicKey, isSigner: true, isWritable: true },
          { pubkey: SystemProgram.programId, isSigner: false, isWritable: false },
        ],
        data: IX.initialize,
      }),
    );
  }

  async getProducer(keyHex: string) {
    const info = await this.connection.getAccountInfo(this.producerPda(keyHex), 'confirmed');
    return info ? decodeProducer(info.data) : null;
  }

  async registerProducer(keyHex: string, name: string) {
    await this.send(
      new TransactionInstruction({
        programId: this.programId,
        keys: [
          { pubkey: this.registry, isSigner: false, isWritable: false },
          { pubkey: this.producerPda(keyHex), isSigner: false, isWritable: true },
          { pubkey: this.relayer.publicKey, isSigner: true, isWritable: true },
          { pubkey: SystemProgram.programId, isSigner: false, isWritable: false },
        ],
        data: Buffer.concat([IX.registerProducer, fromHex(keyHex)!, encodeString(name)]),
      }),
    );
    const rec = await this.getProducer(keyHex);
    if (!rec) throw new ChainError('producer not found after registering', 'unavailable');
    return rec;
  }

  async getBatch(producerHex: string, batchId: bigint) {
    const info = await this.connection.getAccountInfo(
      this.batchPda(producerHex, batchId),
      'confirmed',
    );
    return info ? decodeBatch(info.data) : null;
  }

  async listBatches(producerHex: string) {
    const accounts = await this.connection.getProgramAccounts(this.programId, {
      commitment: 'confirmed',
      filters: [
        { memcmp: { offset: 0, bytes: toBase58(ACC.batch) } },
        { memcmp: { offset: 8, bytes: toBase58(fromHex(producerHex)!) } },
      ],
    });
    return accounts
      .map((a) => decodeBatch(a.account.data))
      .sort((a, b) => Number(a.batchId - b.batchId));
  }

  async createBatch(input: {
    producerHex: string;
    batchId: bigint;
    productName: string;
    origin: string;
    quantity: number;
  }) {
    await this.send(
      new TransactionInstruction({
        programId: this.programId,
        keys: [
          { pubkey: this.registry, isSigner: false, isWritable: false },
          { pubkey: this.producerPda(input.producerHex), isSigner: false, isWritable: false },
          { pubkey: this.batchPda(input.producerHex, input.batchId), isSigner: false, isWritable: true },
          { pubkey: this.relayer.publicKey, isSigner: true, isWritable: true },
          { pubkey: SystemProgram.programId, isSigner: false, isWritable: false },
        ],
        data: Buffer.concat([
          IX.createBatch,
          u64(input.batchId),
          encodeString(input.productName),
          encodeString(input.origin),
          u32(input.quantity),
        ]),
      }),
    );
    const rec = await this.getBatch(input.producerHex, input.batchId);
    if (!rec) throw new ChainError('batch not found after creating', 'unavailable');
    return rec;
  }

  async recallBatch(producerHex: string, batchId: bigint, reason: string) {
    await this.send(
      new TransactionInstruction({
        programId: this.programId,
        keys: [
          { pubkey: this.registry, isSigner: false, isWritable: false },
          { pubkey: this.batchPda(producerHex, batchId), isSigner: false, isWritable: true },
          { pubkey: this.relayer.publicKey, isSigner: true, isWritable: false },
        ],
        data: Buffer.concat([IX.recallBatch, encodeString(reason)]),
      }),
    );
    const rec = await this.getBatch(producerHex, batchId);
    if (!rec) throw new ChainError('batch not found', 'not_found');
    return rec;
  }
}
