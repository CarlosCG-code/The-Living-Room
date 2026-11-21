"""Descarga pinturas CC0 del Met (Open Access) desde su copia oficial en Wikimedia Commons (usuario, 2026-11-21).
El servidor de imágenes del Met rechaza descargas por script; Commons tiene la donación del Met con licencia CC0,
que se comprueba en cada archivo. Wikimedia limita la velocidad (429): se reintenta con esperas largas y se puede
relanzar, salta lo ya descargado.

Uso: python tools/fetch_met.py            (las de SEL)
Salida: art_source/met/<id>.jpg y art_source/met/met.json (título, autor, URLs del Met y de Commons, SHA-512).
"""
import json, urllib.request, urllib.parse, urllib.error, hashlib, time, os
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
SEL = [436262, 437336, 436200, 441965, 437841, 435847, 437008, 435763, 436545, 437388, 436617, 437237, 435757, 437374, 436348, 435721, 436628, 437653, 437914, 436653, 437462, 436832, 435983, 437044, 437042, 438417, 436558, 816520, 437997, 438031, 436961, 436014, 435774, 436936, 438659]
UA = {"User-Agent": "TheLivingRoom-assets/1.0 (game asset fetch)"}
def raw(u):
    for i in range(6):
        try:
            return urllib.request.urlopen(urllib.request.Request(u, headers=UA), timeout=60).read()
        except urllib.error.HTTPError as e:
            print("HTTP", e.code, "esperando"); time.sleep(60 * (i + 1))
        except OSError:
            time.sleep(5 * (i + 1))
    raise OSError(u)
g = lambda u: json.loads(raw(u))
C = "https://commons.wikimedia.org/w/api.php?action=query&format=json&"
M = ROOT + "/art_source/met/met.json"
meta = json.load(open(M, encoding="utf-8")) if os.path.exists(M) else {}
for i in SEL:
    if str(i) in meta and os.path.exists(ROOT + f"/art_source/met/{i}.jpg"):
        continue
    o = g(f"https://collectionapi.metmuseum.org/public/collection/v1/objects/{i}")
    img = o["primaryImage"].rsplit("/", 1)[1].rsplit(".", 1)[0]
    r = g(C + "list=search&srnamespace=6&srlimit=3&srsearch=" + urllib.parse.quote(f'"MET {img}"'))["query"]["search"]
    if not r:
        print("SIN COMMONS", i, o["title"][:40]); continue
    p = next(iter(g(C + "prop=imageinfo&iiprop=url|extmetadata|size&iiurlwidth=1024&titles=" + urllib.parse.quote(r[0]["title"]))["query"]["pages"].values()))["imageinfo"][0]
    lic = p["extmetadata"].get("LicenseShortName", {}).get("value")
    if lic != "CC0":
        print("LICENCIA", lic, i); continue
    data = raw(p["thumburl"])
    assert data[:3] == b"\xff\xd8\xff", i
    open(ROOT + f"/art_source/met/{i}.jpg", "wb").write(data)
    meta[str(i)] = {"title": o["title"], "artist": o.get("artistDisplayName"), "date": o.get("objectDate"), "met": o["objectURL"],
                    "commons": p["descriptionurl"], "w": p["width"], "h": p["height"], "sha512": hashlib.sha512(data).hexdigest()}
    json.dump(meta, open(M, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    time.sleep(12)
print("OK", len(meta))
