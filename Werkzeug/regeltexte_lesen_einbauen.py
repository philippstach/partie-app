#!/usr/bin/env python3
"""Build 25: neue deutsche Lesetexte („Alle Regeln lesen“) aus plan/regeln-neu/<id>/regeln.md in den Katalog.

Ändert NUR den deutschen Wert ("de") des bestehenden Schlüssels (= alter deutscher regeln:-Text im Modul).
Swift bleibt unverändert, en/es/fr behalten den alten übersetzten Text, bis Philipp das Deutsche abgenommen hat.

Umwandlung (Text(LocalizedStringKey) zeigt nur Inline-Markdown und behält Zeilenumbrüche):
  - alles vor der ersten „## “ fällt weg (Kopf mit Stand/Quellen), „---“ fällt weg
  - „## Titel“ -> „**Titel**“, „### Titel“ -> „**Titel**“
  - „- x“ -> „• x“ (eingerückt: „   ◦ x“), nummerierte Zeilen bleiben
  - Tabellen: 2 Spalten -> „• A: B“; 3+ Spalten -> „• A (Kopf2: B; …): Letzte“
  - „%“ -> „ Prozent“ (kein Formatzeichen im Katalogwert), Backticks fallen weg
  - mehrere Leerzeilen -> eine

Aufruf:  python3 Werkzeug/regeltexte_lesen_einbauen.py [--quelle DIR] [--nur id,id] [--trocken] [--mit-entscheidungen]
Läuft als LETZTER Schritt auf dem Sammelzweig (Integrator), damit es keinen Konflikt in Localizable.xcstrings gibt.
"""
import argparse, json, os, re, sys

WURZEL = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KATALOG = os.path.join(WURZEL, "App/Ressourcen/Localizable.xcstrings")

# Spiel-ID (Ordner in regeln-neu) -> Moduldatei mit dem regeln:-Text. None = eigene Regelansicht, Lesetext bleibt (Blatt nötig).
MODULE = {
    "10k": None,          # eigene Regelseite (ZehnKRegelnAnsicht)
    "wortpfeil": None,    # eigene Regelseite (RulesDetailView)
    "chicago": "Pakete/SpielChicago/Sources/SpielChicago/Chicago.swift",
    "elferraus": "Pakete/SpielElferRaus/Sources/SpielElferRaus/Modul.swift",
    "farbflut": "Pakete/SpielFarbflut/Sources/SpielFarbflut/Farbflut.swift",
    "galgenmaennchen": "Pakete/SpielGalgenmaennchen/Sources/SpielGalgenmaennchen/Spiel/NeuModul.swift",
    "herzensjagd": "Pakete/SpielHerzensjagd/Sources/SpielHerzensjagd/Herzensjagd.swift",
    "irrgang": "Pakete/SpielIrrgang/Sources/SpielIrrgang/Irrgang.swift",
    "kakuro": "Pakete/SpielKakuro/Sources/SpielKakuro/Kakuro.swift",
    "koenigsweg": "Pakete/SpielKoenigsweg/Sources/SpielKoenigsweg/Koenigsweg.swift",
    "maexchen": "Pakete/SpielMaexchen/Sources/SpielMaexchen/Maexchen.swift",
    "maumau": "Pakete/SpielMauMau/Sources/SpielMauMau/Modul.swift",
    "minensuche": "Pakete/SpielMinensuche/Sources/SpielMinensuche/Modul.swift",
    "mogeln": "Pakete/SpielMogeln/Sources/SpielMogeln/Mogeln.swift",
    "muehle": "Pakete/SpielMuehle/Sources/SpielMuehle/Muehle.swift",
    "pokerwurf": "Pakete/SpielPokerwurf/Sources/SpielPokerwurf/Pokerwurf.swift",
    "rauswurf": "Pakete/SpielRauswurf/Sources/SpielRauswurf/Spiel/NeuModul.swift",
    "romme": "Pakete/SpielRomme/Sources/SpielRomme/Romme.swift",
    "schiebepuzzle": "Pakete/SpielSchiebepuzzle/Sources/SpielSchiebepuzzle/Schiebepuzzle.swift",
    "schocken": None,     # T-091 (claude/b26-wuerfel-2): alte Regelseite mit Wertungstabelle per mitRegelnAnsicht
    "schwimmen": "Pakete/SpielSchwimmen/Sources/SpielSchwimmen/Modul.swift",
    "siebzehnundvier": "Pakete/SpielSiebzehn/Sources/SpielSiebzehn/Siebzehn.swift",
    "solitaer": "Pakete/SpielSolitaer/Sources/SpielSolitaer/Spiel/NeuModul.swift",
    "sudoku": "Pakete/SpielSudoku/Sources/SpielSudoku/Spiel/NeuModul.swift",
    "viererreihe": "Pakete/SpielViererreihe/Sources/SpielViererreihe/Modul.swift",
    "yacht": None,        # T-091 (claude/b26-wuerfel-2): alte Regelseite mit Wertungstabelle per mitRegelnAnsicht
}

# Texte beschreiben Philipps Entscheidungen vom 13.11. 23:10 (Gleichstand ohne Sieger, wer beginnt reihum, Bank-Blackjack,
# Mischen nach Größe). Nur mit --mit-entscheidungen, wenn der Code dazu im selben Build ist.
ENTSCHEIDUNGEN = {"maumau", "elferraus", "siebzehnundvier", "pokerwurf", "koenigsweg", "maexchen", "schiebepuzzle"}

LITERAL = re.compile(r'regeln:\s*"((?:[^"\\\n]|\\.)*)"')


def swift_text(s):
    """Swift-Stringliteral (einzeilig) -> Laufzeittext; mit \\( ) (Interpolation) -> None."""
    if "\\(" in s:
        return None
    s = re.sub(r"\\u\{([0-9a-fA-F]+)\}", lambda m: chr(int(m.group(1), 16)), s)
    return s.replace('\\"', '"').replace("\\n", "\n").replace("\\t", "\t").replace("\\\\", "\\")


def zellen(z):
    return [c.strip() for c in z.strip().strip("|").split("|")]


def umwandeln(md):
    zeilen = md.splitlines()
    try:
        start = next(i for i, z in enumerate(zeilen) if z.startswith("## "))
    except StopIteration:
        raise SystemExit("keine ##-Überschrift")
    aus, i = [], start
    while i < len(zeilen):
        z = zeilen[i].rstrip()
        if z.strip() == "---":
            i += 1; continue
        if z.lstrip().startswith("|"):
            block = []
            while i < len(zeilen) and zeilen[i].lstrip().startswith("|"):
                block.append(zellen(zeilen[i])); i += 1
            kopf = block[0]
            daten = [r for r in block[1:] if not all(re.fullmatch(r":?-{2,}:?", c) for c in r)]
            for r in daten:
                if len(r) <= 2:
                    aus.append("• " + r[0] + (": " + r[1] if len(r) > 1 and r[1] else ""))
                else:
                    mitte = "; ".join(f"{k}: {w}" for k, w in zip(kopf[1:-1], r[1:-1]) if w)
                    aus.append(f"• {r[0]}" + (f" ({mitte})" if mitte else "") + f": {r[-1]}")
            continue
        m = re.match(r"^(#{2,4})\s+(.*)$", z)
        if m:
            if aus and aus[-1] != "":
                aus.append("")
            aus.append(f"**{m.group(2).strip()}**")
        elif re.match(r"^\s{2,}[-*]\s+", z):
            aus.append("   ◦ " + re.sub(r"^\s*[-*]\s+", "", z))
        elif re.match(r"^[-*]\s+", z):
            aus.append("• " + z[2:].lstrip())
        else:
            aus.append(z)
        i += 1
    text = "\n".join(aus)
    text = re.sub(r"\s*%", " Prozent", text)
    text = text.replace("`", "")   # kein Code-Satz in der Regelseite
    text = re.sub(r"\n{3,}", "\n\n", text).strip()
    return text


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--quelle", default="/mnt/project-files/plan/regeln-neu")
    ap.add_argument("--nur", default="")
    ap.add_argument("--trocken", action="store_true")
    ap.add_argument("--mit-entscheidungen", action="store_true")
    a = ap.parse_args()
    nur = set(filter(None, a.nur.split(",")))
    with open(KATALOG, encoding="utf-8") as f:
        katalog = json.load(f)
    gesetzt, offen = [], []
    for sid, pfad in sorted(MODULE.items()):
        if nur and sid not in nur:
            continue
        if pfad is None:
            offen.append(f"{sid}: eigene Regelseite, Lesetext bleibt"); continue
        if sid in ENTSCHEIDUNGEN and not a.mit_entscheidungen:
            offen.append(f"{sid}: wartet auf den Code zu Philipps Entscheidungen (--mit-entscheidungen)"); continue
        md = os.path.join(a.quelle, sid, "regeln.md")
        if not os.path.exists(md):
            offen.append(f"{sid}: regeln.md fehlt"); continue
        quelltext = open(os.path.join(WURZEL, pfad), encoding="utf-8").read()
        treffer = LITERAL.findall(quelltext)
        if len(treffer) != 1:
            offen.append(f"{sid}: {len(treffer)} regeln:-Texte in {pfad}, von Hand zuordnen"); continue
        schluessel = swift_text(treffer[0])
        if schluessel is None:
            offen.append(f"{sid}: regeln:-Text mit Interpolation"); continue
        neu = umwandeln(open(md, encoding="utf-8").read())
        eintrag = katalog["strings"].setdefault(schluessel, {})
        lok = eintrag.setdefault("localizations", {})
        alt_de = lok.get("de", {}).get("stringUnit", {}).get("value")
        lok["de"] = {"stringUnit": {"state": "translated", "value": neu}}
        eintrag.pop("extractionState", None) if eintrag.get("extractionState") == "stale" else None
        gesetzt.append(f"{sid}: {len(neu.split())} Wörter" + ("" if alt_de is None or alt_de == schluessel else " (ersetzt eigenen de-Wert)")
                       + ("" if len(lok) > 1 else " (Schlüssel hatte keine Übersetzungen)"))
    if not a.trocken:
        with open(KATALOG, "w", encoding="utf-8") as f:
            json.dump(katalog, f, ensure_ascii=False, indent=2)
            f.write("\n")
    print("GESETZT\n  " + "\n  ".join(gesetzt))
    print("OFFEN\n  " + "\n  ".join(offen or ["—"]))


if __name__ == "__main__":
    main()
