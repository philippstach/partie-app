# Arcade-Spiele

Gilt für Steinfall, Wolkenhüpfer, Dauerlauf, Mauerbrecher, Ballwechsel und alle künftigen Arcade-Spiele.

## Bausteine

| Baustein | Ort | Aufgabe |
|---|---|---|
| `ArcadeKern` (Foundation, `swift test`) | `Pakete/ArcadeKern` | `FesterTakt` (1/120 s), `ArcadePhase` (bereit, läuft, vorbei(grund)), `ArcadeZufall` (reproduzierbar), `Beutel`, `Kasten`/`Treffer.kreis`, `Schwierigkeit`, `Rekord` |
| `ArcadeHuelle` (SwiftUI) | `SpieleKern` | Kopf mit Punkten, Pause (auch bei App-Wechsel), „Tippe zum Starten“, „Aus!“-Anzeige, fester Takt |
| `SpielRahmen` | `SpieleKern` | Rekord auf der Startseite (`zeigtRekord: true`), Ende-Bildschirm „Aus!“ / „Neuer Rekord!“ / „Gewonnen!“ / „Verloren“ |
| `ArcadeAusgang` | `SpielEnde.arcade` | `sieg == nil`: Punktespiel (zählt als Partie, nie als Sieg); `sieg` gesetzt: Duell |
| `StatistikDienst.rekord(spiel:)` | `SpieleKern` | Rekord = höchste je gemeldete Punktzahl |

## Regeln für jedes Arcade-Spiel

1. **Spielschleife:** Das Spiel ist ein `struct` (Kern) mit `schritt(dt)`; die Hülle ruft es nur mit festem `dt`. Phase `bereit` → Tipp → `laeuft` → `vorbei(grund)`. Nichts bewegt sich vor dem ersten Tipp.
2. **Steuerung:** eine Hauptgeste (Ziehen oder Tippen), höchstens eine zweite (Wischen). Mit Nachsicht: Sprungpuffer, Landezeit, Schläger mit Höchstgeschwindigkeit statt Teleport.
3. **Kollision:** Treffer-Kästen kleiner als die Grafik; Schritt pro Frame kleiner als die Objektgröße; Auflösung über `Treffer.kreis`.
4. **Punkte und Rekord:** ganze Zahlen, steigen nur durch Spielhandlungen. Der Rekord kommt aus der Statistik. Punktespiele haben nie „Gewonnen“.
5. **Spielende:** Der Grund wird genannt (`vorbei(grund:)`), kurze „Aus!“-Anzeige, dann Ende-Bildschirm. Duelle melden Sieg oder Niederlage.
6. **Schwierigkeitskurve:** `Schwierigkeit.wert(start:grenze:t:halbwert:)` steigt anfangs spürbar und flacht dann ab. Hindernisse sind immer schaffbar (Bot-Test je Spiel).
7. **Tests:** jede Spiellogik hat einen Bot-Test (Spiel ist schaffbar), einen Nichts-tun-Test (Spiel endet mit „Aus“) und Regeltests.

## Haptik und Töne

`ArcadeRueckmeldung` (ArcadeKern) legt fest, was bei Treffer, Verlust und Rekord oder Sieg passiert. Die `ArcadeHuelle` löst es selbst aus und spielt
es über `ArcadeFeedback` (Haptik und Systemtöne); in den Spielen ist dafür kein Code nötig. Schalter: Einstellungen › „Töne“ (`toeneAn`) und „Haptik“
(`haptikAn`). Treffer sind auf 0,12 s gedrosselt, in der Pause ist alles stumm.

## Die Spiele

- **Steinfall:** Fünferteile, 10 × 18, Beutel-Zufall, Landezeit, Schatten, Sofort-Fall.
- **Wolkenhüpfer:** Finger lenkt seitlich, Randumbruch; jede Wolkenreihe ist erreichbar, brüchige Wolken und Federn als Zugabe.
- **Dauerlauf:** Hürde und Loch (springen), Balken (ducken); Abstände aus Flugzeit und Reaktionszeit beim aktuellen Tempo.
- **Mauerbrecher:** Mauer rückt nach unten, Serie bis ×4, Gaben (breit, drei Bälle, Leben), drei Leben, Level mit Mustern.
- **Ballwechsel:** Duell bis 7, Ball wird pro Schlag schneller, Computer mit Reaktionszeit, Irrtum und Ausgleich nach Spielstand.
