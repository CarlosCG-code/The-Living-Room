"""Descarga modelos CC0 de Sketchfab (usuario, 2026-11-22: solo lo que no hay en Poly Haven, p. ej. botas viejas).

Uso: python tools/fetch_sketchfab.py <nombre>:<uid> ...
La clave de API la guarda el usuario en ~/.sketchfab_token (fuera del repositorio; nunca en el chat ni en git).
Antes de descargar comprueba en la API que la licencia del modelo sea CC0; si no, lo salta.
Salida: art_source/sketchfab/<nombre>/ (el glTF tal cual) y una línea por modelo para ASSETS.md.
Después: tools/blender/prep_downloads.py lo reduce a <nombre>_1k.gltf para import_model.
"""
import hashlib
import io
import json
import os
import sys
import urllib.request
import zipfile

API = "https://api.sketchfab.com/v3/models/"
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "art_source", "sketchfab")


def get(url, token=None, timeout=60):
    headers = {"User-Agent": "TheLivingRoom-assets/1.0"}
    if token:
        headers["Authorization"] = "Token " + token
    with urllib.request.urlopen(urllib.request.Request(url, headers=headers), timeout=timeout) as r:
        return r.read()


def fetch(name, uid, token):
    info = json.loads(get(API + uid))
    lic = (info.get("license") or {}).get("slug")
    if lic != "cc0":
        print("SALTADO %s: licencia %s, no CC0" % (name, lic))
        return
    links = json.loads(get(API + uid + "/download", token))
    data = get(links["gltf"]["url"], timeout=300)  # el enlace firmado no lleva la clave
    out = os.path.join(ROOT, name)
    os.makedirs(out, exist_ok=True)
    zipfile.ZipFile(io.BytesIO(data)).extractall(out)
    print("| %s (`art_source/sketchfab/%s/`) | %s (autor: %s) | `%s` | CC0 1.0 |" % (
        info["name"], name, info["viewerUrl"], info["user"]["displayName"], hashlib.sha512(data).hexdigest()))


if __name__ == "__main__":
    token = open(os.path.expanduser("~/.sketchfab_token"), encoding="utf-8").read().strip()
    for arg in sys.argv[1:]:
        name, uid = arg.split(":")
        fetch(name, uid, token)
