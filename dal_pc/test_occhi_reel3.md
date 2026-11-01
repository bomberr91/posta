# 👁 OCCHI-FB — 01/11 10:28
URL: https://www.facebook.com/reel/4713312268949074
yt-dlp is up to date (stable@2026.10.26 from yt-dlp/yt-dlp)
## 1. Scarico (prima senza cookie: molti reel sono pubblici)
   ✓ scaricato: 23M
   grosso e NIENTE ffmpeg → riprovo col formato minimo
   → ora: 15M

## 2. Gemini guarda il video
(File API ko: HTTP Error 403: Forbidden — provo la via inline)
Traceback (most recent call last):
  File "<stdin>", line 40, in <module>
  File "<stdin>", line 11, in genera
  File "/usr/lib/python3.12/urllib/request.py", line 215, in urlopen
    return opener.open(url, data, timeout)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/lib/python3.12/urllib/request.py", line 521, in open
    response = meth(req, response)
               ^^^^^^^^^^^^^^^^^^^
  File "/usr/lib/python3.12/urllib/request.py", line 630, in http_response
    response = self.parent.error(
               ^^^^^^^^^^^^^^^^^^
  File "/usr/lib/python3.12/urllib/request.py", line 559, in error
    return self._call_chain(*args)
           ^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/lib/python3.12/urllib/request.py", line 492, in _call_chain
    result = func(*args)
             ^^^^^^^^^^^
  File "/usr/lib/python3.12/urllib/request.py", line 639, in http_error_default
    raise HTTPError(req.full_url, code, msg, hdrs, fp)
urllib.error.HTTPError: HTTP Error 403: Forbidden
