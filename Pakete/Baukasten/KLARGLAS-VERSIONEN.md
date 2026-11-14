# KlarGlas – Versionen (R4: was ist neu, welche Apps müssen nachziehen)

Jede Änderung am Produkt `KlarGlas` bekommt hier einen Eintrag und erhöht `KlarGlas.version` (`Sources/KlarGlas/KlarGlas.swift`).
`tor.sh` meldet Apps, die eine ältere Fassung eingebunden haben (Vergleich mit `Screenshots/ios/tor-<build>.txt`).



## 2.51 – 14.11.2026 (Blatt 26b, Integrator)

Patch `Doku/Patches/klarglas-anleitung-ohne-weiter.patch` (gegen älteren Stand; 4 von 6 Teilen sauber, 2 von Hand): Anleitung ohne
„Weiter“, Wischen oder Tippen auf die Punkte, „Los geht’s“ nur auf der letzten Seite. Fließtext außerhalb von Tinte kräftiger
(primary 88 %); in Tinte bleibt `schriftZweit` aus 2.48. Material-hell (2.48) und Filz-Bühne (2.47) unverändert.

## 2.50 – 13.11.2026 (Blatt 24b, ST Stufe 2, Integrator)

`DesignWahl.swift` DesignWurzel: in Tinte zusätzlich `.toggleStyle(SchalterStil())`, jeder blanke Toggle wird der gemeinsame
Schalter (an grün, aus grau, gesperrt blass seit 2.49). `Einstellungen.swift` SchalterGrafik: in Tinte Spur 63 × 28, länglicher
Knopf 37 × 24. Klar und Salon unverändert. Im Baukasten selbst gibt es keine weiteren `Toggle(`. Rücknahme: Patch
`Doku/Patches/klarglas-2.50-schalter-tinte.patch` rückwärts anwenden und Fassung auf 2.49.

## 2.49 – 13.11.2026 (Nachtschicht Build 25, Integrator)

Auftrag des Kern-Chats (Feedback Build 24). A `Spiel.swift` SpielerLeiste: Name eines Spielers, der nicht dran ist, in Tinte
`Color.schrift.opacity(0.82)` statt `schriftZweit` (Klar/Salon unverändert). B `Einstellungen.swift` SchalterZeile: liest
`isEnabled`; gesperrt Grafik 45 % Deckkraft, kein Umschalten (Tippen, Grafik, VoiceOver-Aktion), alle Designs. C `DesignWahl.swift`
navigationsleisteAnwenden: großer Serifentitel höchstens 34 pt (normale Schrift unverändert).

## 2.48 – 13.11.2026 (Design-Runde 5, Blatt 11 Nacharbeit, Integrator)

Patch `design-runde-3/klarglas-anleitung-material-hell.patch` (Design-Chat, gegen 2.47) sauber angewendet. Nur Tinte:
`Anleitung.swift` – AnleitungWuerfel, AnleitungKarte und AnleitungKachel bleiben auf dem Filz helles Material (helles
Farbschema); Fließtext und „Überspringen“ in `Color.schriftZweit` statt Systemgrau. Klar und Salon unverändert.

## 2.47 – 13.11.2026 (Design-Runde 5, Blatt 11, Integrator)

Patch `design-runde-3/klarglas-anleitung-buehne-filz.patch` (Design-Chat, gegen 2.46) sauber angewendet. Nur Tinte:
`Anleitung.swift` – die Bühne der Anleitung am Tisch ist ein rundes Stück Filz statt eines eckigen Kastens. Klar und Salon unverändert.

## 2.46 – 13.11.2026 (Design-Runde 5, K2 + R1, Integrator)

Patch `design-runde-3/klarglas-kopf-rund-tinte.patch` (Design-Chat, gegen 2.43) sauber auf 2.45 angewendet. Nur Tinte:
`RundKnopfFlaeche` bei dunklem Farbschema runde helle Fassung (44/36 pt); `SpielKopf.links` am Tisch `RundKnopf` mit
`chevron.left` statt „‹ Start“; `StatusChip` ohne Unterstrich; Ergebnisseite (`protokoll`): „Teilen“ und „Partie ansehen“
als Kapsel, Schließen als eigener Kreis 44 pt. Klar und Salon unverändert.

## 2.45 – 13.11.2026 (Große Tinte-Runde, Integrator)

`klarglas-2.45-darstellung-gross.patch`, baut auf 2.44 auf. `KlarGlas.version` 2.45.
- `DarstellungsAuswahl`: in Tinte bei Schriftgrößen der Bedienungshilfen Wert unter der Bezeichnung (Paket S); Klar und Salon unverändert.
- `SpielerListe` (nur Tinte, Bedienungshilfe-Schrift): Art (Mensch/Computer) als Wort in einer zweiten Zeile unter dem Namen (Paket K, Punkt 2); Klar/Salon unverändert.
- Neu: `Miniatur.zahlenkarten` (Karten 10 · 11 · 12) für Elfer raus (Paket B, Punkt 14e).

## 2.44 – 13.11.2026 (Design-Runde 3, Integrator)

`klarglas-2.44-spielerleiste-tinte.patch` (vom Design-Chat), baut auf 2.43 auf. `KlarGlas.version` 2.44.
- `SpielerLeiste` in Tinte: aktiver Spieler auf runder (18 pt), durchscheinender Fläche (Schriftfarbe 14 %) statt Feldgrund – passt auf Filz und Papier (Philipps Freigabe Punkt 2).

## 2.43 – 13.11.2026 (Build 22, Integrator)

`klarglas-2.43-schalterzeile-text.patch`, baut auf 2.41 auf (2.42 war zurückgenommen). `KlarGlas.version` 2.43.
- F21-006 (sechster Anlauf): `SchalterZeile` – Tippen auf Name/Erklärung schaltet um; die Grafik behält ihr eigenes Tippen; keine Geste auf der ganzen Zeile.

## 2.42 – 13.11.2026 (Build 22, Integrator) – ZURÜCKGENOMMEN 13.11. 08:06 (Schalter ließen sich im Salon nicht mehr umschalten); gültig ist 2.41

`klarglas-2.42-schalterzeile-tippen.patch`, baut auf 2.41 auf. `KlarGlas.version` 2.42.
- F21-006: `SchalterZeile` – Tippen an der ganzen Zeile statt an der Grafik; die Grafik ist reine Darstellung.

## 2.41 – 13.11.2026 (Build 22, Integrator)

`klarglas-2.41-schaltergrafik.patch`, baut auf 2.40 auf. `KlarGlas.version` 2.41.
- F21-006 (vierter Anlauf): `SchalterZeile` zeigt eine eigene `SchalterGrafik` (Kapsel + Knopf, 51 × 31 pt) statt eines verborgenen System-Toggles; damit liegt kein UISwitch mehr im Bedienungshilfen-Baum.

## 2.40 – 13.11.2026 (Build 22, Integrator)

`klarglas-2.40-schalterzeile.patch`, baut auf 2.39 auf. `KlarGlas.version` 2.40.
- F21-006 (dritter Anlauf): Neuer Baustein `SchalterZeile`. `SchalterStil` (Einstellungen, grün) und `BlattSchalterStil` (klar) bauen keinen zweiten Toggle mehr; die Zeile ist EIN Element mit Name, Merkmal Schalter, „ausgewählt“ und Aktion, der sichtbare Schalter ist für VoiceOver verborgen.

## 2.39 – 13.11.2026 (Build 22, Integrator)

`klarglas-2.39-blattschalter.patch`, baut auf 2.38 auf. `KlarGlas.version` 2.39.
- F21-006: `BlattSchalterStil` (klar) gibt den Schalter mit `Toggle(configuration)` weiter statt einen zweiten Toggle zu bauen; kein namenloser Zweit-Schalter mehr im Bedienungshilfen-Baum (Hausregeln Rauswurf/Schocken u. a.).

## 2.38 – 13.11.2026 (Build 22, Integrator)

`klarglas-2.38-art-ausgewaehlt.patch`, baut auf 2.37 auf. `KlarGlas.version` 2.38.
- F21-001: Art-Auswahl (Mensch/Computer) in der `SpielerListe`: die gewählte Art trägt für VoiceOver „ausgewählt“, die andere nicht.

## 2.37 – 13.11.2026 (Build 20, Integrator)

`KlarGlas.version` 2.37. Eingespielt in dieser Reihenfolge auf 2.30/2.26/2.27/2.34: 2.35, 2.36, 2.37 (Teil A als Patch, Teil B von Hand; zusammen `klarglas-2.37-knopfleiste-AB.patch`).
- 2.35 (N-023, N-005): `RundKnopfMenue` und Art-Auswahl im Neues-Spiel-Blatt mit `accessibilityRepresentation` (Menü bzw. Auswahl „Art“), kein namenloser Knopf mehr.
- 2.36 (N-003, Cloud-Chat): `KaestchenStil` ist ein einziges Element mit Namen, Merkmal Schalter und „ausgewählt“.
- 2.37 (A-002, A-004, A-005, A-008, Cloud-Chat): Bei Bedienungshilfe-Schrift keine feste Knopfleiste in `SpielStartSeite` und „Los geht's“ am Ende des Inhalts im `NeuesSpielBlatt`; Rollbalken sichtbar.
- Ohne Vorprüfung am Gerät eingebaut (Philipps Entscheidung 13.11. 00:46); Gegenprüfung auf Build 20.

## 2.34 – 12.11.2026 (Build 19, Integrator, Fund aus Chat 3)

`klarglas-2.34-nebenknopf.patch`, baut auf 2.25 auf. `KlarGlas.version` steht auf 2.30 (höchste eingespielte Patch-Fassung aus den Fix-Chats); 2.34 hebt die Nummer nicht, damit die reservierten Nummern 2.27–2.33 ihre Versionszeile sauber setzen können.
- Behoben (K-037): `NebenKnopf` – der Kommentar aus 2.22 stand mitten in der Zeile und verschluckte den else-Zweig. In Tinte und Salon fehlte dadurch jeder `.nebenKnopf()` (z. B. „Tipp“ in Rommé, Elfer raus, Solitär).
- Geändert (N-007): `KompaktKnopfStil` (nur Tinte und Salon) hat jetzt `minHeight: 44` statt 36. Dazu `wortKnopf` in `Spiel.swift` (Tinte, Salon) mit `minWidth: Theme.tapSize` (Solitär „Tipp“, „Neu“).
- Behoben (N-003): `KaestchenStil` (Tinte, Salon) – die Bedienungshilfe-Darstellung fasst das Label zusammen, VoiceOver nennt das Kästchen jetzt beim Namen (auch Minensuche-Einstellungen).
- Geändert (N-020): Abschnitts-Label (`Design.Schrift.label`, Tinte/Salon, z. B. `KartenKopf`) wächst bis 2,2-fach statt 1,35-fach; Tageskreise im `TagesKalender` wachsen per `@ScaledMetric` von 36 bis höchstens 46 pt.
- Apps müssen nichts nachziehen.

## 2.27 – 12.11.2026 (Build 19, Blatt-Chat)

`klarglas-2.27-name-einzeilig.patch`, baut auf 2.30 auf. Neu: `SpielStartSeite.nameEinzeilig` – Spielname aus einem Wort bleibt im Salon einzeilig (F-AWS-K-038).

## 2.26 – 12.11.2026 (Build 19, Blatt-Chat)

`klarglas-2.26-blatt.patch`, eingespielt nach 2.34. Apps müssen nichts nachziehen; der SpielRahmen (fix-b19-blatt) nutzt `losHinweisAnsage`.
- Geändert: `NeuesSpielBlatt` wächst als Ganzes gleichmäßig bis `accessibility2` (F-AWS-G-002, N-018). `SpielerListe` ohne eigene Deckelung, Zeilenhöhe wächst mit der Schrift (56 bis 96 pt), bei Schriftgrößen der Bedienungshilfen zeigt das Art-Menü nur das Symbol.
- Geändert: Art-Menü der Spielerzeile mit `menuStyle(.button)` wie `RundKnopfMenue`, Inhalt für VoiceOver verborgen; der Name „Art“ und der Wert kommen jetzt an (F-AWS-N-005, vorher 68×42 ohne Namen).
- Geändert: `RundKnopfMenue`: Glasfläche im Menü für VoiceOver verborgen, kein namenloser Knopf im Knopf „Mehr“ (F-AWS-N-023). Hinweis: `Knoepfe.swift` liegt außerhalb meines Bereichs, Änderung ist eine Zeile.
- Geändert: Namensfeld der Spielerliste markiert beim Antippen den vorbelegten Namen, Tippen ersetzt ihn (F-AWS-M-008, „AnnaAnna“).
- Geändert: `NeuesSpielBlatt` sagt die Meldung bei gesperrtem „Los geht's“ auch per VoiceOver an; neuer Parameter `losHinweisAnsage` (F-AWS-T-017).
- Geändert: Ende-Bildschirm (`EndeKern`): Name des Spiels in allen drei Designs in der Kopfzeile (aus `endeSpielName`, sonst `KlarGlasHaken.spielName`); Untertitel entfällt, wenn er den Sieger wiederholt; Klar & Glas: „Teilen“ als beschrifteter Glasknopf statt kleinem Symbolkreis (F-AWS-G-017, N-024, T-021).

## 2.30 – 12.11.2026 (Build 19, Hüllen-Chat)

`KlarGlas.version` 2.30 (`klarglas-2.30-starttitel.patch`, baut auf 2.25 auf; unabhängig von 2.26 bis 2.29, die Versionszeile kann beim Zusammenführen bleiben oder auf die höchste Nummer gesetzt werden).
- Neu: `StartTitel.einzeilig(_:)` hält den Titel im Salon bei einer Zeile (verkleinern statt mitten im Wort brechen; F-AWS-K-038, „Galgenmännchen“).

## 2.25 – 12.11.2026 (Build 18, Rätsel-Chat)

`KlarGlas.version` 2.25 (`klarglas-2.25-knoepfe.patch`, baut auf 2.24 auf).
- Geändert: `HauptKnopfStil`, `ZweitKnopfStil` und `NebenKnopfStil` (klar, Tinte) wachsen mit der Schrift bis `accessibility2` (vorher bei `xxxLarge` gedeckelt; F-AWS-M-015).

## 2.24 – 12.11.2026 (Build 18, Rätsel-Chat, Übernahme von Kern/Navigation)

`KlarGlas.version` 2.24 (`klarglas-2.24-uebernahme.patch`, baut auf 2.23 auf).
- Geändert: `SpielZeile` liest Spielart und Spielerzahl im Label vor (N-008); bei großer Schrift schmalere Miniatur und bis zu drei Zeilen Untertitel (K-004).
- Neu: `EnvironmentValues.endeSpielName`; die Tinte-Endseite zeigt „Spiel · Protokoll · Datum“ (N-024). Minensuche setzt ihn, andere Spiele können folgen.

## 2.23 – 12.11.2026 (Rätsel: N-020 Abschnittstitel/Symbolknöpfe)

`KlarGlas.version` 2.23 (`klarglas-2.23-raetsel.patch`, baut auf 2.22 auf). Eintrag vom Integrator.

## 2.22 – 12.11.2026 (Build 18, Kern und Navigation)

`KlarGlas.version` 2.22 (`klarglas-2.22-kern-navigation.patch`, baut auf 2.21 auf).
- Geändert: `SpielerListe`: Namensfeld mit ausdrücklichem VoiceOver-Namen „Name“ und dem eingetragenen Namen als Wert (F-AWS-N-001).
- Geändert: `HauptKnopfStil` gesperrt: Deckkraft 0,6 statt 0,4 (F-AWS-K-021, „Abwerfen“ in Rommé dunkel kaum lesbar).
- Geändert: `StatusChip` im Salon, Ton `akzent` ohne eigene Farbe: Schriftfarbe statt App-Farbe (F-AWS-K-026, Klondike rosa auf rot). Klar & Glas und Tinte unverändert.
- Geändert: `nebenKnopf()` in Klar & Glas mit `controlSize(.large)`, damit die Tippfläche 44 pt erreicht (F-AWS-N-007). Dadurch werden Zweitknöpfe in Klar & Glas etwas höher.
- Geändert: `NeuesSpielBlatt` bei Schriftgrößen der Bedienungshilfen immer ganz hoch (F-AWS-G-002, N-018); sonst bleibt die Höhe nach Inhalt.
- Geändert: `NeuesSpielBlatt`: „Los geht's" schließt bei sichtbarer Tastatur erst die Tastatur und startet nach 0,4 s (F-AWS-G-015, Blatt blieb über dem Spiel stehen; einmalig beobachtet, Ursache vermutet). Art-Menü der Spielerzeile nennt den Wert („Mensch"/„Computer") für VoiceOver (F-AWS-N-005).
- Sonst Darstellung unverändert.

## 2.21 – 11.11.2026 (Designwechsel: Voreinstellung, Auswahl öffentlich)

`KlarGlas.version` 2.21 (`klarglas-2.21-designwechsel.patch`, baut auf 2.20 auf).
- Neu: `DesignWahl.voreinstellung` / `setzeVoreinstellung(_:)`. Das Design ohne gespeicherte Wahl; im Baukasten weiter `klar` (Paket-Tests, Vorschauen, Bildwerkzeuge unverändert), eine App setzt ihren Standard beim Start (Partie: Tinte, `PartieGeteilt.standardDesign`).
- Geändert: Die Wahl wird immer ausdrücklich gespeichert (auch `klar`); vorher löschte `klar` den Eintrag, was bei abweichender Voreinstellung die Wahl verloren hätte. Gespeicherte Wahlen bestehender Nutzer bleiben gültig.
- Geändert: `Design.umschalterOeffentlich = true`: die Auswahl steht für alle in „Start und Aussehen“ (nicht mehr nur im Entwicklermodus).
- Geändert: `SpielerLeiste` (Tinte, Salon): beide Namen in derselben Schriftfamilie (Salon Serife, aktiv fett mit Punkt, nicht aktiv normal in „Schrift zweit“; Tinte nicht aktiv ebenfalls „Schrift zweit“). Gilt damit auch für Pokerwurf und Herzensjagd.
- Darstellung in Klar & Glas unverändert.

## 2.20 – 11.11.2026 (Designwechsel, nur Versionsnummer)

`KlarGlas.version` steht auf 2.20, passend zur Patch-Nummer (`klarglas-2.20-designwechsel.patch`, baut auf 2.19 auf). Keine Änderung an Bausteinen, kein Unterschied in der Darstellung.
Die Patches 2.18 und 2.19 setzten die Konstante nicht mit (sie stand auf 2.18); 2.19 (iPad-Schriftfaktor, `DesignBreit.swift`) gilt als in 2.20 enthalten.

## 2.18 – 10.11.2026 (Designwechsel, Nachträge nach dem Stand von Integration)

Baut auf 2.17 auf (2.17 ist im gemeinsamen Baukasten schon eingespielt). Nur für Salon und Tinte, „klar“ bleibt unverändert.
- `SiegerBildschirm` (Salon): Schlagzeile liegt über dem Porträt (zIndex) und überlappt nur noch 14 pt, damit der erste Buchstabe nie verdeckt wird.
- Neu: `View.designFlaeche(_ radius:)`: Fläche eines Spielfeld-Abschnitts. In klar genau `.background(Color.kartenGrund, in: .rect(cornerRadius: radius))`, in Tinte und Salon nur eine Haarlinie unten.

## 2.17 – 10.11.2026 (Designwechsel: Klar & Glas, Tinte, Salon)

Drei wählbare Designs. `klar` ist das bisherige Aussehen und die Voreinstellung: Wer nichts umstellt, sieht keinen Unterschied.

Neu (Design-Ebene):
- `DesignArt` (klar, tinte, salon), `DesignWahl.geteilt` (beobachtbar, gespeichert unter „design.art“), `Design.art`, `Design.werte`,
  `Design.ist(_:)`, `Design.umschalterOeffentlich`, `EnvironmentValues.designArt`, `View.designWurzel()`, `Design.navigationsleisteAnwenden()`.
- `DesignWerte` (drei feste Instanzen), `FarbPaar`, `SpielartFarben`, `Design.Spielart`, `KartenWerte`, `WuerfelWerte`, `Kontrast`.
- Farbrollen: `Color.seitenGrund`, `kartenGrund`, `feldGrund`, `linie`, `linieStark`, `schrift`, `schriftZweit`, `schriftBlass`, `knopfFlaeche`,
  `schriftAufKnopf`, `Color(hell:dunkel:)`. In klar sind es die Systemfarben.
- Schrift-Rollen in `Design.Schrift` (`titelSchrift`, `schlagzeileSchrift`, `name`, `neben`, `label`, `zahl`, `serif`, `text`, `skaliert`),
  `Design.zahlDesign`, Typalias `KlarGlasDesign`.
- Haken: `KlarGlasHaken.spielart`, `designGewechselt`, `spielerBild`, `spielName`.
- Bausteine: `DesignAuswahl`, `SpielStartSeite`, `ZeilenLinie`, `DesignZeile`, `DesignWertZeile`, `KaestchenStil`, `linieUnten()`, `designLabel()`,
  `unterstrichen()`, `designListe()`, `designZeilen()`, `tischKarte()`, `EnvironmentValues.knopfFarben` und `spielZeileZusatz`,
  `MiniaturAnsicht(…, strich:)`, `StartTitel(titel:untertitel:)`.

Geändert (je Design ein Zweig, Schnittstellen unverändert): alle Bausteine aus `KlarGlas.swift`, `Knoepfe.swift`, `Spiel.swift`, `Startseite.swift`,
`Sammlung.swift`, `NeuesSpiel.swift`, `Ende.swift`, `Hinweis.swift`, `Anleitung.swift`, `Einstellungen.swift`, `Tagesraetsel.swift`.
`Color.onAccent` ist jetzt berechnet (klar: Weiß). `Theme.seitenRand` liest `Design.Abstand.seite` (klar 16).
`nebenKnopf()` steht jetzt in `Knoepfe.swift` (klar weiter `.bordered`).

Wer nachziehen muss: niemand, solange das Design „klar“ gilt. Apps, die die neuen Designs anbieten wollen, setzen die Haken
(`spielart`, `designGewechselt`), hängen `designWurzel()` an die Wurzel und ersetzen feste Systemfarben durch die Rollen
(in Partie: `Werkzeug/design_farben_umstellen.py`). Texte: neue Schlüssel in de, en, es, fr.
## 2.16 – 10.11.2026 (Testflight-Rückmeldung Build 10)

`NeuesSpielBlatt`: Ist „Los geht's“ gesperrt (`losAktiv: false`), wird der Knopf nur noch abgedunkelt, nicht mehr deaktiviert. Tippen darauf zeigt
über dem Knopf eine Meldung mit Warn-Haptik, welche Pflichtfelder fehlen. Neuer optionaler Parameter `losHinweis: LocalizedStringKey?`
(Text der Meldung; ohne Angabe „Bitte zuerst alle Pflichtfelder ausfüllen.“). Aufrufer ohne Parameter funktionieren unverändert; Apps sollten
einen konkreten Text übergeben (z. B. „Bitte zuerst beide Namen eintragen.“). Ein neuer Schlüssel (de, en, es, fr).

## 2.15 – 09.11.2026 (Design-Punkt DP2)

`SiegerBildschirm`: Teilen- und Schließen-Rundknopf oben stehen jetzt in voller Größe (44 pt statt 36 pt, `klein: false`). Sonst unverändert; niemand muss nachziehen.

## 2.14 – 09.11.2026 (Design-Zentralisierung, Runde 2)

`Design.heldSymbolGroesse` und `View.nebenKnopf()` (heute `.buttonStyle(.bordered)`) in `Design.swift`. Aussehen identisch; niemand muss nachziehen.

## 2.13 – 09.11.2026 (Design-Zentralisierung)

Neu `Design.swift`: zentrale Stelle für Farben (`Design.Farbe`), Abstandsstufen, Eckenstufen, Titelgröße, Maße und drei Regler
(`Design.Regler.abstand/ecken/schrift`, Voreinstellung 1,0 = Aussehen unverändert). `Theme.*` liest nur noch daraus
(Quellkompatibel; `static let` wurde `static var`). Wer nachziehen muss: niemand, Aussehen identisch.

## 2.12 – 08.11.2026 (Partie-Chat Spieler, Build 7)
`SpielerEintrag.bild: Data?` und `SpielerAvatar(…, bild:)`: Foto im Kreis statt Zeichen/Initiale, Rand in Spielerfarbe. Die Spielerliste im
Blatt „Neues Spiel“ zeigt das Foto automatisch, sobald die App `bild` setzt. Alles optional (nil); Apps müssen nicht nachziehen.

## 2.11 – 07.11.2026 (Partie-Chat Anleitung, Philipps Livetest)
Neu `Anleitung.swift`: `AnleitungBlatt` (Sheet zum Durchwischen: Seiten, Punkte, „Weiter“/„Los geht’s“, „Überspringen“),
`AnleitungSchritt` (Symbol, Titel, Text, `geste`, eigene Bühne mit `fortschritt` 0…1), `AnleitungBuehne` (zarte App-Farb-Fläche mit
animiertem Finger: `.tippen`, `.wischen`, `.ziehen`, `.halten`), `AnleitungGeste`. Bei „Bewegung reduzieren“ steht die Bühne still.
Apps müssen nicht nachziehen; ein Spiel ersetzt seine Textliste im Regeln-Blatt durch `AnleitungBlatt` (kein Dialog beim ersten Start).
Texte: drei neue Schlüssel (de, en, es, fr).

## 2.10 – 06.11.2026 (Design-Chat, W16 Tor-Altlasten Partie)
Neu `Farben.swift`: `Familienfarbe` (elf App-Farben + `nachtblau`, `graphit`) mit `flaeche`/`textHell`/`textDunkel`/`color`
und `Familienfarbe.spieler`. Zweck: Apps und Pakete (SpieleKern, Widget) schreiben keine Hex-Literale mehr, sondern
`Familienfarbe.rot.flaeche`; `design_pruefung.py` zählt dann 0. Werte identisch mit `AkzentFarbe` (Produkt `Baukasten`)
und DESIGN.md A.1.
`StatusChip` zusätzlich mit `Text`, `ton` (.akzent/.warnung/.neutral) und `farbe` (Legenden) – ersetzt eigene Pillen in Schocken/10k/Yacht/Wortpfeil/Minensuche.
Neu `View.toast()`: Hinweiskarte ohne Glas für kurze Meldungen (ersetzt `.regularMaterial, in: .capsule`).
`prominentButton()` bleibt nur für Altbestand; die Apps nutzen `hauptKnopf()`.

## 2.9 – 05.11.2026 (Design-Chat Partie, Startseite „Spieleabend“, Philipps Wahl C)

| Wunsch | Baustein | Änderung |
|---|---|---|
| Startseite Partie | neu `Sammlung.swift`: `Miniatur`, `MiniaturAnsicht` | gezeichnetes Spielmaterial (Kartenfächer, Würfel, Brett, Gitter, Buchstaben …) statt SF-Symbol, 64 × 48 pt, skalierbar |
| | `SpielZeile` | Zeile mit Bildfeld in der Spielart-Farbe links, Name und Untertitel rechts, Herz bei Favoriten |
| | `FilterChip` | Pille für Spielart-Filter auf dunklem Grund (aktiv weiß), optional Farbpunkt oder Symbol |
| | `spieleabendGrund(_:)` | dunkler Nachtblau-Verlauf als Tisch, Inhalt in dunkler Darstellung |
| | `hauptKnopf(hell:)` | Hauptknopf weiß mit Schrift in App-Farbe, nur auf `spieleabendGrund` |
| | `StartTitel` | liest `\.startTitelFarbe` aus der Umgebung (Weiß auf dem Tisch); ohne Wert wie bisher App-Farbe |
| Barrierefreiheit | `SpielerLeiste` | bei `\.farbenUnterscheidbar` ein Formzeichen je Sitz (Kreis, Quadrat, Dreieck, Raute, Stern, Sechseck) am Avatar und als Dran-Marke; `SpielerLeiste.sitzZeichen` für Spiele, die ihre Steine damit kennzeichnen wollen |
| Start | `SpielZeile(marke:)` | kleine Pille rechts neben dem Namen („Neu“), in der Spielart-Farbe, VoiceOver liest sie mit |
| Miniaturen | `Miniatur.domino/.turm/.labyrinth` | drei weitere Motive (Domino, Turm von Hanoi, Irrgarten) |
| Barrierefreiheit | `\.farbenUnterscheidbar` (EnvironmentValues), `SpielZeile(zeichen:)` | App-Schalter „Farben unterscheidbar“ (G2) für alle Bausteine und Spiele lesbar; Spielzeile mit Spielart-Zeichen in der Ecke, VoiceOver liest Name, Favorit und Untertitel als ein Element |
| Blätter der Sammlung | `SpielZeile(hell:)`, `SpielartLabel`, `SpielBild` | helle Zeilenfassung für Neues Spiel/Suche/Was spielen wir, Gruppenüberschrift mit Farbpunkt, großes Bildfeld fürs Spielprofil |

Nur die Sammlung (Partie) nutzt die neuen Bausteine; alle anderen Apps bauen unverändert. Vorlage: `Partie/Design/Entwurf/Startseite/C-spieleabend.png`.

## 2.8 – 05.11.2026 (Design-Chat, Bausteinwunsch 16 aus Rauswurf-T3, AXXXL)

| Wunsch | Baustein | Änderung |
|---|---|---|
| 16 Rangliste AXXXL | `SiegerBildschirm` (Rangliste `RangEintrag`) | Platz einzeilig und so breit wie nötig (vorher feste 22 pt, „1.“ brach um), Name und Punkte einzeilig mit Schrumpfen bis 0,6, Karte wächst nur bis `xxxLarge` (wie `SiegerStand` seit 2.6) |
| 16 Auswahlzeile AXXXL | `AuswahlZeile` | Untertitel wächst nur bis `xxxLarge` (keine Silbentrennung „Par-tie“ mehr); Titel wächst weiter |

Apps müssen nichts ändern, nur neu bauen.

## 2.7 – 05.11.2026 (Design-Chat, Bausteinwunsch 15 aus Rauswurf)

| Wunsch | Baustein | Änderung |
|---|---|---|
| 15 Spielerliste: Sitzfarbe, Avatar, Zusatz | `SpielerEintrag` | neu `farbe: Color?` (hat Vorrang vor `farbeHex`) und `symbol: String?` (Emoji im Avatar-Kreis statt Initiale); `anzeigeFarbe` liefert die Farbe für die Anzeige |
| | `SpielerAvatar` | neuer Parameter `symbol:`; Kreis und Farbring bleiben, das Zeichen ersetzt die Initiale |
| | `SpielerListe` | `avatarTippen:` macht den Avatar zu einem 44-pt-Knopf (die App zeigt ihre eigene Avatar-Wahl, E.5); `zusatz:` ist ein kleiner Platz je Zeile vor dem Art-Menü (ein Knopf oder Menü, ≤ 60 pt breit), z. B. Würfelart „📱 / ✋“ |

Bestehende Aufrufe bauen unverändert (`SpielerListe` ohne `zusatz` = wie bisher). Rauswurf: `SpielerEintrag(…, farbe: theme.farbe(sitz), symbol: avatar)` im Binding
setzen, `avatarTippen` öffnet den `AvatarPicker`, `zusatz` zeigt die Würfelart. Andere Apps: nur neu bauen.

## 2.6 – 05.11.2026 (Design-Chat, Bausteinwunsch 14 aus Viererreihe-T3-Retest, XXXL)

| Wunsch | Baustein | Änderung |
|---|---|---|
| 14 Spielstand-Karte XXXL | `SiegerBildschirm` (`SiegerStand`) | Namen einzeilig mit Schrumpfen bis 0,6 (kein „Compu-ter“); die ganze Karte wächst nur bis `xxxLarge`, damit „3 : 1“ mit Namen in eine Reihe passt und nicht unter die Knöpfe rutscht |

Apps müssen nichts ändern, nur neu bauen.

## 2.5 – 05.11.2026 (Design-Chat, Bausteinwünsche 11–13 aus Viererreihe-T3, alle XXXL)

| Wunsch | Baustein | Änderung |
|---|---|---|
| 11 Stufen-Chips XXXL | `StufenWahl` | Chip-Schrift wächst nur bis `xxxLarge`; die Kapsel ist mindestens 36 pt und wächst mit dem Text (vorher fest 36 pt, Text lief über den Rand) |
| 12 Start-Titel XXXL | `StartTitel` | Titel wächst nur bis ×1,25 der Grundgröße (70 pt) statt bis zur Bedienungshilfen-Größe; füllt nicht mehr die ganze Breite |
| 13 Ende-Inhalt XXXL | `SiegerBildschirm`, `ZwischenstandBildschirm` | Inhalt endet 16 pt über den Knöpfen (statt 4) und wird am unteren Rand weich ausgeblendet statt hart abgeschnitten |

Apps müssen nichts ändern, nur neu bauen (Paket wird automatisch eingebunden).

## 2.4 – 04.11.2026 (Design-Chat, Bausteinwünsche 9–10 aus Galgenmännchen-T3)

| Wunsch | Baustein | Änderung |
|---|---|---|
| 9 Zahlen-Karte XXXL | `SiegerBildschirm` (`SiegerStand`) | Zahlen einzeilig mit Schrumpfen bis 0,5; passt die Reihe nicht, stehen beide Werte untereinander (`ViewThatFits`), Karte wächst mit |
| 10 Blatt XXXL | `NeuesSpielBlatt`, `SectionLabel` | Inhalt endet 16 pt über „Los geht's“ (statt 4); Section-Label (alle Karten, Stufen, Spieler) wächst nur bis `xxxLarge` |

Nachziehen müssen: alle Apps nur Paket neu auflösen, kein Code.

## 2.3 – 04.11.2026 (Design-Chat, Sudoku-T3 Nachtest 0169325)

| Befund | Baustein | Änderung |
|---|---|---|
| M1 Stufen-Chips weiter 42,2 pt | `StufenWahl` | Das Label selbst ist jetzt 44 pt hoch (`frame` vor dem Hintergrund), die 36-pt-Kapsel liegt als `background` darunter; XCUITest misst bei `.plain`-Buttons das Label, nicht einen äußeren `frame` |

Nachziehen müssen: alle Apps mit `StufenWahl` (nur Paket neu auflösen, kein Code).

## 2.2 – 04.11.2026 (Design-Chat, Befunde aus Sudoku-T3 Build 20)

| Befund | Baustein | Änderung |
|---|---|---|
| M1 Stufen-Chips 42,2 pt | `StufenWahl` | Tippfläche 44 pt liegt jetzt am Knopf selbst (`frame` + `contentShape` auf dem `Button`), Kapsel bleibt 36 pt |
| S1 Einstellungen ohne Schließen | `einstellungsSchliessen()` (neu) | Rundknopf `xmark` klein oben rechts, schließt per `dismiss`; auf das `Form` setzen |
| S2 „Weiterspie-len“ | `WeiterspielenKarte` | Titel in der Hochkant-Variante einzeilig, schrumpft bis 0,6 |
| S2 Hauptknopf klemmt Karten ab | `hauptKnopf()`, `zweitKnopf()`, `AkzentPilleStil` | wachsen nur bis `xxxLarge` (wie B.3 schon vorsah) |

Nachziehen müssen: Sudoku (`.einstellungsSchliessen()` aufs Form; „Hilfen“ und „Ruhe“ in die fünf Gruppen einsortieren), Viererreihe (`.einstellungsSchliessen()`), Referenz (erledigt).

## 2.1 – 04.11.2026 (Design-Chat, Bausteinwünsche 2–8 aus Sudoku-Chat und Test-Chat)

**Neu:**

| Wunsch | Baustein | So benutzen |
|---|---|---|
| 2 Menü im Rundknopf | `RundKnopfMenue` (`Knoepfe.swift`) | `RundKnopfMenue(beschriftung: "Menü") { Button("Regeln") {} … }` rechts im `SpielKopf`. Symbol-Standard `ellipsis`, Inhalt wie bei `Menu` (`Button`, `Divider`, `Section`), auch `beschriftungText: Text` |
| 3 Schalter in Systemgrün (E1) | `einstellungsSchalter()` / `SchalterStil` (`Einstellungen.swift`) | einmal auf das `Form` der Einstellungen setzen; alle Toggles darunter werden Systemgrün, Picker, Menüs und Links behalten die App-Farbe. `.tint(Color(.systemGreen))` an den einzelnen Toggles löschen |
| 4 ErklaerSheet mit fertigen Texten | zweiter Init von `ErklaerSheet` (`Hinweis.swift`) | `titel: Text(verbatim: tipp.titel)`, `hinweis: tipp.notiz.map { Text(verbatim: $0) }`. Der Init mit `LocalizedStringKey` bleibt |
| 6 Weiterspielen-Menü überdeckt Titel (XXXL) | `WeiterspielenKarte` | nichts zu tun: bei großer Schrift bekommt der Titel rechts Platz für das Menü, und das Menü wächst nicht mehr mit |
| 7 Blatt und Ende zu zwei Dritteln leer | `NeuesSpielBlatt`, `SiegerBildschirm`/`ZwischenstandBildschirm` | nichts zu tun: das Neues-Spiel-Blatt ist so hoch wie sein Inhalt (ziehbar bis ganz hoch); das Ende stellt kurzen Inhalt mittig zwischen Kopf und Knöpfe, langer scrollt wie bisher. Eigene `.presentationDetents` am Blatt entfernen |
| 8 „Experte“ allein in der zweiten Reihe | `StufenWahl` | nichts zu tun: bis drei Stufen eine Reihe, genau vier immer 2 × 2, mehr nach Platz |
| 5 HinweisKarte mit zwei Knöpfen | – (bewusst nicht) | Zwei Aktionen sind der Fall für `ErklaerSheet` (Konzept 3.4: Glasblatt, zwei Pillen). `HinweisKarte` behält höchstens einen Zweitknopf. „Gut gemacht!“ also als `ErklaerSheet(symbol: "checkmark.seal.fill", titel: …, sekundaerTitel: "Weiterspielen", primaerTitel: "Nächste Übung", …)` |

**Werkzeuge:** `tor.sh` und `design_pruefung.py` lesen das App-Icon jetzt auch ohne Pillow (eingebauter PNG-Leser) und nehmen
das Python der venv `~/.cache/klarglas-venv`, wenn es sie gibt. Bisher kam „Icon-Farbe weicht ab oder fehlt“ fälschlich,
sobald dem System-Python Pillow fehlte.

**Geändert:** nichts Bestehendes, alle Aufrufe aus 2.0 übersetzen weiter. Referenz-App: Runde-Szene mit `RundKnopfMenue`,
Einstellungen mit `einstellungsSchalter()`.

**Nachziehen müssen:** Sudoku (TODOs `baustein 2`–`4` auflösen, Wunsch 5 per `ErklaerSheet`). Alle weiteren Apps setzen direkt auf 2.1 auf.

## 2.0 – 04.11.2026 (Design-Chat, Phase A1)

**Neu:** Die Vorlagen `KlarGlas.swift` (243 Zeilen) und `KlarGlasBausteine.swift` (718 Zeilen) sind jetzt das Paket `KlarGlas`
(öffentliche Typen, Texte im Paket in de/en/es/fr). Dazu die zwölf Bausteine aus Konzept 3.5:
`NeuesSpielBlatt` (+ `NeuesSpielKarte`), `StufenWahl`, `SpielerListe` (+ `SpielerEintrag`, `SpielerArt`, `SpielerAvatar`),
`SpielerLeiste`, `SpielfeldKarte`, `HinweisKarte`, `StatusChip`, `ZwischenstandBildschirm`, `TagesKalender`
(+ `Tagesschluessel`, `TagesSerie`), `TagesWidget` (`TagesWidgetKonfiguration.widget`, `TagesWidgetSpeicher`),
`Zeitformat`, `SpielSpeicher` (+ Ablagen, `wert(_:sonst:)`, `spielSpeicherRueckfrage()`).

**Geändert gegenüber den Kopien (beim Umstieg anpassen):**

| Was | Vorher | Jetzt |
|---|---|---|
| `StartTitel` | `StartTitel("Sudoku", gruss: Gruss.text(name: "…"))` | `StartTitel("Sudoku")` – Gruß ohne Namen (E2) |
| `SpielKopf` | `linksSymbol: "chevron.left"` Pflicht | Standard `house` + „Zum Start“ (Home fragt nicht nach, E6) |
| `SiegerBildschirm` | Schließen nur ohne Motiv; „Teilen“ als Zweitknopf | Schließen immer oben rechts; `teilen:` = Rundknopf oben links; unten „Zum Start“ + „Revanche/Nächstes“ |
| `WeiterspielenKarte` | kein Verwerfen | `verwerfen:` zeigt Menü „…“ mit Rückfrage (E6) |
| `EinstellungsGruppe.titel` | `LocalizedStringKey` | `Text` (Texte kommen aus dem Paket) |
| `Darstellung.name` | `LocalizedStringResource` | `String` (bereits übersetzt) – `Text(verbatim:)` benutzen |
| `RundKnopf` | – | zusätzlich `beschriftungText: Text` |
| `Theme` | je App eine Kopie (teils eigenes `Theme.swift`) | nur noch im Paket; eigenes `Theme` löschen |
| `FensterTintStil` | – | nicht in App-Erweiterungen (Widget) verfügbar |
| Texte der Bausteine | aus der App (`Localizable.xcstrings` der App) | aus dem Paket; die Schlüssel in den Apps dürfen bleiben, werden aber nicht mehr gebraucht |

**Nachziehen müssen:** alle elf Apps (Phase B, je App-Chat): Paket einbinden, `Views/KlarGlas*.swift` löschen, `import KlarGlas`
in jeder Datei, die Bausteine nutzt, Aufrufe nach der Tabelle oben anpassen. Widget-Ziele: `KlarGlas` einbinden und die
Widget-Datei auf `TagesWidgetKonfiguration(…).widget` kürzen (Vorlage `_Gemeinsam/Widget/WidgetVorlage.swift.txt`).

## Produkt `Baukasten` – `Akzent.swift`, 04.11.2026 (Design-Chat, Phase A5)

Keine neue `KlarGlas.version` (Änderung im Produkt `Baukasten`). Die Farbfamilie hat jetzt **elf** Farben, eine je App:
neu `schiefer` (Minensuche, `#4F6377`) und `limette` (Farbrätsel, `#5E8F00`); Schocken `#9A5B2E`, Yacht `#4B4ACF`.
Flächen- und Textwerte sind identisch mit `DESIGN.md` A.1, `design_pruefung.py` (SOLL) und `accenttext_soll.json`.
`AkzentTests` prüfen alle elf (Weiß auf Fläche ≥ 3:1, Text ≥ 4,5:1). Apps müssen nichts nachziehen; die Voreinstellung
jeder App bleibt ihre eigene Farbe (E8).
