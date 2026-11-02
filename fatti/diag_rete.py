#!/usr/bin/env python3
"""Diagnostica di rete: distingue DNS rotto, porta bloccata, TLS rotto,
endpoint lento o semplicemente non raggiungibile.

Uso:  python3 fatti/diag_rete.py [host ...]
"""
import socket
import ssl
import sys
import time
import urllib.error
import urllib.request

DEFAULT = [
    ("integrate.api.nvidia.com", "/v1/models"),
    ("api.mistral.ai", "/v1/models"),
    ("api.groq.com", "/openai/v1/models"),
    ("api.tavily.com", "/search"),
    ("github.com", "/"),
]


def dns(host):
    try:
        infos = socket.getaddrinfo(host, 443, proto=socket.IPPROTO_TCP)
        ips = sorted({i[4][0] for i in infos})
        return "ok " + ",".join(ips[:4])
    except Exception as e:
        return "ERR %s: %s" % (type(e).__name__, e)


def tcp(host, t=8):
    t0 = time.time()
    try:
        s = socket.create_connection((host, 443), timeout=t)
        s.close()
        return "ok %.2fs" % (time.time() - t0)
    except Exception as e:
        return "ERR %s: %s (%.2fs)" % (type(e).__name__, e, time.time() - t0)


def tls(host, t=8):
    t0 = time.time()
    try:
        ctx = ssl.create_default_context()
        with socket.create_connection((host, 443), timeout=t) as s:
            with ctx.wrap_socket(s, server_hostname=host) as ss:
                return "ok %.2fs %s" % (time.time() - t0, ss.version())
    except Exception as e:
        return "ERR %s: %s (%.2fs)" % (type(e).__name__, e, time.time() - t0)


def get(host, path, t=12):
    t0 = time.time()
    try:
        req = urllib.request.Request(
            "https://%s%s" % (host, path), headers={"User-Agent": "Mozilla/5.0"})
        r = urllib.request.urlopen(req, timeout=t)
        return "HTTP %s (%.2fs)" % (r.status, time.time() - t0)
    except urllib.error.HTTPError as e:
        return "HTTP %s (%.2fs)" % (e.code, time.time() - t0)
    except Exception as e:
        return "ERR %s: %s (%.2fs)" % (type(e).__name__, e, time.time() - t0)


def main():
    hosts = DEFAULT
    if len(sys.argv) > 1:
        hosts = [(h, "/") for h in sys.argv[1:]]
    for host, path in hosts:
        print("== %s" % host)
        print("   dns : %s" % dns(host))
        print("   tcp : %s" % tcp(host))
        print("   tls : %s" % tls(host))
        print("   get : %s" % get(host, path))
    return 0


if __name__ == "__main__":
    sys.exit(main())
