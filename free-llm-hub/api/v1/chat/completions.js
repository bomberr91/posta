// api/v1/chat/completions.js — endpoint OpenAI-COMPATIBILE per gli agenti (OpenClaw, Hermes, ecc.)
// Esposto a /v1/chat/completions via rewrite in vercel.json.
// Body identico a OpenAI; il model può essere "provider/modello" (es. "freellmapi/auto", "freellmapi/fusion")
// oppure un id nudo se non ambiguo. Chiavi: env su Vercel OPPURE header x-fh-key.
// Ricerca web: header "x-fh-web: 1" oppure body.web_search === true.
// Se è impostata l'env FREEHUB_ACCESS_KEY, richiede Authorization: Bearer <quella chiave>.
const { handleChat, readBody } = require('../../../lib/proxy');
const { resolve } = require('../../../lib/providers');

module.exports = async (req, res) => {
  if (req.method !== 'POST') return res.status(405).json({ error: { message: 'usa POST', type: 'invalid_request_error' } });
  const accessKey = process.env.FREEHUB_ACCESS_KEY;
  if (accessKey) {
    const auth = (req.headers['authorization'] || '').replace(/^Bearer\s+/i, '');
    if (auth !== accessKey) return res.status(401).json({ error: { message: 'FREEHUB_ACCESS_KEY impostata ma bearer errante/mancante', type: 'authentication_error' } });
  }
  let body;
  try { body = await readBody(req); } catch { return res.status(400).json({ error: { message: 'body JSON non valido', type: 'invalid_request_error' } }); }

  const r = resolve(body.model);
  if (!r) return res.status(400).json({ error: { message: `modello non riconosciuto: "${body.model}". Formato: provider/modello (es. freellmapi/auto, freellmapi/fusion) — catalogo: http://127.0.0.1:31415/v1/models`, type: 'invalid_request_error' } });

  // LA RICERCA WEB È LA BASE DEL PROGETTO: ON di default.
  // Disattivabile solo esplicitamente: header "x-fh-web: 0" oppure body.web_search === false
  const web = !(req.headers['x-fh-web'] === '0' || body.web_search === false);

  return handleChat({
    req, res,
    provider: r.provider,
    model: r.model,
    messages: Array.isArray(body.messages) ? body.messages : [],
    web,
    stream: body.stream === true,
    temperature: body.temperature,
  });
};
