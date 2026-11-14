# Schocken – Regeltests

Erzeugt von `Referenz/erzeuge_tests.py`, geprüft von `Referenz/pruefe_tests.py`. **Nie von Hand ändern.**
iOS und Android lesen genau diese Dateien. Alle Felder in camelCase, Würfel immer als Augenzahlen 1–6.
`optionen` ist immer ein Teil-Objekt: Fehlende Schlüssel bekommen den Standardwert (SPEZIFIKATION Abschnitt 7).

| Datei | Prüft | Ein Fall |
|---|---|---|
| `wertung.json` | `werte(wuerfel, ausEinemWurf, optionen)` | `wuerfel`, `ausEinemWurf`, `optionen` → `erwartet {art, hoehe, deckel}`; dazu `rangfolge.standard/jule` = alle Wertungen aus einem Wurf von schlecht nach gut |
| `vergleich.json` | `istBesser(a, b)` | `a`, `b` = `{wertung, wuerfe, position}`; a ist besser, b nicht |
| `zug.json` | `weiterErlaubt(...)` | `draussen`, `wurf`, `wuerfe`, `maxWuerfe`, `herauslegen`, `umdrehen` → `erlaubt`; dazu `moeglicheZuege` = vollständige Liste in fester Reihenfolge |
| `runde.json` | Runde werten + Deckel bewegen | `vorher {stock, deckel[]}`, `ergebnisse[]` (Index = Spieler = Position) → `erwartet {verlierer, gewinner, deckel, ausStock, schockAus, stock, stand[], raus[], haelfteVerlierer}` |
| `ablauf.json` | Was kommt nach den Hälften? | `haelftenVerlierer[]` → `{naechste: haelfte2\|finale\|null, verlierer, finaleSpieler[]}` |
| `computer.json` | Entscheidung „einfach“ und „gut“ | Lage (`draussen`, `wurf`, `wuerfe`, `maxWuerfe`, `position`, `zuSchlagen` oder null) → `einfach`, `gut` als Aktion, `gutWert` (±1e-6); dazu `perzentil` |
| `partien/*.json` | ganze Partien | siehe unten; dazu Rundenverlauf (F7): der aufgebaute Verlauf = `erwartet.haelften[i].runden` |
| `abend.json` | Spieleabend (F8) | `schritte[]` (`partieBeendet` mit `zeit`, `spieler`, `verlierer`, `haelftenVerlierer` oder `neuerAbend`) → nach jedem Schritt `{partien, karteZeigen, bilanz[]}` |
| `auswuerfeln.json` | Auswürfeln, wer anfängt (R1) | `spieler[]`, `wuerfel[]` (genau verbraucht) → `{beginner, runden[[{spieler, augen}]]}` |
| `auszeichnungen.json` | Auszeichnungen am Abend (R2) | `partien`, `werte{Name: {schockAus, deckel, rundenVerloren}}` → Liste `{id, namen[], wert}` |
| `statistik.json` | Serien und Duelle (R5) | `partien[]` (`spieler[]`, `verlierer`) → `{spieler{Name: {partien, verloren, serieOhneNiederlage, besteSerie}}, duelle[]}` |
| `hinweise.json` | Hinweise der geführten Partie (F6) | `schritte[]` mit `ereignis` und `an` → `erwartet` = Hinweis-id oder null; `reihenfolge`, `gefuehrtStart` |

**Aktion:** `{"typ": "stehen"}` oder `{"typ": "weiter", "herauslegen": [1], "umdrehen": 1}`. `herauslegen` ist aufsteigend sortiert.

## partien/*.json
```
name, beschreibung, optionen, strategien[] (je Spieler "einfach" | "gut"), beginner,
wuerfel[]                      – Würfelquelle, wird der Reihe nach verbraucht, muss genau aufgehen
erwartet.verlierer             – Verlierer der Partie
erwartet.haelften[]            – {spieler[], beginner, verlierer, runden[]}
  runden[]                     – {beginner, zuege[], verlierer, gewinner, deckel, ausStock, stock, stand[], raus[]}
    zuege[]                    – {spieler, aktionen[], wuerfel (absteigend), wuerfe, wertung}
```
- `stand[]` gehört zu `spieler[]` der Hälfte (im Finale nur die zwei Finalisten).
- Ein Zug beginnt immer mit dem ersten Wurf, dafür gibt es keine Aktion. Nach dem letzten erlaubten Wurf endet er automatisch, auch dafür gibt es keine Aktion.
- **Jede Plattform prüft zweimal:**
  - (a) Nachspielen mit `aktionen` wie ein Mensch,
  - (b) Nachspielen mit der Computer-Strategie aus `strategien`.

  Beide Durchläufe müssen jeden Zug und jeden Rundenstand treffen.

`partien/*.json` geben `beginner` fest vor; das Auswürfeln (R1) wird nur in `auswuerfeln.json` geprüft.
