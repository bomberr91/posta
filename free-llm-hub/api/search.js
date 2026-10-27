// api/search.js — solo la ricerca web dell'hub (per la modalità DIRETTA della UI e per gli agenti)
// POST {q} → {context, results} — stesso motore di /api/chat (DDG lite → DDG IA → Wikipedia IT)
const { searchWeb, resultsToContext } = require('../lib/search');

function readBody(req) {
  return new Promise((ok, ko) => {
    let b = '';
    req.on('data', c => { b += c; if (b.length > 1e6) req.destroy(); });
    req.on('end', () => { try { ok(b ? JSON.parse(b) : {}); } catch (e) { ko(e); } });
    req.on('error', ko);
  });
}

module.exports = async (req, res) => {
  if (req.method !== 'POST') return res.status(405).json({ error: { message: 'usa POST', type: 'invalid_request_error' } });
  let body;
  try { body = await readBody(req); } catch { return res.status(400).json({ error: { message: 'body JSON non valido', type: 'invalid_request_error' } }); }
  const q = String(body.q || '').slice(0, 400);
  if (!q) return res.status(400).json({ error: { message: 'manca "q" (la domanda)', type: 'invalid_request_error' } });
  const results = await searchWeb(q);
  const context = resultsToContext(results, q.slice(0, 200));
  const clean = Array.isArray(results) ? results.map(r => ({ title: r.title, url: r.url })) : [];
  return res.status(200).json({ q, context, engine: (results && results._engine) || null, results: clean });
};
