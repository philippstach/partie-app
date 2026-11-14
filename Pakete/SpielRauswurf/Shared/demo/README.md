# Demo-Szenarien (Screenshots)

Erzeugt von `Referenz/erzeuge_demos.py`. **Nie von Hand ändern.** iOS und Android bauen daraus die Szenarien `-demo <name>` (DESIGN.md).

Spieler: Anna (Mensch, Sitz 0), Ben (Computer gut, Sitz 1), Clara (Computer einfach, Sitz 2), David (Mensch, Sitz 3). Felder: `namen`, `arten` (so in der App anzeigen), `sitze`, `beginner`, `optionen` (Standard).

**Aufbau:**
1. Partie mit `sitze` und `beginner` anlegen. Die Würfelquelle ist die Liste `wuerfel`.
2. `zuege` (Format wie `partien/*.json`) mit den aufgezeichneten Zügen nachspielen, ohne Animation.
3. `laufend` = der Spielzug, der gerade läuft:
   - `spieler`: wer dran ist.
   - `wuerfe`: diese Würfe sind in diesem Spielzug schon passiert und werden nachgespielt.
   - `augen`: Ist der Wert gesetzt, ist schon gewürfelt und die App steht in der Phase „Wahl“. Ist er `null`, steht sie vor dem Wurf.
4. Danach sind alle `wuerfel` verbraucht, und die Figuren stimmen mit `figuren` überein (sonst Fehler).

| Datei | Szenario | Halt |
|---|---|---|
| `game.json` | `game` | Anna hat eine 4, Wahl, ein Zug schlägt Ben. `zug` = dieser Zug |
| `game.json` + `zug` | `capture` | wie `game`, dann `zug` ausführen und die Animation im Flug einfrieren |
| `six.json` | `six` | Anna hat eine 6, Raus-Pflicht |
| `tries.json` | `tries` | Clara vor dem 3. Versuch (`fehlversuche` = 2) |
| `goal.json` | `goal` | Anna vor dem Wurf, 3 Figuren im Ziel |
| `end.json` | `end` | Partie vorbei, Anna gewinnt |
| `home-running.json` | `home-running` | laufende Partie für „Weiterspielen“ |

`home`, `setup`, `rules` und `settings` brauchen keine Würfel. Für `home-running` und `end` füllt die App die Statistik mit `end.json`.
