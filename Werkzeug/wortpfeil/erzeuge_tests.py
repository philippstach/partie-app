"""Erzeugt Shared/regeltests/*.json aus der Python-Referenz.

Aufruf (im Ordner Referenz/):  python3 erzeuge_tests.py
Die Dateien werden komplett neu geschrieben. Nie von Hand ändern – erst hier, dann neu erzeugen.
"""
from __future__ import annotations

import datetime as dt
import json
import os

from generator import erzeuge, lade_wortliste
from kreuzwort import ERFOLGE, Frage, Raetsel, Spiel, empfehlung, erfolge, normalisiere, pruefe, serie, tagesindex

HIER = os.path.dirname(os.path.abspath(__file__))
ZIEL = os.path.join(HIER, "..", "Shared", "regeltests")

# Kleines, von Hand gebautes Rätsel für die Spiellogik (5 breit, 7 hoch):
#   -#-#-     (0,1)↓ OPA   (0,3)↓ AST
#   #OMA-     (1,0)→ OMA
#   -P-S-
#   #ART-     (3,0)→ ART  und  (3,0)↓ EIS  (ein Fragefeld mit zwei Fragen)
#   E----
#   I----
#   S----
MINI = Raetsel(
    id="T-MINI",
    stufe="leicht",
    breite=5,
    hoehe=7,
    gitter=["-#-#-", "#OMA-", "-P-S-", "#ART-", "E----", "I----", "S----"],
    fragen=[
        Frage(0, 1, "unten", "Großvater"),
        Frage(0, 3, "unten", "Teil des Baumes"),
        Frage(1, 0, "rechts", "Großmutter"),
        Frage(3, 0, "rechts", "Weise, Sorte"),
        Frage(3, 0, "unten", "Gefrorenes Wasser"),
    ],
)


def schreibe(name: str, inhalt: dict) -> None:
    os.makedirs(ZIEL, exist_ok=True)
    with open(os.path.join(ZIEL, name), "w", encoding="utf-8") as datei:
        json.dump(inhalt, datei, ensure_ascii=False, indent=1)
        datei.write("\n")


# ---------------------------------------------------------------------------
def normalisierung() -> dict:
    eingaben = [
        "Löwe", "Straße", "GRÖSSE", "Ärger", "Übel", "Öl", "maß", "Café", "Rhône", "Señor",
        "Schleswig-Holstein", "New York", "A4", "", "ẞ", "äöüß", "x", "?",
    ]
    return {
        "beschreibung": "normalisiere(text): Rätselschreibweise A–Z, Ä→AE, Ö→OE, Ü→UE, ß→SS, Akzente weg, Rest entfällt",
        "faelle": [{"eingabe": e, "erwartet": normalisiere(e)} for e in eingaben],
    }


# ---------------------------------------------------------------------------
def kaputt(gitter=None, fragen=None, stufe=None, **_) -> dict:
    d = MINI.als_json()
    if gitter is not None:
        d["gitter"] = gitter
    if fragen is not None:
        d["fragen"] = fragen
    if stufe is not None:
        d["stufe"] = stufe
    return d


def pruefer(paket_raetsel: list[Raetsel]) -> dict:
    basis = MINI.als_json()
    f = basis["fragen"]
    faelle = [
        ("mini_gueltig", basis),
        ("stufe_unbekannt", kaputt(stufe="extrem")),
        ("gitter_groesse", kaputt(gitter=basis["gitter"][:-1])),
        ("gitter_zeichen", kaputt(gitter=["-#-#-", "#oMA-"] + basis["gitter"][2:])),
        ("frage_nicht_im_fragefeld", kaputt(fragen=f + [{"zeile": 2, "spalte": 0, "richtung": "rechts", "text": "x"}])),
        ("frage_doppelt", kaputt(fragen=f + [dict(f[0])])),
        ("fragetext_leer", kaputt(fragen=[dict(f[0], text="  ")] + f[1:])),
        ("fragetext_zu_lang", kaputt(fragen=[dict(f[0], text="Eine viel zu lange Frage für ein Feld")] + f[1:])),
        ("mit_kurztext_gueltig", kaputt(fragen=[dict(f[0], kurz="Opa")] + f[1:])),
        ("kurztext_leer", kaputt(fragen=[dict(f[0], kurz="  ")] + f[1:])),
        ("kurztext_zu_lang", kaputt(fragen=[dict(f[0], kurz="Ein viel zu langer Kurztext fürs Feld")] + f[1:])),
        ("richtung_unbekannt", kaputt(fragen=f + [{"zeile": 1, "spalte": 0, "richtung": "links", "text": "x"}])),
        # (0,3)↓ zeigt jetzt auf ein einzelnes Feld: AST wird zu A + Leerfeld
        ("wort_zu_kurz", kaputt(gitter=["-#-#-", "#OMA-", "-P---", "#ART-", "E----", "I----", "S----"])),
        # Frage für ART fehlt → Folge ART ohne Frage; Fragefeld (3,0) behält EIS
        ("wort_ohne_frage", kaputt(fragen=[x for x in f if not (x["zeile"] == 3 and x["richtung"] == "rechts")])),
        # Einzelner Buchstabe ohne Wort unten rechts
        ("buchstabe_ohne_wort", kaputt(gitter=["-#-#-", "#OMA-", "-P-S-", "#ART-", "E----", "I----", "S---Q"])),
        ("fragefeld_ohne_frage", kaputt(gitter=["-#-##", "#OMA-", "-P-S-", "#ART-", "E----", "I----", "S----"])),
        # OPA zweimal: zweites OPA in Zeile 6 statt S, waagerecht – Gitter dafür umgebaut
        ("wort_doppelt", {
            **basis,
            "breite": 5, "hoehe": 7,
            "gitter": ["-#-#-", "#OMA-", "-P-S-", "#ART-", "-----", "#OPA-", "-----"],
            "fragen": [x for x in f if not (x["zeile"] == 3 and x["richtung"] == "unten")]
                      + [{"zeile": 5, "spalte": 0, "richtung": "rechts", "text": "Großvater"}],
        }),
    ]
    aus = []
    for name, d in faelle:
        erwartet = pruefe(Raetsel.aus_json(d))
        aus.append({"name": name, "raetsel": d, "fehler": erwartet})
    for r in paket_raetsel:
        aus.append({"name": f"generiert_{r.id}", "raetsel": r.als_json(), "fehler": pruefe(r)})
    return {
        "beschreibung": "pruefe(raetsel) → sortierte Liste der Fehlercodes (leer = gültig). Codes siehe SPEZIFIKATION.md",
        "faelle": aus,
    }


# ---------------------------------------------------------------------------
def T(z, s):
    return {"aktion": "tippe", "zeile": z, "spalte": s}


def B(zeichen):
    return {"aktion": "buchstabe", "zeichen": zeichen}


LOE = {"aktion": "loeschen"}
NEXT = {"aktion": "naechsteFrage"}
PREV = {"aktion": "vorigeFrage"}
AUF = {"aktion": "buchstabeAufdecken"}
WP = {"aktion": "wortPruefen"}
RP = {"aktion": "raetselPruefen"}
BL = {"aktion": "bleistiftUmschalten"}
WA = {"aktion": "wortAufdecken"}


def fuehre_aus(spiel: Spiel, a: dict):
    art = a["aktion"]
    if art == "tippe":
        spiel.tippe(a["zeile"], a["spalte"])
    elif art == "buchstabe":
        spiel.buchstabe(a["zeichen"])
    elif art == "loeschen":
        spiel.loeschen()
    elif art == "naechsteFrage":
        spiel.naechste_frage(1)
    elif art == "vorigeFrage":
        spiel.naechste_frage(-1)
    elif art == "buchstabeAufdecken":
        spiel.buchstabe_aufdecken()
    elif art == "wortPruefen":
        return spiel.wort_pruefen()
    elif art == "raetselPruefen":
        return spiel.raetsel_pruefen()
    elif art == "bleistiftUmschalten":
        spiel.bleistift_umschalten()
    elif art == "wortAufdecken":
        spiel.wort_aufdecken()
    else:
        raise ValueError(art)
    return None


def spiel_faelle() -> dict:
    # Mit klugem Cursor: OMA → springt zu ART → EIS → OPA (Lücke) → AST (Lücke) → gelöst
    alles_richtig = [T(1, 0), B("o"), B("m"), B("a"), B("a"), B("r"), B("t"),
                     B("e"), B("i"), B("s"), B("p"), B("s")]
    szenarien = {
        "start": [],
        "tippen_gleiches_feld_wechselt_richtung": [T(1, 1), T(1, 1)],
        "tippen_ohne_querwort_bleibt_richtung": [T(2, 3), T(2, 3)],
        "tippen_wechselt_richtung_wenn_noetig": [T(1, 2)],
        "fragefeld_mit_zwei_fragen": [T(3, 0), T(3, 0), T(3, 0)],
        "tippen_leerfeld_und_rand": [T(4, 4), T(9, 9)],
        "eingabe_rueckt_vor_wortende_springt_zur_naechsten_luecke": [T(1, 0), B("o"), B("m"), B("a"), B("x")],
        "kluger_cursor_ueberspringt_gefuellte": [T(0, 3), B("a"), T(1, 0), B("o"), B("m")],
        "korrektur_im_vollen_wort_rueckt_einfach_vor": [T(1, 0), B("o"), B("m"), B("a"), T(1, 1), B("x"), B("y"), B("z"), B("q")],
        "lueckenfuellung_springt_im_wort_zurueck": [T(1, 0), B("o"), LOE, LOE, T(1, 2), B("m"), B("a"), B("o")],
        "wort_aufdecken": [T(1, 0), B("o"), WA, WA, T(1, 0), WA],
        "bleistift": [BL, T(1, 0), B("o"), B("m"), BL, T(1, 2), B("m"), T(1, 1), AUF],
        "umlaut_und_sz": [T(1, 0), B("ä"), B("ß")],
        "ungueltige_zeichen_ignoriert": [T(1, 0), B("1"), B(" "), B("?")],
        "loeschen": [T(1, 0), B("o"), B("m"), LOE, LOE, LOE, LOE],
        "aufdecken_sperrt_feld": [T(1, 0), AUF, AUF, B("m"), LOE, LOE, LOE, B("x")],
        "wort_pruefen_markiert_fehler": [T(1, 0), B("o"), B("x"), B("a"), WP, T(1, 2), B("m")],
        "raetsel_pruefen": [T(1, 0), B("x"), T(3, 0), B("a"), B("q"), RP],
        "naechste_und_vorige_frage": [NEXT, NEXT, NEXT, NEXT, NEXT, PREV, PREV],
        "naechste_frage_springt_zur_luecke": [T(0, 3), B("a"), B("s"), NEXT, NEXT],
        "kreuzung_teilt_buchstaben": [T(1, 0), B("o"), T(0, 1)],
        "voll_mit_fehlern": alles_richtig[:-1] + [B("x")],
        "geloest": alles_richtig,
    }
    faelle = []
    szenarien_mit_start = [(n, a, False) for n, a in szenarien.items()]
    szenarien_mit_start.append(("starthilfe_anfangsbuchstaben", [B("p"), B("a"), T(1, 0), B("m")], True))
    for name, aktionen, starthilfe in szenarien_mit_start:
        spiel = Spiel.neu(MINI, starthilfe=starthilfe)
        schritte = [{"aktion": None, "erwartet": spiel.zustand()}]
        for a in aktionen:
            ergebnis = fuehre_aus(spiel, a)
            schritt = {"aktion": a, "erwartet": spiel.zustand()}
            if ergebnis is not None:
                schritt["ergebnis"] = ergebnis
            schritte.append(schritt)
        fall = {"name": name, "schritte": schritte}
        if starthilfe:
            fall["starthilfe"] = True
        faelle.append(fall)
    return {
        "beschreibung": "Spiellogik auf dem Rätsel 'raetsel'. Spiel.neu(raetsel), dann jede Aktion ausführen und "
                        "den Zustand mit 'erwartet' vergleichen. Fall mit \"starthilfe\": true → Spiel.neu(raetsel, starthilfe=True). 'ergebnis' = Rückgabewert (Anzahl Fehler) bei Prüfen.",
        "raetsel": MINI.als_json(),
        "faelle": faelle,
    }


# ---------------------------------------------------------------------------
def tage() -> dict:
    d = dt.date
    index = [(d(2026, 1, 1), 365), (d(2026, 1, 2), 365), (d(2026, 12, 31), 365), (d(2027, 1, 1), 365),
             (d(2025, 12, 31), 365), (d(2024, 2, 29), 365), (d(2026, 10, 4), 30), (d(2030, 6, 15), 7)]
    heute = d(2026, 10, 4)
    tag = lambda n: (heute - dt.timedelta(days=n)).isoformat()  # noqa: E731
    serien = [
        ("leer", []),
        ("nur_heute", [0]),
        ("heute_offen_gestern_geloest", [1, 2, 3]),
        ("heute_und_davor", [0, 1, 2]),
        ("luecke", [0, 1, 3, 4, 5]),
        ("vorgestern_zuletzt", [2, 3]),
        ("ueber_monatsgrenze", list(range(0, 10))),
    ]
    return {
        "beschreibung": "tagesindex(datum, anzahl) = Tage seit 2026-01-01, positiv modulo anzahl. "
                        "serie(geloest, heute) = gelöste Tage am Stück bis heute (heute offen bricht nicht).",
        "tagesindex": [{"datum": x.isoformat(), "anzahl": n, "erwartet": tagesindex(x, n)} for x, n in index],
        "serie": [
            {"name": name, "heute": heute.isoformat(), "geloest": [tag(n) for n in ns],
             "erwartet": serie([heute - dt.timedelta(days=n) for n in ns], heute)}
            for name, ns in serien
        ],
    }


def loesungswort_faelle() -> dict:
    """Lösungswort: Prüfregeln und Anzeige-Zustand. MINI mit Lösung ROT = (3,2) R, (1,1) O, (3,3) T."""
    import copy

    mit = copy.deepcopy(MINI)
    mit.loesung = [(3, 2), (1, 1), (3, 3)]
    basis = mit.als_json()
    pruef = [
        ("gueltig", basis),
        ("feld_doppelt", {**basis, "loesung": [[3, 2], [1, 1], [3, 2]]}),
        ("kein_buchstabenfeld", {**basis, "loesung": [[3, 2], [0, 1], [3, 3]]}),
        ("zu_kurz", {**basis, "loesung": [[3, 2], [1, 1]]}),
    ]
    spiel = Spiel.neu(mit)
    schritte = [{"aktion": None, "erwartet": spiel.zustand()}]
    for a in [T(1, 0), B("o"), T(3, 0), B("a"), B("r"), B("t")]:
        fuehre_aus(spiel, a)
        schritte.append({"aktion": a, "erwartet": spiel.zustand()})
    return {
        "beschreibung": "Lösungswort: 'loesung' = Liste der Felder in Lesereihenfolge (optional im Rätsel). "
                        "pruefe → 'loesung_ungueltig' bei doppeltem Feld, Nicht-Buchstabenfeld oder Länge außerhalb 3–12. "
                        "Zustand 'loesung' = Einträge dieser Felder, '.' für leer (nur wenn das Rätsel eins hat). "
                        "Das Lösungswort wird nicht extra eingegeben – es füllt sich aus dem Gitter.",
        "pruefer": [{"name": n, "raetsel": d, "fehler": pruefe(Raetsel.aus_json(d))} for n, d in pruef],
        "spiel": {"raetsel": basis, "schritte": schritte},
    }


def erfolge_faelle() -> dict:
    gross = {"leicht": 150, "mittel": 150, "schwer": 150}
    faelle = [
        ("leer", {}),
        ("erstes", {"geloest": {"leicht": 1}, "ohneHilfe": {}, "bestzeit": {"leicht": 400}}),
        ("ohne_hilfe_und_flink", {"geloest": {"leicht": 3}, "ohneHilfe": {"leicht": 1}, "bestzeit": {"leicht": 170}}),
        ("bestzeit_null_zaehlt_nicht", {"geloest": {}, "bestzeit": {"leicht": 0}}),
        ("grenzen_genau", {"geloest": {"leicht": 5, "mittel": 4, "schwer": 1}, "ohneHilfe": {"mittel": 25},
                           "bestzeit": {"mittel": 420, "schwer": 900}, "besteSerie": 7, "tagesGeloest": 30}),
        ("knapp_daneben", {"geloest": {"leicht": 9}, "ohneHilfe": {"leicht": 24}, "bestzeit": {"mittel": 421},
                           "besteSerie": 6, "tagesGeloest": 29}),
        ("alle_leicht", {"geloest": {"leicht": 150, "mittel": 0}, "paketgroesse": gross}),
        ("alles", {"geloest": {"leicht": 150, "mittel": 60, "schwer": 10}, "ohneHilfe": {"leicht": 30},
                   "bestzeit": {"leicht": 100, "mittel": 300, "schwer": 800}, "besteSerie": 40, "tagesGeloest": 50,
                   "themenGeloest": 2, "paketgroesse": gross}),
    ]
    return {
        "beschreibung": "erfolge(statistik) → Liste erreichter Erfolg-ids in der Reihenfolge von 'liste'. "
                        "Fehlende Felder = 0/leer; Bestzeit 0 = noch keine. Zeiten in Sekunden.",
        "liste": [{"id": e, "de": de, "en": en} for e, (de, en, _) in ERFOLGE.items()],
        "faelle": [{"name": n, "statistik": s, "erwartet": erfolge(s)} for n, s in faelle],
    }


def empfehlung_faelle() -> dict:
    o, m, v = {"hilfen": 0}, {"hilfen": 1}, {"hilfen": 3}
    faelle = [
        ("zu_wenige", "leicht", [o, o]),
        ("drei_ohne_hilfe_leicht", "leicht", [m, o, o, o]),
        ("drei_ohne_hilfe_mittel", "mittel", [o, o, o]),
        ("schwer_bleibt", "schwer", [o, o, o]),
        ("eine_hilfe_unterbricht", "leicht", [o, m, o]),
        ("drei_mal_viele_hilfen", "mittel", [v, v, {"hilfen": 5}]),
        ("leicht_nie_leichter", "leicht", [v, v, v]),
        ("nur_letzte_drei", "schwer", [o, v, v, v]),
        ("gemischt", "mittel", [v, o, v]),
    ]
    return {
        "beschreibung": "empfehlung(stufe, letzte) – letzte gelöste Rätsel DIESER Stufe, neueste zuletzt. "
                        "Ergebnis: andere Stufe oder null.",
        "faelle": [{"name": n, "stufe": st, "letzte": l, "erwartet": empfehlung(st, l)} for n, st, l in faelle],
    }


def main() -> None:
    woerter = lade_wortliste(os.path.join(HIER, "testwoerter.tsv"))
    generiert = [erzeuge(woerter, stufe, seed, f"T-{stufe}-{seed}", versuche=3)
                 for stufe in ("leicht", "mittel", "schwer") for seed in (1, 2)]
    schreibe("normalisierung.json", normalisierung())
    schreibe("pruefer.json", pruefer(generiert))
    schreibe("spiel.json", spiel_faelle())
    schreibe("tage.json", tage())
    schreibe("loesungswort.json", loesungswort_faelle())
    schreibe("erfolge.json", erfolge_faelle())
    schreibe("empfehlung.json", empfehlung_faelle())
    print("Shared/regeltests/ neu geschrieben")


if __name__ == "__main__":
    main()
