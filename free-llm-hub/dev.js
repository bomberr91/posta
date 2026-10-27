#!/usr/bin/env node
// dev.js — test LOCALE senza Vercel: serve index.html e monta le funzioni api/ alla stessa maniera
// Uso: PORT=12777 node dev.js  →  http://localhost:12777 (porta Centrale; modificabile con PORT)
const http = require('http');
const fs = require('fs');
const path = require('path');

const chat = require('./api/chat');
const search = require('./api/search');
const fllmModels = require('./api/freellmapi/models');
const fllmUsage = require('./api/freellmapi/usage');
const completions = require('./api/v1/chat/completions');
const models = require('./api/v1/models');

const PORT = process.env.PORT || 3000;

const server = http.createServer((req, res) => {
  let url = req.url.split('?')[0];
  // stessa rewrite di vercel.json
  if (url.startsWith('/v1/')) url = '/api' + url;
  // polyfill: su Vercel res.status/json/send esistono nativamente, su Node puro no
  res.status = c => { res.statusCode = c; return res; };
  res.json = o => { res.setHeader('Content-Type', 'application/json; charset=utf-8'); res.end(JSON.stringify(o)); return res; };
  res.send = b => { res.end(b); return res; };
  if (url === '/' || url === '/index.html') {
    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    return res.end(fs.readFileSync(path.join(__dirname, 'index.html')));
  }
  if (url.startsWith('/pdfjs/')) { // pdf.js venduto nel repo: estrazione testo PDF, tutto locale
    const name = url.slice('/pdfjs/'.length);
    if (/^[a-z0-9.\-]+\.js$/.test(name) && fs.existsSync(path.join(__dirname, 'pdfjs', name))) {
      res.setHeader('Content-Type', 'application/javascript; charset=utf-8');
      return res.end(fs.readFileSync(path.join(__dirname, 'pdfjs', name)));
    }
    res.statusCode = 404; return res.end('404');
  }
  if (url === '/api/chat') return chat(req, res);
  if (url === '/api/search') return search(req, res);
  if (url === '/api/freellmapi/models') return fllmModels(req, res);
  if (url === '/api/freellmapi/usage') return fllmUsage(req, res);
  if (url === '/api/v1/chat/completions') return completions(req, res);
  if (url === '/api/v1/models' || url === '/v1/models') return models(req, res);
  res.statusCode = 404;
  res.end('404');
});

server.listen(PORT, '0.0.0.0', () => console.log(`Free LLM Hub (locale) → http://localhost:${PORT}`));
