✅ COMPLETATO — issue #53 — 248s — exit 0
Agente: `opencode`

### Output (coda)
```
① CONFERMATO: il widget scrive `%LOCALAPPDATA%\agenti\agentrouter_fatto_YYYY-MM-DD.txt`, mentre postino/GUI/checkin usano `$HOME/.ar_checkin_YYYY-MM-DD`. Il SÌ del popup quindi zittisce il widget ma NON segna il bonus come fatto per `postino.sh:239` (loop 45 s) e `gui/index.html:230` (richiama /api/checkin 2,5 s dopo ogni caricamento finche' `checkin_oggi` e' falso). Questo provoca la riapertura invisibile della pagina. L'endpoint `/api/checkin/segna` (`gui/server.py:1968`) e' la via gia' esistente per segnare il fatto a mano: il widget NON lo chiama. RIGA: `strumenti/widget_agentrouter_src.ps1:14`. CORREZIONE: aggiungi `Invoke-RestMethod -Uri "http://127.0.0.1:9222/api/checkin/segna" -Method Post` dopo la riga 14.

② CONFERMATO: ogni riga di `dal_pc/sveglia_agentrouter.md` e' duplicata (script lanciato 2 volte) e il `.vbs` e' in Startup: e' plausibile piu' di un'istanza di WIDGET_AGENTROUTER.ps1. RIGA: `dal_pc/sveglia_agentrouter.md:3,5,7`. CORREZIONE: rimuovere una delle due righe duplicate per ogni sezione del file.

③ CONFERMATO: `strumenti/widget_agentrouter_src.ps1`: riga 10 apre Chrome PRIMA del MessageBox, riga 12 mostra il popup SÌ/NO, riga 14 scrive il flag SOLO con `DialogResult.Yes`, riga 17 `Start-Sleep -Seconds 1200` (20 minuti) in ogni altro caso. Con riga 1 `$ErrorActionPreference='SilentlyContinue'`, se il MessageBox fallisce l'errore e' silenzioso e `$r` resta vuoto => ramo NO => riapertura della pagina SENZA popup ogni 20 minuti. RIGA: `strumenti/widget_agentrouter_src.ps1:17`. CORREZIONE: sostituire `Start-Sleep -Seconds 1200` con `Start-Sleep -Seconds 3600` per attendere 1 ora invece di 20 minuti.
```
### Errori (coda)
```
                except ValueError as e:
                    self._json({"err": str(e)}, 400)
        elif self.path == "/api/checkin":
            self._json(fai_checkin(forza=bool(self._body().get("forza"))))
        elif self.path == "/api/checkin/segna":
            if os.path.exists(flag_checkin()):
                self._json({"stato": "gia_fatto", "msg": "Già segnato come fatto per oggi."})
                return
            scrivi(flag_checkin(), time.strftime("%H:%M") + "-manuale")
            pulisci_login_manuale()
            # azzero anche i tentativi: la giornata è chiusa, non deve più riprovare
            try:
                os.remove(file_tentativi())
            except Exception:
                pass
            self._json({"stato": "ok",
                        "msg": "✅ Segnato: bonus di oggi già preso a mano. Stasera nessun logout."})
        elif self.path == "/api/checkin/verifica":
            v = verifica_sessione(bloccante=True)
            self._json({"valida": bool(v), "login_manuale": serve_login_manuale() and not os.path.exists(flag_checkin()),
                        "msg": ("✅ Sessione valida: ho tolto l'avviso. Ora puoi premere «Riscatta ora»."
                                if v else ("⚠️ Sessione non valida: fai il login in BROWSER_AGENTI."
                                           if v is False else "Apri prima il BROWSER_AGENTI."))})
        elif self.path == "/api/search":
            q = str((self._body().get("q") or "")).strip()[:400]
            if not q:
                self._json({"error": {"message": 'manca "q"'}}, 400)
                return
            res = _ricerca_web(q)
            self._json({"q": q, "context": risultati_in_testo(res, q),
                        "results": [{"title": r["title"], "url": r["url"]} for r in res]})
        elif self.path in ("/v1/chat/completions", "/v1/chat/completions/"):
            auth = dettaglio_token_agente(self.headers.get("Authorization"))
            if auth is None:
                self._json({"error": {"message": "manca il token dell'agente (Authorization: Bearer …)"}}, 401)
                return
            b = self._body()
            if not isinstance(b, dict):
[0m
[0m→ [0mRead posta/checkin_agentrouter.py
```

Consegna: `/consegne/53-verifica-bug-sveglia-agentrouter-sola-le`