# THE LIVING ROOM — Game Design Document (v0.2)

> Estado: lo marcado **[PENDIENTE]** está abierto y se propone al usuario antes de fijarlo; lo marcado **[DEFECTO]** es una decisión provisional que se aplica salvo que el usuario diga otra cosa; el resto está decidido. Las decisiones técnicas están en `CLAUDE.md`.

## 1. Visión

Juego de **terror psicológico con un clicker/incremental como mecánica central**. Empieza como un juego mundano en una tele antigua y revela, run a run, que el jugador está atrapado en un bucle. Duración objetivo: **~2h35–2h50** según cuánto explore el jugador, pensado para no alargarse con relleno.

**Pilares**
1. **El sonido es el miedo.** Sin enemigos; el audio y lo que se ve (o se deja de ver) hacen todo el trabajo.
2. **El clicker es la causa, no un adorno.** Lo que compras altera el mundo; el jugador se siente cómplice.
3. **Premiar la atención.** Quien explora y observa decide con información; quien corre decide a ciegas.
4. **Lo mundano da más miedo.** Repartidor, café, fusibles, escaleras.

**No objetivos:** combate o enemigos, estado de derrota, multijugador, contenido procedural (todo está diseñado a mano), plataformas distintas de PC (Windows).

## 2. Historia y reglas del bucle

El protagonista es un **electricista**. El jugador no lo sabe al inicio; lo descubre por pistas y por lo que le piden hacer.

**Causa del bucle:** el juego de la tele **se alimenta de la electricidad del edificio**. Cada reinicio deposita un poco más del jugador dentro. La señora del 3.º lleva cientos de reinicios y se ha ido vaciando.

**Cómo empezó:** el juego es uno solo y las teles son ventanas a él. La señora del 3.º regaló al protagonista una tele (la nota sin firma de su piso es una pista). El bucle empezó con el primer *Reiniciar* del protagonista. Para salir, ella necesita que él ocupe su lugar frente a la tele de ella: la avería de la run 3 es el cebo.

**Reglas (la señora las explica al final):**
1. El juego consume la corriente del edificio.
2. Cada reinicio te deja más dentro.
3. Solo se sale si alguien ocupa tu lugar frente a tu tele.

**La señora mayor:** amable, de mal aspecto. **Te atrajo a propósito** con la avería y lo confiesa al final. Ni monstruo ni solo víctima: el jugador debe sentir el peso de perdonarla o no. Sus frases deben leerse de **dos maneras** (amable en la primera lectura, inquietante al recordarlas).

**Los sonidos de la run 1** (pastillas, gafas, dentadura cayendo) son **restos de su vida filtrándose** en el piso del jugador. El final los recontextualiza.

## 3. Estructura de runs

El ***Reiniciar*** del incremental es el disparador del bucle: al pulsarlo ocurre el evento de transición.

| Run | Duración aprox. | Qué escucha/ve el jugador | Evento tras el reinicio |
|---|---|---|---|
| Menú | — | Solo la tele y algo de fondo | — |
| 1 | ~35 min | Sonidos del incremental que derivan en toques en la puerta y objetos que caen. Zoom out sutil: se revela que está sentado en un sofá | Llama a la puerta el **repartidor**. Animación de levantarse. Recoge la comida, la deja en la mesa. Puede **explorar el piso** (~15 min, opcional) o volver a la tele |
| 2 | ~25 min | Luces y sonidos | **Apagón**. Solo linterna. La casa está **en espejo**. Hay que llegar a la caja de plomos y cambiar un fusible (~15 min) |
| 3 | ~20 min | Más de lo anterior, más intenso; objetos que cambian de sitio | Llama la **señora del 3.º**. El protagonista vive en el 8.º. Ascensor roto: **escalera a oscuras** hasta su piso, repara la avería, café, y en el salón la **misma tele con el mismo progreso**. Evento ~25 min |
| 4 | ~15 min | Juega en la tele de ella; su salón (3.º) se transforma objeto a objeto hasta ser idéntico al tuyo, solo cuando no miras. Quien va rápido no lo nota; quien observa sí (intencionado: premia la atención). Lo que falte por cambiar cambia durante la transición | Sonidos de la señora (pastillas, gafas, dentadura). Final |
| Final | ~20 min | Confesión de la señora, en su salón ya idéntico al tuyo, con ella delante | Ver sección 9 |

Total estimado: ~2h35 sin la exploración opcional; ~2h50 con ella.

**Guardado:** autoguardado al empezar cada run y cada evento de transición (repartidor, apagón, avería, confesión), no en los sustos del director, y además cada ~5 minutos. El periódico se aplaza mientras haya un evento en curso (un susto, una transición). Si se carga a mitad de un evento, este se repite desde su inicio. Tras un final, el *Reiniciar* del menú empieza una partida nueva: se reinician Energía, Carga y Evidencia, y se conserva el meta-estado: el último final, que decide el menú alterado.

## 4. Núcleo incremental

- **Moneda:** *Energía* (la electricidad del edificio). La producción se refleja en la intensidad de las luces del piso: cuanto más produces, más bajan, y se recuperan al reiniciar. Los parpadeos son eventos del director (§5).
- **El juego de la tele:** sintonizar una señal, en una pantalla retro de baja resolución: una fábrica dibujada a líneas donde cada generador es una máquina unida por cables a la fábrica; pulsar la fábrica abre la tienda (`specs/hito2.md` D19). Cada clic en el dial da Energía; la tienda vende generadores y mejoras. Detalle completo y razones: `specs/incremental.md` (aprobado el 2026-11-17).
- **Generadores/automatizaciones:** cada compra altera el mundo; en la run 1, solo con sonido. Seis generadores, uno nuevo cada ~5 min: *Antena* (zumbido), *Válvulas* (chasquidos en las paredes), *Frecuencia de audio* (llanto en la cocina), *Sintonizador* (voces de otra tele por el techo), *Mando a distancia* (clic de un mando, algo cae), *Canal 3* (toques en la puerta). Cada generador suma Energía a cada clic y produce algo por segundo: el clic es la fuente principal toda la run. Mejoras ×2 por generador al tener 10 y 25.
- **Línea de los clics** (mejoras de la run): *Pulso*, *Dial firme* (mantener pulsado), *Pulso fuerte*, *Resonancia* (el clic suma parte de la producción), *Dial solo* y *Dial solo II* (la tele hace clic sola). Cada paso hacia la automatización libera al jugador para mirar a su alrededor.
- **Interferencias:** cada 2-4 min salen chispas de uno de los cables de la fábrica de la tele durante unos segundos; atraparlas con un clic da una ráfaga de Energía. Premia mirar la tele mientras el director premia mirar el piso. El director puede colar un fotograma en la pantalla durante las chispas (hito 3; cuenta en el tope de destellos, no es un jumpscare).
- ***Reiniciar*** se habilita al alcanzar el umbral de Energía producida en la run (el de la run 1 sale del test de ritmo del hito 1; los demás, de los hitos 4-5); después, el jugador decide cuándo pulsarlo. Excepción: durante la confesión, *Reiniciar (último)* está siempre disponible (§9).
- **Prestigio:** cada *Reiniciar* da *Carga*: 3 al llegar al umbral y más si se espera (rendimiento decreciente). Esperar es una decisión de terror: más tiempo en un piso que suena peor. La Carga compra mejoras de **una sola rama**, permanentes durante la partida, que acortan las runs (35 → 15 min). Son partes del protagonista que la tele se queda: *Tus manos* (la tele hace clic sola desde el inicio), *Tu memoria* (empiezas con generadores), *Tu costumbre* (generadores más baratos), *Tu paciencia* (producción ×2), *Tu nombre* (+1 Carga por reinicio; la tele muestra su nombre). Sus rangos exactos se fijan en los hitos 4 y 5.
- Balance de la run 1 (hito 1, 2026-11-17): umbral de *Reiniciar* 6.986.879 de Energía producida; recompensa de la interferencia 15 s de producción. Los demás valores están en `data/economy_run1.tres`, generado por `tools/gen_economy_tres.py`; el test de ritmo comprueba que la run 1 dura 30-40 min delante de la tele. Balance de las runs 2-4 **[PENDIENTE]** (hitos 4-5) y playtests.

## 5. Sistema de miedo

Sin enemigos ni estado de derrota. Toda la tensión sale de **anormalidad escalonada**:

- Run 1: **audio**.
- Run 2: **espacio** (espejo, oscuridad).
- Run 3: **entorno** (objetos que se mueven, luces).
- Run 4: **identidad** (¿de quién es esta casa?).

**Director de eventos** (scheduler):
- Presupuesto de eventos por run, cooldowns y nivel de tensión acumulada.
- Los parpadeos de luz son eventos del director, nunca una respuesta a cada clic.
- Algunos eventos solo se disparan **cuando el jugador no mira**. "Mirar" = el objeto está en pantalla y nada lo tapa; "no mirar" = fuera de pantalla o tapado (la técnica concreta se decide en el hito 3). Ningún avance depende de un evento de mirada: si el jugador lo observa demasiado tiempo, el cambio pasa a otro objeto que no esté mirando.
- Silencios largos entre eventos; el vacío asusta más que el ruido.
- Evitar la habituación: variar, retener, no repetir patrones.

**Jumpscares (máximo 2):**
1. En la **escalera de la run 3**, tras un tramo tranquilo.
2. **Opcional** durante la confesión, en el salón (solo si el jugador sigue allí). **[PENDIENTE]**: se decide con el usuario tras probar el final en el hito 6.

Ninguno mata ni penaliza. Si el jugador los desactiva en ajustes, cada uno se sustituye por un evento de audio inquietante, sin susto.

**Accesibilidad visual:** aviso de fotosensibilidad al iniciar el juego. En ajustes, **"Intensidad de efectos" (0–100 %)**: regula la fuerza de los parpadeos del director, los bajones de luz y los efectos de pantalla; al 0 %, los parpadeos se convierten en bajones suaves. No elimina el oscurecimiento por producción (es parte de la mecánica); solo limita cuánto bajan las luces. Sea cual sea el ajuste, nunca más de 3 destellos por segundo.

## 6. Audio (pilar principal)

- Audio 3D posicional; mezcla distinta por run.
- Los sonidos de la run 1 son los objetos de la señora (ver sección 2).
- Capas: ambiente del edificio, zumbido eléctrico ligado a la producción, eventos puntuales.
- Subtítulos descriptivos (ej. "[pastillas cayendo]") como opción de accesibilidad. Cada evento de audio lleva desde su creación una clave de subtítulo (`tr()`).

## 7. Exploración y pistas

La exploración es opcional y **se premia**. Cada pista suma a una variable de **Evidencia**.

- **Piso del jugador:** herramientas de electricista, uniforme, llaves de furgoneta, correo mal entregado, la nota sin firma que acompañaba a la tele, fotos. Siembran quién es y por qué lo llaman.
- **Escalera:** detalles de otros vecinos que ya no están.
- **Piso de la señora:** tarjetas y herramientas de **otros electricistas** anteriores (la prueba de que no eres el primero).

La Evidencia determina cuánto confiesa la señora (y por tanto cuánto sabe el jugador al decidir; niveles **[PENDIENTE]**) y si puede abrir la caja general del final secreto. Los niveles de confesión son frases añadidas a un tronco común, no versiones completas.

## 8. Escenarios

1. Piso del jugador (incluye la caja de plomos): normal, **en espejo**, **a oscuras** (la run 2 combina ambas; la técnica del espejo y de la variante a oscuras se valida en el hito 2).
2. Escalera del 8.º a la planta baja (portal).
3. Piso de la señora (salón y recibidor como mínimo).
4. Portal / bajo del edificio, al pie de la escalera: **caja general** (final secreto).

## 9. Finales

La señora confiesa en su salón, ya idéntico al tuyo, **mientras el clicker sigue activo**. La tele muestra dos botones: **clic** (producción) y ***Reiniciar***. Cuanto más clicas, más baja la intensidad de las luces, como si el juego se comiera la corriente. La decisión es una **acción diegética**, no un menú: durante la confesión, *Reiniciar* pasa a *Reiniciar (último)* y hay que mantenerlo pulsado 2 s, para no activarlo sin querer. El jugador también puede levantarse y salir del piso; salir es un punto de no retorno: la puerta se cierra detrás de él y la decisión queda entre «Irte» y el final secreto.

- **Liberarla:** el jugador mantiene pulsado *Reiniciar (último)*. Ella sale por la puerta y vuelve la luz al edificio; tú quedas sentado frente a su tele, en su lugar.
  - **Ignorarla:** si al terminar la confesión el jugador no ha pulsado *Reiniciar (último)* ni ha salido del piso (clicando o no), ella misma pulsa *Reiniciar* y se va sin despedirse. Mismo final que "Liberarla".
- **Irte:** se levanta del sofá, sale del piso, baja hasta el portal y sale del edificio sin tocar la caja general. El edificio está iluminado, pero bajo los créditos suenan sin fin las pastillas y gafas de ella. Que salga sin que nadie ocupe su lugar (regla 3) es intencionado: el bucle no termina aunque lo parezca.
- **Secreto (opcional):** en el portal, abrir la **caja general** y cortar la corriente. Condición: Evidencia ≥ umbral **[PENDIENTE]**; sin ella, la caja está cerrada y solo queda irse. La tele se apaga: no hay bucle que alimentar ni lugar que ocupar, y los dos quedan libres con el edificio a oscuras.

Cada final termina en un **menú principal** distinto:
- **Liberarla / Ignorarla:** la tele y una silla; de fondo, *tus* objetos cayendo, como antes los suyos. Ahora el que se vacía eres tú.
- **Irte:** la tele encendida; de fondo, las pastillas y gafas de ella sin fin. Sigue atrapada, esperando al siguiente que pulse *Reiniciar*.
- **Secreto:** tu salón y el edificio a oscuras, con la tele apagada; los dos sois libres. Al pulsar *Reiniciar* (partida nueva), la tele se enciende sola: quien vuelve a poner en marcha el bucle eres tú.

Detalle de epílogos **[PENDIENTE]**.

## 10. Técnica

Las decisiones técnicas (motor, versión, arquitectura, verificación y licencias) están en `CLAUDE.md` y mandan sobre este documento. Lo propio del diseño:

- Motor: Godot 4.7.2, Forward+ (detalle técnico en `CLAUDE.md`).
- PC (Windows), primera persona; mando opcional **[PENDIENTE]**, se decide en el hito 7.
- **Visual:** el máximo fotorrealismo oscuro alcanzable con assets gratuitos, Blender y Godot (referencia *Visage*, videojuego de terror, 2020). En el hito 2 se itera el look-dev hacia el máximo fotorrealismo alcanzable, hasta que el usuario lo apruebe.
- **Tele:** el clicker se ve en la pantalla de la tele, con dos botones (clic y *Reiniciar*); se juega apuntando a ella.
- **Cámara:** un zoom out progresivo revela dónde está el jugador.
- **Assets y licencias:** según `CLAUDE.md` (todo gratuito y libre).

## 11. Plan de desarrollo (hitos)

Cada hito empieza con su **especificación de implementación** (archivos, pasos, decisiones [PENDIENTE] a cerrar y casos de test), que se revisa con EGM y el usuario aprueba antes de escribir código. Al cerrar cada hito se comprueba que la build exportada arranca.

0. **Base del proyecto.** Proyecto Godot y estructura de carpetas (las ubicaciones se anotan en `CLAUDE.md`); traducción (CSV, idioma `es`, `tr()` desde el primer texto); instalar GUT (versión compatible con 4.7.2) y el addon de capturas (`godot_mcp_runtime`); versión, origen y licencia de ambos se fijan en su especificación y se registran en `ASSETS.md` (sección de dependencias), que también se crea aquí. Comprobar que la build exportada arranca sin el addon (ni el nodo `MCPRuntime` que añade `DevBoot`) (sale con código 0 y sin errores en el log); la técnica de exclusión y la instalación de las plantillas de exportación se fijan en su especificación.
1. **Núcleo incremental + UI plana.**
   - Diseño del incremental aprobado (§4, `specs/incremental.md`). La especificación fija los costes, las producciones y el umbral de la run 1 con el test de ritmo, y entran las interferencias (sin el fotograma del director).
   - Reloj, `EventBus` y el adaptador entre `core/` y el `EventBus`; economía; *Reiniciar* con umbral (en este hito vacía la Energía y suma una run; la Carga y las mejoras llegan en el hito 4).
   - Guardado: su especificación fija las rutas `user://`, el esquema JSON (versión 1), el formato reservado del meta-estado (el último final, que decide el menú alterado) y qué hacer con un archivo corrupto (cargar el `.bak`).
   - Validar el **ritmo** con una simulación determinista en un test de `core/` (una forma de comprar fija): tiempo hasta el primer reinicio (~35 min) y compras por minuto dentro de los rangos aprobados. Efecto provisional: un sonido en cada compra. Si los jugadores quieren seguir tras el primer reinicio se pregunta en el playtest del hito 4.
2. **Tele en el salón del jugador** + SubViewport; apuntar y clicar en la tele en primera persona.
   - **Look-dev** del salón del jugador en Forward+: iterar hacia el máximo fotorrealismo alcanzable con assets gratuitos, Blender y Godot, comprobándolo con capturas, hasta que el usuario lo apruebe. Su especificación elige la GI (SDFGI, VoxelGI o LightmapGI) y la niebla.
   - Validar en esa habitación la técnica del **espejo** y de la variante **a oscuras**.
   - Presupuesto de frame **[PENDIENTE]** sobre el PC de desarrollo (`CLAUDE.md`), midiendo el look-dev con la GI activada y desactivada.
3. **Zoom out + audio de la run 1 + director de eventos** (presupuesto, cooldowns, tensión acumulada, mirada), con el tope de 3 destellos por segundo y el parámetro de intensidad de efectos implementados en este hito. Su especificación decide: la técnica de la mirada, cómo se arma el estado que recibe el director, la pausa del menú y la congelación parcial del final (`CLAUDE.md`), cómo leen la producción las luces y el zumbido, qué controla el zoom out y dónde se guarda la intensidad de efectos. Cada evento de audio lleva su clave de subtítulo desde que se crea.
4. **Corte vertical:** run 1 + repartidor + piso + apagón/espejo de la run 2 + Evidencia (registro de qué pistas se han encontrado) + 1-2 mejoras de prestigio (Carga). Controlador en primera persona (andar, mirar), interacciones (puerta, comida, linterna, caja de plomos, fusible), animación de levantarse y menú principal básico. Guardado ampliado con migración a la versión 2 y su test. Aviso de fotosensibilidad y ajuste de intensidad de efectos antes del playtest. **Playtest con ~5 personas.**
5. Run 3 y escalera (incluye jumpscare 1 y su sustituto de audio) + mejoras de prestigio completas. Al cerrar el hito, un test de `core/` simula las runs 1-4 con `tick()` y comprueba que las duraciones caen en los rangos de la §3.
6. Run 4 (transformación del salón de ella hasta ser idéntico al tuyo; usa la mirada del director), escalera hasta el portal, confesión con niveles según la Evidencia y sus voces, *Reiniciar (último)* con pulsación de 2 s, finales «Liberarla», «Ignorarla» e «Irte», variantes del menú y partida nueva. Final secreto: el usuario decide al cerrar el hito 6 si entra ahora o se pospone. Decidir el jumpscare 2.
7. Pulido, accesibilidad (menú de ajustes completo, subtítulos descriptivos, desactivar jumpscares, mando opcional), presets de calidad, optimización hasta el presupuesto de frame del hito 2.

## 12. Decisiones abiertas

- Balance de las runs 2-4 y su umbral de Energía (la run 1 está fijada, §4).
- Más mejoras para el incremental (petición del usuario, 2026-11-17): proponerlas en los hitos 4-5, junto a la Carga y las runs siguientes.
- Si la tele sigue produciendo Energía mientras el jugador explora (hito 4; propuesta: sí, para que explorar no retrase). Las duraciones de la §3 cuentan solo el tiempo delante de la tele; explorar no tiene límite.
- Música (si la hay) y voces/idiomas.
- Epílogos detallados de cada final.
- Nombres y diseño de las pistas; niveles de confesión según la Evidencia.
- Umbral de Evidencia del final secreto.
- Técnica de GI y niebla; presupuesto de frame (hito 2).
- Rangos de las mejoras de prestigio (hito 4).
- Mando opcional (hito 7).
- Minutos de diálogo de la confesión (antes del hito 6).
- Jumpscare 2 (hito 6).

## 13. Riesgos y mitigaciones

- **Abandono en la run 1** (~35 min con solo audio): cada compra cambia el mundo con sonido desde la primera, el zoom out revela poco a poco dónde estás y el director sube la tensión del audio. Se mide en el playtest del hito 4.
- **Fotorrealismo solo con medios gratuitos:** el hito 2 itera el look-dev de una habitación hacia el máximo fotorrealismo alcanzable, hasta que el usuario lo apruebe, antes de construir el resto.
- **Volumen de voz** (confesión de ~20 min con variantes según la Evidencia): se estima en minutos de diálogo antes del hito 6. Voces generadas con modelos libres (VoxCPM2/MOSS-TTS) o grabadas. Idiomas **[PENDIENTE]**.
- **Activar el final sin querer:** *Reiniciar (último)* se mantiene pulsado 2 s.
- **Bloqueo por la mirada:** ningún avance depende de un evento de mirada (§5).
- **Fotosensibilidad:** aviso, intensidad de efectos y límite de 3 destellos por segundo (§5).

## 14. Alternativas consideradas

- **Clicker dentro de la tele, no como menú superpuesto:** es más inmersivo, y el zoom out revela dónde está el jugador; así puede notar el cambio de habitación en la run 4.
- **Cuatro runs:** cada una sostiene un evento propio (repartidor y exploración, apagón y fusible, escalera hasta la señora, cambio de piso y confesión). No se buscaron más porque estas cuatro cubren la historia completa.
- **Una sola rama de prestigio, no dos:** más sencilla de desarrollar y equilibrar. La atención se premia con la exploración y la Evidencia, no con una rama aparte.
- **Final con una acción diegética, no con un botón de menú:** realizar una acción pesa más que elegir una opción.
