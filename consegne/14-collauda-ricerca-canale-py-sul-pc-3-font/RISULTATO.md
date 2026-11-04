✅ COMPLETATO — issue #14 — 190s — exit 0
Agente: `goose`

### Output (coda)
```
+        snip = " ".join(re.sub(r"<[^>]+>", "", r.get("content", "") or "").split())[:280]
+        out.append({"titolo": titolo, "url": r.get("url", ""), "snippet": snip})
+    return out
+
 
-def search_web(keywords):
-    # Ricerca sul web usando l'API di SerpAPI
-    import requests
-    api_key = 'YOUR_SERPAPI_API_KEY'
-    query = '+'.join(keywords)
-    url = f'https://serpapi.com/search.json?q={query}&api_key={api_key}'
-    response = requests.get(url)
  ────────────────────────────────────────
  ▸ shell
    timeout_secs: 60
    command: cd /home/agenti/posta && python3 fatti/ricerca_canale.py "async python http client" --max 5 --fonte github

Ricerca su: async python http client

=== GITHUB (5 risultati)
1. aio-libs/aiohttp
   https://github.com/aio-libs/aiohttp
   16604★ — Asynchronous HTTP client/server framework for asyncio and Python
2. vibora-io/vibora
   https://github.com/vibora-io/vibora
   5580★ — Fast, asynchronous and elegant Python web framework.
3. tomplus/kubernetes_asyncio
   https://github.com/tomplus/kubernetes_asyncio
   440★ — Python asynchronous client library for Kubernetes http://kubernetes.io/
4. zszszszsz/.config
   https://github.com/zszszszsz/.config
   364★ — # # Automatically generated file; DO NOT EDIT. # OpenWrt Configuration # CONFIG_MODULES=y CONFIG_HAVE_DOT_CONFIG=y # CONFIG_TARGET_sunxi is not set # CONFIG_TARGET_apm821xx is not set # CONFIG_TARGET_ath25 is not set CONFIG_TARGET_ar71xx=y # CONFIG_TARGET_ath79 is not set 
5. KAY53N/rusty-req
   https://github.com/KAY53N/rusty-req
   299★ — ⚡ High-performance async HTTP client in Rust with Python bindings for blazing-fast batch requests.
  ────────────────────────────────────────
  ▸ shell
    command: cd /home/agenti/posta && python3 fatti/ricerca_canale.py "machine learning" --max 3 --fonte tutte
    timeout_secs: 60

Ricerca su: machine learning

=== REDDIT — DuckDuckGo (senza chiave) (0 risultati)
  nessun risultato

=== GITHUB (3 risultati)
1. tensorflow/tensorflow
   https://github.com/tensorflow/tensorflow
   201296★ — An Open Source Machine Learning Framework for Everyone
2. huggingface/transformers
   https://github.com/huggingface/transformers
   168523★ — 🤗 Transformers: the model-definition framework for state-of-the-art machine learning models in text, vision, audio, and multimodal models, for both inference and training.
3. microsoft/ML-For-Beginners
   https://github.com/microsoft/ML-For-Beginners
   91985★ — 12 weeks, 26 lessons, 52 quizzes, classic Machine Learning for all

=== WEB (0 risultati)
  nessun risultatoEcco l'output **VERBATIM** dei due comandi eseguiti sul PC:

---

### Comando 1
```bash
python3 fatti/ricerca_canale.py "async python http client" --max 5 --fonte github
```

**Output:**
```
Ricerca su: async python http client

=== GITHUB (5 risultati)
1. aio-libs/aiohttp
   https://github.com/aio-libs/aiohttp
   16604★ — Asynchronous HTTP client/server framework for asyncio and Python
2. vibora-io/vibora
   https://github.com/vibora-io/vibora
   5580★ — Fast, asynchronous and elegant Python web framework.
3. tomplus/kubernetes_asyncio
   https://github.com/tomplus/kubernetes_asyncio
   440★ — Python asynchronous client library for Kubernetes http://kubernetes.io/
4. zszszszsz/.config
   https://github.com/zszszszsz/.config
   364★ — # # Automatically generated file; DO NOT EDIT. # OpenWrt Configuration # CONFIG_MODULES=y CONFIG_HAVE_DOT_CONFIG=y # CONFIG_TARGET_sunxi is not set # CONFIG_TARGET_apm821xx is not set # CONFIG_TARGET_ath25 is not set CONFIG_TARGET_ar71xx=y # CONFIG_TARGET_ath79 is not set 
5. KAY53N/rusty-req
   https://github.com/KAY53N/rusty-req
   299★ — ⚡ High-performance async HTTP client in Rust with Python bindings for blazing-fast batch requests.
```

---

### Comando 2
```bash
python3 fatti/ricerca_canale.py "machine learning" --max 3 --fonte tutte
```

**Output:**
```
Ricerca su: machine learning

=== REDDIT — DuckDuckGo (senza chiave) (0 risultati)
  nessun risultato

=== GITHUB (3 risultati)
1. tensorflow/tensorflow
   https://github.com/tensorflow/tensorflow
   201296★ — An Open Source Machine Learning Framework for Everyone
2. huggingface/transformers
   https://github.com/huggingface/transformers
   168523★ — 🤗 Transformers: the model-definition framework for state-of-the-art machine learning models in text, vision, audio, and multimodal models, for both inference and training.
3. microsoft/ML-For-Beginners
   https://github.com/microsoft/ML-For-Beginners
   91985★ — 12 weeks, 26 lessons, 52 quizzes, classic Machine Learning for all

=== WEB (0 risultati)
  nessun risultato
```

---

**Nota:** Il canale **GitHub funziona perfettamente** (nessuna chiave richiesta, solo rate limit). Le fonti **Reddit** e **Web** tornano "0 risultati" perché il fallback DuckDuckGo HTML è bloccato da un CAPTCHA "bot check" — per averle operative serve configurare `TAVILY_API_KEY` (env o `~/.tavily/config.json`), come documentato nello script.
```

Consegna: `/consegne/14-collauda-ricerca-canale-py-sul-pc-3-font`