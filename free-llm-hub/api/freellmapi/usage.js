// api/freellmapi/usage.js — contatori VERI del centralino via MCP (stateless): usage_summary 24h + provider_health
// GET con header x-fh-key (chiave unificata) → {usage:{totals,topModels}, health:{...}}
// Serve: centralino ACCESO + MCP attivato nella sua dashboard (Keys → Agent compatibility).
const BASE = process.env.FREELLMAPI_BASE || 'http://127.0.0.1:31415';

async function mcpCall(key, name, args){
  const r = await fetch(BASE + '/mcp', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + key },
    body: JSON.stringify({ jsonrpc: '2.0', id: Date.now() % 100000, method: 'tools/call', params: { name, arguments: args || {} } }),
  });
  if (r.status === 403) throw new Error('MCP disattivato sul centralino: dashboard → Keys → Agent compatibility → Server MCP');
  if (!r.ok) throw new Error('MCP HTTP ' + r.status);
  const j = await r.json();
  if (j.error) throw new Error(j.error.message || 'errore MCP');
  const res = j.result || {};
  // il payload arriva come content[0].text (JSON), structuredContent, o diretto
  try { if (res.content && res.content[0] && res.content[0].text) return JSON.parse(res.content[0].text); } catch {}
  if (res.structuredContent) return res.structuredContent;
  return res;
}

module.exports = async (req, res) => {
  const key = (req.headers['x-fh-key'] || '') || (process.env.FREELLMAPI_KEY || '');
  if (!key) return res.status(401).json({ error: { message: 'manca la chiave unificata del centralino (⚙ → FreeLLMAPI)', type: 'authentication_error' } });
  try {
    const usage = await mcpCall(key, 'usage_summary', { range: '24h' });
    let health = null;
    try { health = await mcpCall(key, 'provider_health', {}); } catch {}
    return res.status(200).json({ usage, health });
  } catch (e) {
    return res.status(502).json({ error: { message: 'centralino non raggiungibile (serve hub LOCALE + FreeLLMAPI acceso + MCP attivo): ' + e.message, type: 'api_error' } });
  }
};
