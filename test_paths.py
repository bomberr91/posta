import urllib.request, urllib.error, json, subprocess, sys
key = subprocess.check_output([sys.executable, '/home/agenti/posta/chiave_di.py', 'Gizmo']).decode().strip()
base = 'https://api.gizmoplatforms.com/api/v1'
mid = 'xingchen-agi/xing4.0-29b-a4b:free'
body = json.dumps({'model': mid, 'messages': [{'role':'user','content':'Say OK'}]}).encode()
for path in ['/chat/completions','/completions']:
    req = urllib.request.Request(base+path, data=body, headers={
        'Authorization': f'Bearer {key}',
        'Content-Type': 'application/json',
        'User-Agent': 'Mozilla/5.0'
    }, method='POST')
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            print(path, r.status)
    except urllib.error.HTTPError as e:
        print(path, e.code)
    except Exception as e:
        print(path, e)
