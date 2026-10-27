// lib/search.js — ricerca web senza chiavi: DuckDuckGo lite (HTML) con fallback all'Instant Answer API
// Nota: best-effort. DDG a volte limita gli IP datacenter (Vercel incluso): i risultati
// vengono iniettati come contesto; se la ricerca fallisce, la chat funziona comunque.

const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126 Safari/537.36';

function decodeDdgUrl(u) {
  try {
    if (u.includes('duckduckgo.com/l/')) {
      const m = u.match(/uddg=([^&]+)/);
      if (m) return decodeURIComponent(m[1]);
    }
    return u;
  } catch { return u; }
}

function stripTags(s) {
  return String(s || '').replace(/<[^>]*>/g, '').replace(/&amp;/g, '&').replace(/&quot;/g, '"')
    .replace(/&#x27;/g, "'").replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/\s+/g, ' ').trim();
}

async function ddgLite(q, n) {
  const r = await fetch('https://lite.duckduckgo.com/lite/?q=' + encodeURIComponent(q), {
    headers: { 'User-Agent': UA, 'Accept-Language': 'it-IT,it;q=0.9,en;q=0.8' },
  });
  if (!r.ok) throw new Error('ddg lite ' + r.status);
  const html = await r.text();
  // i risultati sono ancore con redirect uddg= (apici singoli o doppi, ordine variabile)
  const links = [...html.matchAll(/<a[^>]*href=["']([^"']*uddg=[^"']+)["'][^>]*>([\s\S]*?)<\/a>/gi)].map(m => ({
    url: decodeDdgUrl(m[1].startsWith('//') ? 'https:' + m[1] : m[1]), title: stripTags(m[2]),
  }));
  const snips = [...html.matchAll(/<td[^>]*class=["']result-snippet["'][^>]*>([\s\S]*?)<\/td>/gi)].map(m => stripTags(m[1]));
  const out = [];
  for (let i = 0; i < links.length && out.length < n; i++) {
    if (!links[i].url || !/^https?:\/\//.test(links[i].url)) continue;
    out.push({ title: links[i].title, url: links[i].url, snippet: snips[i] || '' });
  }
  if (!out.length) throw new Error('ddg lite: 0 risultati (blocco o captcha?)');
  return out;
}

async function ddgViaJina(q, n) {
  // r.jina.ai fetcha DDG lite al posto nostro: bypassa il 403 che DDG dà agli IP datacenter (Vercel).
  // Senza chiave: ~20 richieste/min — più che sufficienti per un hub personale.
  const jinaHeaders = { 'User-Agent': UA };
  if (process.env.JINA_API_KEY) jinaHeaders['Authorization'] = 'Bearer ' + process.env.JINA_API_KEY; // free key su jina.ai/key: limiti più alti (opzionale)
  const r = await fetch('https://r.jina.ai/https://lite.duckduckgo.com/lite/?q=' + encodeURIComponent(q), {
    headers: jinaHeaders,
  });
  if (!r.ok) throw new Error('jina+ddg ' + r.status);
  const md = await r.text();
  const out = [];
  const re = /\[([^\]]+)\]\(https:\/\/duckduckgo\.com\/l\/\?uddg=([^)]+)\)/g;
  let m;
  while ((m = re.exec(md)) && out.length < n) {
    const url = decodeDdgUrl('https://duckduckgo.com/l/?uddg=' + m[2]);
    const title = stripTags(m[1]);
    if (!/^https?:\/\//.test(url) || url.includes('duckduckgo.com')) continue;
    // snippet: il testo in grassetto che segue il link nel markdown di jina
    const after = md.slice(m.index + m[0].length, m.index + m[0].length + 400);
    const sn = (after.match(/^\s*\*\*?([^*\n]{20,300})/) || [])[1] || '';
    out.push({ title, url, snippet: sn.trim() });
  }
  if (!out.length) throw new Error('jina+ddg: 0 risultati');
  return out;
}

async function ddgInstant(q) {
  const r = await fetch('https://api.duckduckgo.com/?format=json&no_html=1&skip_disambig=1&q=' + encodeURIComponent(q));
  if (!r.ok) throw new Error('ddg ia ' + r.status);
  const j = await r.json();
  const out = [];
  if (j.AbstractText && j.AbstractURL) out.push({ title: j.Heading || q, url: j.AbstractURL, snippet: j.AbstractText });
  for (const t of (j.RelatedTopics || [])) {
    if (t.Text && t.FirstURL) out.push({ title: (t.Text || '').split(' - ')[0], url: t.FirstURL, snippet: t.Text });
    if (out.length >= 6) break;
  }
  if (!out.length) throw new Error('ddg ia: 0 risultati');
  return out.slice(0, 6);
}

async function wikipediaIt(q, n) {
  const r = await fetch('https://it.wikipedia.org/w/api.php?action=query&list=search&srlimit=' + n + '&srsearch=' + encodeURIComponent(q) + '&format=json&origin=*');
  if (!r.ok) throw new Error('wiki ' + r.status);
  const j = await r.json();
  const hits = (j.query && j.query.search) || [];
  if (!hits.length) throw new Error('wiki: 0 risultati');
  return hits.map(h => ({
    title: h.title,
    url: 'https://it.wikipedia.org/wiki/' + encodeURIComponent(h.title.replace(/ /g, '_')),
    snippet: stripTags(h.snippet),
  }));
}

async function wikipediaEn(q, n) {
  const r = await fetch('https://en.wikipedia.org/w/api.php?action=query&list=search&srlimit=' + n + '&srsearch=' + encodeURIComponent(q) + '&format=json&origin=*');
  if (!r.ok) throw new Error('wiki-en ' + r.status);
  const j = await r.json();
  const hits = (j.query && j.query.search) || [];
  if (!hits.length) throw new Error('wiki-en: 0 risultati');
  return hits.map(h => ({
    title: h.title,
    url: 'https://en.wikipedia.org/wiki/' + encodeURIComponent(h.title.replace(/ /g, '_')),
    snippet: stripTags(h.snippet),
  }));
}

async function googleNewsRss(q, n) {
  // Google News RSS: pubblico, senza chiave, tollera gli IP datacenter (i feed sono fatti per i server)
  const r = await fetch('https://news.google.com/rss/search?q=' + encodeURIComponent(q) + '&hl=it&gl=IT&ceid=IT:it', {
    headers: { 'User-Agent': UA },
  });
  if (!r.ok) throw new Error('gnews ' + r.status);
  const xml = await r.text();
  const items = [...xml.matchAll(/<item>([\s\S]*?)<\/item>/g)].map(m => m[1]).slice(0, n);
  if (!items.length) throw new Error('gnews: 0 risultati');
  return items.map(it => {
    const t = (it.match(/<title>([\s\S]*?)<\/title>/) || [])[1] || '';
    const l = (it.match(/<link>([\s\S]*?)<\/link>/) || [])[1] || '';
    const d = stripTags((it.match(/<description>([\s\S]*?)<\/description>/) || [])[1] || '');
    return { title: t.slice(0, 200), url: l.trim(), snippet: d.slice(0, 250) };
  }).filter(x => x.url);
}

async function searchWeb(query, n = 6) {
  const errs = [];
  const motori = [['ddg-lite', ddgLite], ['ddg-via-jina', ddgViaJina], ['gnews-rss', googleNewsRss], ['ddg-ia', ddgInstant], ['wiki-it', wikipediaIt], ['wiki-en', wikipediaEn]];
  for (const [nome, fn] of motori) {
    try { const r = await fn(query, n); if (Array.isArray(r)) r._engine = nome; return r; } catch (e) { errs.push(nome + ': ' + e.message); }
  }
  return { error: 'ricerca non disponibile: ' + errs.join(' | ') };
}

function resultsToContext(results, query) {
  if (!results || results.error) {
    return `[ricerca web per "${query}" non riuscita (${results ? results.error : 'errore'}) — rispondi con le tue conoscenze e dillo se potrebbero non essere aggiornate]`;
  }
  const blocchi = results.map((r, i) => `[${i + 1}] ${r.title}\n${r.url}\n${r.snippet}`).join('\n\n');
  return `RISULTATI DI RICERCA WEB (DuckDuckGo) per la domanda: "${query}"\n(data: ${new Date().toISOString().slice(0, 10)})\n\n${blocchi}\n\nUsa questi risultati per rispondere. Cita le fonti come [1], [2] quando usi un'informazione. Se i risultati non bastano, dillo.`;
}

module.exports = { searchWeb, resultsToContext };
