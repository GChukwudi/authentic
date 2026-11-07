export interface ProducerRecord {
  keyHex: string;
  name: string;
  registeredAt: Date;
  active: boolean;
}

export interface BatchRecord {
  producerHex: string;
  batchId: bigint;
  productName: string;
  origin: string;
  quantity: number;
  createdAt: Date;
  recalled: boolean;
  recalledAt: Date | null;
  recallReason: string | null;
}

/** The registry the API reads and writes. Memory and Solana implement it. */
export interface Chain {
  getProducer(keyHex: string): Promise<ProducerRecord | null>;
  registerProducer(keyHex: string, name: string): Promise<ProducerRecord>;
  getBatch(producerHex: string, batchId: bigint): Promise<BatchRecord | null>;
  listBatches(producerHex: string): Promise<BatchRecord[]>;
  createBatch(input: {
    producerHex: string;
    batchId: bigint;
    productName: string;
    origin: string;
    quantity: number;
  }): Promise<BatchRecord>;
  recallBatch(
    producerHex: string,
    batchId: bigint,
    reason: string,
  ): Promise<BatchRecord>;
}

export class ChainError extends Error {
  constructor(
    message: string,
    readonly code: 'not_found' | 'conflict' | 'invalid' | 'unavailable',
  ) {
    super(message);
  }
}
