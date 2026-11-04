import urllib.request, json, subprocess, sys
key = subprocess.check_output([sys.executable, '/home/agenti/posta/chiave_di.py', 'Gizmo']).decode().strip()
base = 'https://api.gizmoplatforms.com/api/v1'
for ua in ['Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36', 'curl/7.88.1', 'python-urllib/3.10']:
    body = json.dumps({'model': 'xingchen-agi/xing4.0-29b-a4b:free', 'messages': [{'role':'user','content':'Say OK'}]}).encode()
    req = urllib.request.Request(base+'/chat/completions', data=body, headers={
        'Authorization': f'Bearer {key}',
        'Content-Type': 'application/json',
        'User-Agent': ua
    }, method='POST')
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            resp = json.load(r)
            txt = resp.get('choices',[{}])[0].get('message',{}).get('content','')[:40]
            print(ua, '200', txt)
    except urllib.error.HTTPError as e:
        print(ua, e.code)
    except Exception as e:
        print(ua, 'ERR', e)
