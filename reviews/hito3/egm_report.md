# Informe de revisión EGM — Hito 3

**Objetivo:** `specs/hito3.md` v1 (2026-11-24). Revisores: `design`, `implementation-readiness`, `codebase-details` y `zoom-out` (los cuatro completados; no se pasaron `comprehension`, `structural` ni `style`). Ninguno ejecutó el juego; la vista desde el asiento se comprobó después con capturas.

Veredicto de los cuatro sobre la v1: no lista. La v2 aplica lo siguiente.

| Hallazgo | Sev. | Revisores | En la v2 |
|---|---|---|---|
| Con `reveal` bajo, echarse atrás acercaba la vista; jugando el zoom casi no se nota y de frente no se ve el sofá | Bloq. | 3 | D2: `lerp` del FOV, ojos a 1,10 m; D4: la revelación gira la cabeza a un lado (capturas) |
| La revelación se cancelaba sola, caía sobre el árbol y se repetía al cargar | Bloq. | 3 | D4: espera a `is_idle()`, solo la corta clic o tecla, obligatoria, no se repite |
| Los sonidos lejanos quedarían a −24 dB y 300 Hz; `House` no tiene filtro propio | Bloq. | 3 | D8: bus `HouseEvents`, un solo escalón de muro |
| Faltaban valores e interfaces del director | Bloq. | 3 | D6: firmas, tabla con enfriamientos, menos reglas |
| `LAMP` sin lugar: el director no podía elegir lámpara y ninguna entra en cuadro jugando | Bloq. | 3 | D6, D7: `lamps` en el estado; vale una lámpara de tu zona |
| Ritmo contradictorio, bloqueo con 2 sucesos posibles, casa muda al agotar el presupuesto, test vacío | Mayor | 4 | D6: silencios fijos, tanda creciente, presupuesto solo con `p` < 1, test nuevo |
| El fotograma salía en ~3 % de las runs; sonidos de la señora al azar | Mayor | 4 | D6: obligatorios; D9 |
| Luces y zumbido leían Energía acumulada, no producción (GDD §4) | Mayor | 2 | D1: `production_level()` |
| Clic izquierdo atascado, Espacio mantenido y dueño del ratón | Mayor | 3 | D3 |
| Sonda de reflejos sin recapturar | Mayor | 2 | D5 |
| Tope de destellos y efectos de pantalla incompletos | Mayor | 3 | D11 |
| Segundo director en `tv.gd` (silencios al azar) | Mayor | 3 | D8: preludio |
| Captura del juego en el repositorio (privacidad) | Mayor | 1 | D9: en directo con `SubViewport` |
| Pasos que dependían de otros posteriores; archivos y tests sin listar | Mayor | 2 | §3, §4, §5 |
| Datos falsos: sonido de compra, 4 m, linterna | Bloq. (regla) | 1 | Corregidos |

**No aplicado:** quitar `UNSEEN` (el GDD §11 pide la mirada en este hito; es un filtro y su test). `creak` mantiene `door_creak.ogg`, recortado.
