import { ChainError, type BatchRecord, type Chain, type ProducerRecord } from './types.js';

/** In-memory registry for local development without Solana. Starts empty. */
export class MemoryChain implements Chain {
  private producers = new Map<string, ProducerRecord>();
  private batches = new Map<string, BatchRecord>();

  private k(producerHex: string, batchId: bigint) {
    return `${producerHex}:${batchId}`;
  }

  async getProducer(keyHex: string) {
    return this.producers.get(keyHex) ?? null;
  }

  async registerProducer(keyHex: string, name: string) {
    if (this.producers.has(keyHex)) {
      throw new ChainError('producer already registered', 'conflict');
    }
    const rec: ProducerRecord = {
      keyHex,
      name,
      registeredAt: new Date(),
      active: true,
    };
    this.producers.set(keyHex, rec);
    return rec;
  }

  async getBatch(producerHex: string, batchId: bigint) {
    return this.batches.get(this.k(producerHex, batchId)) ?? null;
  }

  async listBatches(producerHex: string) {
    return [...this.batches.values()]
      .filter((b) => b.producerHex === producerHex)
      .sort((a, b) => Number(a.batchId - b.batchId));
  }

  async createBatch(input: {
    producerHex: string;
    batchId: bigint;
    productName: string;
    origin: string;
    quantity: number;
  }) {
    if (!this.producers.has(input.producerHex)) {
      throw new ChainError('unknown producer', 'not_found');
    }
    const key = this.k(input.producerHex, input.batchId);
    if (this.batches.has(key)) throw new ChainError('batch exists', 'conflict');
    const rec: BatchRecord = {
      ...input,
      createdAt: new Date(),
      recalled: false,
      recalledAt: null,
      recallReason: null,
    };
    this.batches.set(key, rec);
    return rec;
  }

  async recallBatch(producerHex: string, batchId: bigint, reason: string) {
    const rec = this.batches.get(this.k(producerHex, batchId));
    if (!rec) throw new ChainError('batch not found', 'not_found');
    if (rec.recalled) throw new ChainError('already recalled', 'conflict');
    rec.recalled = true;
    rec.recalledAt = new Date();
    rec.recallReason = reason;
    return rec;
  }
}
