"""Sintetiza los avisos sonoros de los eventos de la tele (sin assets externos).

Uso: python tools/build_tv_sounds.py  -> assets/audio/tv/event_*.wav (22 050 Hz, 16 bits, mono).
Cada evento tiene un sonido propio y siempre el mismo, para que el jugador lo aprenda. Volumen moderado:
avisan, no asustan.
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


def clear_signal():
    # Acorde mayor suave (do, mi, sol) que se abre y se apaga: la señal limpia.
    n = int(RATE * 1.4)
    out = []
    for i in range(n):
        t = i / RATE
        chord = sum(math.sin(2 * math.pi * f * t) for f in (523.25, 659.25, 783.99))
        out.append(chord * env(t, 1.4, 0.15, 0.9))
    return out


def click_relay():
    # Relé mecánico seco: un chasquido de ruido muy corto y un golpe grave que se apaga en 60 ms.
    rng = random.Random(3)
    n = int(RATE * 0.07)
    out = []
    for i in range(n):
        t = i / RATE
        snap = rng.uniform(-1, 1) * math.exp(-t * 400)
        body = math.sin(2 * math.pi * 180 * t) * math.exp(-t * 60) * 0.6
        out.append(snap + body)
    return out


def test_tone():
    # Tono de prueba de 1 kHz que desafina hacia abajo y se ensucia: el fin de la emisión.
    n = int(RATE * 2.5)
    out = []
    phase = 0.0
    for i in range(n):
        t = i / RATE
        f = 1000 - 140 * (t / 2.5) ** 2
        phase += 2 * math.pi * f / RATE
        out.append((math.sin(phase) + 0.15 * math.sin(phase * 3.01)) * env(t, 2.5, 0.02, 0.4))
    return out


def tv_hum():
    # Zumbido de la tele en bucle (4 s, ciclos enteros): red a 50 Hz con armónicos, un siseo muy bajo y algún
    # chasquido. Nada de pitido de 15,7 kHz: cansa y mucha gente no lo oye.
    rng = random.Random(4)
    n = RATE * 4
    out = []
    hiss = 0.0
    for i in range(n):
        t = i / RATE
        hum = 0.6 * math.sin(2 * math.pi * 50 * t) + 0.3 * math.sin(2 * math.pi * 100 * t)             + 0.15 * math.sin(2 * math.pi * 150 * t)
        hiss = hiss * 0.6 + rng.uniform(-1, 1) * 0.4
        crackle = rng.uniform(-1, 1) if rng.random() < 0.0004 else 0.0
        out.append(hum * 0.5 + hiss * 0.06 + crackle * 0.3)
    return out


def drone():
    # Dron casi subsónico en bucle (8 s): 38 y 41 Hz batiendo y un armónico que respira.
    n = RATE * 8
    out = []
    for i in range(n):
        t = i / RATE
        breath = 0.6 + 0.4 * math.sin(2 * math.pi * t / 8)
        out.append((math.sin(2 * math.pi * 38 * t) + math.sin(2 * math.pi * 41 * t)
                    + 0.3 * math.sin(2 * math.pi * 76 * t) * breath) * 0.5)
    return out


if __name__ == "__main__":
    save("tv_hum", tv_hum())
    save("drone", drone())
    save("test_tone", test_tone())
    save("click_relay", click_relay())
    save("event_interference", interference())
    save("event_shooting_star", shooting_star())
    save("event_clear_signal", clear_signal())
    print("SOUNDS_OK")
