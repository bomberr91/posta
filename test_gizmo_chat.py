import urllib.request, urllib.error, json, subprocess, sys
key = subprocess.check_output([sys.executable, '/home/agenti/posta/chiave_di.py', 'Gizmo']).decode().strip()
base = 'https://api.gizmoplatforms.com/api/v1'
models_to_test = [
    'nvidia/nemotron-3.5-lightning:free',
    'nvidia/nemotron-3-ultra-550b-a55b:free',
    'xingchen-agi/xing4.0-29b-a4b:free'
]
results = {}
for mid in models_to_test:
    body = json.dumps({'model': mid, 'messages': [{'role':'user','content':'Say OK'}]}).encode()
    req = urllib.request.Request(base+'/chat/completions', data=body, headers={
        'Authorization': f'Bearer {key}',
        'Content-Type': 'application/json',
        'User-Agent': 'Mozilla/5.0'
    }, method='POST')
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            resp = json.load(r)
            txt = resp.get('choices',[{}])[0].get('message',{}).get('content','')
            results[mid] = ('200', txt[:120])
    except urllib.error.HTTPError as e:
        err_body = e.read().decode(errors='ignore')
        results[mid] = (str(e.code), err_body[:200])
    except Exception as e:
        results[mid] = ('ERR', str(e))
    print(mid, results[mid][0])
    print(results[mid][1][:200])
    print('---')
