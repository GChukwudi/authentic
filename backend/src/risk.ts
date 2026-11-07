import type { ScanResult } from './store.js';

export interface Risk {
  score: number; // 0..100, higher means more likely a copy
  facts: string[]; // plain facts used for the explanation
  fallback: string; // template explanation, used when no AI is configured
}

/** Deterministic score. The AI only words the explanation; it never sets the score. */
export function assessRisk(scan: ScanResult, now = Date.now()): Risk {
  const facts = [`This unit has now been scanned ${scan.count} time(s).`];
  if (scan.count <= 1) {
    return {
      score: 8,
      facts,
      fallback: 'First scan of this unit, and nothing about it looks unusual.',
    };
  }

  let score = scan.count === 2 ? 55 : 80 + Math.min(15, (scan.count - 3) * 4);

  if (scan.distinctClients > 1) {
    score += 6;
    facts.push(`${scan.distinctClients} different phones have scanned it.`);
  }
  if (scan.previousAt !== null) {
    const minutes = Math.round((now - scan.previousAt) / 60_000);
    facts.push(`The previous scan was ${minutes} minute(s) ago.`);
    if (minutes < 10 && scan.distinctClients > 1) score += 6;
  }
  if (scan.lastHour >= 3) {
    score += 5;
    facts.push(`${scan.lastHour} scans in the last hour.`);
  }
  score = Math.min(99, score);

  const fallback =
    scan.count === 2
      ? 'This tag was scanned once before. A genuine unit is usually scanned once, so it may be a copy. Ask the seller where it came from.'
      : `Scanned ${scan.count} times. That pattern is typical of a copied tag. Do not rely on this product, and report it to the seller.`;
  return { score, facts, fallback };
}

export interface ExplainOptions {
  apiKey: string | undefined;
  model: string;
  productName: string;
  fetchImpl?: typeof fetch;
  timeoutMs?: number;
}

/** One or two plain sentences for a shopper. Falls back to the template on any failure. */
export async function explainRisk(risk: Risk, opts: ExplainOptions): Promise<string> {
  if (!opts.apiKey || risk.score < 20) return risk.fallback;
  const doFetch = opts.fetchImpl ?? fetch;
  try {
    const res = await doFetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        'x-api-key': opts.apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify({
        model: opts.model,
        max_tokens: 120,
        system:
          'You explain product-authenticity scan results to a shopper. Two short sentences, plain words, no jargon, no markdown. Never claim certainty; say what the pattern suggests and what to do next.',
        messages: [
          {
            role: 'user',
            content: `Product: ${opts.productName}\nRisk score (0-100, higher = more likely a copied tag): ${risk.score}\nFacts:\n- ${risk.facts.join('\n- ')}`,
          },
        ],
      }),
      signal: AbortSignal.timeout(opts.timeoutMs ?? 3500),
    });
    if (!res.ok) return risk.fallback;
    const json = (await res.json()) as { content?: { type: string; text?: string }[] };
    const text = json.content?.find((c) => c.type === 'text')?.text?.trim();
    return text && text.length <= 400 ? text : risk.fallback;
  } catch {
    return risk.fallback;
  }
}
