"""Descarga pinturas CC0 del Cleveland Museum of Art (Open Access, https://openaccess-api.clevelandart.org).
Usuario, 2026-11-21: cualquier fuente CC0; si una descarga tarda o falla, se salta (sin esperas largas).

Uso: python tools/fetch_cma.py            (busca por temas de QUERIES, hasta N por tema)
Salida: art_source/cma/<id>.jpg y art_source/cma/cma.json (título, autor, fecha, URL, licencia, SHA-512).
Solo entra lo que la API marca share_license_status = CC0, sin desnudos: pinturas de antes de 1930 y fotos de 1860-1945.
"""
import hashlib
import json
import os
import urllib.parse
import urllib.request

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "art_source", "cma")
API = "https://openaccess-api.clevelandart.org/api/artworks/"
UA = {"User-Agent": "TheLivingRoom-assets/1.0"}
QUERIES = {"Virgin": 4, "saint": 4, "portrait": 8, "landscape": 6, "still life": 5, "interior": 3, "village": 3}
# Fotos de familia (usuario, 2026-11-22: casa vivida como en sus fotos de referencia): retratos fotográficos de 1860-1945.
PHOTOS = {"portrait of a woman": 5, "portrait of a man": 4, "untitled portrait": 3, "as a child": 3}
SKIP = ("nude", "venus", "bath", "naked", "bather", "leda", "susanna")


def get(url, timeout=20):
    for _ in range(2):  # un reintento rápido; si vuelve a fallar, se salta
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=timeout) as r:
                return r.read()
        except OSError:
            pass
    return None


def main():
    os.makedirs(ROOT, exist_ok=True)
    meta_path = os.path.join(ROOT, "cma.json")
    meta = json.load(open(meta_path, encoding="utf-8")) if os.path.exists(meta_path) else {}
    jobs = [(q, n, {"type": "Painting", "created_before": 1930}) for q, n in QUERIES.items()]
    jobs += [(q, n, {"type": "Photograph", "created_after": 1860, "created_before": 1945}) for q, n in PHOTOS.items()]
    for q, n, kind in jobs:
        params = urllib.parse.urlencode({"q": q, "cc0": 1, "has_image": 1, "limit": 40, **kind})
        raw = get(API + "?" + params)
        if not raw:
            print("SIN RESPUESTA", q)
            continue
        got = 0
        for a in json.loads(raw)["data"]:
            if got >= n:
                break
            key = str(a["id"])
            if key in meta:
                got += 1
                continue
            if a.get("share_license_status") != "CC0" or any(w in a["title"].lower() for w in SKIP):
                continue
            web = (a.get("images") or {}).get("web") or {}
            data = get(web.get("url", ""))
            if not data or data[:3] != b"\xff\xd8\xff":
                print("SALTADA", key)
                continue
            open(os.path.join(ROOT, key + ".jpg"), "wb").write(data)
            creator = (a.get("creators") or [{}])[0].get("description", "")
            meta[key] = {"title": a["title"], "creator": creator, "date": a.get("creation_date"), "url": a.get("url"),
                         "theme": q, "type": kind["type"], "license": "CC0", "sha512": hashlib.sha512(data).hexdigest()}
            json.dump(meta, open(meta_path, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
            got += 1
    print("OK", len(meta))


if __name__ == "__main__":
    main()
