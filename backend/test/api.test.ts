import assert from 'node:assert/strict';
import { test } from 'node:test';
import { Producer, testApp } from './helpers.js';

async function setup() {
  const { app } = testApp();
  const p = new Producer();
  const reg = await app.inject({
    method: 'POST',
    url: '/v1/producers',
    headers: p.headers('POST', '/v1/producers', { name: 'Huye Coffee Co-op' }),
    payload: { name: 'Huye Coffee Co-op' },
  });
  assert.equal(reg.statusCode, 201);
  const path = `/v1/producers/${p.hex}/batches`;
  const body = { productName: 'Arabica 250g', origin: 'Huye, Rwanda', quantity: 3 };
  const created = await app.inject({
    method: 'POST',
    url: path,
    headers: p.headers('POST', path, body),
    payload: body,
  });
  assert.equal(created.statusCode, 201);
  return { app, p, batch: created.json() as { id: string; label: string } };
}

const verify = (app: Awaited<ReturnType<typeof setup>>['app'], tag: string, clientId = 'phone-a') =>
  app.inject({ method: 'POST', url: '/v1/verify', payload: { tag, clientId } }).then((r) => r.json());

test('register, create batch, list', async () => {
  const { app, p, batch } = await setup();
  assert.equal(batch.label, 'B-1001');
  const list = await app.inject({ method: 'GET', url: `/v1/producers/${p.hex}/batches` });
  assert.equal(list.json().length, 1);
});

test('first scan is genuine, repeat scans raise risk', async () => {
  const { app, p } = await setup();
  const tag = p.tag(1001, 0);
  const first = await verify(app, tag);
  assert.equal(first.kind, 'genuineFirstScan');
  assert.equal(first.scanCount, 1);
  assert.ok(first.riskScore < 20);
  assert.equal(first.producerName, 'Huye Coffee Co-op');

  const second = await verify(app, tag, 'phone-b');
  assert.equal(second.kind, 'genuineScannedBefore');
  assert.equal(second.scanCount, 2);
  assert.ok(second.riskScore >= 55);

  const third = await verify(app, tag, 'phone-c');
  assert.ok(third.riskScore > second.riskScore);
  assert.equal(third.batch.unitsScanned, 1);
});

test('tampered tag, wrong serial, unknown producer', async () => {
  const { app, p } = await setup();
  const good = p.tag(1001, 1);
  const flipped = good.slice(0, -4) + (good.endsWith('AAAA') ? 'BBBB' : 'AAAA');
  assert.equal((await verify(app, flipped)).kind, 'invalidTag');
  assert.equal((await verify(app, 'AUTH1.zzz')).kind, 'invalidTag');
  assert.equal((await verify(app, p.tag(1001, 3))).kind, 'invalidTag'); // serial >= quantity
  assert.equal((await verify(app, p.tag(9999, 0))).kind, 'invalidTag'); // no such batch

  const stranger = new Producer();
  assert.equal((await verify(app, stranger.tag(1, 0))).kind, 'unknownProducer');
});

test('recall flips the verdict, only the producer can recall', async () => {
  const { app, p, batch } = await setup();
  const path = `/v1/batches/${batch.id}/recall`;
  const body = { reason: 'Contamination found' };

  const other = new Producer();
  const denied = await app.inject({
    method: 'POST',
    url: path,
    headers: other.headers('POST', path, body),
    payload: body,
  });
  assert.equal(denied.statusCode, 403);

  const ok = await app.inject({
    method: 'POST',
    url: path,
    headers: p.headers('POST', path, body),
    payload: body,
  });
  assert.equal(ok.statusCode, 200);
  assert.equal(ok.json().status, 'flagged');

  const v = await verify(app, p.tag(1001, 0));
  assert.equal(v.kind, 'recalled');
  assert.equal(v.batch.recallReason, 'Contamination found');

  const custody = await app.inject({ method: 'GET', url: `/v1/batches/${batch.id}/custody` });
  assert.deepEqual(
    custody.json().map((e: { kind: string }) => e.kind),
    ['created', 'flagged'],
  );
});

test('writes need a fresh, valid signature over the exact body', async () => {
  const { app } = testApp();
  const p = new Producer();
  const body = { name: 'X' };
  const path = '/v1/producers';

  const none = await app.inject({ method: 'POST', url: path, payload: body });
  assert.equal(none.statusCode, 401);

  const stale = await app.inject({
    method: 'POST',
    url: path,
    headers: p.headers('POST', path, body, Date.now() - 3_600_000),
    payload: body,
  });
  assert.equal(stale.statusCode, 401);

  const swapped = await app.inject({
    method: 'POST',
    url: path,
    headers: p.headers('POST', path, body),
    payload: { name: 'Y' },
  });
  assert.equal(swapped.statusCode, 401);
});

test('AI explanation is used when configured and falls back on failure', async () => {
  const mk = (impl: typeof fetch) => testApp(impl, { ANTHROPIC_API_KEY: 'test' });
  const okFetch = (async () =>
    new Response(JSON.stringify({ content: [{ type: 'text', text: 'Looks copied. Ask the seller.' }] }))) as typeof fetch;
  const badFetch = (async () => new Response('no', { status: 500 })) as typeof fetch;

  for (const [impl, expectAi] of [[okFetch, true], [badFetch, false]] as const) {
    const { app } = mk(impl);
    const p = new Producer();
    const rb = { name: 'N' };
    await app.inject({ method: 'POST', url: '/v1/producers', headers: p.headers('POST', '/v1/producers', rb), payload: rb });
    const path = `/v1/producers/${p.hex}/batches`;
    const bb = { productName: 'P', origin: 'O', quantity: 2 };
    await app.inject({ method: 'POST', url: path, headers: p.headers('POST', path, bb), payload: bb });
    const tag = p.tag(1001, 0);
    await verify(app, tag);
    const second = await verify(app, tag, 'phone-b');
    assert.equal(second.riskExplanation === 'Looks copied. Ask the seller.', expectAi);
  }
});

test('GET /t/<tag> serves the verify page without counting a scan', async () => {
  const { app, p } = await setup();
  const tag = p.tag(1001, 0);
  const res = await app.inject({ method: 'GET', url: `/t/${tag}` });
  assert.equal(res.statusCode, 200);
  assert.match(res.headers['content-type'] as string, /text\/html/);
  assert.match(res.body, /\/v1\/verify/);
  // opening the page alone must not record a scan
  assert.equal((await verify(app, tag)).scanCount, 1);
});
