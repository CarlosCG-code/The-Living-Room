"""Descarga modelos CC0 y gratuitos de BlenderKit (usuario, 2026-11-22: ventanas antiguas y cocina, que no hay en
Poly Haven ni en Sketchfab).

Uso: python tools/fetch_blenderkit.py <nombre>:<id del asset> ...   (el id sale de la búsqueda de la API)
La clave la guarda el usuario en ~/.blenderkit_token (fuera del repositorio; nunca en el chat ni en git).
Solo descarga si la API dice license = cc_zero e isFree. Salida: art_source/blenderkit/<nombre>/ (el glTF, o el .blend si no hay glTF)
y una línea por modelo para ASSETS.md. Después: tools/blender/prep_downloads.py lo reduce para import_model.
"""
import hashlib
import io
import json
import os
import sys
import urllib.parse
import urllib.request
import uuid
import zipfile

API = "https://www.blenderkit.com/api/v1/"
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "art_source", "blenderkit")


def get(url, token=None, timeout=60):
    headers = {"User-Agent": "TheLivingRoom-assets/1.0"}
    if token:
        headers["Authorization"] = "Bearer " + token
    with urllib.request.urlopen(urllib.request.Request(url, headers=headers), timeout=timeout) as r:
        return r.read()


def fetch(name, asset_id, token):
    a = json.loads(get(API + "assets/%s/" % asset_id, token))
    if a.get("license") != "cc_zero" or not a.get("isFree"):
        print("SALTADO %s: licencia %s" % (name, a.get("license")))
        return
    f = next((f for f in a["files"] if f["fileType"] == "gltf"), None) or next(f for f in a["files"] if f["fileType"] == "blend")
    link = json.loads(get(f["downloadUrl"] + "?scene_uuid=" + str(uuid.uuid4()), token))["filePath"]
    data = get(link, timeout=300)
    out = os.path.join(ROOT, name)
    os.makedirs(out, exist_ok=True)
    ext = os.path.splitext(urllib.parse.urlparse(link).path)[1] or ".bin"
    if data[:2] == b"PK":  # zip con el glTF y sus texturas
        zipfile.ZipFile(io.BytesIO(data)).extractall(out)
    else:
        open(os.path.join(out, "scene" + ext), "wb").write(data)
    print("| %s (`art_source/blenderkit/%s/`) | https://www.blenderkit.com/asset-gallery-detail/%s/ (autor: %s) | `%s` | CC0 1.0 |" % (
        a["name"], name, a["id"], (a.get("author") or {}).get("fullName", ""), hashlib.sha512(data).hexdigest()))


if __name__ == "__main__":
    token = open(os.path.expanduser("~/.blenderkit_token"), encoding="utf-8").read().strip()
    for arg in sys.argv[1:]:
        name, asset_id = arg.split(":")
        fetch(name, asset_id, token)
