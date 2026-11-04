import urllib.request, time, json, subprocess, sys
key = subprocess.check_output([sys.executable, '/home/agenti/posta/chiave_di.py', 'Gizmo']).decode().strip()
base = 'https://api.gizmoplatforms.com/api/v1'
mid = 'xingchen-agi/xing4.0-29b-a4b:free'
for i in range(5):
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
            print('OK', txt[:60])
            break
    except urllib.error.HTTPError as e:
        print('attempt', i+1, e.code)
        time.sleep(5)
else:
    print('failed')
