"""Descarga modelos y texturas CC0 de Poly Haven a art_source/polyhaven/<id>/ (specs/hito2.md D18).

Uso: python tools/fetch_polyhaven.py models sofa_03:2k ArmChair_01:1k ...
     python tools/fetch_polyhaven.py textures painted_plaster_wall:2k ...
Comprueba el tamaño de cada archivo con el que da la API e imprime una línea por recurso para ASSETS.md
(autor, URL, SHA-512 del archivo principal). Poly Haven publica todo en CC0 (https://polyhaven.com/license).
art_source/ tiene .gdignore: Godot no importa estas copias; el salón se exporta desde Blender a assets/models.
"""
import hashlib
import json
import os
import sys
import urllib.request

API = "https://api.polyhaven.com"
ROOT = os.path.join(os.path.dirname(__file__), "..", "art_source", "polyhaven")
UA = {"User-Agent": "TheLivingRoom-assets/1.0"}  # Poly Haven pide un User-Agent propio


def get(url: str) -> bytes:
    with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=60) as r:
        return r.read()


def save(url: str, path: str, size: int) -> bytes:
    data = get(url)
    if size and len(data) != size:
        raise SystemExit(f"tamaño distinto en {url}: {len(data)} != {size}")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as f:
        f.write(data)
    return data


def fetch(kind: str, asset_id: str, res: str) -> None:
    info = json.loads(get(f"{API}/info/{asset_id}"))
    files = json.loads(get(f"{API}/files/{asset_id}"))
    out = os.path.join(ROOT, asset_id)
    if kind == "models":
        main = files["gltf"][res]["gltf"]
        data = save(main["url"], os.path.join(out, os.path.basename(main["url"])), main["size"])
        for rel, f in main["include"].items():
            save(f["url"], os.path.join(out, rel), f["size"])
    else:
        data = b""
        for map_name in ("Diffuse", "nor_gl", "Rough", "AO", "arm"):
            if map_name in files and res in files[map_name]:
                f = files[map_name][res]["jpg"]
                data += save(f["url"], os.path.join(out, os.path.basename(f["url"])), f["size"])
    authors = ", ".join(info.get("authors", {}))
    sha = hashlib.sha512(data).hexdigest()
    print(f"| {info['name']} (`art_source/polyhaven/{asset_id}/`, {res}) | https://polyhaven.com/a/{asset_id} "
          f"(autor: {authors}) | `{sha}` | CC0 1.0 (polyhaven.com/license) |")


if __name__ == "__main__":
    for arg in sys.argv[2:]:
        asset, _, res = arg.partition(":")
        fetch(sys.argv[1], asset, res or "1k")
