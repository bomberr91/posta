#!/usr/bin/env node
// leggi_fb_cdp.mjs — Legge un post/gruppo Facebook + TUTTI i commenti dal Browser degli Agenti (porta 9222)
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import { execSync } from 'node:child_process';

const targetUrl = process.argv[2] || 'https://www.facebook.com/groups/vibecodinglife/permalink/2167430827178776';
const outFile = process.argv[3] || path.join(os.homedir(), 'posta', 'dal_pc', 'fb_post_commenti.md');

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function getTabs() {
  const res = await fetch('http://127.0.0.1:9222/json');
  return await res.json();
}

async function ensureBrowserRunning() {
  try {
    await getTabs();
    return true;
  } catch {
    console.log('🌐 Avvio automaticamente il Browser degli Agenti (porta 9222)...');
    try {
      const batWin = execSync('wslpath -w ~/posta/6_BROWSER_AGENTI.bat').toString().trim();
      execSync(`cmd.exe /c start "" "${batWin}"`, { stdio: 'ignore' });
    } catch {}
    for (let i = 0; i < 15; i++) {
      await sleep(1000);
      try {
        await getTabs();
        return true;
      } catch {}
    }
    return false;
  }
}

function cdpCall(ws, id, method, params = {}) {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error('Timeout CDP ' + method)), 120000);
    const handler = (ev) => {
      try {
        const msg = JSON.parse(ev.data.toString());
        if (msg.id === id) {
          clearTimeout(timer);
          ws.removeEventListener('message', handler);
          if (msg.error) reject(new Error(msg.error.message));
          else resolve(msg.result);
        }
      } catch {}
    };
    ws.addEventListener('message', handler);
    ws.send(JSON.stringify({ id, method, params }));
  });
}

async function main() {
  const ok = await ensureBrowserRunning();
  if (!ok) {
    console.error('✗ Impossibile contattare il Browser degli Agenti sulla porta 9222.');
    process.exit(1);
  }

  let tabs = await getTabs();
  let pageTab = tabs.find((t) => t.type === 'page' && t.url && t.url.includes('2167430827178776'))
             || tabs.find((t) => t.type === 'page' && t.url && t.url.includes('facebook.com'))
             || tabs.find((t) => t.type === 'page');

  if (!pageTab) {
    const r = await fetch('http://127.0.0.1:9222/json/new?' + encodeURIComponent(targetUrl), { method: 'PUT' });
    pageTab = await r.json();
  }

  console.log('🔗 Connesso al Browser degli Agenti:', pageTab.title || pageTab.url);
  const ws = new WebSocket(pageTab.webSocketDebuggerUrl);
  await new Promise((res, rej) => {
    ws.addEventListener('open', res, { once: true });
    ws.addEventListener('error', rej, { once: true });
  });

  let msgId = 1;
  if (!pageTab.url || !pageTab.url.includes(targetUrl.split('/').filter(Boolean).pop())) {
    console.log('➡️ Apro il link nel Browser degli Agenti:', targetUrl);
    await cdpCall(ws, msgId++, 'Page.navigate', { url: targetUrl });
    await sleep(6000);
  } else {
    await sleep(2000);
  }

  console.log('⏳ Espando TUTTI i commenti e le risposte (circa 20 secondi)...');
  const jsExpandAndExtract = `
    (async () => {
      const wait = (ms) => new Promise(r => setTimeout(r, ms));
      // 1. Prova a selezionare "Tutti i commenti" / "All comments"
      for (const el of document.querySelectorAll('div[role="button"], span')) {
        const tx = (el.innerText || '').trim();
        if (/^(Più pertinenti|Most relevant)$/i.test(tx)) {
          el.click();
          await wait(1200);
          for (const opt of document.querySelectorAll('div[role="menuitem"], div[role="option"], span')) {
            if (/^(Tutti i commenti|All comments)$/i.test((opt.innerText || '').trim())) {
              opt.click();
              await wait(2000);
              break;
            }
          }
          break;
        }
      }

      // 2. Ciclo di espansione di tutti i commenti e sottorisposte
      for (let i = 0; i < 22; i++) {
        let clicked = 0;
        const nodes = document.querySelectorAll('div[role="button"], span');
        for (const el of nodes) {
          const tx = (el.innerText || '').trim();
          if (
            tx.length > 2 && tx.length < 55 &&
            /altri commenti|altre risposte|visualizza altr|mostra altr|altro\\.\\.\\.|more comments|more replies|view more|see more|\\b\\d+\\s+(rispost|repl)/i.test(tx)
          ) {
            try { el.click(); clicked++; } catch (e) {}
          }
        }
        window.scrollBy(0, 1600);
        await wait(900);
        if (clicked === 0 && i > 6) break;
      }
      return {
        url: location.href,
        title: document.title,
        text: document.body.innerText
      };
    })()
  `;

  const evalRes = await cdpCall(ws, msgId++, 'Runtime.evaluate', {
    expression: jsExpandAndExtract,
    awaitPromise: true,
    returnByValue: true
  });

  ws.close();

  const val = evalRes?.result?.value || {};
  const bodyText = val.text || '';
  fs.mkdirSync(path.dirname(outFile), { recursive: true });
  const header = `# 📌 Post e Commenti Facebook Estratti\n- **URL**: ${val.url || targetUrl}\n- **Titolo**: ${val.title || ''}\n- **Caratteri estratti**: ${bodyText.length}\n\n---\n\n`;
  fs.writeFileSync(outFile, header + bodyText, 'utf8');
  console.log(`✓ Estratti ${bodyText.length} caratteri! Salvato in: ${outFile}`);

  // Spedisci subito sul ponte GitHub così Arena lo legge in automatico!
  try {
    const postaDir = path.join(os.homedir(), 'posta');
    let tok = '';
    const tokFile = path.join(os.homedir(), '.posta_token');
    const chiaviFile = path.join(os.homedir(), 'CHIAVI_LOCALI.md');
    if (fs.existsSync(tokFile)) tok = fs.readFileSync(tokFile, 'utf8').trim();
    if (!tok && fs.existsSync(chiaviFile)) {
      const m = fs.readFileSync(chiaviFile, 'utf8').match(/ghp_[A-Za-z0-9]{30,}/);
      if (m) tok = m[0];
    }
    execSync('git config user.name "bomberr91" && git config user.email "bomberr91@users.noreply.github.com"', { cwd: postaDir });
    execSync('git add dal_pc/ && git commit -m "Post e commenti FB estratti da FilippoPC" || true', { cwd: postaDir, stdio: 'ignore' });
    if (tok) {
      execSync(`git push "https://x-access-token:${tok}@github.com/bomberr91/posta.git" HEAD:main`, { cwd: postaDir, stdio: 'ignore' });
      console.log('🚀 Spedito automaticamente sul ponte GitHub (bomberr91/posta)!');
    }
  } catch (e) {
    console.log('· Nota push GitHub:', e.message);
  }
}

main().catch((err) => {
  console.error('Errore:', err.message);
  process.exit(1);
});
