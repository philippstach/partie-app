# Rauswurf – Ludo · Regeltests

Erzeugt von `Referenz/erzeuge_tests.py`, geprüft von `Referenz/pruefe_tests.py`. **Nie von Hand ändern.**
iOS und Android lesen genau diese Dateien. Alle Felder sind in camelCase.

- **Positionen** sind relativ: `-1` Haus, `0–39` Laufbahn (0 = eigenes Startfeld), `40–43` Ziel (SPEZIFIKATION Abschnitt 3).
- **`optionen`** ist immer ein Teil-Objekt. Fehlende Schlüssel bekommen den Standardwert (SPEZIFIKATION Abschnitt 6).
- **`lage`** = `{sitze: [..], figuren: [[Positionen] je Spieler]}`. Je Spieler stehen so viele Positionen, wie die Option `figuren` sagt (Standard 4, auch 3 oder 2). Spieler-Index = Index in `sitze`, `sitze` ist aufsteigend.
- **`zug`** = `{von, nach, schlaegt}`. `schlaegt` ist der Index des geschlagenen Spielers oder `null`.

| Datei | Prüft | Ein Fall |
|---|---|---|
| `brett.json` | Geometrie für die Oberfläche | `raster` (11), `laufbahn[40]` = (x, y) je absolutem Feld, `haus[sitz][4]`, `ziel[sitz][4]` (rel 40–43), `start[sitz]` |
| `zuege.json` | `alleZuege` und `moeglicheZuege` | `lage`, `spieler`, `augen`, `optionen` → `erwartet.alle` (nur Bewegungsregeln), `erwartet.erlaubt` (nach Pflichten); beide in fester Reihenfolge (nach `von` aufsteigend). Dazu `blockiert[]`: `lage`, `spieler`, `optionen` → `erwartet` (bool) |
| `spielzug.json` | ein ganzer Spielzug (Extrawurf nach 6, drei Versuche, verfallene Würfe) | `lage`, `spieler`, `wuerfel[]`, `optionen`; gewählt wird **immer der erste erlaubte Zug** → `erwartet.wuerfe[]` (`{augen, zug \| null}`), `verbraucht` (Anzahl genommener Würfel, der Rest bleibt übrig), `figuren` (alle Spieler danach), `fertig` |
| `computer.json` | Entscheidung „einfach“ und „gut“ | `lage`, `spieler`, `augen`, `optionen` → `erlaubt[]`, `gutWerte[]` (ganze Zahlen, gleiche Reihenfolge wie `erlaubt`), `einfach`, `gut` |
| `partien/*.json` | ganze Partien | siehe unten |
| `lieb.json` | Computer „lieb“ (SPEZIFIKATION 7.3) | `faelle` wie `computer.json`, dazu `menschen[]` → `liebWerte[]`, `lieb`; `partien[]` wie `partien/*.json` mit `menschen[]` (die Menschen ziehen dort wie „gut“) |
| `reaktionen.json` | Emoji-Blasen (SPEZIFIKATION 7.4) | je Partie (`partie` = Pfad in `partien/`) die Liste `blasen[]`, ein Eintrag je Spielzug: `{spieler: emoji}` (Schlüssel als Text) |
| `echt.json` | echte Würfel (SPEZIFIKATION 8.1) | wie `partien`, aber mit `wuerfelArten[]` (`app` / `echt` je Spieler), `appWuerfel[]` und `eingaben[]`. Wer `echt` hat, bekommt seine Würfe aus `eingaben`, alle anderen aus `appWuerfel`. Beide Listen müssen genau aufgehen |

## partien/*.json
```
name, beschreibung, optionen, sitze[], strategien[] (je Spieler "einfach" | "gut"), beginner,
wuerfel[]                  – Würfelquelle, wird der Reihe nach verbraucht, muss genau aufgehen
erwartet.zuege[]           – je Spielzug: {spieler, wuerfe[] ({augen, zug | null}), figuren (alle Spieler danach)}
erwartet.platzierung[]     – Spieler in der Reihenfolge, in der sie fertig wurden
```
- Der erste Spielzug gehört dem `beginner`. Danach ist reihum der nächste Spieler dran, der noch nicht fertig ist.
- `figuren` vergleicht exakt, also auch den Figuren-Index. Aus dem Haus kommt immer die Figur mit dem kleinsten Index.
- **Jede Plattform prüft zweimal:**
  - (a) Nachspielen mit den aufgezeichneten Zügen. Jeder muss in `moeglicheZuege` vorkommen.
  - (b) Nachspielen mit der Computer-Strategie aus `strategien`. Gibt es genau einen erlaubten Zug, wird er ohne Strategie genommen.

  Beide Durchläufe müssen jeden Spielzug treffen.
- Die Partien sind lang (bis einige hundert Spielzüge). Das ist Absicht, sie decken fast jede Regel-Kombination ab.
