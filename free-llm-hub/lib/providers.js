// lib/providers.js — l'UNICO provider è il centralino FreeLLMAPI sul PC (10/10: hub solo locale).
// Dentro il centralino ci sono GIÀ i 34 provider (Google, Groq, OpenRouter, NVIDIA, …) con le stesse chiavi.
// Un solo punto da aggiornare quando cambia qualcosa.

const PROVIDERS = {
  freellmapi: {
    label: 'FreeLLMAPI (centralino sul PC) 🔌',
    base: process.env.FREELLMAPI_BASE || 'http://127.0.0.1:31415/v1',
    keyEnv: 'FREELLMAPI_KEY',
    keyUrl: 'http://127.0.0.1:31415',
    quota: 'il TUO centralino: 34 provider impilati (~7,4B token/mese) · failover automatico · richiede FreeLLMAPI desktop ACCESO',
    training: 'dipende dal provider che il router sceglie',
    models: [
      { id: 'auto', note: 'il router sceglie il migliore + failover' },
      { id: 'auto:fast', note: 'il più veloce' },
      { id: 'auto:smart', note: 'il più intelligente' },
      { id: 'auto:cheap', note: 'il più leggero in quota' },
      { id: 'fusion', note: '✨ 3 modelli + giudice che fonde le risposte' },
    ],
  },
};

// "provider/modello" → { provider, model } | modello nudo → match nella lista di un provider
function resolve(model) {
  if (!model || typeof model !== 'string') return null;
  const i = model.indexOf('/');
  if (i > 0) {
    const p = model.slice(0, i);
    if (PROVIDERS[p]) return { provider: p, model: model.slice(i + 1) };
  }
  for (const [p, cfg] of Object.entries(PROVIDERS)) {
    if (cfg.models.some(m => m.id === model)) return { provider: p, model };
  }
  return null;
}

module.exports = { PROVIDERS, resolve };
