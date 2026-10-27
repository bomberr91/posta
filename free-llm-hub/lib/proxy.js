// lib/proxy.js — il cuore: gira la chat su un provider OpenAI-compatible e (opzionale) inietta la ricerca web
const { PROVIDERS, resolve } = require('./providers');
const { searchWeb, resultsToContext } = require('./search');

function readBody(req) {
  return new Promise((ok, ko) => {
    let b = '';
    req.on('data', c => { b += c; if (b.length > 5e6) req.destroy(); });
    req.on('end', () => { try { ok(b ? JSON.parse(b) : {}); } catch (e) { ko(e); } });
    req.on('error', ko);
  });
}

// prende la chiave: header esplicito > env del provider
function pickKey(req, provider) {
  const cfg = PROVIDERS[provider];
  return (req.headers['x-fh-key'] || '') || (process.env[cfg.keyEnv] || '') || '';
}

function lastUserQuestion(messages) {
  for (let i = messages.length - 1; i >= 0; i--) if (messages[i].role === 'user') return messages[i].content;
  return '';
}

// main: { provider, model, messages, web, stream, fusion } → risponde a res (SSE o JSON)
async function handleChat({ req, res, provider, model, messages, web, stream, temperature, fusion }) {
  const cfg = PROVIDERS[provider];
  if (!cfg) return res.status(400).json({ error: { message: `provider sconosciuto: ${provider}. Validi: ${Object.keys(PROVIDERS).join(', ')}`, type: 'invalid_request_error' } });
  const key = pickKey(req, provider);
  if (!key) {
    return res.status(401).json({ error: {
      message: `chiave mancante per ${cfg.label}. Incollala nella UI (⚙) oppure imposta la variabile d'ambiente ${cfg.keyEnv} su Vercel. Chiave gratuita: ${cfg.keyUrl}`,
      type: 'authentication_error' } });
  }

  // ricerca web opzionale: iniettata come messaggio di sistema
  let outMessages = messages;
  if (web) {
    const q = lastUserQuestion(messages);
    if (q) {
      const results = await searchWeb(String(q).slice(0, 400));
      const ctx = resultsToContext(results, String(q).slice(0, 200));
      outMessages = [{ role: 'system', content: ctx }, ...messages];
    }
  }

  const payload = { model, messages: outMessages, stream: !!stream };
  if (typeof temperature === 'number') payload.temperature = temperature;
  // config fusion del centralino (model "fusion"): pannello esplicito per "code", expose_panel per la UI
  if (fusion && typeof fusion === 'object') payload.fusion = fusion;

  let upstream;
  try {
    upstream = await fetch(cfg.base + '/chat/completions', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + key, ...(cfg.extraHeaders || {}) },
      body: JSON.stringify(payload),
    });
  } catch (e) {
    const extra = provider === 'freellmapi'
      ? ' — il centralino gira sul TUO PC (127.0.0.1:31415): controlla che FreeLLMAPI desktop sia ACCESO (icona nella tray).'
      : '';
    return res.status(502).json({ error: { message: `impossibile contattare ${cfg.label}: ${e.message}${extra}`, type: 'api_error' } });
  }

  if (!upstream.ok) {
    const txt = await upstream.text();
    let msg = txt.slice(0, 600);
    try { msg = JSON.parse(txt).error?.message || msg; } catch {}
    if (upstream.status === 429) msg = 'limite di quota raggiunto su ' + cfg.label + ' (RPM/RPD). ' + cfg.quota + ' — risposta originale: ' + msg;
    return res.status(upstream.status).json({ error: { message: msg, type: upstream.status === 429 ? 'rate_limit_error' : 'upstream_error', provider: provider } });
  }

  if (stream && upstream.body) {
    const via = upstream.headers.get('x-routed-via'); // quale modello ha SERVITO davvero (auto/fusion)
    if (via) res.setHeader('X-Routed-Via', via);
    res.setHeader('Content-Type', 'text/event-stream; charset=utf-8');
    res.setHeader('Cache-Control', 'no-cache, no-transform');
    res.setHeader('X-Accel-Buffering', 'no');
    res.flushHeaders && res.flushHeaders();
    const reader = upstream.body.getReader();
    try {
      while (true) {
        const { done, value } = await reader.read();
        if (done) break;
        res.write(value);
      }
    } catch (e) {
      res.write(`data: {"error":{"message":"stream interrotto: ${e.message}"}}\n\n`);
    }
    return res.end();
  }

  const json = await upstream.text();
  const viaJ = upstream.headers.get('x-routed-via');
  if (viaJ) res.setHeader('X-Routed-Via', viaJ);
  res.setHeader('Content-Type', 'application/json; charset=utf-8');
  return res.status(200).send(json);
}

module.exports = { handleChat, readBody };
