# Etapa 8 — Zoom out intermedio: `specs/hito2.md`

Revisor: **zoom out**. Comprueba qué cambió tras las etapas 5-7 y si el diseño encaja con el plan.

**Veredicto:** se aprueba con cambios. Los puntos de la etapa 5 están **todos resueltos**. La spec creció mucho, pero casi todo responde a hallazgos o a tus decisiones, y no hay sistemas especulativos. Quedan tres importantes, que conviene arreglar antes de la etapa 9.

## 🟡 Importantes

1. **Nadie hace las conexiones de la escena.**
   - **Problema:** D1 dice que `main.tscn` coloca la tele y la cámara en las anclas y conecta las piezas, y D14 dice que el salón refleja sus nodos «por código». Pero `main.gd` está marcado «sin cambios» y el salón no tiene script.
   - **Lo que queda sin dueño:**
     - leer las anclas después de aplicar el espejo;
     - aplicar el espejo;
     - darle a `LightMixer` las luces del salón, la de la pantalla y la linterna;
     - de dónde sale el estado de la tele (interferencia, apagada);
     - aplicar el preset por defecto al arrancar.
   - **Cambio:** `main.gd` es el punto de montaje: lee las anclas, crea `LightMixer` y aplica el preset. El salón tiene un `living_room.gd` pequeño con la opción «espejo». El estado de la tele sale de lo que `Game` ya expone (`economy.interference_active()`), que la tele lee porque es de presentación.
2. **El preset bajo pierde su luz base.**
   - **Problema:** D9 saca la luz base de la sonda de reflejos, pero la tabla apaga la sonda justo en el preset bajo.
   - **Cambio:** la luz base sale de la luz ambiente del `WorldEnvironment` (un color por estado de iluminación), que es el mecanismo normal de Godot, no cuesta nada y no depende de la sonda. La sonda solo hace reflejos.
3. **El preset por defecto no es el que se aprueba [tú].** El aspecto se aprueba sobre todo en el preset alto, pero hasta el hito 7 todo el mundo jugará con el medio, sin iluminación global ni niebla. Eso incluye el playtest del hito 4. Hay dos opciones:
   - **(a)** el preset por defecto es el alto hasta el hito 7;
   - **(b)** la parada del look-dev aprueba el alto y el medio, con capturas de los dos.

## 🟢 Menores

4. **El factor de `LightMixer` decide algo del hito 3:** el GDD deja al hito 3 decidir cómo leen la producción las luces. **Cambio:** `LightMixer` sigue siendo el único que escribe la intensidad, pero el factor queda solo como propuesta para el hito 3.
5. **La interpolación de `reveal` sin pose final:** en este hito solo se usa `reveal` = 0. **Cambio:** la cámara se coloca en la pose de `reveal` = 0, y la interpolación llega en el hito 3, junto con su pose final.
6. **`tv_input` independiente del origen del rayo:** recibe un rayo (origen y dirección) y los eventos de botón y rueda. La cámara decide de dónde sale el rayo: ahora el cursor del sistema; en el hito 3, el cursor virtual. Así el hito 3 añade el modo híbrido sin tocar el reenvío.
7. **El brillo no tiene uso todavía:** el valor no se puede cambiar hasta el hito 7. **Cambio:** queda como un multiplicador de exposición en `GraphicsSettings`, sin test propio, y la pantalla de calibración llega en el hito 7.

## Sin problemas
- Las carpetas encajan con la arquitectura.
- La UI del hito 1 se reutiliza tal cual (solo cambia su tema).
- No hay piezas duplicadas en el código existente.
- El alcance está justificado por lo que pediste.
