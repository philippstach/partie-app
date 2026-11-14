# VierGewinnt – Regeltests

Erzeugt von `Referenz/erzeuge_tests.py`, geprüft von `Referenz/pruefe_tests.py`. **Nie von Hand ändern.**
iOS und Android lesen genau diese Dateien. Alle Felder in camelCase.
Koordinaten: Spalte 0–6 von links, Zeile 0–5 von unten. Spieler 1 = Gold, 2 = Blau.
Jede Stellung ist gegeben als `beginner` + `zuege` (Liste der Spalten). `bild` ist nur zum Lesen (oberste Zeile zuerst, `.` leer, `G` Gold, `B` Blau) und wird nicht geprüft.

| Datei | Prüft | Ein Fall |
|---|---|---|
| `brett.json` | Einwerfen, Gewinn, Unentschieden | `beginner`, `zuege` → `erwartet {status, gewinner, gewinnZellen, amZug, hoehen, legaleSpalten, bild}` |
| `fehler.json` | ungültige Züge | `beginner`, `zuege`, `spalte` → `erwartet.fehler` (`ungueltigeSpalte \| spielVorbei \| spalteVoll`); `zuege` danach unverändert |
| `rueckgaengig.json` | Rückgängig | `beginner`, `zuege`, `computer` (1, 2 oder `null` = zu zweit) → `erwartet {moeglich, zuege, amZug}` bzw. `{moeglich: false}` |
| `bewertung.json` | Heuristik (SPEZIFIKATION 7.2) | `beginner`, `zuege` → `erwartet {spieler1, spieler2}` |
| `computer.json` | Stufen leicht und mittel, exakt | `stufe`, `beginner`, `zuege`, `zufall[]` → `erwartet {spalte, zufallGezogen}`; bei mittel zusätzlich `werte[7]` (`null` = Spalte voll) |
| `geuebt.json` | Stufe geübt (SPEZIFIKATION 7.6), exakt | `beginner`, `zuege`, `zufall[]` → `erwartet {spalte, zufallGezogen, werte[7] \| null}` |
| `stark.json` | Stufe stark | `maxTiefe` (oben), je Fall `art`, `beginner`, `zuege` → `erwartet.haltend[]`: Die Wahl (ohne Zeitlimit, `maxTiefe`) muss darin liegen. `werte` = exakte Werte je Spalte, nur zur Information |
| `zufall.json` | SplitMix64 | `seed` (Text) → `weiter[5]` (Text), `naechste7[10]` (Zahlen, frischer Generator), `zustandDanach` (Text, nach den 10 `naechste`) |
| `raetsel.json` | Rätsel (SPEZIFIKATION 15.2) | `id`, `n`, `beginner`, `zuege` → `erwartet.hauptvariante[]`, je Schritt `{zuege, verbleibend, richtig[], gespielt, verteidigung}` (`null` = `gespielt` gewinnt) |
| `rueckblick.json` | Rückblick (SPEZIFIKATION 15.3) | `beginner`, `zuege` → `erwartet.spieler1[]`, `erwartet.spieler2[]`, je Markierung `{zug, art (verpassterSieg \| fehler), spalte, besser, zuege}` |
| `raetsel-v3.json` | Rätsel v3 (SPEZIFIKATION 18): 6 Kapitel, 100 Rätsel | je Fall `id`, `kapitel`, `art`, `n`, `beginner`, `zuege`. Bei `gewinnen`: `erwartet {hauptvariante[], widerlegung{spalte: {art, antwort}}}`. Bei `retten`: `erwartet {richtig[1], fehler{spalte: m}, widerlegung{…}}` |
| `partien/*.json` | ganze Partien | siehe unten |

`zufall[]` in `computer.json` ist eine `ListenQuelle`: `naechste(n) = folge[i] % n`. `zufallGezogen` sagt, ob der Computer Zufall gezogen hat (0 oder 1).

## partien/*.json
```
name, beschreibung,
strategien[2]   – Stufe für Spieler 1 (Gold) und Spieler 2 (Blau): "leicht" | "mittel"
beginner        – 1 oder 2
zufall[]        – EINE gemeinsame ListenQuelle für beide Computer, muss genau aufgehen
erwartet        – {zuege[], status, gewinner, gewinnZellen, amZug, hoehen, legaleSpalten, bild}
```
**Jede Plattform prüft zweimal:**
- (a) Nachspielen mit `erwartet.zuege`.
- (b) Nachspielen mit den Strategien und der Zufallsquelle.

Beide Durchläufe müssen genau `erwartet` treffen.

## Inhalt für die App: `Shared/inhalt/raetsel-v3.json` (SPEZIFIKATION 18; die App bündelt sie als `raetsel.json`, die alte v1 ist entfernt)
Die 100 Rätsel (`id`, `n`, `beginner`, `zuege`), dazu `kapitel` (Titel DE/EN), `tagesStart` und `tagesreihenfolge`. Die App liefert die Datei unverändert mit aus.
