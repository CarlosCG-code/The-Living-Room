"""Sintetiza los avisos sonoros de los eventos de la tele (sin assets externos).

Uso: python tools/build_tv_sounds.py  -> assets/audio/tv/event_*.wav (22 050 Hz, 16 bits, mono).
Cada evento tiene un sonido propio y siempre el mismo, para que el jugador lo aprenda. Volumen moderado:
avisan, no asustan (la silueta entra con un zumbido grave que crece despacio, no con un golpe).
"""
import math
import os
import random
import struct
import wave

RATE = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio", "tv")


def save(name, samples):
    os.makedirs(OUT, exist_ok=True)
    peak = max(1e-9, max(abs(x) for x in samples))
    gain = 0.7 / peak
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, x * gain)) * 32767)) for x in samples))


def env(t, length, attack, release):
    a = min(1.0, t / attack) if attack > 0 else 1.0
    r = min(1.0, (length - t) / release) if release > 0 else 1.0
    return max(0.0, min(a, r))


def interference():
    # Chisporroteo eléctrico: chasquidos sueltos sobre un zumbido de 100 Hz.
    rng = random.Random(1)
    n = int(RATE * 0.7)
    out = []
    crackle = 0.0
    for i in range(n):
        t = i / RATE
        if rng.random() < 0.004:
            crackle = rng.uniform(0.6, 1.0) * rng.choice([-1, 1])
        crackle *= 0.93
        hum = 0.25 * (1 if math.sin(2 * math.pi * 100 * t) > 0 else -1)
        out.append((crackle + hum * 0.4 + rng.uniform(-0.05, 0.05)) * env(t, 0.7, 0.01, 0.3))
    return out


def shooting_star():
    # Campanilla que sube: barrido de 1500 a 2400 Hz con un brillo de armónico y trémolo.
    n = int(RATE * 0.9)
    out = []
    phase = 0.0
    for i in range(n):
        t = i / RATE
        f = 1500 + 900 * (t / 0.9)
        phase += 2 * math.pi * f / RATE
        trem = 0.75 + 0.25 * math.sin(2 * math.pi * 14 * t)
        out.append((math.sin(phase) + 0.3 * math.sin(phase * 2.01)) * trem * env(t, 0.9, 0.02, 0.6))
    return out


def silhouette():
    # Zumbido grave y desafinado que crece y se va (55 y 58 Hz batiendo), con un poco de soplido.
    rng = random.Random(2)
    n = int(RATE * 2.2)
    out = []
    noise = 0.0
    for i in range(n):
        t = i / RATE
        noise = noise * 0.98 + rng.uniform(-1, 1) * 0.02
        tone = math.sin(2 * math.pi * 55 * t) + math.sin(2 * math.pi * 58.3 * t) + 0.4 * math.sin(2 * math.pi * 110 * t)
        out.append((tone * 0.5 + noise * 3.0) * env(t, 2.2, 1.0, 0.9))
    return out


def clear_signal():
    # Acorde mayor suave (do, mi, sol) que se abre y se apaga: la señal limpia.
    n = int(RATE * 1.4)
    out = []
    for i in range(n):
        t = i / RATE
        chord = sum(math.sin(2 * math.pi * f * t) for f in (523.25, 659.25, 783.99))
        out.append(chord * env(t, 1.4, 0.15, 0.9))
    return out


if __name__ == "__main__":
    save("event_interference", interference())
    save("event_shooting_star", shooting_star())
    save("event_silhouette", silhouette())
    save("event_clear_signal", clear_signal())
    print("SOUNDS_OK")
