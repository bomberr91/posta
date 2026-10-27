// api/v1/models.js — lista modelli in formato OpenAI (GET /v1/models)
const { PROVIDERS } = require('../../lib/providers');

module.exports = async (req, res) => {
  const data = [];
  for (const [p, cfg] of Object.entries(PROVIDERS)) {
    for (const m of cfg.models) {
      data.push({ id: `${p}/${m.id}`, object: 'model', owned_by: p, note: m.note, quota: cfg.quota });
    }
  }
  res.setHeader('Content-Type', 'application/json; charset=utf-8');
  return res.status(200).send(JSON.stringify({ object: 'list', data }, null, 2));
};
