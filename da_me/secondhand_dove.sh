#!/usr/bin/env bash
# secondhand_dove.sh — 4/11: DOVE 0.4.3 prende modello e base url (una domanda sola).
#
# Il.config e' gia' scritto bene ovunque (base_url del cervello, env_key, model=auto),
# ma la richiesta esce ancora con "gpt-4o": il pacchetto installato non sembra
# leggere nessun config.toml. Qui si cerca, nel codice, la riga che decide il
# modello di default e il nome del file di configurazione: poi la correzione
# e' UNA riga.
#
# Niente pipe verso tail.
set -uo pipefail

PKG="$HOME/.local/lib/python3.12/site-packages/interpreter"
echo "### 1. DOVE NASCE IL MODELO DI DEFAULT"
grep -rn --include=*.py -E "gpt-4o" "$PKG" 2>/dev/null | head -12
echo
echo "### 2. QUALI FILE TOML / CONFIG IL PACCHETTO LEGGE"
grep -rn --include=*.py -E "\.toml|toml\.load|toml\.loads" "$PKG" 2>/dev/null | grep -v "pyproject" | head -15
echo
echo "### 3. COME COSTRUISCE IL PERCORSO DELLA CONFIG"
grep -rn --include=*.py -E "expanduser|user_config_dir|user_data_dir|config_path|settings_path" "$PKG" 2>/dev/null | head -15
echo
echo "### 4. DOVE SETTA IL MODELO (core)"
grep -rn --include=*.py -E "model\s*=\s*[\"']|llm\.model|\.model\s*=" "$PKG/core/core.py" 2>/dev/null | head -15
echo
echo "### 5. IL MODELLO CHE ARRIVA AL CERVELLO (ultimo tentativo con -c e con --model PRIMA di exec)"
export OPENAI_API_KEY=sk-cervello
export OPENAI_BASE_URL=http://127.0.0.1:20129/v1
for modo in "interpreter exec -c model=\"auto\" --skip-git-repo-check" ; do
  echo "--- $modo"
  timeout 120 bash -c "$modo 'Rispondi solo OK'" 2>&1 | tail -3
done
echo "--- senza 'exec': (la CLI e' solo TUI ora)"
timeout 60 bash -c "interpreter --help" 2>&1 | grep -iE "exec|prompt|auto_run|--model" | head -8
echo "FINE"
exit 0
