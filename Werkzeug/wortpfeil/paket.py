"""Erzeugt die Rätselpakete der App: Pakete/SpielWortpfeil/Shared/raetsel/*.json

Aufruf (im Ordner Referenz/):
  python3 paket.py --demo                      kleines Demo-Paket aus testwoerter.tsv (jetzt)
  python3 paket.py --woerter <datei.tsv>       echtes Paket 1.0 (nach Philipps Entscheidung zur Inhaltsquelle)

Jedes Rätsel wird vor dem Schreiben mit pruefe() kontrolliert. Feste Seeds → das Paket ist reproduzierbar.
"""
from __future__ import annotations

import argparse
import itertools
import multiprocessing
import datetime as dt
import json
import os

from generator import erzeuge, lade_wortliste
from kreuzwort import kennzahlen, pruefe

HIER = os.path.dirname(os.path.abspath(__file__))
ZIEL = os.path.join(HIER, "..", "..", "Pakete", "SpielWortpfeil", "Shared", "raetsel")

# Paketname → (Stufe der Rätsel, Anzahl Demo, Anzahl 1.0, ID-Präfix, Seed-Basis)
PAKETE = {
    "leicht": ("leicht", 20, 150, "L", 10_000),
    "mittel": ("mittel", 20, 150, "M", 20_000),
    "schwer": ("schwer", 10, 150, "S", 30_000),
    "taeglich": ("mittel", 30, 1100, "T", 40_000),
}


PROZESSE = int(os.environ.get("WORTPFEIL_PROZESSE", "5"))
_WOERTER = _STUFE = _DEMO = None


def _ein_seed(seed: int):
    return erzeuge(_WOERTER, _STUFE, seed, "x", versuche=4 if _DEMO else 12, dicht=not _DEMO, rueckfall=_DEMO)


def baue(woerter_pfad: str, demo: bool, nur: set[str] | None = None) -> None:
    woerter = lade_wortliste(woerter_pfad)
    os.makedirs(ZIEL, exist_ok=True)
    benutzt: set[str] = set()  # gleiche Gitter in zwei Paketen vermeiden
    for name, (stufe, n_demo, n_echt, praefix, seed0) in PAKETE.items():
        if nur and name not in nur:
            continue
        anzahl = n_demo if demo else n_echt
        raetsel = []
        seed = seed0
        # Mehrere Prozesse rechnen die Seeds voraus; übernommen wird streng in Seed-Reihenfolge,
        # das Ergebnis ist also dasselbe wie beim Rechnen nacheinander.
        global _WOERTER, _STUFE, _DEMO
        _WOERTER, _STUFE, _DEMO = woerter, stufe, demo
        with multiprocessing.get_context("fork").Pool(PROZESSE) as pool:
            for r in pool.imap(_ein_seed, itertools.count(seed0), chunksize=1):
                seed += 1
                if r is None:
                    continue  # dicht nicht gelungen → nächster Seed (echtes Paket nur mit dichten Gittern)
                schluessel = "".join(r.gitter)
                if schluessel in benutzt:
                    continue
                r.id = f"{praefix}-{len(raetsel) + 1:04d}"
                assert pruefe(r, woerter) == [], (r.id, pruefe(r, woerter))
                benutzt.add(schluessel)
                raetsel.append(r)
                if len(raetsel) % 10 == 0:
                    print(f"  {name}: {len(raetsel)}/{anzahl}", flush=True)
                if len(raetsel) >= anzahl:
                    break
            pool.terminate()
        werte = [kennzahlen(r) for r in raetsel]
        inhalt = {
            "format": 1,
            "paket": name,
            "version": ("demo-" if demo else "") + dt.date.today().isoformat(),
            "demo": demo,
            "raetsel": [r.als_json() for r in raetsel],
        }
        with open(os.path.join(ZIEL, f"{name}.json"), "w", encoding="utf-8") as datei:
            json.dump(inhalt, datei, ensure_ascii=False, separators=(",", ":"))
            datei.write("\n")
        mittel = lambda k: round(sum(w[k] for w in werte) / len(werte), 3)  # noqa: E731
        print(f"{name}: {len(raetsel)} Rätsel (Seeds {seed0}–{seed - 1}) · Leeranteil {mittel('leeranteil')} · Kreuzanteil {mittel('kreuzanteil')}")


def baue_themen(woerter_pfad: str, je_thema: int = 30, mindestens: int = 3) -> None:
    """Themen-Paket: je Thema `je_thema` Mittel-Rätsel mit ≥ `mindestens` langen Themenwörtern (≥ 5 Buchstaben)."""
    from themen import THEMEN, themenwoerter

    woerter = lade_wortliste(woerter_pfad)
    raetsel, kopf = [], []
    for nr, (tid, (de, en, symbol, _)) in enumerate(THEMEN.items()):
        th = themenwoerter(tid, woerter)
        kopf.append({"id": tid, "de": de, "en": en, "symbol": symbol})
        seed, gefunden = 70_000 + nr * 1_000, 0
        while gefunden < je_thema:
            r = erzeuge(woerter, "mittel", seed, f"TH-{tid}-{gefunden + 1:02d}", versuche=1, dicht=True,
                        rueckfall=False, bevorzugt=th)
            seed += 1
            if r is None:
                continue
            lang = [r.loesungswort(f) for f in r.fragen if len(r.loesungswort(f)) >= 5]
            if sum(w in th for w in lang) < mindestens:
                continue
            assert pruefe(r, woerter) == [], (r.id, pruefe(r, woerter))
            r.thema = tid
            raetsel.append(r)
            gefunden += 1
        print(f"  {tid}: {gefunden} Rätsel (Seeds bis {seed - 1})", flush=True)
    inhalt = {"format": 1, "paket": "themen", "version": dt.date.today().isoformat(), "demo": False,
              "themen": kopf, "raetsel": [r.als_json() for r in raetsel]}
    with open(os.path.join(ZIEL, "themen.json"), "w", encoding="utf-8") as datei:
        json.dump(inhalt, datei, ensure_ascii=False, separators=(",", ":"))
        datei.write("\n")
    print(f"themen: {len(raetsel)} Rätsel")


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--demo", action="store_true")
    ap.add_argument("--woerter")
    ap.add_argument("--nur", help="nur diese Pakete, z. B. schwer,taeglich")
    ap.add_argument("--themen", action="store_true", help="Themen-Paket erzeugen (braucht --woerter)")
    args = ap.parse_args()
    if args.demo:
        baue(os.path.join(HIER, "testwoerter.tsv"), demo=True)
    elif args.woerter and args.themen:
        baue_themen(args.woerter)
    elif args.woerter:
        baue(args.woerter, demo=False, nur=set(args.nur.split(",")) if args.nur else None)
    else:
        ap.error("--demo oder --woerter angeben")
