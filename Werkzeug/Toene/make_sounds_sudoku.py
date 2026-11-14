#!/usr/bin/env python3
"""Erzeugt die Soundeffekte der App (iOS/Sudoku/Sounds/*.wav).

Alle Töne sind hier per Synthese selbst erzeugt – keine fremden Samples,
keine Lizenz nötig. Neu erzeugen: python3 Tools/make_sounds.py
"""
import math, struct, wave
from pathlib import Path

RATE = 44100
OUT = Path(__file__).resolve().parent.parent / "iOS" / "Sudoku" / "Sounds"


def tone(freq, dur, vol=0.3, attack=0.004, shape="sine", glide=None):
    n = int(RATE * dur)
    out, phase = [], 0.0
    for i in range(n):
        t = i / RATE
        f = freq if glide is None else freq + (glide - freq) * (t / dur)
        phase += 2 * math.pi * f / RATE
        s = math.sin(phase)
        if shape == "tri":
            s = 2 / math.pi * math.asin(s)
        env = min(1.0, t / attack) * math.exp(-t / (dur / 5))
        out.append(s * env * vol)
    return out


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


# Zahl eingetragen: kurzes, weiches Tock
save("place", mix((0, tone(520, 0.09, 0.35, shape="tri")), (0, tone(1040, 0.05, 0.08))))
# Falsche Zahl: tiefer, kurzer Abwärtston
save("error", mix((0, tone(220, 0.22, 0.35, shape="tri", glide=150))))
# Zeile/Spalte/Box fertig: zwei aufsteigende Töne
save("complete", mix((0, tone(660, 0.14, 0.28)), (0.09, tone(880, 0.22, 0.28))))
# Gewonnen: aufsteigender Dur-Akkord
save("win", mix(*[(i * 0.11, tone(f, 0.55, 0.25)) for i, f in enumerate([523.25, 659.25, 783.99, 1046.5])]))
