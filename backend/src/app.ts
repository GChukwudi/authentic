import Fastify, { type FastifyInstance, type FastifyRequest } from 'fastify';
import { authenticate } from './auth.js';
import { ChainError, type BatchRecord, type Chain } from './chain/types.js';
import type { Config } from './config.js';
import { fromHex, toBase58 } from './encoding.js';
import { verifyPage } from './page.js';
import { assessRisk, explainRisk } from './risk.js';
import type { ScanStore } from './store.js';
import { parseTag, tagSignatureIsValid } from './tag.js';

export interface Deps {
  config: Config;
  chain: Chain;
  store: ScanStore;
  fetchImpl?: typeof fetch;
}

const MAX_QUANTITY = 1000; // one printed sheet worth of tags per batch in the app

function batchJson(b: BatchRecord, unitsScanned: number) {
  return {
    id: `${b.producerHex}:${b.batchId}`,
    label: `B-${b.batchId}`,
    productName: b.productName,
    origin: b.origin,
    quantity: b.quantity,
    status: b.recalled ? 'flagged' : 'active',
    createdAt: b.createdAt.toISOString(),
    unitsScanned,
    recallReason: b.recallReason,
  };
}

function parseBatchRef(ref: string): { producerHex: string; batchId: bigint } | null {
  const m = /^([0-9a-f]{64}):(\d{1,20})$/i.exec(ref);
  if (!m) return null;
  return { producerHex: m[1]!.toLowerCase(), batchId: BigInt(m[2]!) };
}

function cleanText(value: unknown, max: number): string | null {
  if (typeof value !== 'string') return null;
  const t = value.trim();
  return t.length > 0 && Buffer.byteLength(t) <= max ? t : null;
}

export function buildApp(deps: Deps): FastifyInstance {
  const { config, chain, store } = deps;
  const app = Fastify({ logger: false, bodyLimit: 64 * 1024, routerOptions: { maxParamLength: 512 } });

  app.addContentTypeParser(
    'application/json',
    { parseAs: 'string' },
    (req, body, done) => {
      (req as FastifyRequest & { rawBody: string }).rawBody = body as string;
      try {
        done(null, body === '' ? {} : JSON.parse(body as string));
      } catch {
        done(Object.assign(new Error('invalid JSON'), { statusCode: 400 }), undefined);
      }
    },
  );

  app.setErrorHandler((err: Error & { statusCode?: number }, _req, reply) => {
    if (err instanceof ChainError) {
      const status =
        err.code === 'not_found' ? 404 : err.code === 'conflict' ? 409 : err.code === 'invalid' ? 400 : 503;
      return reply.code(status).send({ error: err.message });
    }
    const status = err.statusCode && err.statusCode < 500 ? err.statusCode : 500;
    return reply.code(status).send({ error: status === 500 ? 'internal error' : err.message });
  });

  const guard = (req: FastifyRequest) => {
    const path = new URL(req.url, 'http://x').pathname;
    const raw = (req as FastifyRequest & { rawBody?: string }).rawBody ?? '';
    return authenticate(req.headers, req.method, path, raw, config.maxSkewMs);
  };

  // Batch ids are allocated per producer; serialise so two creates never collide.
  const locks = new Map<string, Promise<unknown>>();
  const withLock = <T>(key: string, fn: () => Promise<T>): Promise<T> => {
    const run = (locks.get(key) ?? Promise.resolve()).then(fn, fn);
    locks.set(key, run.catch(() => undefined));
    return run;
  };

  // Landing page for plain camera scans. See page.ts.
  app.get('/t/:tag', async (_req, reply) =>
    reply
      .header('cache-control', 'no-store')
      .type('text/html; charset=utf-8')
      .send(verifyPage()),
  );

  app.get('/health', async () => ({ ok: true, chain: config.chain }));

  // Register the signing key as a producer. The key signs this request, which proves it holds it.
  app.post('/v1/producers', async (req, reply) => {
    const auth = guard(req);
    if (!auth.ok) return reply.code(401).send({ error: auth.reason });
    const name = cleanText((req.body as { name?: unknown } | undefined)?.name, 40);
    if (!name) return reply.code(400).send({ error: 'name is required (max 40 bytes)' });

    const existing = await chain.getProducer(auth.producerHex);
    const rec = existing ?? (await chain.registerProducer(auth.producerHex, name));
    return reply.code(existing ? 200 : 201).send({
      name: rec.name,
      publicKey: toBase58(fromHex(rec.keyHex)!),
      registeredAt: rec.registeredAt.toISOString(),
    });
  });

  app.get('/v1/producers/:key', async (req, reply) => {
    const { key } = req.params as { key: string };
    const bytes = fromHex(key);
    if (!bytes || bytes.length !== 32) return reply.code(400).send({ error: 'bad key' });
    const rec = await chain.getProducer(key.toLowerCase());
    if (!rec) return reply.code(404).send({ error: 'not found' });
    return {
      name: rec.name,
      publicKey: toBase58(bytes),
      registeredAt: rec.registeredAt.toISOString(),
    };
  });

  app.get('/v1/producers/:key/batches', async (req, reply) => {
    const { key } = req.params as { key: string };
    const bytes = fromHex(key);
    if (!bytes || bytes.length !== 32) return reply.code(400).send({ error: 'bad key' });
    const hex = key.toLowerCase();
    const list = await chain.listBatches(hex);
    return list
      .reverse()
      .map((b) => batchJson(b, store.unitsScanned(`${b.producerHex}:${b.batchId}`)));
  });

  app.post('/v1/producers/:key/batches', async (req, reply) => {
    const auth = guard(req);
    if (!auth.ok) return reply.code(401).send({ error: auth.reason });
    const { key } = req.params as { key: string };
    if (key.toLowerCase() !== auth.producerHex) {
      return reply.code(403).send({ error: 'key does not match signer' });
    }
    const body = (req.body ?? {}) as Record<string, unknown>;
    const productName = cleanText(body.productName, 48);
    const origin = cleanText(body.origin, 48);
    const quantity = body.quantity;
    if (!productName || !origin) {
      return reply.code(400).send({ error: 'productName and origin are required (max 48 bytes)' });
    }
    if (!Number.isInteger(quantity) || (quantity as number) < 1 || (quantity as number) > MAX_QUANTITY) {
      return reply.code(400).send({ error: `quantity must be 1 to ${MAX_QUANTITY}` });
    }
    if (!(await chain.getProducer(auth.producerHex))) {
      return reply.code(404).send({ error: 'register the producer first' });
    }

    const created = await withLock(auth.producerHex, async () => {
      const existing = await chain.listBatches(auth.producerHex);
      const next = existing.reduce((m, b) => (b.batchId > m ? b.batchId : m), 1000n) + 1n;
      return chain.createBatch({
        producerHex: auth.producerHex,
        batchId: next,
        productName,
        origin,
        quantity: quantity as number,
      });
    });
    return reply.code(201).send(batchJson(created, 0));
  });

  app.post('/v1/batches/:ref/recall', async (req, reply) => {
    const auth = guard(req);
    if (!auth.ok) return reply.code(401).send({ error: auth.reason });
    const ref = parseBatchRef((req.params as { ref: string }).ref);
    if (!ref) return reply.code(400).send({ error: 'bad batch id' });
    if (ref.producerHex !== auth.producerHex) {
      return reply.code(403).send({ error: 'only the producer can recall a batch' });
    }
    const reason = cleanText((req.body as { reason?: unknown } | undefined)?.reason, 80);
    if (!reason) return reply.code(400).send({ error: 'reason is required (max 80 bytes)' });
    const rec = await chain.recallBatch(ref.producerHex, ref.batchId, reason);
    return batchJson(rec, store.unitsScanned(`${rec.producerHex}:${rec.batchId}`));
  });

  app.get('/v1/batches/:ref/custody', async (req, reply) => {
    const ref = parseBatchRef((req.params as { ref: string }).ref);
    if (!ref) return reply.code(400).send({ error: 'bad batch id' });
    const [batch, producer] = await Promise.all([
      chain.getBatch(ref.producerHex, ref.batchId),
      chain.getProducer(ref.producerHex),
    ]);
    if (!batch || !producer) return reply.code(404).send({ error: 'not found' });
    const events = [
      {
        kind: 'created',
        title: 'Batch created and signed',
        actor: producer.name,
        place: batch.origin,
        at: batch.createdAt.toISOString(),
      },
    ];
    if (batch.recalled && batch.recalledAt) {
      events.push({
        kind: 'flagged',
        title: 'Batch recalled',
        actor: producer.name,
        place: batch.recallReason ?? '',
        at: batch.recalledAt.toISOString(),
      });
    }
    return events;
  });

  // Registry, recall and scan-history check. The signature is re-checked here; the phone's check is only for offline use.
  app.post('/v1/verify', async (req, reply) => {
    const body = (req.body ?? {}) as { tag?: unknown; clientId?: unknown };
    if (typeof body.tag !== 'string') return reply.code(400).send({ error: 'tag is required' });
    const client =
      typeof body.clientId === 'string' && body.clientId.length <= 64 ? body.clientId : req.ip;

    const tag = parseTag(body.tag);
    if (!tag || !tagSignatureIsValid(tag)) return { kind: 'invalidTag' };

    const producer = await chain.getProducer(tag.producerHex);
    if (!producer || !producer.active) return { kind: 'unknownProducer' };

    const batch = await chain.getBatch(tag.producerHex, tag.batchId);
    if (!batch || tag.serial >= batch.quantity) {
      return { kind: 'invalidTag', producerName: producer.name };
    }
    if (batch.recalled) {
      return {
        kind: 'recalled',
        producerName: producer.name,
        batch: batchJson(batch, store.unitsScanned(tag.batchRef)),
      };
    }

    const scan = store.record(tag.batchRef, tag.serial, client);
    const risk = assessRisk(scan);
    const explanation = await explainRisk(risk, {
      apiKey: config.anthropicKey,
      model: config.anthropicModel,
      productName: batch.productName,
      fetchImpl: deps.fetchImpl,
    });
    return {
      kind: scan.count === 1 ? 'genuineFirstScan' : 'genuineScannedBefore',
      scanCount: scan.count,
      riskScore: risk.score,
      riskExplanation: explanation,
      producerName: producer.name,
      batch: batchJson(batch, store.unitsScanned(tag.batchRef)),
    };
  });

  return app;
}
