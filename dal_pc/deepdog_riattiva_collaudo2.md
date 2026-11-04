# Risposta a «deepdog_riattiva_collaudo2»

_04/11/2026 17:32 · FilippoPC_

### 1. opzioni di setup che la web app accetta
62:    search_provider: str = "exa"
63:    speed_profile: str = "fast"
90:                                 ("search_provider", SETUP.search_provider),
91:                                 ("speed_profile", SETUP.speed_profile)):
121:    fast = selected.speed_profile == "fast"
138:        web_search_engine=selected.search_provider,
167:            search_provider=SETUP.search_provider,
168:            speed_profile=SETUP.speed_profile,
180:        "search_provider": selected.search_provider,
181:        "speed_profile": selected.speed_profile,
276:function paintSetup(s){for(const [name,ids] of Object.entries(keyFields)){const el=$(ids[1]),ok=!!s.configured[name];el.textContent=ok?'configurata':'non impostata';el.className='key-state'+(ok?' ok':'')} $('modelProvider').value=s.model_provider;$('searchProvider').value=s.search_provider;$('speedProfile').value=s.speed_profile;$('setupReady').textContent=s.ready?'Pronto':'Da configurare';$('setupReady').className=s.ready?'ready':'not-ready'}
279:$('saveSetup').onclick=async()=>{const keys={};for(const [name,ids] of Object.entries(keyFields)){const value=$(ids[0]).value.trim();if(value)keys[name]=value}const r=await fetch('/api/setup',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({keys,model_provider:$('modelProvider').value,search_provider:$('searchProvider').value,speed_profile:$('speedProfile').value})});const b=await r.json();if(!r.ok){$('setupMessage').textContent=b.error;return}for(const ids of Object.values(keyFields))$(ids[0]).value='';paintSetup(b);$('setupMessage').textContent=b.ready?'Configurazione pronta':'Mancano: '+b.missing.join(', ')};
377:            search_provider = str(payload.get("search_provider", "exa"))
378:            speed_profile = str(payload.get("speed_profile", "fast"))
382:            if model_provider not in ("cervello", "deepseek", "openrouter") or search_provider not in ("exa", "tavily", "both") or speed_profile not in ("fast", "deep"):
383:                self.send_json({"error": "Opzione di setup non valida"}, HTTPStatus.BAD_REQUEST)
396:                SETUP.search_provider = search_provider
397:                SETUP.speed_profile = speed_profile
401:                        "search_provider": SETUP.search_provider,
402:                        "speed_profile": SETUP.speed_profile,
-- chiavi riconosciute:
263:<div class="field"><label for="deepseekKey">DeepSeek API key</label><div class="key-wrap"><input id="deepseekKey" type="password" autocomplete="off" placeholder="sk-…"><span id="deepseekState" class="key-state">non impostata</span></div></div>
265:<div class="field"><label for="openrouterKey">OpenRouter API key <small>(opzionale, anche modelli Anthropic/Google)</small></label><div class="key-wrap"><input id="openrouterKey" type="password" autocomplete="off" placeholder="sk-or-…"><span id="openrouterState" class="key-state">non impostata</span></div></div>
275:const keyFields={DEEPSEEK_API_KEY:['deepseekKey','deepseekState'],EXA_API_KEY:['exaKey','exaState'],OPENROUTER_API_KEY:['openrouterKey','openrouterState'],TAVILY_API_KEY:['tavilyKey','tavilyState']};
276:function paintSetup(s){for(const [name,ids] of Object.entries(keyFields)){const el=$(ids[1]),ok=!!s.configured[name];el.textContent=ok?'configurata':'non impostata';el.className='key-state'+(ok?' ok':'')} $('modelProvider').value=s.model_provider;$('searchProvider').value=s.search_provider;$('speedProfile').value=s.speed_profile;$('setupReady').textContent=s.ready?'Pronto':'Da configurare';$('setupReady').className=s.ready?'ready':'not-ready'}
279:$('saveSetup').onclick=async()=>{const keys={};for(const [name,ids] of Object.entries(keyFields)){const value=$(ids[0]).value.trim();if(value)keys[name]=value}const r=await fetch('/api/setup',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({keys,model_provider:$('modelProvider').value,search_provider:$('searchProvider').value,speed_profile:$('speedProfile').value})});const b=await r.json();if(!r.ok){$('setupMessage').textContent=b.error;return}for(const ids of Object.values(keyFields))$(ids[0]).value='';paintSetup(b);$('setupMessage').textContent=b.ready?'Configurazione pronta':'Mancano: '+b.missing.join(', ')};

### 2. stato prima
   status           failed
   error            APIStatusError: Error code: 402 - This request requires more credits, or fewer max_tokens. You requested up to 32000 tokens, but can only afford 4447. To increase, visit https://openrouter.ai/settings/credits and upgrade to a paid account

### 3. POST /api/setup con il provider 'cervello'
   payload ['keys', 'model_provider'] -> 200 {"configured": {"DEEPSEEK_API_KEY": false, "EXA_API_KEY": true, "OPENROUTER_API_KEY": true, "TAVILY_API_KEY": true}, "model_provider": "cervello", "search_provider": "exa", "speed_profile": "fast", "ready": false, "missing": ["DEEPSEEK_API_KEY", "DEEPSEEK_KEY"]}

### 4. stato dopo il setup
   model_provider: None | status: failed

### 5. se il cane e' ancora sul vecchio provider: riavvio (uccido SOLO chi sta sulla 8765)
   processo in ascolto sulla 8765: 16068
   uccido il PID 16068 (il cane) e riavvio
   cane di nuovo vivo (~30s)

### 6. COLLAUDO REALE: una ricerca vera col wrapper
exit del wrapper: 1
cane vivo (porta 8765)
domanda: che modelli offre il cervello locale?
domanda mandata, aspetto il report (max 10 minuti)...
stato: failed
report: dal_pc/deepdog_reports/deepdog_ricerca_2026-11-04_17-32-49.md  (dal testo dello stato)
errore del cane: Apri Setup e configura: DEEPSEEK_API_KEY, DEEPSEEK_KEY

--- estratto:
   (il cane non ha scritto un report)

il postino pubblica i report in dal_pc/deepdog_reports/ -> gli agenti li ritrovano nel repo

### 7. PROVA finale: provider usato e log del portiere
   model_provider: None
   status: failed | error: Apri Setup e configura: DEEPSEEK_API_KEY, DEEPSEEK_KEY
-- ultime righe del log del portiere:
{"tipo": "richiesta", "agente": "cervello-168fedf2616d6d39", "politica": "auto", "rotta": "motore", "modello": "auto", "ms": 5550, "quando": "2026-11-04 16:21:49"}
{"tipo": "cache", "agente": "cervello-168fedf2616d6d39", "rotta": "cache", "ms": 0, "quando": "2026-11-04 16:22:38"}
{"tipo": "richiesta", "agente": "cervello-168fedf2616d6d39", "politica": "auto", "rotta": "motore", "modello": "auto", "ms": 6167, "quando": "2026-11-04 16:22:45"}
{"tipo": "richiesta", "agente": "cervello-168fedf2616d6d39", "politica": "auto", "rotta": "motore", "modello": "auto", "ms": 5571, "quando": "2026-11-04 16:27:57"}
FINE

<!-- fine deepdog_riattiva_collaudo2 -->
