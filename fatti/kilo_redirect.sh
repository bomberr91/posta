#!/bin/bash
echo "## KILO: DOVE PORTA IL 308? — $(date '+%H:%M')"
U="https://kilocode.[CHIAVE-RIMOSSA]"
echo "### 1. La meta del redirect"
curl -s -o /dev/null -w "redirect → %{redirect_url}\ncodice → %{http_code}\n" -X POST -H "Content-Type: application/json" -d '{"model":"qwen/qwen3.8-omni-flash","max_tokens":20,"messages":[{"role":"user","content":"ciao"}]}' "$U"
echo
echo "### 2. Seguo il redirect (curl -L mantiene il POST sui 308)"
curl -sL -m 60 -X POST -H "Content-Type: application/json" -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) cervello/2.1" -d '{"model":"qwen/qwen3.8-omni-flash","max_tokens":20,"messages":[{"role":"user","content":"Rispondi solo: kilo funziona"}]}' "$U" | head -c 400
echo
