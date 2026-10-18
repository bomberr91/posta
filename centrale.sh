#!/usr/bin/env bash
# centrale.sh — UNICA CENTRALE DI COMANDO SU FILIPPOPC (raggruppa tutte le funzioni presenti e future)
set -u
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
export PATH="$HOME/.opencode/bin:$HOME/.local/bin:$HOME/.hermes/hermes-agent/bin:$PATH"
if [ -f "$HOME/CHIAVI_LOCALI.md" ]; then
  OC_KEY=$(grep -oE 'oc_sk_[A-Za-z0-9_-]+' "$HOME/CHIAVI_LOCALI.md" 2>/dev/null | head -1)
  [ -n "$OC_KEY" ] && export OPENCODE_API_KEY="$OC_KEY"
  GQ_KEY=$(grep -i "Groq" "$HOME/CHIAVI_LOCALI.md" | grep -oE 'gsk_[A-Za-z0-9_-]+' 2>/dev/null | head -1)
  [ -n "$GQ_KEY" ] && export GROQ_API_KEY="$GQ_KEY"
fi

# 0. Se il potenziamento del 18/10 (26 skill + nuovi agenti) non è ancora stato eseguito, fallo subito!
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

# Assicura che yt-dlp sia presente per i video
if ! command -v yt-dlp >/dev/null 2>&1; then
  curl -fsSL https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o "$HOME/.local/bin/yt-dlp" 2>/dev/null && chmod +x "$HOME/.local/bin/yt-dlp" || true
fi

while :; do
  clear 2>/dev/null || true
  POSTINO_ST=$(pgrep -f 'postino.sh' >/dev/null 2>&1 && echo "🟢 ATTIVO" || echo "🔴 SPENTO")
  MAGPIE_ST=$(pgrep -f 'magpie serve' >/dev/null 2>&1 && echo "🟢 ATTIVO" || echo "🔴 SPENTO")
  SKILLS_N=$(ls -1 "$HOME/.agents/skills" 2>/dev/null | wc -l)
  echo "======================================================================"
  echo "   ⚡ CENTRALE AGENTI H24 — FILIPPOPC"
  echo "   Ponte GitHub: $POSTINO_ST  ·  Magpie: $MAGPIE_ST  ·  Skill attive: $SKILLS_N"
  echo "======================================================================"
  echo ""
  echo "  [1] 💬 Chatta con un Agente singolo (OpenCode / Goose / Hermes / Secondhand)"
  echo "  [2] 🔥 SQUADRA FUSION (lancia 3 Agenti in sincronia su un compito)"
  echo "  [3] 🎬 TRASCRIVI & CATALOGA VIDEO/REEL (incolla link FB, YouTube, IG, TikTok)"
  echo "  [4] 📌 LEGGI I TUOI 'SALVATI' DI FACEBOOK (via Browser degli Agenti)"
  echo "  [5] 🌐 APRI IL BROWSER DEGLI AGENTI (Chrome/Edge profilo isolato porta 9222)"
  echo "  [6] 📁 APRI CARTELLA COMPITI E RISPOSTE (in Esplora Risorse di Windows)"
  echo "  [7] 📊 STATO AGENTI, SKILL E CREDITI (Magpie Quota)"
  echo "  [8] 🔄 AGGIORNA CENTRALE E NUOVE FUNZIONI DA GITHUB (1 secondo)"
  echo ""
  echo "  [0] Esci"
  echo "======================================================================"
  read -r -p "Scegli un numero [0-8] e premi INVIO: " SCELTA
  echo ""
  case "$SCELTA" in
    1)
      echo "Quale agente vuoi aprire?"
      echo "  [a] OpenCode (consigliato per codice e tuttofare)"
      echo "  [b] Goose (ricette e sub-agenti)"
      echo "  [c] Secondhand / OpenInterpreter (camaleonte Rust)"
      echo "  [d] Hermes Agent (NousResearch)"
      read -r -p "Scelta [a/b/c/d, INVIO=a]: " AG
      case "${AG:-a}" in
        b|B) cd "$HOME/posta" && goose session ;;
        c|C) cd "$HOME/posta" && interpreter ;;
        d|D) cd "$HOME/posta" && (hermes || "$HOME/.hermes/hermes-agent/venv/bin/hermes") ;;
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
      python3 "$HOME/posta/leggi_video.py" --saved
      read -r -p "Premi INVIO per tornare al menu..." _
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
      echo "── Versioni Agenti installati ──"
      echo "  • OpenCode   : $(opencode --version 2>&1 | head -1)"
      echo "  • Goose      : $(goose --version 2>&1 | head -1)"
      echo "  • Secondhand : $(interpreter --version 2>&1 | head -1 || echo non presente)"
      echo "  • Hermes     : $(hermes --version 2>&1 | head -1 || ([ -d ~/.hermes/hermes-agent ] && echo installato in ~/.hermes || echo non presente))"
      echo "  • OpenClaw   : $(openclaw --version 2>&1 | head -1 || echo non presente)"
      echo "  • Skill (26) : $(ls "$HOME/.agents/skills" 2>/dev/null | tr '\n' ' ')"
      echo ""
      echo "── Stato Quote Magpie ──"
      magpie quota 2>/dev/null || true
      echo ""
      read -r -p "Premi INVIO per tornare al menu..." _
      ;;
    8)
      cd "$HOME/posta" && git fetch origin main && git reset --hard origin/main && bash "$HOME/posta/aggiorna_tutto.sh"
      pulisci_desktop
      read -r -p "Aggiornato! Premi INVIO per ricaricare la Centrale..." _
      exec bash "$HOME/posta/centrale.sh"
      ;;
    0|q|Q)
      exit 0
      ;;
  esac
done
