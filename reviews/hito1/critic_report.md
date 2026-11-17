# Etapa 7 — Crítica: `specs/hito1.md`, líneas 1-89 (§1-§4)

Ronda 1. Revisores: **diseño**, **estructura** y **estilo**. Estándar: `feature-spec-standard`. Los tres terminaron.

**Veredicto:** hacen falta cambios. Hay 1 bloqueante y 10 importantes. Muchos repiten lo que ya salió en las etapas 5 y 6, que aquí se indican.

**Comprobado con Godot 4.7.2** (prueba en headless, 2026-11-17):
- `JSON.parse_string` devuelve **todos** los números como `float`. Un estado de generador aleatorio de 64 bits vuelve cambiado: `1024092676969774224` se convierte en `1024092676969774208`.
- `DirAccess.rename_absolute` sobre un archivo que ya existe **lo sobrescribe** en Windows, sin error.

## 🔴 Bloqueante

### 1. El estado aleatorio no sobrevive al JSON (diseño, estructura; etapa 5 n.º 2) — **confirmado**
- **Dónde:** D8, §4 (`"rng"`).
- **Cambio:** quitar `rng` del guardado. Es lo que propuso la etapa 5 y lo más simple: ya se guardan `next_in` y `active_left`, que es todo lo que una partida cargada necesita. Al cargar, nueva semilla al azar; los tests inyectan una fija. La alternativa (guardar la semilla y el estado como texto) se descarta en D8.

## 🟡 Importantes

### 2. Falta la lista de identificadores, que forman parte del formato de guardado (diseño, estructura; etapa 6 n.º 2)
- **Problema:** solo aparecen `antenna` y `pulse`. Cambiar un `id` más adelante haría perder progreso sin error, y `CLAUDE.md` exige confirmación para cambiar el formato de guardado.
- **Cambio:** columna `id` en la tabla de generadores y una tabla de las 18 mejoras (id, nombre, requisito, coste, efecto). Las de generador siguen el patrón `<generador>_x2_10` y `<generador>_x2_25`.

### 3. No se valida el contenido del archivo cargado (diseño, estructura)
- **Problema:** un archivo con JSON válido y `version: 1` pero con `"energy": "abc"`, claves que faltan o números negativos entraría tal cual.
- **Cambio:** se valida el tipo de cada clave. Si falta una obligatoria o tiene otro tipo, el archivo cuenta como ilegible (se pasa al `.bak`). Los números negativos se ponen a 0, y los enteros se convierten de `float` a `int`. Se añade un test.

### 4. Cargar el `.bak` puede acabar destruyéndolo (los tres; etapa 5 n.º 1)
- **Cambio:** un archivo ilegible se renombra al momento a `X.corrupt` (o `X.bak.corrupt`), funcione o no el `.bak`. Un `X.tmp` sobrante al arrancar se borra. Un `meta.json` ilegible da el meta-estado por defecto, no una partida nueva. Si no existe ni `X` ni `X.bak` (primera vez), no hay aviso.

### 5. Los costes y los números en pantalla no cuadran entre sí (diseño, estilo, estructura; etapa 6 n.º 4)
- **Problema:** `15 × 1,15 = 17,25`, mostrado como «17»; el botón podría verse desactivado con 17 de Energía. La producción de 0,2/s saldría como «0». Además, «1,23 B» se confunde con el *billion* inglés.
- **Cambio:**
  - Coste = `ceil(coste_base × 1,15^poseídos)`.
  - La Energía se muestra truncada a entero, con punto de miles.
  - La producción por segundo lleva 1 decimal por debajo de 100.
  - Los formatos de más de 10⁹ se fijan en el hito 4 (etapa 5 n.º 10).

### 6. Falta la regla de atrapar la interferencia (diseño; etapa 6 n.º 3)
- **Cambio:**
  - `catch_interference()` solo funciona si hay una interferencia activa, paga D7 una vez y la termina.
  - No cuenta como clic del dial, y los clics automáticos no la atrapan.
  - El siguiente intervalo (120-240 s) se sortea al terminar la interferencia.
  - *Reiniciar* cancela la activa y sortea un intervalo nuevo.
  - Se quita «la primera no antes del minuto 2», que es redundante.

### 7. Mantener pulsado y hacer clic a la vez es imposible con un ratón (diseño)
- **Problema:** el perfil «6 clics/s sosteniendo el dial» simula algo que nadie puede hacer.
- **Cambio:** mientras se sostiene el dial, no hay clics manuales; mantener pulsado es una sola pulsación. En el test, el perfil activo hace 6 clics/s y no mantiene pulsado; el perfil tranquilo hace 0,5 clics/s y mantiene pulsado en cuanto tiene *Dial firme*. Así *Dial firme* ayuda a quien casi no hace clic, que es para lo que está.

### 8. Los valores iniciales se contradicen (diseño)
- **Problema:** el umbral (550.000) es menor que el coste de *Canal 3* (1.900.000), así que nunca se llegaría a comprar. D5 habla de ~10⁷ sin fuente.
- **Cambio:** costes y producciones con fórmula (`base × factor^posición`, etapa 5 n.º 4). El umbral inicial debe ser mayor que el coste acumulado de lo previsto (≥ 10⁷); el test lo ajusta. D5 se reformula: el error relativo de un `float` (~10⁻¹⁶) es despreciable hasta ~10¹⁵.

### 9. Falta decir que no hay producción sin jugar (diseño)
- **Cambio:** añadir a «Fuera de alcance»:
  - **Sin producción con el juego cerrado:** las duraciones del GDD §3 cuentan el tiempo delante de la tele.
  - **Sin comprar ×10 ni vender.**

### 10. Faltan el requisito y el coste de las 6 mejoras de clic (diseño, estilo; etapa 6 n.º 2)
- **Cambio:** que estén en la tabla de mejoras (punto 2). *Pulso*, con requisito 0 y coste ≤ 7 (primera compra antes de 15 s a 0,5 clics/s). *Dial solo II* requiere *Dial solo*.

### 11. Faltan los riesgos del diseño, y algunas justificaciones no son exactas (estructura, estilo)
- **Cambio:**
  - Añadir a la §9 los riesgos del guardado y de los números.
  - **D9:** `CLAUDE.md` fija `.tmp`, `.bak` y archivos separados; esta especificación fija las rutas y el esquema. En «alternativas», poner «forzada por `CLAUDE.md`».
  - **D7:** quitar la cita circular a `incremental.md`.
  - **D4:** son 24 filas, no 20.

## 🟢 Menores

12. Los multiplicadores se multiplican entre sí; sin mejoras valen 1 (etapa 6 n.º 8).
13. `tick(delta: float, holding: bool)` en inglés, coherente con D2.
14. `play_time` es el tiempo de la run actual (vuelve a 0 al reiniciar); el guardado periódico va por un contador propio de 5 min (etapa 6 n.º 9).
15. Valores de `last_ending`: `""` o el id de un final; los ids se fijan en el hito 6.
16. Soltar el dial al perder el foco (etapa 5 n.º 7).
17. Una frase del porqué del hito: la economía y su ritmo tienen que estar probados antes de construir encima la tele 3D y el director.
18. **Estilo:**
    - «valores iniciales» en vez de «de partida» (para no confundir con partida guardada);
    - «build exportada»;
    - «especificación» en vez de «spec»;
    - definir qué es `X`;
    - nombres de mejora en cursiva;
    - «pone a cero la run y pasa a la siguiente».
19. Añadir `specs/hito0.md` a las fuentes.

## Correspondencia

| Aquí | Diseño | Estructura | Estilo | Etapas 5-6 |
|---|---|---|---|---|
| 1 | B1 | M2 | — | 5 n.º 2 |
| 2 | M2 | M4 | — | 6 n.º 2 |
| 3 | M3 | M3 | — | — |
| 4 | M4, N14 | N6 | M6 | 5 n.º 1; 6 n.º 7 |
| 5 | M5 | N5 | M5 | 5 n.º 10; 6 n.º 4 |
| 6 | M6, N11 | N7 | — | 6 n.º 3 |
| 7 | M7 | — | — | — |
| 8 | M8 | — | M2 | 5 n.º 4 |
| 9 | M9 | — | — | — |
| 10 | M10, N12 | — | N12 | 6 n.º 2 |
| 11 | N17 | M1, N1, N2 | M1, M3, M4 | — |
| 12-19 | N13, N16, N15, N18 | N3, N4, N7 | N1-N11, N13 | 5 n.º 7; 6 n.º 8, 9 |
