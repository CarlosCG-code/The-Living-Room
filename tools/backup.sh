#!/usr/bin/env bash
# Copia de seguridad en <carpeta>/<hito>/<fecha>: bash tools/backup.sh hito3
# La carpeta, una vez por PC: git config tlr.backups <ruta>
# Proyecto entero con su historial (sin lo que se regenera), la build jugable, la partida y las notas de Claude.
set -euo pipefail
cd "$(dirname "$0")/.."
: "${1:?falta el hito, p. ej. hito3}"
ROOT=$(git config tlr.backups) && [ -d "$ROOT" ] || { echo "BACKUP FAIL: no existe la carpeta de copias (git config tlr.backups)" >&2; exit 1; }
DEST="$ROOT/$1/$(date +%F)"
[ ! -e "$DEST" ] || DEST="${DEST}_$(date +%H%M%S)"
mkdir -p "$DEST/proyecto"

EXCLUDE=(--exclude=./.godot --exclude=./build --exclude='*.blend1' --exclude=__pycache__)
tar "${EXCLUDE[@]}" -cf - . | tar -xf - -C "$DEST/proyecto"
mkdir "$DEST/build"
cp build/TheLivingRoom.exe build/TheLivingRoom.pck "$DEST/build/"
SAVES="$APPDATA/Godot/app_userdata/The Living Room"
mkdir "$DEST/partidas"
[ ! -d "$SAVES" ] || tar --exclude=./shader_cache --exclude=./vulkan --exclude=./logs --exclude=./objectdb_snapshots -C "$SAVES" -cf - . | tar -xf - -C "$DEST/partidas"
NOTES="$HOME/.claude/projects/$(pwd -W | sed 's/[^A-Za-z0-9]/-/g')/memory"
[ ! -d "$NOTES" ] || cp -r "$NOTES" "$DEST/notas_claude"

# Se da por buena solo si coincide byte a byte y su historial está sano.
diff -rq -x .godot -x build -x '*.blend1' -x __pycache__ . "$DEST/proyecto"
cmp build/TheLivingRoom.pck "$DEST/build/TheLivingRoom.pck"
git -C "$DEST/proyecto" fsck --no-progress >/dev/null
git log -1 --format='Commit %h del %ci: %s' >"$DEST/LEEME.txt"
echo "Para recuperarlo: copiar la carpeta «proyecto» y ejecutar en ella: godot --headless --path . --import" >>"$DEST/LEEME.txt"
echo "BACKUP OK $DEST ($(du -sh "$DEST" | cut -f1))"
