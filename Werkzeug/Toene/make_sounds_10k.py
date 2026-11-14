#!/usr/bin/env python3
"""Erzeugt die Soundeffekte der App (TenK/Sounds/*.wav).

Alle Töne sind hier per Synthese selbst erzeugt – keine fremden Samples,
keine Lizenz nötig. Neu erzeugen: python3 Tools/make_sounds.py
"""
import math, random, struct, wave
from pathlib import Path

RATE = 44100
OUT = Path(__file__).resolve().parent.parent / "TenK" / "Sounds"


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


def save(name, samples, peak=0.9):
    OUT.mkdir(parents=True, exist_ok=True)
    scale = min(1.0, peak / max(1e-9, max(abs(v) for v in samples)))
    with wave.open(str(OUT / f"{name}.wav"), "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(s * scale * 32767)) for s in samples))


def brass(freq, dur, vol=0.25, glide=None, vibrato=0.0):
    """Gedämpfter Blechbläser-Ton (einige Obertöne, weicher Einsatz, optional Vibrato)."""
    n = int(RATE * dur)
    out, phase = [], 0.0
    for i in range(n):
        t = i / RATE
        f = freq if glide is None else freq + (glide - freq) * (t / dur)
        f *= 1 + vibrato * math.sin(2 * math.pi * 6 * t) * min(1.0, t / 0.15)
        phase += 2 * math.pi * f / RATE
        s = sum(math.sin(phase * h) / h ** 1.3 for h in range(1, 6))
        env = min(1.0, t / 0.03) * min(1.0, (dur - t) / 0.06)
        out.append(s * env * vol)
    return out


rng = random.Random(42)
# Würfeln: mehrere kurze Klacker, unregelmäßig verteilt
save("roll", mix(*[(0.03 + i * 0.055 + rng.random() * 0.02,
                    [v * 0.7 for v in click()] + tone(600 + rng.random() * 500, 0.03, 0.12, shape="tri"))
                   for i in range(6)]))
# Würfel auswählen: kurzer, heller Tick
save("select", tone(1400, 0.06, 0.25, attack=0.002, shape="tri"))
# Punkte sichern: zwei aufsteigende Töne
save("bank", mix((0, tone(660, 0.12, 0.3)), (0.08, tone(990, 0.18, 0.3))))
# Niete: zwei absteigende, gedämpfte Töne. 1.0.1 (8): eine Oktave höher und mit Obertönen –
# die alte Fassung (330→180 Hz, fast reiner Dreieckston) gibt der iPhone-Lautsprecher kaum wieder.
save("niete", mix((0, brass(660, 0.32, 0.3, glide=380)), (0.12, brass(494, 0.34, 0.22, glide=280))))
# Sieg: Dur-Fanfare, Schlussakkord und goldenes Glitzern
fanfare = [(i * 0.11, tone(f, 0.35, 0.28)) for i, f in enumerate([523, 659, 784])]
chord = [(0.33, tone(f, 1.1, 0.22, decay=1.1)) for f in (523, 659, 784, 1047)]
sparkle = [(0.42 + i * 0.07 + rng.random() * 0.03, tone(1800 + rng.random() * 1400, 0.09, 0.08, attack=0.002, shape="tri"))
           for i in range(10)]
save("win", mix(*(fanfare + chord + sparkle)))
# Alle Würfel punkten („Hot Dice“): schnelles, aufsteigendes Arpeggio
save("hotdice", mix(*[(i * 0.055, tone(f, 0.16, 0.24, attack=0.003, shape="tri"))
                      for i, f in enumerate([660, 830, 990, 1320, 1660])]))


# Strafe nach 3 Nieten („Fail“, siehe Doku/FAIL-TON.md): gedämpfte Posaune, chromatisch abwärts
# G4 → F♯4 → F4 → E4, der letzte lang mit Vibrato und Abfall um einen Halbton; ca. 3 dB leiser als der Sieg
save("fail", mix((0.00, brass(392, 0.17)), (0.17, brass(370, 0.17)), (0.34, brass(349, 0.17)),
                 (0.51, brass(330, 0.62, glide=311, vibrato=0.02))), peak=0.9 * 0.71)
print("OK:", sorted(p.name for p in OUT.glob("*.wav")))
