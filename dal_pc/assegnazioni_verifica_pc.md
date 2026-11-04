# Risposta a «assegnazioni_verifica_pc»

_04/11/2026 10:49 · FilippoPC_

   2fbee35..fe1da01  main       -> origin/main
Already up to date.
commit: fe1da01 4/11: da_me/assegnazioni_verifica_pc.sh — collaudo del libro mastro sul PC (portachiavi vero)
libro mastro: 4812 byte
portachiavi: 21467 byte

====================================================================================================
 LIBRO MASTRO DELLE CHIAVI — lavori/assegnazioni_provider.tsv
====================================================================================================
  Cervello / portiere                WSL (20129 *roster*                                       ATTIVO
      via        : diretto · esclusivita: ESCLUSIVA
      note       : è l'allocatore: è l'unico che può usare tutte le chiavi (file: portiere_lista.txt, quote in portiere_quote.txt)
  Motore locale + sito + OmniRoute   WSL (20128 *roster*                                       ATTIVO
      via        : diretto · esclusivita: CONDIVISA
      note       : stessa catena del cervello: il "migliore" ci passa (rotta motore-mappato)
  Appello / sentinella delle chiavi  WSL        *roster*                                       ATTIVO
      via        : vault · esclusivita: CONDIVISA
      note       : non consuma provider ma brucia quota: è un lettore (una chiamata a provider per giro)
  OpenCode (ponte + postino)         WSL        -                                              ATTIVO
      via        : cervello · esclusivita: ESCLUSIVA
      note       : config ~/.config/opencode/opencode.json: provider "cervello", base http://127.0.0.1:20129/v1, chiave finta sk-cervello
  OpenClaw (agente main)             WIN        -                                              ATTIVO
      via        : cervello · esclusivita: ESCLUSIVA
      note       : config C:\Users\giopi\.openclaw\openclaw.json: provider "cervello", modello cervello/migliore
  Goose (ponte)                      WSL        -                                              ATTIVO
      via        : cervello · esclusivita: ESCLUSIVA
      note       : wrapper lavori/ponte/goose_run.sh: dal 4/11 parla col cervello locale (20129, chiave finta sk-cervello) — test reale OK. Prima usava OpenRouter (accavallamento col roster): sistemato
  Secondhand / Open Interpreter      WIN        NVIDIA                                         ATTIVO
      via        : diretto · esclusivita: DA-SISTEMARE
      note       : config C:\Users\giopi\.openinterpreter\config.toml: model_provider nvidia, base integrate.api.nvidia.com/v1, env NVIDIA_API_KEY
  Hermes                             WIN        Google AI Studio;Groq;OpenCode Zen;OmniRoute ( ATTIVO
      via        : ? · esclusivita: DA-SISTEMARE
      note       : le config di Hermes non sono state trovate: i nomi delle chiavi vengono da ~/posta/chiavi_env.sh (OC/GQ/GM/OM/AR) — da verificare quale usa davvero
  Antigravity                        WIN        -                                              ATTIVO
      via        : oauth · esclusivita: ESCLUSIVA
      note       : login OAuth Google: nessuna nostra chiave (quota Google personale)
  Freebuff                           WIN        -                                              ATTIVO
      via        : freebuff.com · esclusivita: ESCLUSIVA
      note       : solo TUI: il ponte non lo usa
  Postino / squadra                  WSL        -                                              ATTIVO
      via        : cervello · esclusivita: ESCLUSIVA
      note       : ogni turno del postino passa da OpenCode → cervello
  Orchestratore (Arena, sandbox)     SANDBOX    Sail;OpenRouter                                ATTIVO
      via        : vault · esclusivita: CONDIVISA
      note       : le misure dichiarate (più anche il PAT GitHub, che è una chiave di strumento): non usare la chiave "di un altro" per le prove
  Tavily (ricerca, Reddit, browser)  WIN+SANDBO Tavily;Linkup;Firecrawl;Exa                    ATTIVO
      via        : diretto · esclusivita: CONDIVISA
      note       : strumenti di ricerca, non provider di chat: usati da ricerca_canale.py, ricerca_strategica.py, cerca.sh
  GitHub PAT (postino, poller, scrip WIN+SANDBO GitHub (bomberr91)                             ATTIVO
      via        : diretto · esclusivita: CONDIVISA
      note       : utilità, non chat: condiviso per natura (il PAT «GitHub Models» è un altro, lo usa il roster su ghmodels)
  OCCHI-FB                           WIN        Gemini Studio (solo per OCCHI-FB)              ATTIVO
      via        : diretto · esclusivita: CONDIVISA
      note       : lavori/reel Facebook: chiave Gemini dedicata (è già staccata da "Google AI Studio")
  FUSION / AgentRouter               WIN        AgentRouter                                    SOSPESO
      via        : diretto · esclusivita: DA-SISTEMARE
      note       : non avviare senza via del capo
  Bot Telegram                       WIN        -                                              SOSPESO
      via        : - · esclusivita: -
      note       : non riproporlo
  Deep Dog                           -          OpenRouter;Tavily;Exa;DeepSeek                 SOSPESO
      via        : diretto · esclusivita: -
      note       : mai usato
  LongCat                            WIN        LongCat                                        MISURATO
      via        : diretto · esclusivita: ESCLUSIVA
      note       : nel roster: la quota non rinnova (402 continuo)
  NaraRouter                         -          NaraRouter                                     MISURATO
      via        : - · esclusivita: ESCLUSIVA
      note       : fuori dal roster (403 telegram_required): la chiave è libera ma il provider non serve

----------------------------------------------------------------------------------------------------
 CHIAVI PROVIDER: chi le usa
----------------------------------------------------------------------------------------------------
  AgentRouter                        Hermes   ⚠ anche nel roster del cervello (l'appello la prova ogni giorno)
  Exa                                Tavily (ricerca, Reddit, browser)
  Firecrawl                          Tavily (ricerca, Reddit, browser)
  Gemini Studio (solo per OCCHI-FB)  OCCHI-FB
  GitHub (bomberr91)                 GitHub PAT (postino, poller, script, sandbox)
  Google AI Studio                   Hermes   ⚠ anche nel roster del cervello (l'appello la prova ogni giorno)
  Groq                               Hermes   ⚠ anche nel roster del cervello (l'appello la prova ogni giorno)
  Linkup                             Tavily (ricerca, Reddit, browser)
  LongCat                            LongCat   ⚠ anche nel roster del cervello (l'appello la prova ogni giorno)
  NVIDIA                             Secondhand / Open Interpreter   ⚠ anche nel roster del cervello (l'appello la prova ogni giorno)
  NaraRouter                         NaraRouter
  OmniRoute (gateway locale)         Hermes
  OpenCode Zen                       Hermes   ⚠ anche nel roster del cervello (l'appello la prova ogni giorno)
  OpenRouter                         Orchestratore (Arena, sandbox)   ⚠ anche nel roster del cervello (l'appello la prova ogni giorno)
  Sail                               Orchestratore (Arena, sandbox)   ⚠ anche nel roster del cervello (l'appello la prova ogni giorno)
  Tavily                             Tavily (ricerca, Reddit, browser)

----------------------------------------------------------------------------------------------------
 CHIAVI LIBERE (nel portachiavi, non nel roster del cervello, non assegnate a nessuno)
----------------------------------------------------------------------------------------------------
  nessuna: TUTTE le chiavi provider del portachiavi sono gia' in uso
  (per un nuovo strumento: passare dal cervello locale, non prendere una chiave)
  chiavi strumento (non provider, condivise): 11

----------------------------------------------------------------------------------------------------
 CONFLITTI DA SISTEMARE: 3
----------------------------------------------------------------------------------------------------
  NVIDIA                                   <- Secondhand / Open Interpreter   (accavalla con il roster del cervello)
  Google AI Studio;Groq;OpenCode Zen;OmniR <- Hermes   (accavalla con il roster del cervello)
  AgentRouter                              <- FUSION / AgentRouter   (accavalla con il roster del cervello)

(il verificatore esce con 1: 1 = ci sono conflitti da sistemare, 0 = tutto pulito)

<!-- fine assegnazioni_verifica_pc -->
