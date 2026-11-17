# Etapa 8 — Zoom out intermedio: `specs/hito1.md`

Revisor: **zoom out**. Comprueba qué cambió tras las etapas 5-7 y si el diseño encaja con el plan.

**Veredicto:** se aprueba con cambios. Las revisiones casi no añadieron alcance, y los 5 puntos de la etapa 5 están resueltos. Pero hay **1 bloqueante, introducido por la propia revisión**.

## 🔴 Bloqueante: la regla de aparición hace imposible el test de ritmo
- **Dónde:** §3.2 («cada uno aparece cuando se ha comprado el anterior») frente al rango «generador nuevo cada 4-7 min» (§3.5).
- **Problema:** la Antena cuesta 15, así que el jugador activo la compra en segundos y las *Válvulas* aparecen en menos de un minuto. Ningún ajuste de los números lo arregla.
- **Cambio:** cada generador tiene un requisito de **Energía producida en la run**, igual que las mejoras (`req_energy_produced` en `GeneratorDef`). Queda una sola regla de aparición para toda la tienda, como dato del `.tres`, y el paso 3 puede ajustar directamente los minutos de aparición (0/5/10/15/22/28 de `incremental.md` §3).

## 🟡 Importante: en la UI real no se distingue un clic de mantener pulsado
- **Dónde:** §3.1 y §5 (dial).
- **Problema:** todo clic es «pulsar y soltar», así que todo clic es un instante de «sostener». Tal como está escrito, con *Dial firme* los clics rápidos dejarían de contar, y la simulación no se parecería al juego real.
- **Cambio:** cada clic cuenta siempre, y mientras el botón esté pulsado se suman además 4 clics/s. Un clic rápido añade una fracción insignificante. La UI y el simulador siguen la misma regla.

## 🟢 Menores
1. **§3.4:** quien guarda al reiniciar es `Game`, al recibir `restarted`, no `Economy`.
2. **Los efectos de las mejoras salen del `.tres`:** `Economy` los lee de `UpgradeDef.kind` y `value`, sin números escritos en el código. «Sustituye» pasa a significar «cuenta la mayor tasa de clics automáticos que se tenga». Sobra `req_upgrade_id`, porque comprar *Dial solo II* sin *Dial solo* no hace daño.
3. **`--no-save`:** que tampoco cargue. Así no se lee ni se toca ningún archivo, y se empieza de cero.
4. **Rangos:** «como mucho cada 3 min» y «4-7 min» son decisiones nuevas para hacer medibles los rangos de `incremental.md`. Se anotan en §2 para que las apruebes.
5. **Test de ritmo:** medir lo que añade cada compra copiando el estado y preguntando a `Economy`, sin repetir sus fórmulas dentro del test.
