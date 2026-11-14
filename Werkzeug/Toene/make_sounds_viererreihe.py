#!/usr/bin/env python3
"""Erzeugt die Soundeffekte der App (iOS/VierGewinnt/Sounds/*.wav).

Alle Töne sind hier per Synthese selbst erzeugt – keine fremden Samples, keine Lizenz nötig.
Neu erzeugen: python3 Tools/make_sounds.py
"""
import math, random, struct, wave
from pathlib import Path

RATE = 44100
OUT = Path(__file__).resolve().parent.parent / "iOS" / "VierGewinnt" / "Sounds"


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


# Stein landet: kurzer, dumpfer Klack (tiefer Ton mit schnellem Abfall plus ein Hauch Klick)
save("drop", mix((0, tone(180, 0.09, 0.5, attack=0.001, decay=0.09, glide=110)),
                 (0, [v * 0.6 for v in click(0.012, 0.35)]),
                 (0.0, tone(360, 0.04, 0.12, attack=0.001, shape="tri"))))
# Spalte wechseln: kurzer, heller Tick, leise
save("select", tone(1400, 0.05, 0.18, attack=0.002, shape="tri"))
# Rückgängig: kurzes Wischen aufwärts
save("undo", tone(420, 0.16, 0.22, attack=0.004, decay=0.16, shape="tri", glide=760))
# Gewonnen: kleine Dur-Fanfare
save("win", mix(*[(i * 0.11, tone(f, 0.35 if i < 3 else 0.7, 0.28)) for i, f in enumerate([523, 659, 784, 1047])]))
# Verloren: zwei weiche fallende Töne
save("lose", mix((0, tone(392, 0.28, 0.26, shape="tri", glide=349)), (0.2, tone(311, 0.42, 0.24, shape="tri", glide=262))))
# Unentschieden: zwei gleiche weiche Töne
save("draw", mix((0, tone(440, 0.22, 0.24, shape="tri")), (0.24, tone(440, 0.34, 0.22, shape="tri"))))
# Brett leeren: kurzes Prasseln, 8 Klacke in etwa 300 ms (jeder etwas anders)
_r = random.Random(11)
save("leeren", mix(*[(0.012 + i * 0.038 + _r.random() * 0.012,
                      [v * (0.55 + 0.1 * _r.random()) for v in click(0.014, 0.4)] + tone(150 + _r.random() * 90, 0.07, 0.34, attack=0.001, decay=0.07))
                     for i in range(8)]))
# Tipp: leiser, kurzer Ping
save("ping", mix((0, tone(1320, 0.16, 0.16, attack=0.003, decay=0.16)), (0.0, tone(1980, 0.08, 0.05, attack=0.002, decay=0.08))))
print("OK:", sorted(p.name for p in OUT.glob("*.wav")))
