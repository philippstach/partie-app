"""Tests der Python-Referenz.  Aufruf (im Ordner Referenz/):  python3 -m unittest -v"""
from __future__ import annotations

import datetime as dt
import glob
import json
import os
import unittest

from generator import GROESSEN, erzeuge, lade_wortliste
from kreuzwort import Raetsel, Spiel, empfehlung, erfolge, normalisiere, pruefe, serie, tagesindex

HIER = os.path.dirname(os.path.abspath(__file__))
TESTS = os.path.join(HIER, "..", "Shared", "regeltests")
PAKETE = os.path.join(HIER, "..", "Shared", "raetsel")
WOERTER = lade_wortliste(os.path.join(HIER, "testwoerter.tsv"))


def lade(name):
    with open(os.path.join(TESTS, name), encoding="utf-8") as d:
        return json.load(d)


class Generator(unittest.TestCase):
    def test_gleicher_seed_gleiches_raetsel(self):
        a = erzeuge(WOERTER, "mittel", 7, versuche=2)
        b = erzeuge(WOERTER, "mittel", 7, versuche=2)
        self.assertEqual(a.als_json(), b.als_json())

    def test_anderer_seed_anderes_raetsel(self):
        a = erzeuge(WOERTER, "leicht", 1, versuche=2)
        b = erzeuge(WOERTER, "leicht", 2, versuche=2)
        self.assertNotEqual(a.gitter, b.gitter)

    def test_dicht_gueltig_und_reproduzierbar(self):
        a = erzeuge(WOERTER, "leicht", 3, versuche=1, dicht=True)
        b = erzeuge(WOERTER, "leicht", 3, versuche=1, dicht=True)
        self.assertEqual(a.als_json(), b.als_json())
        self.assertEqual(pruefe(a, WOERTER), [])

    def test_viele_seeds_alle_gueltig(self):
        for stufe in ("leicht", "mittel", "schwer"):
            for seed in range(8):
                r = erzeuge(WOERTER, stufe, seed, versuche=2)
                self.assertEqual(pruefe(r, WOERTER), [], f"{stufe} {seed}")
                self.assertEqual((r.breite, r.hoehe), GROESSEN[stufe])
                self.assertGreaterEqual(len(r.fragen), 6)


class Regeltests(unittest.TestCase):
    """Die JSON-Dateien müssen zur Referenz passen (sonst erzeuge_tests.py laufen lassen)."""

    def test_normalisierung(self):
        for f in lade("normalisierung.json")["faelle"]:
            self.assertEqual(normalisiere(f["eingabe"]), f["erwartet"], f["eingabe"])

    def test_pruefer(self):
        for f in lade("pruefer.json")["faelle"]:
            self.assertEqual(pruefe(Raetsel.aus_json(f["raetsel"])), f["fehler"], f["name"])

    def test_spiel(self):
        from erzeuge_tests import fuehre_aus

        daten = lade("spiel.json")
        raetsel = Raetsel.aus_json(daten["raetsel"])
        for fall in daten["faelle"]:
            spiel = Spiel.neu(raetsel, starthilfe=fall.get("starthilfe", False))
            for i, schritt in enumerate(fall["schritte"]):
                if schritt["aktion"]:
                    ergebnis = fuehre_aus(spiel, schritt["aktion"])
                    if "ergebnis" in schritt:
                        self.assertEqual(ergebnis, schritt["ergebnis"])
                self.assertEqual(spiel.zustand(), schritt["erwartet"], f"{fall['name']} Schritt {i}")

    def test_loesungswort(self):
        from erzeuge_tests import fuehre_aus

        daten = lade("loesungswort.json")
        for f in daten["pruefer"]:
            self.assertEqual(pruefe(Raetsel.aus_json(f["raetsel"])), f["fehler"], f["name"])
        spiel = Spiel.neu(Raetsel.aus_json(daten["spiel"]["raetsel"]))
        for schritt in daten["spiel"]["schritte"]:
            if schritt["aktion"]:
                fuehre_aus(spiel, schritt["aktion"])
            self.assertEqual(spiel.zustand(), schritt["erwartet"])

    def test_erfolge(self):
        for f in lade("erfolge.json")["faelle"]:
            self.assertEqual(erfolge(f["statistik"]), f["erwartet"], f["name"])

    def test_empfehlung(self):
        for f in lade("empfehlung.json")["faelle"]:
            self.assertEqual(empfehlung(f["stufe"], f["letzte"]), f["erwartet"], f["name"])

    def test_tage(self):
        daten = lade("tage.json")
        for f in daten["tagesindex"]:
            self.assertEqual(tagesindex(dt.date.fromisoformat(f["datum"]), f["anzahl"]), f["erwartet"])
        for f in daten["serie"]:
            tage = [dt.date.fromisoformat(x) for x in f["geloest"]]
            self.assertEqual(serie(tage, dt.date.fromisoformat(f["heute"])), f["erwartet"], f["name"])


class Pakete(unittest.TestCase):
    def test_alle_paketraetsel_gueltig(self):
        dateien = glob.glob(os.path.join(PAKETE, "*.json"))
        self.assertTrue(dateien, "Shared/raetsel/ ist leer – paket.py --demo laufen lassen")
        for pfad in dateien:
            with open(pfad, encoding="utf-8") as d:
                paket = json.load(d)
            self.assertEqual(paket["format"], 1)
            ids = [r["id"] for r in paket["raetsel"]]
            self.assertEqual(len(ids), len(set(ids)), pfad)
            for r in paket["raetsel"]:
                self.assertEqual(pruefe(Raetsel.aus_json(r)), [], f"{pfad} {r['id']}")


if __name__ == "__main__":
    unittest.main()
