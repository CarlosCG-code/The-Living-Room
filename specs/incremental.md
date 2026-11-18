# Propuesta — El incremental de la tele (v2)

> Estado: **aprobada por el usuario (2026-11-17)**. Resumen en el GDD §4; este documento es el detalle y la base de la especificación del hito 1.
>
> Cumple lo fijado en el GDD: moneda *Energía*; cada compra altera el mundo (en la run 1 solo con sonido); *Reiniciar* con umbral; *Carga* con mejoras de **una sola rama** que acortan las runs (35 → 15 min); sin estado de derrota.

## 0. Qué hace que funcione (y cómo se aplica aquí)

Un incremental engancha cuando cada pocos minutos pasa algo nuevo, cuando hay decisiones pequeñas pero reales y cuando el jugador pasa de hacerlo todo a mano a ver cómo funciona solo. En este juego hay una ventaja extra: **cada paso hacia la automatización libera al jugador para mirar a su alrededor**, que es justo cuando el director de miedo puede actuar (eventos que solo ocurren si no miras, GDD §5).

| Principio | Cómo se aplica |
|---|---|
| Novedad constante | Un generador o una mejora nueva cada 2-3 minutos; un generador nuevo cada ~5 minutos, con su sonido nuevo en el piso |
| De manual a automático | Tres fases en cada run: clic → clic potenciado → la tele trabaja sola (§2) |
| Decisiones pequeñas | Qué comprar primero (clics o generadores); atrapar o no las interferencias (§4); cuándo reiniciar (§5) |
| La mecánica cuenta la historia | Las compras hacen sonar el piso; la automatización es inquietante («la tele hace clic sola»); las mejoras permanentes son partes de ti |
| Nada se pierde del todo | La Carga hace cada run más corta: el jugador nota que avanza aunque reinicie |

## 1. La pantalla de la tele

Un juego retro de apariencia inocente, en una tele de tubo: **sintonizar una señal**. En el centro está el **dial**, un botón grande; cada clic da Energía. A la derecha, la tienda: generadores y mejoras. Arriba, la Energía y la producción por segundo. Un medidor de señal sube con la producción.

## 2. La línea de los clics: de la mano a la tele sola

El clic importa al principio y nunca deja de servir, pero el juego lo va automatizando. Mejoras de la run (se pierden al reiniciar):

| Mejora | Cuándo aparece | Efecto |
|---|---|---|
| **Pulso** | al empezar (coste muy bajo) | Cada clic vale ×2 |
| **Dial firme** | ~minuto 2 | Mantener pulsado el dial cuenta como 6 clics por segundo (era 4; subido el 2026-11-18 para que quien casi no clica siga el ritmo con la economía centrada en el clic) |
| **Pulso fuerte** | ~minuto 8 | Cada clic vale ×2 otra vez |
| **Resonancia** | ~minuto 12 | Cada clic suma además el 2 % de la producción por segundo, para que hacer clic siga valiendo al final |
| **Dial solo** | ~minuto 18 | El dial gira solo: 2 clics por segundo sin tocar nada. Se ve girar en la tele |
| **Dial solo II** | ~minuto 26 | 5 clics por segundo solos |

**Accesibilidad:** en el menú de ajustes (hito 7) habrá una opción para que mantener pulsado cuente como clics desde el principio, para quien no pueda hacer muchos clics.

## 3. Generadores (run 1)

La primera compra de cada uno activa su sonido en el piso; las siguientes lo hacen más frecuente o más cercano. Cuanta más producción, más bajan las luces (GDD §4).

| # | Generador | Qué cambia en el piso (run 1, solo sonido) | Aparece hacia el minuto |
|---|---|---|---|
| 1 | **Antena** | Un zumbido eléctrico que crece con cada compra | 0 |
| 2 | **Válvulas** | Chasquidos en las paredes, como cables que se calientan | 5 |
| 3 | **Frecuencia de audio** | Un llanto lejano en la cocina (ejemplo del GDD) | 10 |
| 4 | **Sintonizador** | Voces apagadas de otra tele, a través del techo | 15 |
| 5 | **Mando a distancia** | El clic de un mando en una habitación vacía; algo cae al suelo | 22 |
| 6 | **Canal 3** | Toques en la puerta (anticipan al repartidor; el 3 es el piso de la señora) | 28 |

**Centrados en el clic (cambio del usuario, 2026-11-18):** cada generador suma Energía a cada clic (su bono, al que también afectan *Pulso* y *Pulso fuerte*) y produce algo por segundo, menos que antes. Con el ajuste, el clic (manual, mantenido o automático) da ~3/4 de la Energía desde el minuto 15. La tienda muestra en cada generador lo que suma por clic y por segundo, y el panel muestra «Por clic».

**Árbol de mejoras (2026-11-18):** cada mejora tiene un padre (`requires_id`) y solo aparece cuando el padre está comprado: *Pulso* es la raíz de la línea de los clics (de ella salen *Pulso fuerte*, *Dial firme* y *Resonancia* → *Dial solo* → *Dial solo II*) y cada ×2 (25) cuelga de su ×2 (10). La cadena de generadores solo se dibuja: exigir el anterior retrasaba al jugador tranquilo. Con este árbol el test de ritmo sigue en verde sin cambiar los números.

Mejoras de generador: **×2 al tener 10** de un generador y otra vez **al tener 25** (12 mejoras). El coste de cada generador crece en torno a ×1,15 por compra. Los números exactos se ajustan con el test de ritmo del hito 1.

## 4. Interferencias (el evento que premia mirar la tele)

De vez en cuando (cada 2-4 minutos) salen chispas de uno de los cables de la fábrica durante unos 8 segundos (antes: la imagen se llenaba de estática; cambiado el 2026-11-18, `specs/hito2.md` D19). Si el jugador hace clic en ellas, gana una ráfaga instantánea: 15 segundos de producción de golpe (era 60; reducido en el ajuste del hito 1 para que sea un extra y no algo obligatorio) (como mínimo, 50 clics; detalle en `specs/hito1.md`, D7).

- **Por qué:** da un motivo para mirar la tele, mientras que el director de miedo da motivos para mirar el piso. El jugador tiene que repartir su atención, que es el núcleo de la tensión (pilar 3: premiar la atención).
- **Lectura de terror:** muy de vez en cuando, la estática deja ver un fotograma de algo que no debería estar ahí (por ejemplo, el salón del 3.º). Eso lo decide y lo programa el director (hito 3) y cuenta dentro del tope de destellos (GDD §11). No es un jumpscare.
- Nunca es obligatoria: quien no la atrapa solo tarda un poco más.

## 5. Reiniciar y Carga (aprobado)

- *Reiniciar* se habilita al alcanzar el umbral de Energía de la run (Energía producida en esa run). Después, el jugador decide cuándo pulsarlo.
- **Carga ganada:** 3 al llegar al umbral, y más si espera, con rendimiento decreciente (por ejemplo, 4 veces el umbral da 6).
- **El precio de esperar:** quedarse más tiempo en la run significa más tiempo con el piso sonando cada vez peor. Es una decisión de terror, no solo de números.
- Hay 4 reinicios en toda la partida, así que la Carga total está entre unas 12 y 20.

## 6. Mejoras permanentes (Carga): una sola rama (aprobado)

Se compran en orden. Se conservan al reiniciar y se pierden en una partida nueva (GDD §3). Cada una es una parte del protagonista que la tele se queda («cada reinicio te deja más dentro», GDD §2).

| Orden | Mejora | Coste | Efecto |
|---|---|---|---|
| 1 | **Tus manos** | 1 | Cada run empieza con *Dial firme* y *Dial solo* ya comprados: la tele hace clic sola desde el primer segundo |
| 2 | **Tu memoria** | 2 | Cada run empieza con 10 Antenas y 5 Válvulas |
| 3 | **Tu costumbre** | 3 | Los generadores cuestan un 25 % menos |
| 4 | **Tu paciencia** | 4 | Toda la producción ×2 |
| 5 | **Tu nombre** | 6 | +1 Carga en cada reinicio. La tele muestra el nombre del protagonista en una esquina |

Coste total: 16 Carga. Quien reinicia en cuanto puede llega a la run 4 con unas 4 mejoras; quien espera, con las 5. Los efectos exactos se ajustan en los hitos 4 y 5 para que las runs duren 35 / 25 / 20 / 15 min.

## 7. Runs 2-4

Los mismos 6 generadores, que empiezan de cero en cada run (salvo lo que dé *Tu memoria*). Su efecto en el mundo pasa a ser visible: luces, objetos que cambian de sitio (GDD §3). Cada run tiene su propio umbral, que se fija en los hitos 4 y 5. En la run 3, la tele de la señora muestra el mismo progreso (GDD §3).

## 8. Ritmo objetivo de la run 1 (rangos para el test del hito 1)

- Primera compra antes de 15 s.
- Algo nuevo que comprar cada 2-3 minutos; un generador nuevo cada 5-6 minutos.
- Entre 3 y 8 compras por minuto en los primeros 15 minutos, y al menos 1,5 por minuto después.
- *Reiniciar* se habilita a los 35 min (±5) tanto para quien hace clic mucho como para quien casi no lo hace (simulado con 0,5 y 6 clics por segundo, con y sin interferencias).

## 9. Qué entra en el hito 1

Solo la run 1: los 6 generadores, todas las mejoras de la run (clics y generadores), las interferencias (sin el fotograma de terror, que es del director, hito 3), el umbral, *Reiniciar* (vacía la Energía y suma una run), la UI plana y un sonido provisional por compra. La Carga y las mejoras permanentes llegan en el hito 4 (GDD §11).
