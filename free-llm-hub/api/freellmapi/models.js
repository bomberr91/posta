// api/freellmapi/models.js — il catalogo del CENTRALINO (per la fusion "code": scegliere il pannello di esperti)
// GET con header x-fh-key (chiave unificata) → {data:[{id}]} dei modelli disponibili ADESSO
// Ha senso solo con hub LOCALE + FreeLLMAPI acceso: su Vercel 127.0.0.1 è il server stesso → 502 pulito.
const BASE = process.env.FREELLMAPI_BASE || 'http://127.0.0.1:31415';

module.exports = async (req, res) => {
  const key = (req.headers['x-fh-key'] || '') || (process.env.FREELLMAPI_KEY || '');
  if (!key) return res.status(401).json({ error: { message: 'manca la chiave unificata del centralino (⚙ → FreeLLMAPI)', type: 'authentication_error' } });
  try {
    const r = await fetch(BASE + '/v1/models?available=true', { headers: { Authorization: 'Bearer ' + key } });
    if (!r.ok) {
      const t = await r.text();
      let msg = t.slice(0, 300);
      try { msg = JSON.parse(t).error?.message || msg; } catch {}
      return res.status(r.status).json({ error: { message: 'centralino: ' + msg, type: 'upstream_error' } });
    }
    const j = await r.json();
    const data = (Array.isArray(j.data) ? j.data : []).map(m => ({ id: m.id })).filter(m => m.id);
    return res.status(200).json({ data });
  } catch (e) {
    return res.status(502).json({ error: { message: 'centralino non raggiungibile (serve l\'hub LOCALE con FreeLLMAPI acceso): ' + e.message, type: 'api_error' } });
  }
};
