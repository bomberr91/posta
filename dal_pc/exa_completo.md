# Risposta a «exa_completo»

_01/11/2026 15:26 · FilippoPC_

## 🔎 EXA: VERIFICA + DOPPIA RICERCA + SKILL — 15:26
### 1. .env (mascherato)
OPENROUTER_API_KEY=sk-or-•••
TAVILY_API_KEY=tvly-d•••
PUBMED_EMAIL=strate•••
SEC_EDGAR_CONTACT_EMAIL=strate•••
ROUTE_VIA_OPENROUTER=true
WEB_SEARCH_ENGINE=tavily•••
EXA_API_KEY=cc3a11•••

### 2. valori ammessi per WEB_SEARCH_ENGINE
696-# Which web search engine to expose to the web/general platform agents.
697-# "tavily" = only Tavily; "exa" = only Exa (default); "both" = expose both.
698:WEB_SEARCH_ENGINE = os.environ.get("WEB_SEARCH_ENGINE", "exa").strip().lower()
699-
700-# Max characters of extracted page text Exa returns per search result. This
701-# text is retained as the article's full text and served back on fetch_urls
702-# (so the same page is not re-fetched via Tavily). Bundled into the /search
703-# base price regardless of size.
704-EXA_SEARCH_MAX_CHARS = int(os.environ.get("EXA_SEARCH_MAX_CHARS", "6000"))

### 3. skill ufficiale build-with-exa nei 3 nidi
cp: warning: behavior of -n is non-portable and may change in future; use --update=none instead
  ✓ innestata in /home/agenti/.claude/skills
cp: warning: behavior of -n is non-portable and may change in future; use --update=none instead
  ✓ innestata in /home/agenti/.agents/skills
cp: warning: behavior of -n is non-portable and may change in future; use --update=none instead
  ✓ innestata in /home/agenti/.config/opencode/skills
---
name: build-with-exa
description: "Build applications and agents with Exa's API: search, contents extraction, answer, Agent API, monitors, websets, OpenAI-compatible endpoints, and exa-py/exa-js SDKs. Use when choosing Exa endpoints, writing Exa API calls, integrating semantic web search or research into products, or debugging Exa request shapes."
metadata:
  author: Exa
  version: "0.3.0"
  docs: "https://exa.ai/docs"
---

<!-- fine exa_completo -->
