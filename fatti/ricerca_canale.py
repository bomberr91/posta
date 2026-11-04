import sys
import json
import requests

def search_reddit(keywords):
    # Ricerca su Reddit usando l'API di Reddit
    import praw
    reddit = praw.Reddit(client_id='YOUR_CLIENT_ID',
                         client_secret='YOUR_CLIENT_SECRET',
                         user_agent='Script di ricerca Reddit')
    subreddit = reddit.subreddit('all')
    results = []
    for submission in subreddit.search(' '.join(keywords), limit=10):
        results.append({
            'title': submission.title,
            'url': submission.url,
            'author': submission.author.name
        })
    return results

def search_github(keywords):
    # Ricerca su GitHub usando l'API di GitHub
    import requests
    query = '+'.join(keywords)
    url = f'https://api.github.com/search/repositories?q={query}&sort=stars&order=desc'
    response = requests.get(url)
    if response.status_code == 200:
        repos = response.json()['items'][:10]
        results = [{
            'name': repo['name'],
            'url': repo['html_url'],
            'description': repo['description']
        } for repo in repos]
        return results
    else:
        return []

def search_web(keywords):
    # Ricerca sul web usando l'API di SerpAPI
    import requests
    api_key = 'YOUR_SERPAPI_API_KEY'
    query = '+'.join(keywords)
    url = f'https://serpapi.com/search.json?q={query}&api_key={api_key}'
    response = requests.get(url)
    if response.status_code == 200:
        results = response.json()['organic_results'][:10]
        return [{
            'title': res['title'],
            'url': res['link'],
            'snippet': res['snippet']
        } for res in results]
    else:
        return []

def main():
    if len(sys.argv) < 2:
        print("Usage: python ricerca_canale.py <keywords>")
        sys.exit(1)

    keywords = sys.argv[1:]
    reddit_results = search_reddit(keywords)
    github_results = search_github(keywords)
    web_results = search_web(keywords)

    dossier = {
        "reddit": reddit_results,
        "github": github_results,
        "web": web_results
    }

    if "--json" in sys.argv:
        print(json.dumps(dossier, indent=4))
    else:
        print("Dossier di ricerca:\n")
        print(f"Reddit: {reddit_results}\n")
        print(f"GitHub: {github_results}\n")
        print(f"Web: {web_results}\n")

if __name__ == "__main__":
    main()