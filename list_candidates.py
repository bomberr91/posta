import urllib.request, json, subprocess, sys
key = subprocess.check_output([sys.executable, '/home/agenti/posta/chiave_di.py', 'Gizmo']).decode().strip()
base = 'https://api.gizmoplatforms.com/api/v1'
req = urllib.request.Request(base+'/models', headers={'Authorization': f'Bearer {key}', 'User-Agent': 'Mozilla/5.0'})
with urllib.request.urlopen(req, timeout=20) as r:
    data = json.load(r)
models = data.get('data', [])
ids = [m.get('id') for m in models]
# filter for some prefixes
candidates = [i for i in ids if any(p in i for p in ['groq/','openrouter/','mistral/','qwen/','z-ai/'])]
print('CANDIDATES', len(candidates))
for i in candidates[:80]:
    print(i)
