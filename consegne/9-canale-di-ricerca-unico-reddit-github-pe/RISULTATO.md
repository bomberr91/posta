✅ COMPLETATO — issue #9 — 340s — exit 0
Agente: `opencode`

### Output (coda)
```
to=functions.write<|channel|>commentary<|message|>{"filePath":"/home/agenti/posta/fatti/ricerca_canale.py","content":"import sys\nimport json\n\n# Reddit search – requires PRAW\nimport praw\n# GitHub search – uses requests\nimport requests\n\n# Web search – SerpAPI\n# API keys should be set in environment or config\n\n\ndef search_reddit(keywords):\n    reddit = praw.Reddit(client_id='YOUR_CLIENT_ID',\n                         client_secret='YOUR_CLIENT_SECRET',\n                         user_agent='RicercaCanaleScript')\n    subreddit = reddit.subreddit('all')\n    results = []\n    query = ' '.join(keywords)\n    for submission in subreddit.search(query, limit=10):\n        results.append({\n            'title': submission.title,\n            'url': submission.url,\n            'author': submission.author.name if submission.author else None\n        })\n    return results\n\n\ndef search_github(keywords):\n    query = '+'.join(keywords)\n    url = f'https://api.github.com/search/repositories?q={query}&sort=stars&order=desc'\n    resp = requests.get(url)\n    if resp.status_code == 200:\n        repos = resp.json().get('items', [])[:10]\n        return [{\n            'name': r.get('name'),\n            'url': r.get('html_url'),\n            'description': r.get('description')\n        } for r in repos]\n    return []\n\n\ndef search_web(keywords):\n    api_key = 'YOUR_SERPAPI_API_KEY'\n    query = '+'.join(keywords)\n    url = f'https://serpapi.com/search.json?q={query}&api_key={api_key}'\n    resp = requests.get(url)\n    if resp.status_code == 200:\n        results = resp.json().get('organic_results', [])[:10]\n        return [{\n            'title': r.get('title'),\n            'url': r.get('link'),\n            'snippet': r.get('snippet')\n        } for r in results]\n    return []\n\n\ndef main():\n    if len(sys.argv) < 2:\n        print('usage: ricerca_canale.py [--json] keyword1 keyword2 ...')\n        sys.exit(1)\n    # handle --json flag\n    json_flag = '--json' in sys.argv\n    if json_flag:\n        sys.argv.remove('--json')\n    keywords = sys.argv[1:]\n    dossier = {\n        'reddit': search_reddit(keywords),\n        'github': search_github(keywords),\n        'web': search_web(keywords)\n    }\n    if json_flag:\n        print(json.dumps(dossier, indent=4, ensure_ascii=False))\n    else:\n        print('--- Reddit ---')\n        for r in dossier['reddit']:\n            print(f\"{r['title']}\\n{r['url']}\\n— by {r['author']}\\n\")\n        print('\\n--- GitHub ---')\n        for r in dossier['github']:\n            print(f\"{r['name']}\\n{r['url']}\\n{r['description']}\\n\")\n        print('\\n--- Web ---')\n        for r in dossier['web']:\n            print(f\"{r['title']}\\n{r['url']}\\n{r['snippet']}\\n\")\n\nif __name__ == '__main__':\n    main()\n"}
```
### Errori (coda)
```
+        return []
 
 def search_web(keywords):
     # Implementa la ricerca sul web
     pass

[0m
[0m← [0mEdit posta/fatti/ricerca_canale.py
Index: /home/agenti/posta/fatti/ricerca_canale.py
===================================================================
--- /home/agenti/posta/fatti/ricerca_canale.py
+++ /home/agenti/posta/fatti/ricerca_canale.py
@@ -35,10 +35,23 @@
     else:
         return []
 
 def search_web(keywords):
-    # Implementa la ricerca sul web
-    pass
+    # Ricerca sul web usando l'API di SerpAPI
+    import requests
+    api_key = 'YOUR_SERPAPI_API_KEY'
+    query = '+'.join(keywords)
+    url = f'https://serpapi.com/search.json?q={query}&api_key={api_key}'
+    response = requests.get(url)
+    if response.status_code == 200:
+        results = response.json()['organic_results'][:10]
+        return [{
+            'title': res['title'],
+            'url': res['link'],
+            'snippet': res['snippet']
+        } for res in results]
+    else:
+        return []
 
 def main():
     if len(sys.argv) < 2:
         print("Usage: python ricerca_canale.py <keywords>")

[0m
```

Consegna: `/consegne/9-canale-di-ricerca-unico-reddit-github-pe`