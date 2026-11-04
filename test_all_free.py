import urllib.request, urllib.error, json, subprocess, sys, time
key = subprocess.check_output([sys.executable, '/home/agenti/posta/chiave_di.py', 'Gizmo']).decode().strip()
base = 'https://api.gizmoplatforms.com/api/v1'
free_models = ['nvidia/nemotron-3.5-lightning:free', 'nvidia/nemotron-3-ultra-550b-a55b:free', 'xingchen-agi/xing4.0-29b-a4b:free']
for mid in free_models:
    body = json.dumps({'model': mid, 'messages': [{'role':'user','content':'Say OK'}]}).encode()
    req = urllib.request.Request(base+'/chat/completions', data=body, headers={
        'Authorization': f'Bearer {key}',
        'Content-Type': 'application/json',
        'User-Agent': 'curl/7.88'
    }, method='POST')
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            resp = json.load(r)
            txt = resp.get('choices',[{}])[0].get('message',{}).get('content','')
            print(mid, '200', txt[:60])
    except urllib.error.HTTPError as e:
        print(mid, e.code, e.read().decode(errors='ignore')[:150])
    except Exception as e:
        print(mid, 'ERR', e)
    time.sleep(1)