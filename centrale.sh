#!/usr/bin/env bash
# centrale.sh — UNICA CENTRALE DI COMANDO SU FILIPPOPC (raggruppa tutte le funzioni presenti e future)
set -u
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
NODE22_BIN="$HOME/.nvm/versions/node/v22.22.2/bin"
# Auto-rileva il Node giusto se la versione inchiodata non esiste (preferisci v22: su WSL1 Node 24 non parte)
if [ ! -x "$NODE22_BIN/node" ]; then
  CAND=$(ls -d "$HOME/.nvm/versions/node/v22"*/bin 2>/dev/null | sort -V | tail -1)
  [ -z "$CAND" ] && CAND=$(ls -d "$HOME/.nvm/versions/node/"*/bin 2>/dev/null | sort -V | tail -1)
  [ -n "$CAND" ] && NODE22_BIN="$CAND"
fi
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" >/dev/null 2>&1 || true
export PATH="$NODE22_BIN:$HOME/.opencode/bin:$HOME/.local/bin:$HOME/.hermes/hermes-agent/bin:$PATH"

if [ -f "$HOME/CHIAVI_LOCALI.md" ]; then
  OC_KEY=$(grep -oE 'oc_sk_[A-Za-z0-9_-]+' "$HOME/CHIAVI_LOCALI.md" 2>/dev/null | head -1)
  [ -n "$OC_KEY" ] && export OPENCODE_API_KEY="$OC_KEY"
  GQ_KEY=$(grep -i "Groq" "$HOME/CHIAVI_LOCALI.md" | grep -oE 'gsk_[A-Za-z0-9_-]+' 2>/dev/null | head -1)
  [ -n "$GQ_KEY" ] && export GROQ_API_KEY="$GQ_KEY"
fi

# 0. Se il potenziamento non è ancora stato eseguito, fallo subito!
if [ ! -f "$HOME/.skills_v2_installed" ] && [ -f "$HOME/posta/aggiorna_tutto.sh" ]; then
  bash "$HOME/posta/aggiorna_tutto.sh"
fi

# 1. Avvia in silenzio Magpie e il Postino (ponte GitHub) se non stanno già girando
pgrep -f 'magpie serve' >/dev/null 2>&1 || (nohup magpie serve >/dev/null 2>&1 &)
pgrep -f 'postino.sh --loop' >/dev/null 2>&1 || (nohup "$HOME/posta/postino.sh" --loop >/dev/null 2>&1 &)

# 2. Pulisce il Desktop dalle vecchie icone sparse e lascia SOLO "CENTRALE_AGENTI.bat"
pulisci_desktop(){
  for d in /mnt/c/Users/*/Desktop /mnt/c/Users/*/OneDrive*/Desktop; do
    if [ -d "$d" ] && [ -f "$d/RAPPORTO_AGENTI.txt" -o -f "$d/COMPITI.lnk" -o -f "$d/BROWSER_AGENTI.bat" -o -f "$d/CENTRALE_AGENTI.bat" ]; then
      cp -f "$HOME/posta/CENTRALE_AGENTI.bat" "$d/CENTRALE_AGENTI.bat" 2>/dev/null || true
      rm -f "$d/BROWSER_AGENTI.bat" "$d/SQUADRA_FUSION.bat" "$d/APRI_AGENTE.lnk" "$d/AVVIA_POSTINO.lnk" "$d/COMPITI.lnk" "$d/AGGIORNA_TUTTO_PC.bat" 2>/dev/null || true
      [ -f "$d/RAPPORTO_AGENTI.txt" ] && mv -f "$d/RAPPORTO_AGENTI.txt" "$HOME/posta/RAPPORTO_AGENTI.txt" 2>/dev/null || true
    fi
  done
}
pulisci_desktop

while :; do
  clear 2>/dev/null || true
  POSTINO_ST=$(pgrep -f 'postino.sh' >/dev/null 2>&1 && echo "🟢 ATTIVO" || echo "🔴 SPENTO")
  MAGPIE_ST=$(pgrep -f 'magpie serve' >/dev/null 2>&1 && echo "🟢 ATTIVO" || echo "🔴 SPENTO")
  SKILLS_N=$(ls -1 "$HOME/.agents/skills" 2>/dev/null | wc -l)
  # Verdetto di salute: 1 decimo di secondo, così una rottura si vede subito (senza rifare [8])
  SALUTE=""
  if [ -x "$HOME/posta/verifica.sh" ]; then
    SALUTE=$(bash "$HOME/posta/verifica.sh" 2>/dev/null | grep -oE '🟢 TUTTO A POSTO|🟡 [0-9]+ cose da guardare|🔴 [0-9]+ PROBLEMI' | head -1)
    [ -z "$SALUTE" ] && SALUTE="🩺 verifica non disponibile"
  fi
  echo "======================================================================"
  echo "   ⚡ CENTRALE AGENTI H24 — FILIPPOPC (Pre-Hub v2)"
  echo "   Ponte GitHub: $POSTINO_ST  ·  Magpie: $MAGPIE_ST  ·  Skill attive: $SKILLS_N"
  [ -n "$SALUTE" ] && echo "   Salute del PC: $SALUTE   ([v] per il dettaglio)"
  echo "======================================================================"
  echo ""
  echo "  [1] 💬 Chatta con un Agente singolo (OpenCode / Goose / Secondhand / Hermes / OpenClaw / Gemini)"
  echo "  [2] 🔥 SQUADRA FUSION 2.1 (Il Regista sceglie gli Agenti + Barra 0%->100% + Qualità>Tempo)"
  echo "  [3] 🎬 TRASCRIVI & CATALOGA VIDEO/REEL (incolla link FB, YouTube, IG, TikTok)"
  echo "  [4] 📌 LEGGI POST/COMMENTI FB O DISCORD col Browser Agenti (Sola Lettura)"
  echo "  [5] 🌐 APRI IL BROWSER DEGLI AGENTI (Chrome/Edge profilo isolato porta 9222)"
  echo "  [6] 📁 APRI CARTELLA COMPITI E RISPOSTE (in Esplora Risorse di Windows)"
  echo "  [7] 📊 STATO AGENTI, INNESTI (Headroom/XERJ/Beads) E QUOTE MAGPIE"
  echo "  [8] 🔄 AGGIORNA CENTRALE E NUOVE FUNZIONI DA GITHUB (1 secondo)"
  echo "  [9] 🧠 MOTORE OMNIROUTE — HUB V2 (359 provider, 90+ GRATIS, dashboard web)"
  echo "  [v] 🩺 CONTROLLO SALUTE (2 secondi: dice subito se qualcosa è rotto, non installa niente)"
  echo "  [g] 🖥️ GUI CENTRALE POSTA (Router Hub e dashboard storica)"
  echo ""
  echo "  [0] Esci"
  echo "======================================================================"
  read -r -p "Scegli un numero [0-9] e premi INVIO: " SCELTA
  echo ""
  case "$SCELTA" in
    1)
      echo "Quale agente vuoi aprire?"
      echo "  [a] OpenCode (Architetto & Codice)"
      echo "  [b] Goose (Automazione & Sub-Agenti)"
      echo "  [c] Secondhand / OpenInterpreter (Revisore Rust)"
      echo "  [d] Hermes Agent (Strategia & Ricerca NousResearch)"
      echo "  [e] OpenClaw (Operatore Autonomo PC & Browser H24)"
      echo "  [f] Gemini CLI (Agente da terminale Google)"
      read -r -p "Scelta [a/b/c/d/e/f, INVIO=a]: " AG
      case "${AG:-a}" in
        b|B) cd "$HOME/posta" && goose session ;;
        c|C) cd "$HOME/posta" && interpreter ;;
        d|D) cd "$HOME/posta" && (hermes || "$HOME/.hermes/hermes-agent/venv/bin/hermes") ;;
        e|E) bash "$HOME/posta/apri_openclaw.sh" ;;
        f|F) cd "$HOME/posta" && (gemini || "$NODE22_BIN/gemini") ;;
        *)   cd "$HOME/posta" && opencode ;;
      esac
      ;;
    2)
      bash "$HOME/posta/squadra.sh"
      read -r -p "Premi INVIO per tornare al menu..." _
      ;;
    3)
      python3 "$HOME/posta/leggi_video.py"
      read -r -p "Premi INVIO per tornare al menu..." _
      ;;
    4)
      echo "Cosa vuoi far leggere in SOLA LETTURA dal Browser degli Agenti?"
      echo "  [INVIO vuoto] -> Leggi subito il Server Discord Ecom Elite"
      echo "  [oppure incolla un link Facebook / Discord]"
      read -r -p "Scelta: " TARGET_U
      if [ -z "$TARGET_U" ] || [[ "$TARGET_U" == *"discord.com"* ]]; then
        python3 "$HOME/posta/leggi_discord.py"
      else
        python3 "$HOME/posta/leggi_fb_cdp.py" "$TARGET_U"
      fi
      read -r -p "Fatto! Premi INVIO per tornare al menu..." _
      ;;
    5)
      cmd.exe /c start "" "$(wslpath -w "$HOME/posta/6_BROWSER_AGENTI.bat")" 2>/dev/null \
        || echo "Apri 6_BROWSER_AGENTI.bat dalla cartella posta"
      sleep 2
      ;;
    6)
      explorer.exe "$(wslpath -w "$HOME/posta")" 2>/dev/null || true
      ;;
    7)
      bash "$HOME/posta/agenti_stato.sh" 2>/dev/null || echo "  (agenti_stato.sh non trovato: rifai [8])"
      echo ""
      echo "── Super-Poteri & Innesti Attivi ──"
      echo "  • Headroom   : $(headroom --version 2>&1 | head -1 || echo non presente)"
      echo "  • XERJ (Rust): $(xerj --version 2>&1 | head -1 || echo non presente)"
      echo "  • Beads (Mem): $(bd version 2>&1 | head -1 || echo non presente)"
      echo "  • OmniRoute  : $( (exec 3<>/dev/tcp/127.0.0.1/20128) 2>/dev/null && echo "🟢 acceso" || echo "🔴 spento — menu [9]")"
      echo "  • Skill ($SKILLS_N) : $(ls "$HOME/.agents/skills" 2>/dev/null | tr '\n' ' ' | cut -c1-160)"
      echo ""
      echo "  [a] installa/sistema gli agenti mancanti"
      read -r -p "Invio per tornare al menu (oppure 'a'): " AZ7
      if [ "${AZ7:-}" = "a" ] || [ "${AZ7:-}" = "A" ]; then
        bash "$HOME/posta/installa_agenti.sh"
        read -r -p "Premi INVIO per tornare al menu..." _
      fi
      ;;
    8)
      if cd "$HOME/posta" && git fetch origin main && git reset --hard origin/main && bash "$HOME/posta/aggiorna_tutto.sh"; then
        echo "✅ Centrale aggiornata da posta/main."
      else
        echo "❌ Aggiornamento di posta non riuscito: controlla il messaggio Git sopra; non considero l'update completato."
      fi
      # La UI standalone è incorporata in posta/free-llm-hub e viene aggiornata insieme al repo.
      if [ -f "$HOME/posta/free-llm-hub/SOURCE_COMMIT" ] && \
         [ "$(tr -d '\r\n' < "$HOME/posta/free-llm-hub/SOURCE_COMMIT")" = "bbc524fb0d67b563d0fd1f9d2b52445b4d84523e" ]; then
        echo "✅ UI standalone incorporata aggiornata (Free LLM Hub bbc524f)."
      else
        echo "⚠️ Bundle UI standalone mancante o non allineato: controlla free-llm-hub/SOURCE_COMMIT."
      fi
      pulisci_desktop
      read -r -p "Aggiornamento completato (o avvisi sopra). Premi INVIO per ricaricare la Centrale..." _
      exec bash "$HOME/posta/centrale.sh"
      ;;
    9)
      echo "── 🧠 MOTORE OMNIROUTE (Scaglione 2 — Hub v2) ──"
      OMNI_BIN=$(command -v omniroute || echo "$NODE22_BIN/omniroute")
      if [ ! -x "$OMNI_BIN" ] && ! command -v omniroute >/dev/null 2>&1; then
        echo "OmniRoute NON è ancora installato (78k+ stelle, MIT, 359 provider di cui 90+ gratis)."
        echo "Installazione: ~2-5 minuti via npm (Node 22 già presente). Nessun costo."
        read -r -p "Vuoi installarlo ADESSO? [s/N]: " OK9
        if [[ "$OK9" == "s" || "$OK9" == "S" ]]; then
          NPM_BIN=$(command -v npm || true)
          [ -z "$NPM_BIN" ] && [ -x "$NODE22_BIN/npm" ] && NPM_BIN="$NODE22_BIN/npm"
          [ -z "$NPM_BIN" ] && NPM_BIN=$(ls "$HOME/.nvm/versions/node/"*/bin/npm 2>/dev/null | sort -V | tail -1)
          if [ -z "$NPM_BIN" ]; then
            echo "❌ npm non trovato in nessun Node di nvm: dimmelo in chat e sistemiamo."
          else
            echo "Uso npm: $NPM_BIN"
            "$NPM_BIN" config set allow-scripts=omniroute,keytar,onnxruntime-node,@parcel/watcher,@swc/core,protobufjs,esbuild --location=user 2>/dev/null || true
            "$NPM_BIN" install -g omniroute && echo "✅ Installato! Rientra nel menu [9] per avviarlo." || echo "❌ Errore installazione: rilancia o controlla la connessione."
          fi
        else
          echo "Ok, nessuna installazione. (Regola: niente auto-avvio installer!)"
        fi
      else
        if pgrep -f "omniroute" >/dev/null 2>&1; then OMNI_ST="🟢 ATTIVO"; else OMNI_ST="🔴 SPENTO"; fi
        echo "Stato motore: $OMNI_ST  ·  Dashboard: http://localhost:20128  ·  API: http://localhost:20128/v1 (model: auto)"
        echo "  [a] Avvia il motore in background"
        echo "  [d] Apri la Dashboard nel browser Windows"
        echo "  [f] Attiva i provider GRATIS (automatico, ~2-5 min)"
        echo "  [k] Innesta le chiavi API del portachiavi nei provider free (~2-3 min)"
        echo "  [x] Spegni il motore"
        echo "  [INVIO] Torna al menu"
        read -r -p "Scelta: " OM
        case "$OM" in
          a|A) nohup "$OMNI_BIN" >/tmp/omniroute.log 2>&1 & sleep 3
               pgrep -f omniroute >/dev/null && echo "🟢 Motore avviato! Dashboard: http://localhost:20128" || echo "❌ Problema all'avvio: guarda /tmp/omniroute.log" ;;
          d|D) cmd.exe /c start "" "http://localhost:20128" 2>/dev/null || echo "Apri a mano: http://localhost:20128" ;;
          f|F) bash "$HOME/posta/omni_free.sh" ;;
          k|K) bash "$HOME/posta/omni_chiavi.sh" ;;
          x|X) pkill -x omniroute 2>/dev/null; pkill -f "bin/omniroute" 2>/dev/null && echo "🔴 Motore spento." || echo "Era già spento." ;;
        esac
      fi
      read -r -p "Premi INVIO per tornare al menu..." _
      ;;
    g|G)
      # Avvia la dashboard storica integrata; non usare il prototipo standalone sulla porta 3000.
      pkill -f '[g]ui/server.py' 2>/dev/null || true
      nohup python3 "$HOME/posta/gui/server.py" >/tmp/gui.log 2>&1 </dev/null &
      sleep 2
      cmd.exe /c start "" "http://localhost:20200" 2>/dev/null || echo "Apri nel browser: http://localhost:20200"
      echo "🖥️ Router Hub locale avviato su http://localhost:20200"
      read -r -p "Premi INVIO per tornare al menu..." _
      ;;
    v|V)
      bash "$HOME/posta/verifica.sh"
      echo ""
      echo "  (se è giallo/rosso: [8] aggiorna, ./openclaw_fix.sh mette a posto OpenClaw)"
      read -r -p "Premi INVIO per tornare al menu..." _
      ;;
    0|q|Q)
      exit 0
      ;;
  esac
done
