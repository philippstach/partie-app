#!/usr/bin/env python3
"""Erzeugt die Soundeffekte der App (iOS/Galgenmaennchen/Sounds/*.wav).

Alle Töne sind hier per Synthese selbst erzeugt – keine fremden Samples,
keine Lizenz nötig. Neu erzeugen: python3 Tools/make_sounds.py
"""
import math, struct, wave
from pathlib import Path

RATE = 44100
OUT = Path(__file__).resolve().parent.parent / "iOS" / "Galgenmaennchen" / "Sounds"


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


def save(name, samples, peak_level=0.25):
    """Normalisiert auf die Spitze `peak_level` (0,25 ≈ −12 dBFS, leise und weich)."""
    OUT.mkdir(parents=True, exist_ok=True)
    peak = max(1e-9, max(abs(s) for s in samples))
    scale = peak_level / peak
    with wave.open(str(OUT / f"{name}.wav"), "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(s * scale * 32767)) for s in samples))


def noise(dur, vol, seed=7):
    """Kurzes Rauschen (feste Zufallsfolge, damit die Datei reproduzierbar bleibt)."""
    import random
    rnd = random.Random(seed)
    n = int(RATE * dur)
    return [(rnd.random() * 2 - 1) * vol * (1 - i / n) for i in range(n)]


# Holzblock-Klick: Sinus 880 Hz + Oberton 1760 Hz (15 %), 80 ms, schneller Abfall.
# Für die steigenden Töne je Stelle gibt es hit1–hit5 mit +0/+2/+4/+6/+8 Halbtönen (Faktor 1,1225 je Schritt).
for k in range(5):
    f = 880 * (1.1225 ** k)
    save(f"hit{k + 1}", mix((0, tone(f, 0.08, 0.5, attack=0.002)), (0, tone(2 * f, 0.08, 0.075, attack=0.002))))

# Weiches Plopp: Sinus 300 → 120 Hz in 120 ms + kurzes Rauschen 15 ms (10 %), kein Hall
save("pop", mix((0, tone(300, 0.12, 0.5, attack=0.002, glide=120)), (0, noise(0.015, 0.05))))

# Glas-Glitzern: 3 Sinus 1319/1568/2093 Hz, Abstand 50 ms, je 150 ms
save("hint", mix(*[(i * 0.05, tone(f, 0.15, 0.3)) for i, f in enumerate([1319.0, 1568.0, 2093.0])]))

# Gewonnen: Dur-Arpeggio C-E-G-C, Abstand 90 ms, Ausklang 500 ms, Dreieck für Wärme
save("win", mix(*[(i * 0.09, tone(f, 0.5, 0.3, shape="tri")) for i, f in enumerate([523.25, 659.25, 783.99, 1046.5])]))

# Verloren: zwei weiche Töne A4 → F4 (250 ms + 400 ms), 3 dB leiser als „win“
save("lose", mix((0, tone(440.0, 0.25, 0.3)), (0.25, tone(349.23, 0.4, 0.3))), peak_level=0.25 * 0.708)
