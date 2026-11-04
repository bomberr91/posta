import urllib.request, urllib.error, json, subprocess, sys
key = subprocess.check_output([sys.executable, '/home/agenti/posta/chiave_di.py', 'Gizmo']).decode().strip()
base = 'https://api.gizmoplatforms.com/api/v1'
# test a few non-free that may be routed via free tier? Try some common groq/openrouter models
models_to_test = [
    'z-ai/glm-5.3-flash',
    'z-ai/glm-4.7-flash',
    'qwen/qwen3.5-35b-a3b',
    'z-ai/glm-5.3',
]
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
            print(mid, '200', txt[:60])
    except urllib.error.HTTPError as e:
        err = e.read().decode(errors='ignore')
        print(mid, e.code, err[:150])
    except Exception as e:
        print(mid, 'ERR', e)
