import urllib.request, urllib.error, json, subprocess, sys
key = subprocess.check_output([sys.executable, '/home/agenti/posta/chiave_di.py', 'Gizmo']).decode().strip()
base = 'https://api.gizmoplatforms.com/api/v1'
req = urllib.request.Request(base+'/models', headers={'Authorization': f'Bearer {key}', 'User-Agent': 'Mozilla/5.0'})
try:
    with urllib.request.urlopen(req, timeout=20) as r:
        data = json.load(r)
    models = data.get('data', [])
    free = [m.get('id') for m in models if m.get('id','').endswith(':free')]
    print('TOTAL', len(models))
    print('FREE', len(free))
    for m in free:
        print(m)
except Exception as e:
    print('ERROR', e)
