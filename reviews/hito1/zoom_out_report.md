# Etapa 5 — Zoom out: `specs/hito1.md`

Revisores: **zoom out** (alcance y simplicidad) y **catalizador** (contradicciones y alternativas). Contexto: `CLAUDE.md`, `GAME_DESIGN.md`, `specs/incremental.md`, `specs/hito0.md`.

**Veredicto:** se aprueba con cambios. No hay bloqueantes. La arquitectura cumple `CLAUDE.md` y el reparto en clases es casi el mínimo posible. Hay **dos fallos reales**, que conviene arreglar antes de escribir código:
- uno en el guardado, que puede perder la copia buena;
- otro con la semilla aleatoria, que se corrompería al guardarse en JSON.

## Importantes (🟡)

### 1. Cargar la copia de seguridad puede acabar destruyéndola (catalizador)
- **Dónde:** §4, lectura y escritura atómica.
- **Problema:** si `run.json` está dañado y se carga `run.json.bak`, el archivo dañado se queda donde está. En el siguiente guardado, ese archivo dañado se renombra a `.bak` y **sustituye a la copia buena**. Si el juego se cierra de golpe en ese momento, se pierde la partida.
- **Cambio:** en cuanto un archivo no se pueda leer, se renombra a `.corrupt` al cargarlo, funcione o no el `.bak`. Así solo se rota a `.bak` un archivo que se ha leído bien. Se añade un test: con el principal dañado y el `.bak` bueno, se carga, se guarda, y el `.bak` sigue siendo el bueno.

### 2. Guardar la semilla aleatoria en JSON la corrompe y no hace falta (zoom out)
- **Dónde:** D8 y §4 (`"rng"`).
- **Problema:** el estado del generador aleatorio es un número de 64 bits, y el JSON de Godot lo lee como decimal, que solo guarda exactos los números de hasta unos 9 billones. El estado se corrompería sin avisar. Además, ya se guardan los segundos que faltan para la próxima interferencia, que es lo único que una partida cargada necesita.
- **Cambio:** quitar `rng` del guardado; al cargar, nueva semilla al azar. Los tests inyectan una semilla fija para ser repetibles.

### 3. Falta la regla de cuándo aparece cada generador, así que el ritmo no se puede medir (los dos)
- **Dónde:** §3, §5 (tienda) y §7 (test de ritmo).
- **Problema:** `specs/incremental.md` dice que cada generador «aparece» hacia cierto minuto, pero la spec enseña los 6 desde el principio. Sin esa regla, «un generador nuevo cada 5-6 minutos» no significa nada medible. Además, el test no define qué es «mejor retorno» para las mejoras de clic, ni si los clics automáticos cuentan como compras.
- **Cambio:**
  - **Regla de aparición:** un generador aparece en la tienda cuando ya se ha comprado el anterior.
  - **«Nuevo»** = la primera vez que algo se muestra en la tienda.
  - **Retorno** = cuánta Energía por segundo añade la compra, para ese estilo de jugador (contando clics, mantener pulsado y clics automáticos), dividido entre su coste.
  - Los clics automáticos no son compras.
  - El simulador devuelve una línea de tiempo (compras, apariciones y minuto del umbral), que se te enseña en el paso 8, y las comprobaciones van aparte.

### 4. Ajustar el ritmo a mano, tocando unos 30 números, puede parecer imposible sin serlo (catalizador)
- **Dónde:** §6 paso 3 y §9.
- **Problema:** la diferencia entre quien hace mucho clic y quien casi no depende sobre todo de las mejoras de clic. El umbral y una escala global mueven a los dos estilos por igual.
- **Cambio:** ajustar en orden:
  1. medir con los valores de partida;
  2. cerrar la diferencia entre estilos tocando solo las mejoras de clic;
  3. fijar la duración media con el umbral y una escala global.

  Los costes y las producciones de los generadores siguen una fórmula (base × factor^posición), así que hay 2-3 números que ajustar en vez de 12. Solo si el paso 2 no lo consigue, se te pregunta.

### 5. Los tests y `verify.sh` tocarían tu partida guardada real (zoom out)
- **Dónde:** D2, D10.
- **Problema:** los autoloads también se cargan al ejecutar los tests y al arrancar la build en `verify.sh`. Cada verificación leería y escribiría `user://run.json` y gastaría la copia de seguridad.
- **Cambio:** `Game` no guarda si se arranca con la opción `--no-save`, y `verify.sh` y los tests la usan. Tus partidas no se tocan.

## Menores (🟢)

6. **Guardar al cerrar:** decidirlo ya, con `auto_accept_quit = false`: se guarda y después se cierra. Si el guardado falla, la ventana se cierra igual.
7. **Dial pegado:** si la ventana pierde el foco con el dial pulsado, puede seguir contando como pulsado. Se suelta al perder el foco.
8. **Riesgo de test lento:** sobra. Son unos 40.000 pasos sencillos, menos de un segundo. Se quita el riesgo y su alternativa (pasos de 1 s), que además empeoraría la precisión.
9. **`meta.json`:** el GDD solo pide fijar su formato. Basta con documentarlo; crearlo, leerlo y probarlo puede esperar a cuando tenga contenido (hitos 4-6).
10. **Números grandes (`mil M`, `B`):** la run 1 no pasa de ~10⁷. Basta con el punto de miles; lo demás llega en los hitos 4-5.
11. **Señales sin uso:** `interference_started` e `interference_ended` no las escucha nadie en este hito. Se quitan hasta el hito 3; `run_restarted` se queda, porque `CLAUDE.md` lo nombra.
12. **Valores en el GDD:** copiarlos todos crea dos fuentes que se desincronizan. Se anota solo el umbral y se remite a `data/economy_run1.tres`.
13. **`id` desconocido al cargar:** defiende de borrar generadores, cosa que nadie planea. Es una línea; se puede quitar o dejar a conciencia.

## No comprobado por los revisores

- Si `DirAccess.rename` de Godot en Windows sobrescribe un archivo existente (lo necesita la escritura atómica).
- Si el paquete «UI Audio» de Kenney trae un `.ogg` adecuado.
- Que los valores de partida lleguen a 35 minutos.

## Correspondencia

| Aquí | Zoom out | Catalizador |
|---|---|---|
| 1 | — | M1 |
| 2 | M2 | N3 |
| 3 | M1 | M2 |
| 4 | — | M3 |
| 5 | M3 | — |
| 6-8 | N5 | N1, N4, N2 |
| 9-13 | N1, N2, N3, N4, N6 | — |
