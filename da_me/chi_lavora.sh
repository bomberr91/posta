#!/bin/bash
echo "## CHI STA ANCORA LAVORANDO? — $(date '+%H:%M')"
echo "### Operai (processi di lavoro veri)"
ps aux | grep -E "deepopen_ven[v]|setaccio_ven[a]|controprova|round[0-9]|snapshot_downloa[d]|opencode ru[n]" | grep -v grep || echo "  NESSUNO: tutti gli operai hanno finito e sono andati a casa ✓"
echo
echo "### Servizi fissi (i guardiani: questi NON sono lavoro, ripartono da soli al boot)"
ps aux | grep -E "postino\.sh --loo[p]|^.*python3 cervello\.p[y]|omnirout[e] " | grep -v grep | awk '{print "  vivo:", substr($0, index($0,$11), 60)}' | head -6
