✅ COMPLETATO — issue #28 — 382s — exit 0
Agente: `opencode`

### Output (coda)
```
Verifica completata e referto salvato in `/home/agenti/posta/fatti/verifica_poller.md`.
```
### Errori (coda)
```
Please rewrite the input so it satisfies the expected schema.
[0m
[0m$ [0mpgrep -af poller.py
(no output)
[0m
[0m$ [0mtail -40 /home/agenti/posta/lavori/ponte/poller.log
(no output)
[0m
[0m$ [0mls -la /home/agenti/posta/lavori/ponte/_stato/
(no output)
[0m
[0m$ [0m[ -f /home/agenti/posta/lavori/ponte/_stato/poller.lock ] && cat /home/agenti/posta/lavori/ponte/_stato/poller.lock || echo 'Lock file does not exist'
(no output)
[0m
[0m$ [0mgrep -n 'TIMEOUT dopo 180s' 'GIT_TERMINAL_PROMPT' 'il campo e' /home/agenti/posta/lavori/ponte/poller.py
/home/agenti/posta/lavori/ponte/poller.py:192:        raise RuntimeError(f"git {' '.join(args)} → TIMEOUT dopo 180s")
grep: GIT_TERMINAL_PROMPT: No such file or directory
grep: il campo e: No such file or directory
[0m
[0m$ [0mpython3 -c "import urllib.request,time; t=time.time(); urllib.request.urlopen('https://api.github.com/rate_limit', timeout=20); print(round(time.time()-t,2))"
0.25
[0m
[0m$ [0mgrep -n 'GIT_TERMINAL_PROMPT' /home/agenti/posta/lavori/ponte/poller.py || echo 'GIT_TERMINAL_PROMPT NOT FOUND'
(no output)
[0m
[0m$ [0mgrep -n 'il campo e' /home/agenti/posta/lavori/ponte/poller.py || echo 'il campo e NOT FOUND'
199:    """(fix 4/11) il campo e' TUTTO il testo fino al campo successivo.
[0m
[0m$ [0mgrep -n 'GIT_TERMINAL_PROMPT' /home/agenti/posta/lavori/ponte/poller.py; echo "exit=$?"
(no output)
[0m
[0m$ [0mpython3 -c "import urllib.request,time; t=time.time(); urllib.request.urlopen('https://api.github.com/rate_limit', timeout=20); print(round(time.time()-t,2))"
0.19
[0m
[0m$ [0mpython3 -c "import urllib.request,time; t=time.time(); urllib.request.urlopen('https://api.github.com/rate_limit', timeout=20); print(round(time.time()-t,2))"
0.2
[0m
[0m← [0mWrite posta/fatti/verifica_poller.md
Wrote file successfully.
[0m
```

Consegna: `/consegne/28-verifica-dello-stato-del-poller-e-dei-su`