# Incremental v2 — diseño completo (propuesta, 2026-11-18)

> Estado: **aprobada por el usuario (2026-11-18)**, con Carga en cualquier orden y curvatura de la imagen (cambia D5). Sustituye, si se aprueba, al árbol de la run 1 y a las mejoras permanentes de `specs/incremental.md` §4 y §6. Sale de cuatro investigaciones (mejoras de otros incrementales, estética de terror, cristal CRT y revisión de nuestro código con el test de ritmo). Fuentes al final.

## 0. Diagnóstico (test de ritmo actual)

- **Clicar no compensa:** el jugador activo (6 clics/s) llega al umbral en 34,0 min y el que solo mantiene pulsado en 36,3. *Dial firme* da lo mismo que clicar.
- **El clic lo llevan los generadores:** más del 99 % del valor de un clic sale del bono por clic de las máquinas; las mejoras de clic suman ×4 en total.
- **Mejoras planas:** 14 de 18 son ×2, y el 94 % de las compras son "otra unidad de generador". *Mando ×4* y *Canal 3 ×4* no llegan a aparecer.
- **Tramos muertos:** 8 huecos de más de 2 min sin nada nuevo; el peor, de 5 min (minuto 28,8 → 33,7).
- **Eventos débiles:** pagan en segundos de producción, pero la producción es solo el 22 % de los ingresos. En el minuto 30, una interferencia equivale a unos 3 s de juego.
- **Estética:** tres acentos de color a la vez (verde fósforo, ámbar y verde aurora); partículas y viñeta con alfa suave, que crean colores fuera de paleta; grano que aclara los negros. Ese es el aire "hecho por IA".

## 1. Principios

1. **El clic a mano es el protagonista:** crítico, racha y cintas solo con el clic a mano. El automático (mantener o *Dial solo*) llena la barra de cinta al 25 % y no hace crítico ni racha, salvo con *Eco*.
2. **Cada compra cambia la tele:** un cambio visible o audible por mejora (pilar 2 del GDD).
3. **Algo nuevo cada 45–90 s** en los primeros 10 minutos y cada 1,5–3 min después. Ningún hueco de más de 2 min (el test lo comprueba hasta el umbral).
4. **El árbol se revela:** solo se ve el siguiente anillo, como silueta "???" con su requisito.
5. **Recompensas en ingresos por segundo**, no en producción, para que cintas y eventos pesen igual al minuto 3 que al 30.
6. **El terror crece con la run:** cuanto más tiempo sigas, más se degrada la tele. Esperar al reinicio es una decisión de terror.

## 2. Mecánicas nuevas

- **Crítico:** probabilidad base del 5 % ×5 en el clic a mano. Número grande en ámbar, 40 ms de pausa y la imagen tiembla 1 px.
- **Racha:** cada clic a menos de 0,4 s del anterior suma; la racha pierde fuerza tras 1,2 s sin clicar. Multiplica el clic, con tope según las mejoras. Se ve como un latido en el OSD que se acelera.
- **Cintas de señal:** al comprar *Sintonía* aparece una barra en el OSD. Cada clic a mano la llena 1 (el automático, 0,25). Al llenarse (60 de base) cae una cinta VHS en la nieve. Clicarla la abre y da una ráfaga de N segundos de ingresos.

  | Rareza | Prob. | Premio | Color |
  |---|---|---|---|
  | Común | 80 % | 20 s de ingresos | gris |
  | Rara | 17 % | 60 s | ámbar |
  | Negra | 3 % | producción ×3 durante 15 s | negro con borde verde; puede traer un fragmento de lore |

  Nunca hay más de 2 cintas a la vez. Si se ignoran, se pierden a los 20 s.
- **Habilidades del mando** (con enfriamiento): iconos en el OSD que se activan con clic o con las teclas 1, 2 y 3. Los clics extra que dan no cuentan para el tope de 10 por segundo.
- **Consumo:** mejoras que dan mucho y cuestan algo en tu salón. Avisan antes de comprarlas ("Notarás algo en casa"), al estilo de la Grandmapocalypse.

## 3. Árbol de la run 1 (30 mejoras + 6 generadores)

Las mejoras se agrupan en seis familias:
- **P**, pulso a mano;
- **D**, dial automático;
- **C**, cintas;
- **H**, habilidades del mando;
- **M**, máquinas;
- **X**, consumo.

Los costes son una primera pasada sobre la curva actual; el test de ritmo los ajusta.

| Min | Mejora | Fam. | Efecto | Cambio en la tele |
|---|---|---|---|---|
| 0:40 | Pulso | P | clic ×2 | el «+N» crece, golpe más sordo |
| 1:00 | Dial firme | D | mantener = 4 clics/s (era 6) | la sombra de una mano sobre el receptor |
| 1:30 | Antena orientada | M | antenas ×2 (con 10) | las antenas giran hacia la fábrica |
| 2:00 | Cable pelado | P | crítico +5 % (→ 10 %) | arco azul por el cable, chasquido |
| 2:45 | Latido | P | racha hasta ×1,5 | latido en el OSD |
| 3:30 | Sintonía | C | aparece la barra de cintas | la estática afina al llenarse |
| 4:30 | Válvulas al blanco | M | clic de las válvulas ×3 | brillo frío en la nieve |
| 5:15 | Barrido | H | 10 s a 10 clics/s; enfriamiento 3 min | la tele salta de canal en canal |
| 6:00 | Descarga | P | crítico ×5 → ×10 | la imagen pierde el sincronismo un instante |
| 7:00 | Ojo atento | C | eventos ×2 de premio y el doble de frecuentes (pide atrapar 1) | queda una imagen fantasma |
| 8:00 | Cada antena escucha | P | clic +2 % por cada generador | cada clic recorre los cables |
| 9:00 | Sintonía fina | C | barra −30 % | segunda bobina, más zumbido |
| 10:00 | Acople | M | Frecuencia +3 % por válvula | pitido; los sonidos de la casa se sincronizan |
| 11:00 | Cinta virgen | C | rara 25 %, negra 6 % | etiqueta ámbar, rebobinado |
| 12:00 | Sobretensión | H | 12 s de clic ×5; enfriamiento 4 min | la chimenea llamea; la lámpara real baja |
| 13:00 | Resonancia | P | el clic a mano suma un 3 % de la producción | los cables vibran con tus clics |
| 14:00 | Taquicardia | P | racha hasta ×2,5 | con la racha al máximo, la nieve sube |
| 15:00 | Puentear el contador | X | producción ×1,5 | se apaga una farola; zumbido en la pared del salón |
| 16:00 | Doble sintonizador | M | sintonizadores ×2 | las voces del techo pasan a ser dos |
| 17:00 | Dial solo | D | 2 clics/s automáticos | el receptor gira solo |
| 18:30 | Sin toma de tierra | P | crítico +5 % (→ 15 %) | el crítico se ve un fotograma en negativo |
| 19:30 | Doble pletina | C | cintas ×2 | a veces cae una segunda cinta sin nombre |
| 20:30 | Buscar señal | H | provoca un evento ya; enfriamiento 5 min | la antena gira sola |
| 21:30 | Zapping | M | todas +2 % por mando | el crítico salta de canal un instante |
| 23:00 | Derivar | X | producción ×2 | la luz del rellano parpadea (la usará el director) |
| 24:30 | Eco | D | los clics automáticos hacen racha y crítico | el dial ya no te necesita |
| ~~26:00~~ | ~~No apartes la vista~~ | C | quitada con la silueta (usuario, 2026-11-19) | |
| 27:30 | Alguien más sintoniza | D | 4 clics/s automáticos | otro «+N» de otro color |
| 29:00 | Cinta sin etiqueta | C | la negra pasa a 12 % y siempre trae lore | suenan tus clics, con retraso |
| 30:30 | Sobrecarga | X | apuesta: mantener Espacio 3 s → 70 % de producción ×5 durante 20 s, o 30 % de tele apagada 8 s | la imagen se encoge a un punto |

**Requisitos para que aparezcan**, al estilo de Cookie Clicker:
- las mejoras de clic, por clics hechos a mano;
- las de cintas, por cintas abiertas;
- las de eventos, por eventos atrapados;
- las de máquina, por unidades del generador.

**Tipos de efecto nuevos** (`UpgradeDef.Kind`, añadidos al final del enum): `CRIT_CHANCE`, `CRIT_MULT`, `COMBO`, `MANUAL_CLICK_MULT`, `CLICK_PER_OWNED`, `GENERATOR_CLICK_MULT`, `GENERATOR_SYNERGY` (`source_id`), `PACKAGE_UNLOCK`, `PACKAGE_RATE`, `PACKAGE_RARITY`, `PACKAGE_REWARD`, `EVENT_REWARD` (objetivo opcional), `EVENT_FREQUENCY`, `SKILL` (`duration`, `cooldown`), `AUTO_ECHO`, `GAMBLE`.

**Campos nuevos:** `value2`, `duration`, `cooldown`, `source_id`, `req_manual_clicks`, `req_packages`, `req_events_caught`, `tree_cell: Vector2i` y `warning_key` (para las de consumo). Las posiciones del árbol salen del dato: rejilla de 10 × 5.

## 4. Mejoras permanentes (Carga)

Se compran **en cualquier orden** (antes era en orden fijo, una queja de *Click the Button*). Total: 17 de Carga. Quien reinicia en cuanto puede llega a la run 4 con unas 4; quien espera, con las 6. Nunca más de 2 a la vez.

| Coste | Perk | Qué cambia |
|---|---|---|
| 2 | Tu memoria | empiezas con 10 Antenas, 5 Válvulas, Pulso y Dial firme |
| 2 | Tus manos | la racha aguanta 3 s sin clicar y cada crítico llena un 20 % de la barra de cinta |
| 3 | Tus ojos | eventos cada 1–2 min y desvela la rama escondida (§11) |
| 3 | Tu costumbre | generadores −25 %; las mejoras de máquina piden la mitad de unidades |
| 3 | Tu pulso | clic a mano ×2 |
| 4 | Tu nombre | tu nombre aparece en el OSD y en las cintas; la tabla de récords te reconoce (lore) |

## 5. Dirección de arte: más sombrío

- **Paleta fija de 12 colores**, aplicada con un pase de cuantización en la tele. Todo lo que se dibuja cae en ella.
  - Sombras: `#05060B` `#0B0E16` `#151A24` `#232A36`.
  - Nieve y niebla: `#3A4250` `#5B6370` `#8A8F96` (gris azulado, nunca blanca).
  - OSD: `#9FD9AE` y `#4E7A5C`.
  - **Único acento:** ámbar de ventana, `#E0A048` y `#7A4A1E`.
  - Rojo `#8C2A22` solo en la fase final.
- **Valores:** el 70 % de la imagen por debajo del 15 % de luminancia. Solo las ventanas y el OSD pasan del 60 %.
- **Fuera:** alfa suave en nieve, humo y viñeta (pasan a tramado), aurora verde (pasa al verde del OSD), azul alegre del menú de mejoras (pasa a `#1C2A4A` desaturado), grano que aclara (ya hecho).
- **Animación a 10 fps**, como stop-motion. Una sola anomalía a la vez. La silueta nunca se mueve mientras se la mira. Parpadeos a 2 Hz como mucho, y nada de rojo intermitente.
- **Persistencia de fósforo** leve en el mundo, no en el OSD. Halo solo en las ventanas y el OSD.
- **Textos del OSD con aire oficial** que se vuelven siniestros, al estilo de Local 58 o Paperclips: "NO APAGUE EL RECEPTOR" o un botón llamado "[Derivar]".

## 6. Terror progresivo (f = fracción del umbral; R = número de run)

1. **f 0,2–0,9:** las ventanas de la fábrica se apagan de una en una (el juego consume la corriente). En la R4 queda una sola encendida.
2. **f > 0,5:** la nieve se vuelve más gris y más lenta. En la R3 se para en el aire 1 s de vez en cuando.
3. **f > 0,6:** los pulsos de los cables laten irregulares, como un corazón.
4. **f > 0,7:** el bosque se aclara; los árboles desaparecen entre eventos, nunca mientras se miran.
5. **f > 0,85:** el OSD pierde precisión: dígitos que cambian un fotograma.
6. ~~**La silueta, run a run:**~~ (quitada, usuario 2026-11-19) R1 lejos y en el borde; R2 en el lado espejado; R3 junto a la fábrica; R4 justo detrás del cristal, quieta y sin ojos.
7. **R2:** a mitad de run, el mundo de la tele se espeja; el OSD no.
8. **R4:** el OSD muestra tus cifras de runs anteriores como si fueran "de otro espectador".
9. **Al pulsar Reiniciar:** carta de "FIN DE LA EMISIÓN" con un tono de prueba que desafina, y después la pantalla de Carga.
10. **Los eventos alegres pierden color:** en la R4, la aurora sale gris.

## 7. Lore (quitado el 2026-11-19, §11)

- Fragmentos a 0,25 / 0,5 / 0,75 / 1 / 1,5 / 2,5 / 4 × el umbral, y en las cintas negras.
- **"Emisión del 3.º":** rutina de la señora con doble lectura.
- **Tabla de récords:** nombres con cientos de reinicios y una línea vacía; con *Tu nombre*, la tuya.
- No suman Evidencia.

## 8. Sonido

- **Ambiente de la tele:** zumbido de red a 50 Hz con armónicos, dron grave casi subsónico y un silbido de ~8 kHz filtrado que solo sube en las anomalías. Nada de pitido de 15,7 kHz. Los silencios se alargan con la run.
- **Clic:** relé mecánico seco, con tono variable, que se ensucia con f.
- Todo sintetizado por script o CC0 de Freesound, con la licencia comprobada y registrado en `ASSETS.md`.

## 9. Cristal y pantalla

Hecho el 2026-11-18 (`797ebf0`):
- imagen como emisión y cristal con luz;
- reflejo de la sonda;
- brillo de la lámpara;
- abombado en la normal;
- muestreo nítido;
- sombra del marco;
- halo de medio a ultra.

**Opcional, cambia D5:** curvar también la imagen (barrel de crt-lottes, k = 0,031 / 0,041). Los clics siguen bien: se aplica la misma función al punto clicado, con test. Hay que dejar unos 8 px libres en el borde del OSD.

## Estado de la implementación (2026-11-18)

Pasos 1-7 hechos (commits 7201eb0 → este). Ajustes respecto a la propuesta, medidos con el test de ritmo:
- Umbral de la run 1: 75 M. Activo 28-31 min, tranquilo 39-47 min (rangos del test: 26-32 y 35-47).
- Crítico: base 0 %; Cable pelado 8 % ×3, Descarga ×4, Sin toma de tierra +4 %. Racha ×1,2 / ×1,35.
- Cintas: 300 clics, 8 / 24 s de ingresos; mantener pulsado llena la mitad y hace racha (sin crítico).
- Permanentes: Tu memoria (15 Antenas, 10 Válvulas, 5 Frecuencias y las primeras mejoras), Tus manos
  (racha 3 s, crítico llena un 3 % de la barra), Tu costumbre −35 %, Tu pulso ×1,4, Tu nombre ×1,2.
  Cada una acorta la run 2 un 5-25 %; con las seis dura ~11 min (test).
- Pendiente para más adelante: espejo del mundo de la tele en la run 2, árboles que desaparecen, cifras de
  runs anteriores en la run 4 y el aviso previo de «Tus ojos».

## 11. Árbol que crece con los reinicios (aprobado por el usuario, 2026-11-19)

Problema: todo el árbol se compraba en la run 1 y las runs 2-4 repetían lo mismo más deprisa. Cambios:
- **Ramas por run** (`UpgradeDef.req_run`; en el árbol salen como «???» con «Aún no. Algo cambia cada vez
  que reinicias»):
  - run 1: pulso, dial, máquinas y cintas básicas, más ×2 de cada máquina al tener muchas (Antena 25,
    Válvulas 25, Frecuencia 20, Mando 10 y 20, Canal 3 9 y 20), *Eco* y *Zapping*;
  - run 2: habilidades del mando (*Barrido*, *Sobretensión*, *Buscar señal*), *Sin toma de tierra* y *Doble pletina*;
  - run 3: consumo (*Puentear*, *Derivar*), *Cinta sin etiqueta*;
  - run 4: *Sobrecarga* y *Alguien más sintoniza*.
- **Techo:** *Zapping*, *Sin toma de tierra*, *Derivar* y *Alguien más sintoniza* cuestan 0,8 × el umbral.
  Quien reinicia en cuanto puede no las compra; quien aguanta en la tele, sí.
- **Rama escondida** (`UpgradeDef.req_perk`): *Tus ojos* ya no sube la siguiente cinta; desvela *Imagen
  fantasma* (eventos ×3), *Manos de estática* (clic a mano ×3) y *Señal fantasma* (producción ×2,5), que no
  se ven ni como «???» sin ella.
- **Umbral:** 45 M (× 1,4 en la run 4, `EconomyConfig.threshold_mult`).
- **Lore quitado** (petición del usuario): distraía de la tele; la historia se cuenta en el piso.
- **Test de ritmo de las 4 runs** (jugador activo, reinicia al umbral, gasta la Carga en orden): 27,9 / 20,5 /
  16,9 / 13,6 min. Cada run trae mejoras nuevas y en las runs 1-3 queda algo por comprar. Novedades cada
  2,3-2,6 min en la segunda mitad de la run 1 (tope del test: 165 s).
- Con las seis permanentes (17 de Carga) la run 4 dura 8,4 min: el final se dispara. Se acepta como premio a
  quien esperó; revisar en el playtest.

## 10. Orden de implementación

1. **Núcleo:** tipos nuevos, crítico, racha, cintas, habilidades y requisitos; datos y test de ritmo con rangos por perfil (activo 28–34 min, tranquilo 34–40). Guardado v4 con migrador: devuelve en Carga los perks comprados.
2. **Árbol nuevo en la tele:** rejilla desde los datos, revelado por anillos, unos 22 iconos nuevos, habilidades en el OSD y cintas en la nieve.
3. **Respuesta a cada clic:** números, crítico, temblor, chispas y tono.
4. **Dirección de arte:** paleta cuantizada, tramado, 10 fps y menú desaturado.
5. **Terror progresivo y fin de emisión.**
6. **Sonido.**
7. **Lore.**
8. **Opcional:** curvatura.

Cada paso con tests en headless y capturas, y una parada para que lo pruebes al final de los pasos 2, 4 y 7.

## Fuentes

- Cookie Clicker: https://cookieclicker.wiki.gg/wiki/Upgrades · https://cookieclicker.wiki.gg/wiki/Grandmapocalypse · https://cookieclicker.wiki.gg/wiki/Golden_Cookie
- Clicker Heroes: https://clickerheroes.fandom.com/wiki/Skills
- Universal Paperclips: https://www.decisionproblem.com/paperclips/projects.js · https://if50.substack.com/p/2017-universal-paperclips
- Gnorp Apologue: https://www.gamedeveloper.com/design/interview-the-gnorp-apologue
- Nodebuster: https://vaporlens.app/app/3107330/nodebuster.md
- Click the Button: https://steamcommunity.com/app/3946950/reviews/
- Math of idle games: https://www.gamedeveloper.com/design/the-math-of-idle-games-part-iii
- Analog horror: https://www.dreadcentral.com/editorials/534205/local58-and-the-birth-of-analog-horror · https://thevaultpublication.com/2022/02/08/the-elements-of-analog-horror
- Paletas: https://www.slynyrd.com/blog/2018/1/10/pixelblog-1-color-palettes · https://dev.to/handsupmin/why-ai-pixel-art-looks-fake-and-how-i-turned-it-into-real-pixel-art-5b1b
- Zumbido de CRT: https://nostos.pages.dev/guides/the-crt-whine-understanding-high-frequency-analog-audio
- Accesibilidad: https://www.w3.org/WAI/WCAG21/Understanding/three-flashes-or-below-threshold
