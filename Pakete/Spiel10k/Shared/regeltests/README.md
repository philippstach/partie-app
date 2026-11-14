# Gemeinsame Regeltests (Swift ↔ Python)

Dieselben JSON-Dateien prüfen die Spiellogik der App (`TenK/Model`) und die Regel-Engine des Servers (`Server/regeln`). **Jede Regeländerung braucht zuerst einen neuen Fall hier.** Sie ist erst fertig, wenn Swift und Python grün sind.

- Python: `python -m pytest Server/regeln/tests` (vom Repo-Ordner aus, braucht nur pytest)
- Swift: Test in `TenKTests`, den schreibt Chat 2 (Anleitung unten)

## Regelstand

- `triples = "all"`: drei Einsen = 1.000, drei Gleiche sonst Augenzahl × 100.
- `triples = "onesAndFives"` (geändert am 30.09.2026): **drei Einsen = 500**, drei Fünfen = 500, andere Drillinge zählen nicht. Vier/fünf Einsen = 600/700.
- Vier oder fünf Gleiche zählen immer als Drilling plus Einzelne.

## `wertung.json`

Drei Listen:

| Liste | Felder | Swift-Aufruf |
|---|---|---|
| `wertung` | `dice`, `fullThrow`, `triples` (`all`/`onesAndFives`), optional `diceCount` (5/6) und `straight6` (`five`/`full`), `expectedScore` (Zahl oder `null` = ungültige Auswahl) | `Scoring.score(dice, fullThrow:, rules:)` |
| `nieten` | `dice`, `triples`, `expectedCanScore` (`false` = Niete) | `Scoring.canScore(dice, triples:)` |
| `besteAuswahl` | `dice`, `fullThrow`, `triples`, optional `diceCount`/`straight6`, `expectedPoints`, `expectedIndices` | `Scoring.bestSelection(dice, fullThrow:, rules:)` |

`name` ist nur zur Anzeige.

## `partien/*.json`

Eine komplette kleine Partie pro Datei:

```json
{
  "name": "…",
  "beschreibung": "…",
  "rules": { "diceMode": "real", "roundLimit": 2 },
  "players": ["Anna", "Ben"],
  "dice": [1, 2, 3, 3, 6, 5, 2, 2, 4],
  "steps": [
    {"action": {"type": "roll", "keep": []}},
    {"action": {"type": "roll", "keep": [0]}, "expect": {"turn": {"banked": 100}}},
    {"action": {"type": "bank", "keep": [9]}, "error": true}
  ],
  "expected": {"scores": [150, 0], "current": 1}
}
```

- **`rules`**: Teil-Objekt von `GameRules`, fehlende Schlüssel haben die Standardwerte (`GameRules()`).
- **`players`**: Namen. Avatar `""`, `colorIndex` = Position.
- **`dice`**: Würfelfolge für den `roller`, der Reihe nach. Gewürfelt wird nur bei `roll` und bei `acceptOffer` mit digitalen Würfeln, die freien Würfel in Positionsreihenfolge. Am Ende müssen **alle** Würfel verbraucht sein.
- **`action`**: flaches Aktions-JSON (D13), `type` ist einer von `roll`, `enterThrow`, `bank`, `layOut`, `acceptOffer`, `declineOffer`, `points`, `noPoints`, `undo`.
- **`"error": true`**: Die Aktion muss abgelehnt werden. Der Stand bleibt unverändert, und es wird nicht gewürfelt. (Swift ignoriert ungültige Aktionen still; im Test heißt das: Der `GameState` ist danach gleich wie davor.)
- **`expect`** (nach einem Schritt) und **`expected`** (am Ende) prüfen **nur die angegebenen Schlüssel**:

| Schlüssel | Vergleich mit |
|---|---|
| `current`, `winners`, `timeline`, `finalRoundFrom` | gleichnamiges Feld in `GameState` |
| `scores` | `players.map(\.score)` |
| `players` | Liste mit Teil-Objekten je Spieler (`score`, `streak`, `mackes` (JSON-Schlüssel, in Swift `nieten`), `bestTurn`, `turns`); `{}` = nicht prüfen |
| `turn` | Teil-Objekt von `DiceTurn`; `"inheritedFrom": null` heißt „nicht gesetzt“ |
| `offer`, `tiebreak` | Teil-Objekt (nur die angegebenen Schlüssel) oder `null` (= `nil`) |
| `log` | `log.map { [$0.player, $0.points, $0.penalty] }` |
| `canUndo` | `GameStore.canUndo` |

## Aktion `layOut` (echte Würfel, nur rausgelegte Würfel eintippen)

`{"type":"layOut","dice":[1,1],"bank":false}`. Seit 30.09.2026 ist das die Eingabe der App bei echten Würfeln („Würfel eintippen“). `enterThrow` bleibt als Aktion bestehen.

- **Bedeutung:** `dice` sind die Augen der Würfel, die der Spieler aus dem **aktuellen** Wurf rauslegt. Nicht punktende Würfel gibt er nicht ein. `bank` ist optional (Standard `false`):
  - `false` = danach mit den übrigen Würfeln weiterwürfeln
  - `true` = aufhören und die Punkte gutschreiben
- **Erlaubt, wenn** alles davon gilt:
  - `diceMode = real`
  - Spiel nicht beendet
  - kein offenes Angebot
  - `1 ≤ len(dice) ≤` offene Würfel (= Anzahl `locked == false`)
  - alle Augen in 1–6
  - `score(dice, fullThrow, triples)` ist nicht `null`
- **`fullThrow`** (nur Straße): `true` genau dann, wenn alle 5 Würfel offen sind **und** es nicht der erste Wurf nach einer Übernahme ist (`inheritedFrom` gesetzt und `keptThrows == 0`).
- **Wirkung:**
  1. Undo-Schnappschuss des Stands davor (Rückgängig nimmt je einen bestätigten Wurf zurück).
  2. Die ersten `len(dice)` offenen Positionen bekommen die Augen und werden `locked = true`.
  3. `selected` wird überall `false`, `hasRolled = false`, `fullThrow` wie oben.
  4. `banked += score`, `keptThrows += 1`. Es wird **nicht** gewürfelt, auch nicht bei `bank`.
  5. `bank = false`: Sind danach alle 5 `locked`, werden alle wieder frei (mit allen 5 weiter).
  6. `bank = true`: Der Zug endet mit `banked` Punkten, genau wie `bank`. Angebot mit `dice` und `kept = locked`; sind alle 5 rausgelegt, gilt `kept` = alle `false` (Übernahme mit allen 5, wenn `inheritAllFive`). Ausnahmen wie bei `bank`: Stechen, Spielende.
- **Niete:** `noPoints`, dafür werden keine Würfel eingegeben.
- **Übernahme:** `acceptOffer` wie bisher (bei echten Würfeln wird nicht gewürfelt). Danach `layOut` mit höchstens den offenen Würfeln.
- **Neues Feld im Zug:** `turn.keptThrows` (Anzahl bestätigter `layOut` im Zug, Start 0). Alte Stände ohne das Feld gelten als 0. Die App zeigt damit „Wurf N“.
- **Fehlerfälle** (Stand unverändert):
  - leere Liste, mehr Würfel als offen, Augen außerhalb 1–6
  - ungültige Wertung, z. B. `[2]` oder `[1,3]`
  - Straße nicht im vollen Wurf
  - digital, offenes Angebot, beendetes Spiel

Partien: `21_rauslegen_philipps_fall` (1, 1 → weiter → 1, 5 = 350), `22_rauslegen_alle_fuenf_und_strasse`, `23_rauslegen_uebernahme`.

## 5 oder 6 Würfel (`diceCount`, `straight6`)

Seit 01.10.2026. Zwei neue Felder in `rules` (Teil von `GameRules`):
- `diceCount`: 5 (Standard) oder 6. Andere Werte gelten als 5. Fehlt das Feld (alte Spielstände), gilt 5.
- `straight6`: nur bei 6 Würfeln, `"five"` (Standard) oder `"full"`.

**Zug und Angebot:** `turn.dice`, `turn.locked`, `turn.selected`, `offer.dice` und `offer.kept` haben `diceCount` Einträge. Ein neuer Zug hat `diceCount` Würfel. Überall, wo bisher „alle 5“ galt, gilt jetzt „alle `diceCount`“:
- voller Wurf (Straße)
- mit allen weiter
- Übernahme mit allen (`inheritAllFive`, der Name bleibt)
- `keptFullThrow`
- `nextRollCount`

**Wertung eines Wurfs** (`score(values, fullThrow, rules)`):
- **Normale Wertung**, bei 5 und 6 Würfeln gleich:
  - je Augenzahl höchstens ein Drilling, Rest einzeln
  - nur Einsen (100) und Fünfen (50) zählen einzeln
  - zwei verschiedene Drillinge zählen beide (2-2-2-4-4-4 = 600)
  - sechs Gleiche = Drilling + 3 Einzelne (1-1-1-1-1-1 = 1.300; 2-2-2-2-2-2 ist ungültig)
  - keine drei Paare
- **Straße**, nur bei `fullThrow`:
  - **5 Würfel:** genau 5 Würfel 1–5 oder 2–6 = 1.000
  - **6 Würfel, `five`:** Die Auswahl enthält eine 5er-Straße (1–5 oder 2–6) = 1.000. Ein weiterer Würfel muss 1 (+100) oder 5 (+50) sein, sonst ist diese Deutung ungültig. Beispiele: 1-2-3-4-5-5 = 1.050, 1-2-3-4-5-6 = 2–6 + einzelne 1 = 1.100.
  - **6 Würfel, `full`:** nur 1-2-3-4-5-6 = **1.500**. Der Wert ist vorläufig (Annahme des Architekten), Philipp kann ihn noch ändern; in Swift `Scoring.bigStraightPoints`. Eine 5er-Straße zählt bei dieser Regel nicht.
  - Gibt es mehrere gültige Deutungen, zählt die höchste.
- `canScore` bleibt unverändert: Jede Straße enthält eine 1 oder 5.
- `bestSelection` prüft bei 6 Würfeln alle 63 Kombinationen. Bei Gleichstand gewinnt die Auswahl mit weniger Würfeln.

Partien: `24_sechs_wuerfel_digital`, `25_sechs_wuerfel_grosse_strasse`, `26_sechs_wuerfel_fuenfer_strasse_eintippen`.

## Faire Schlussrunde (`finalRound`)

Seit 05.10.2026, **vorläufig** (Philipp kann die Regel noch ändern). Neues Feld in `rules`: `finalRound` (bool, Standard `false`). Fehlt es, gilt `false`.

Neues Feld im Spielstand: `finalRoundFrom` (Platz-Index oder fehlt/`null`). Es zeigt, wer das Ziel zuerst erreicht und damit die Schlussrunde ausgelöst hat. Alte Stände ohne das Feld gelten als „keine Schlussrunde“.

**Ablauf** in `finishTurn`, nur außerhalb eines Stechens:
1. Ist `finalRound` an und erreicht der Spieler am Zug das Ziel (`score >= goal`), setzt das `finalRoundFrom` (falls noch nicht gesetzt). Es gibt **keinen** sofortigen Sieg.
2. Solange `finalRoundFrom` gesetzt ist:
   - Ist nach dem Zug die Runde voll (`len(log) % Spielerzahl == 0`), wird nach Punkten entschieden, genau wie beim Rundenlimit. Ein Führender gewinnt. Bei Gleichstand gibt es ein Stechen der Führenden (`tiebreak = true`) oder einen gemeinsamen Sieg.
   - Sonst ist der nächste Platz dran, ein Angebot ist erlaubt wie sonst auch.
   - Wer in der Schlussrunde ebenfalls das Ziel erreicht oder überholt, löst nichts Neues aus.
3. Erreicht der letzte Platz der Runde das Ziel, ist die Runde sofort voll und das Spiel sofort entschieden.

Rückgängig stellt `finalRoundFrom` mit dem übrigen Stand wieder her.

Partie: `27_faire_schlussrunde`.

## So liest Chat 2 die Dateien in Swift ein

1. Den Ordner `Shared/regeltests` als **Folder Reference** (blauer Ordner) zum Target `TenKTests` hinzufügen, dann liegt er im Test-Bundle. Alternativ ohne Bundle über den Pfad der Testdatei:
   ```swift
   let root = URL(fileURLWithPath: #filePath)            // …/TenKTests/RegelTests.swift
       .deletingLastPathComponent().deletingLastPathComponent()
       .appendingPathComponent("Shared/regeltests")
   ```
2. `wertung.json` mit einem kleinen `Decodable` (`dice: [Int]`, `fullThrow: Bool`, `triples: TripleRule`, `expectedScore: Int?`) lesen und je Fall `Scoring.score` vergleichen.
3. Für jede Partie:
   - `GameStore` mit einem Wegwerf-Repository (wie in den bestehenden Tests) anlegen, `roller` auf die Würfelfolge setzen: `var i = 0; store.roller = { defer { i += 1 }; return dice[i] }`.
   - `startGame(players:settings:)` mit `GameSettings(...)` aus `rules`, `realEntry = .pips`.
   - Jede `action` direkt als `GameAction` dekodieren (flaches `Codable` aus D13, `JSONDecoder().decode(GameAction.self, …)`) und `store.perform(_:)` aufrufen.
   - Bei `"error": true`: Stand vorher und nachher vergleichen (gleich) und prüfen, dass `i` nicht weitergezählt hat.
   - `expect`/`expected` Schlüssel für Schlüssel wie in der Tabelle oben vergleichen.
   - Am Ende: `i == dice.count`.

Die Partien umgehen bewusst Anzeige-Themen (Nieten-Hinweis, Einblendungen, Töne). Geprüft wird nur der Spielstand.
