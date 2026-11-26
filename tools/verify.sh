#!/usr/bin/env bash
# Comprueba importación, tests, exportación, exclusión del addon y arranque de la build (D7).
set -euo pipefail
cd "$(dirname "$0")/.."
: "${GODOT:?GODOT debe apuntar a Godot_v4.7.2-stable_win64_console.exe}"
fail() { echo "VERIFY FAIL: $1" >&2; exit 1; }

LOG="$PWD/build/run.log"
mkdir -p build && touch build/.gdignore
# Se borra todo lo anterior para no comprobar por error una build vieja.
rm -f build/TheLivingRoom.exe build/TheLivingRoom.pck build/check.zip "$LOG"

# Comprobación 1. Importación. La primera genera el .translation; el criterio se aplica a la segunda.
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
# Texturas del piso a la medida de su uso (tools/texture_budget.gd); la segunda importación aplica lo que cambie.
"$GODOT" --headless --path . -s tools/texture_budget.gd >build/budget.log 2>&1 || fail "texture_budget (build/budget.log)"
grep -q 'BUDGET_CHANGED=' build/budget.log || fail "texture_budget no terminó (build/budget.log)"
"$GODOT" --headless --path . --import >build/import.log 2>&1 || fail "importación (build/import.log)"
! grep -q 'ERROR' build/import.log || fail "líneas ERROR en build/import.log"

# Comprobación 2. Tests GUT: deben ejecutarse los 22 scripts de test y pasar todos.
# TLR_NO_SAVE=1: el autoload Game no toca la partida real (GUT rechaza argumentos que no conoce).
TLR_NO_SAVE=1 "$GODOT" --headless --path . -s addons/gut/gut_cmdln.gd >build/gut.log 2>&1 \
	|| fail "tests GUT (build/gut.log)"
grep -q -F -- '---- All tests passed! ----' build/gut.log || fail "no pasaron todos los tests (build/gut.log)"
grep -q -E 'Scripts +22$' build/gut.log || fail "GUT no ejecutó los 22 scripts de test (build/gut.log)"
! grep -q -E 'SCRIPT ERROR|Parse Error' build/gut.log || fail "errores de script en build/gut.log"

# Comprobación 3. Exportación release, y un .zip con el mismo preset para listar sus archivos.
"$GODOT" --headless --path . --export-release "Windows Desktop" build/TheLivingRoom.exe \
	>build/export.log 2>&1 || fail "exportación (build/export.log)"
[ -f build/TheLivingRoom.exe ] && [ -f build/TheLivingRoom.pck ] || fail "faltan build/TheLivingRoom.exe o .pck"
"$GODOT" --headless --path . --export-pack "Windows Desktop" build/check.zip \
	>build/pack.log 2>&1 || fail "exportación del .zip (build/pack.log)"

# Comprobación 4. Exclusión por lista de archivos, no por texto: dev_boot.gd y las cachés
# de Godot mencionan el addon aunque sus archivos no estén.
unzip -Z1 build/check.zip >build/pack.txt || fail "no se puede listar build/check.zip"
grep -q '^presentation/main\.tscn' build/pack.txt || fail "el paquete no contiene la escena principal"
! grep -q -E '^(addons/godot_mcp_runtime|addons/gut|tests|tools|art_source)/|^\.gutconfig\.json$' build/pack.txt \
	|| fail "el paquete contiene el addon, GUT, los tests o herramientas (build/pack.txt)"

# Comprobación 5. Arranque (D7).
TLR_NO_SAVE=1 ./build/TheLivingRoom.exe --headless --quit-after 120 --log-file "$LOG" >/dev/null 2>&1 \
	|| fail "la build salió con un código distinto de 0"
[ -s "$LOG" ] || fail "$LOG falta o está vacío"
grep -q '^BOOT_OK' "$LOG" || fail "falta BOOT_OK en $LOG"
! grep -q 'ERROR' "$LOG" || fail "líneas ERROR en $LOG"

echo "VERIFY OK"
