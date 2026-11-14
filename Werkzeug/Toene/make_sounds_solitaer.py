#!/usr/bin/env python3
"""Erzeugt die Soundeffekte der App (iOS/Solitaer/Sounds/*.wav).

Alles per Synthese selbst erzeugt – keine fremden Samples, keine Lizenz nötig.
Kartengeräusche entstehen aus gefiltertem Rauschen (fester Seed, also immer gleich),
Sieg und „Farbe komplett“ aus weichen Glockentönen. Bewusst leise und kurz.

    python3 Tools/make_sounds.py
"""
import math
import random
import struct
import wave
from pathlib import Path

RATE = 44100
OUT = Path(__file__).resolve().parent.parent / "iOS" / "Solitaer" / "Sounds"
rnd = random.Random(20261004)


def noise(dur):
    return [rnd.uniform(-1, 1) for _ in range(int(RATE * dur))]


def lowpass(x, cutoff):
    a = 1 - math.exp(-2 * math.pi * cutoff / RATE)
    y, out = 0.0, []
    for v in x:
        y += a * (v - y)
        out.append(y)
    return out


def highpass(x, cutoff):
    low = lowpass(x, cutoff)
    return [v - l for v, l in zip(x, low)]


def bandpass(x, lo, hi):
    return lowpass(highpass(x, lo), hi)


def envelope(x, attack, decay, hold=0.0):
    out = []
    for i, v in enumerate(x):
        t = i / RATE
        if t < attack:
            e = t / attack
        elif t < attack + hold:
            e = 1.0
        else:
            e = math.exp(-(t - attack - hold) / decay)
        out.append(v * e)
    return out


def sine(freq, dur, decay, vol=1.0, glide=None):
    n, phase, out = int(RATE * dur), 0.0, []
    for i in range(n):
        t = i / RATE
        f = freq if glide is None else freq + (glide - freq) * t / dur
        phase += 2 * math.pi * f / RATE
        out.append(math.sin(phase) * math.exp(-t / decay) * min(1.0, t / 0.002) * vol)
    return out


def bell(freq, dur, vol=1.0):
    """Weicher Glockenton: Grundton plus leiser unharmonischer Oberton."""
    a = sine(freq, dur, dur / 4, vol)
    b = sine(freq * 2.76, dur, dur / 10, vol * 0.18)
    c = sine(freq * 5.4, dur, dur / 20, vol * 0.06)
    return [x + y + z for x, y, z in zip(a, b, c)]


def gain(x, g):
    return [v * g for v in x]


def mix(*parts):
    """Legt (Versatz in Sekunden, Samples) übereinander."""
    length = max(int(o * RATE) + len(s) for o, s in parts)
    buf = [0.0] * length
    for o, s in parts:
        start = int(o * RATE)
        for i, v in enumerate(s):
            buf[start + i] += v
    return buf


def save(name, samples, peak_db):
    """Normiert auf einen festen Spitzenpegel (dBFS) – so sind alle Töne gleich leise abgestimmt."""
    OUT.mkdir(parents=True, exist_ok=True)
    tail = int(0.004 * RATE)  # sanft ausblenden, kein Knacken am Ende
    for i in range(min(tail, len(samples))):
        samples[-1 - i] *= i / tail
    peak = max(1e-9, max(abs(s) for s in samples))
    scale = 10 ** (peak_db / 20) / peak
    with wave.open(str(OUT / f"{name}.wav"), "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", max(-32767, min(32767, int(s * scale * 32767)))) for s in samples))
    print(f"{name}.wav  {len(samples) / RATE * 1000:.0f} ms")


def tap(bright=4000, body=170, dur=0.07):
    """Karte landet auf dem Tisch: kurzes helles Klicken + weicher, tiefer Körper."""
    click = envelope(bandpass(noise(dur), 900, bright), 0.0008, 0.008)
    thump = sine(body, dur, 0.018, 0.9, glide=body * 0.8)
    return mix((0, click), (0, gain(thump, 0.5)))


def swish(dur, lo, hi, attack):
    """Karte gleitet: gefiltertes Rauschen, das an- und abschwillt."""
    return envelope(bandpass(noise(dur), lo, hi), attack, dur / 3.5)


# Karte in Spalte abgelegt: weiches Klacken
save("place", tap(), -14)
# Karte aufs Ziel: etwas heller, mit hauchfeinem Glanz
save("foundation", mix((0, tap(bright=6000, body=210)), (0.004, gain(bell(1760, 0.18), 0.12))), -13)
# Karte aufgedeckt: kurzes Wischen
save("flip", swish(0.075, 1500, 7000, 0.012), -20)
# Vom Stapel ziehen: Wischen + leises Klacken
save("draw", mix((0, swish(0.09, 1200, 6000, 0.015)), (0.07, gain(tap(dur=0.05), 0.6))), -18)
# Ablage umdrehen: kurzes Mischen (mehrere schnelle Klicks)
save("shuffle", mix(*[(i * 0.028 + rnd.uniform(0, 0.006), gain(tap(bright=5000, body=150, dur=0.04), 0.5 + 0.08 * i))
                      for i in range(8)]), -16)
# Ungültig: zweimal gedämpftes, tiefes Tock
save("invalid", mix((0, sine(140, 0.06, 0.015)), (0.07, sine(120, 0.06, 0.015))), -22)
# Eine Farbe komplett (König aufs Ziel): zwei ruhige Glockentöne (E6, H6)
save("complete", mix((0, bell(1318.5, 0.5)), (0.09, bell(1975.5, 0.6))), -16)
# Gewonnen: aufsteigender Dur-Klang als Glocken (C6 E6 G6 C7), am Ende zusammen ausklingend
save("win", mix(*[(i * 0.12, gain(bell(f, 1.3 - i * 0.12), 1 - i * 0.12))
                  for i, f in enumerate([1046.5, 1318.5, 1568.0, 2093.0])]), -12)
