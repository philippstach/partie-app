#!/usr/bin/env python3
"""Erzeugt die Soundeffekte von Schocken (iOS/Schocken/Sounds/*.wav).

Alle Töne sind hier per Synthese selbst erzeugt – keine fremden Samples,
keine Lizenz nötig. Neu erzeugen: python3 Tools/make_sounds.py
"""
import math, random, struct, wave
from pathlib import Path

RATE = 44100
OUT = Path(__file__).resolve().parent.parent / "iOS" / "Schocken" / "Sounds"


def tone(freq, dur, vol=0.3, attack=0.005, decay=None, shape="sine", glide=None):
    n = int(RATE * dur)
    decay = decay or dur
    out, phase = [], 0.0
    for i in range(n):
        t = i / RATE
        f = freq if glide is None else freq + (glide - freq) * (t / dur)
        phase += 2 * math.pi * f / RATE
        s = math.sin(phase)
        if shape == "tri":
            s = 2 / math.pi * math.asin(s)
        env = min(1.0, t / attack) * math.exp(-t / (decay / 5))
        out.append(s * env * vol)
    return out


def click(dur=0.018, vol=0.35, rng=random.Random(7)):
    n = int(RATE * dur)
    return [(rng.random() * 2 - 1) * vol * math.exp(-i / (n / 6)) for i in range(n)]


def silence(dur):
    return [0.0] * int(RATE * dur)


def mix(*parts):
    """Legt (offset_sekunden, samples) übereinander."""
    length = max(int(o * RATE) + len(s) for o, s in parts)
    buf = [0.0] * length
    for o, s in parts:
        start = int(o * RATE)
        for i, v in enumerate(s):
            buf[start + i] += v
    return buf


def save(name, samples):
    OUT.mkdir(parents=True, exist_ok=True)
    peak = max(1e-9, max(abs(s) for s in samples))
    scale = min(1.0, 0.9 / peak)
    with wave.open(str(OUT / f"{name}.wav"), "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(s * scale * 32767)) for s in samples))


rng = random.Random(42)
# Würfeln: mehrere kurze Klacker, unregelmäßig verteilt
save("roll", mix(*[(0.03 + i * 0.055 + rng.random() * 0.02,
                    [v * 0.7 for v in click()] + tone(600 + rng.random() * 500, 0.03, 0.12, shape="tri"))
                   for i in range(6)]))
# Würfel herauslegen: kurzer, heller Tick
save("select", tone(1400, 0.06, 0.25, attack=0.002, shape="tri"))
# Sechsen umdrehen: kurzer Klick mit kleinem Ton
save("flip", mix((0, click(0.012, 0.3)), (0.01, tone(900, 0.07, 0.2, shape="tri", glide=1300))))
# Schock / General / Straße: zwei helle Töne
save("good", mix((0, tone(784, 0.14, 0.28)), (0.1, tone(1175, 0.22, 0.28))))
# Schock aus: kurze Fanfare
save("schockaus", mix(*[(i * 0.09, tone(f, 0.3 if i < 4 else 0.7, 0.28)) for i, f in enumerate([523, 659, 784, 1047, 1319])]))
# Deckel landet: dumpfer Klack
save("deckel", mix((0, tone(220, 0.08, 0.35, attack=0.001, shape="tri", glide=140)), (0, click(0.01, 0.25))))
# Würfel landet: kurzer, heller Klack
save("klack", mix((0, click(0.008, 0.3)), (0, tone(1100, 0.035, 0.22, attack=0.001, shape="tri", glide=700))))
# Partie vorbei: kleine Dur-Fanfare
save("end", mix(*[(i * 0.11, tone(f, 0.35 if i < 3 else 0.7, 0.28)) for i, f in enumerate([523, 659, 784, 1047])]))
print("OK:", sorted(p.name for p in OUT.glob("*.wav")))
