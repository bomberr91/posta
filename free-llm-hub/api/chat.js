// api/chat.js — endpoint della UI: {provider, model, messages, web, stream}
const { handleChat, readBody } = require('../lib/proxy');

module.exports = async (req, res) => {
  if (req.method !== 'POST') return res.status(405).json({ error: { message: 'usa POST', type: 'invalid_request_error' } });
  let body;
  try { body = await readBody(req); } catch { return res.status(400).json({ error: { message: 'body JSON non valido', type: 'invalid_request_error' } }); }
  return handleChat({
    req, res,
    provider: body.provider,
    model: body.model,
    messages: Array.isArray(body.messages) ? body.messages : [],
    web: body.web !== false, // la ricerca web è LA BASE: ON di default
    stream: body.stream !== false,
    temperature: body.temperature,
    fusion: (body.fusion && typeof body.fusion === 'object') ? body.fusion : undefined,
  });
};
