#!/bin/bash
D="[CHIAVE-RIMOSSA]"
echo "## 🐕 EMAIL DI SERVIZIO NEL .env — $(date '+%H:%M')"
python3 - "$D/.env" << 'PYEOF'
import sys, re
p = sys.argv[1]
s = open(p, encoding="utf-8", errors="replace").read()
MAIL = "strategiadisuccesso@gmail.com"
for var in ("PUBMED_EMAIL", "SEC_EDGAR_CONTACT_EMAIL"):
    if re.search(r"^%s=.+$" % var, s, re.M):
        print(var, "già settata")
    elif re.search(r"^#\s*%s=" % var, s, re.M):
        s = re.sub(r"^#\s*%s=.*$" % var, "%s=%s" % (var, MAIL), s, flags=re.M)
        print(var, "scommentata e riempita")
    else:
        s += "\n%s=%s" % (var, MAIL)
        print(var, "aggiunta")
open(p, "w", encoding="utf-8").write(s)
print("--- attive ora:")
print("\n".join(r.split("=")[0] for r in s.splitlines() if re.match(r"^[A-Z_]+=.+", r)))
PYEOF
