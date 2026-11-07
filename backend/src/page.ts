/**
 * Public verify page for people without the app. The QR holds
 * `<api>/t/<tag>`; any phone camera opens this page, and the page calls
 * POST /v1/verify itself. The check runs from the page's script, not on page
 * load, so link-preview bots that only fetch the HTML do not count as scans.
 */
export function verifyPage(): string {
  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex">
<title>Authentic: checking your product</title>
<style>
  :root { --ink:#10241d; --soft:#3f5149; --muted:#7d8a83; --line:#e2e6e4; --forest:#0f3d2e; }
  * { box-sizing: border-box; }
  body { margin:0; font-family: Inter, system-ui, -apple-system, "Segoe UI", Roboto, sans-serif; color:var(--ink); background:#fff; }
  main { max-width: 440px; margin: 0 auto; padding: 28px 22px 40px; }
  .brand { font-size: 13px; font-weight: 600; letter-spacing: .08em; text-transform: uppercase; color: var(--forest); }
  .seal { width: 88px; height: 88px; border-radius: 50%; margin: 36px 0 20px; display:grid; place-items:center; background:#e4e6df; color:#6f7c75; font-size:40px; }
  h1 { font-size: 34px; line-height: 1.1; margin: 0 0 10px; font-weight: 600; letter-spacing: -.02em; }
  p { font-size: 16px; line-height: 1.5; color: var(--soft); margin: 0 0 18px; }
  .card { border: 1.2px solid var(--line); border-radius: 18px; padding: 4px 16px; margin: 22px 0; }
  .row { display:flex; justify-content:space-between; gap:16px; padding: 12px 0; border-bottom: 1px solid var(--line); font-size: 15px; }
  .row:last-child { border-bottom: 0; }
  .row span:first-child { color: var(--muted); }
  .row span:last-child { text-align:right; font-weight:500; }
  .risk { margin: 22px 0; }
  .bar { height: 8px; border-radius: 99px; background: #eef0ee; overflow: hidden; margin: 8px 0 10px; }
  .bar i { display:block; height:100%; width:0; background: currentColor; transition: width .8s ease; }
  .label { font-size: 12px; font-weight:600; letter-spacing:.08em; text-transform:uppercase; color: var(--muted); }
  .foot { margin-top: 30px; font-size: 13px; color: var(--muted); }
  button { font: inherit; font-weight:600; padding: 14px 20px; border-radius: 14px; border: 0; background: var(--forest); color: #fff; width: 100%; margin-top: 8px; }
  .good { color:#1f8a5f } .good .seal { background:#dcefe3; color:#1f8a5f }
  .warn { color:#d9891a } .warn .seal { background:#f9e8c8; color:#d9891a }
  .bad  { color:#c1432e } .bad  .seal { background:#f7ddd5; color:#c1432e }
  .good h1,.warn h1,.bad h1 { color: inherit }
</style>
</head>
<body>
<main id="app" class="">
  <div class="brand">Authentic</div>
  <div class="seal" id="seal">…</div>
  <h1 id="title">Checking</h1>
  <p id="msg">Verifying the signature and the registry.</p>
  <div id="extra"></div>
  <div class="foot">Authentic checks that a product tag was signed by its producer and recorded in a public registry. Open the Authentic app to verify tags offline and keep a history.</div>
</main>
<script>
(function () {
  var tag = decodeURIComponent(location.pathname.split('/t/')[1] || '');
  var app = document.getElementById('app');
  var $ = function (id) { return document.getElementById(id); };
  var client;
  try {
    client = localStorage.getItem('authentic_client');
    if (!client) { client = 'web-' + Math.random().toString(16).slice(2) + Date.now().toString(16); localStorage.setItem('authentic_client', client); }
  } catch (e) { client = 'web-anon'; }

  var V = {
    genuineFirstScan: ['good', '\\u2713', 'Genuine', 'Signed by the producer and recorded on Solana. This is the first time this unit has been scanned.'],
    genuineScannedBefore: ['warn', '!', 'Scanned before', 'The signature is real, but this unit has been scanned %n times. It may be a copy.'],
    invalidTag: ['bad', '\\u2715', 'Not authentic', "This tag's signature does not match. It was not issued by the producer it claims."],
    unknownProducer: ['warn', '?', 'Unknown producer', 'The signature is valid, but this producer is not in the registry. Treat the product with suspicion.'],
    recalled: ['bad', '\\u2715', 'Recalled', 'The producer has pulled this batch. Do not use it, and return it to the seller.']
  };

  function row(k, v) { var r = document.createElement('div'); r.className = 'row'; var a = document.createElement('span'); a.textContent = k; var b = document.createElement('span'); b.textContent = v; r.appendChild(a); r.appendChild(b); return r; }

  function show(v) {
    var m = V[v.kind] || V.invalidTag;
    app.className = m[0];
    $('seal').textContent = m[1];
    $('title').textContent = m[2];
    $('msg').textContent = m[3].replace('%n', v.scanCount || 2);
    var extra = $('extra'); extra.innerHTML = '';
    var rows = [];
    if (v.producerName) rows.push(['Producer', v.producerName]);
    if (v.batch) {
      rows.push(['Product', v.batch.productName]);
      rows.push(['Origin', v.batch.origin]);
      rows.push(['Batch', v.batch.label]);
    }
    if (v.scanCount) rows.push(['Times scanned', String(v.scanCount)]);
    if (v.batch && v.batch.recallReason) rows.push(['Recall reason', v.batch.recallReason]);
    if (rows.length) { var c = document.createElement('div'); c.className = 'card'; rows.forEach(function (r) { c.appendChild(row(r[0], r[1])); }); extra.appendChild(c); }
    if (typeof v.riskScore === 'number') {
      var d = document.createElement('div'); d.className = 'risk';
      var l = document.createElement('div'); l.className = 'label'; l.textContent = 'Copy risk ' + v.riskScore + ' / 100';
      var bar = document.createElement('div'); bar.className = 'bar'; var i = document.createElement('i'); bar.appendChild(i);
      d.appendChild(l); d.appendChild(bar);
      if (v.riskExplanation) { var p = document.createElement('p'); p.textContent = v.riskExplanation; d.appendChild(p); }
      extra.appendChild(d);
      setTimeout(function () { i.style.width = v.riskScore + '%'; }, 50);
    }
  }

  function fail() {
    $('seal').textContent = '\\u2026';
    $('title').textContent = 'Could not check';
    $('msg').textContent = 'No connection to the registry right now. Try again.';
    var b = document.createElement('button'); b.textContent = 'Try again'; b.onclick = function () { location.reload(); };
    $('extra').innerHTML = ''; $('extra').appendChild(b);
  }

  if (!tag) { show({ kind: 'invalidTag' }); return; }
  fetch('/v1/verify', { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ tag: tag, clientId: client }) })
    .then(function (r) { if (!r.ok) throw new Error(); return r.json(); })
    .then(show)
    .catch(fail);
})();
</script>
</body>
</html>`;
}
