// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// Erzeugt von Werkzeug/regellesen_erzeugen.py aus plan/regeln-neu/solitaer/regeln.md. Nicht von Hand ändern.
enum RegelLeseText_solitaer {
    static let quelle = #"""
## Worum es geht

Solitär (auch Patience genannt) spielst du allein. Du hast einen Tisch mit Karten vor dir und versuchst, sie nach festen Regeln zu ordnen oder abzuräumen. Es gibt kein Glück beim Ziehen und keinen Gegner. Es kommt nur darauf an, wie gut du vorausdenkst.

In der App gibt es sieben Spiele:

- **Klondike** – der Klassiker. Mit 1 oder 3 Karten vom Stapel.
- **Spider** – mit zwei Blättern. Mit 1, 2 oder 4 Farben.
- **FreeCell** – alle Karten offen, vier freie Zellen zum Parken.
- **Pyramide** – Paare abräumen, die zusammen 13 ergeben.
- **TriPeaks** – drei Gipfel, lange Ketten bringen Punkte.
- **Golf** – Spalten abräumen, ein Durchgang durch den Stapel.
- **Yukon** – wie Klondike, aber ohne Stapel, und du darfst ganze Stapel verschieben.

Das Spiel wählst du vor dem Start. Die App merkt sich, was du zuletzt gespielt hast.

## Grundbegriffe

- **Spalte:** eine Reihe von Karten auf dem Tisch, die nach unten überlappen.
- **Ziel (Zielstapel):** vier Plätze oben. Dort sammelst du je Farbe die Karten von Ass bis König.
- **Stapel:** verdeckte Karten, von denen du neue Karten aufdeckst.
- **Ablage:** die aufgedeckten Karten neben dem Stapel. Nur die oberste ist spielbar.
- **Absteigend, rot und schwarz im Wechsel:** Auf eine Pik 10 (schwarz) passt eine Herz 9 oder Karo 9 (rot). Darauf wieder eine schwarze 8.
- **Reihenfolge der Werte:** Ass, 2, 3 … 10, Bube, Dame, König.

## So bedienst du die Karten

- **Antippen:** Die Karte springt an den besten Platz, den es gerade gibt.
- **Ziehen:** Du kannst eine Karte oder Reihe auch mit dem Finger an einen bestimmten Platz ziehen.
- **Stapel antippen:** deckt neue Karten auf.

## Klondike

**Aufbau:** Sieben Spalten mit 1, 2, 3 bis 7 Karten. Nur die oberste Karte jeder Spalte liegt offen. Die übrigen 24 Karten bilden den Stapel.

**Ziel:** Lege alle Karten nach Farben sortiert von Ass bis König auf die vier Zielstapel oben.

**So geht’s:**
- In den Spalten legst du absteigend und abwechselnd rot und schwarz an, zum Beispiel die Herz 9 auf die Pik 10.
- Ganze passende Reihen darfst du gemeinsam verschieben.
- Liegt eine verdeckte Karte frei, wird sie aufgedeckt.
- In eine leere Spalte darf nur ein König (mit allem, was auf ihm liegt).
- Ein Ass darf jederzeit auf ein leeres Ziel. Danach kommt die 2 derselben Farbe, dann die 3 und so weiter.
- Du darfst eine Karte auch vom Ziel zurück in eine Spalte legen.
- Tippe auf den Stapel, um 1 oder 3 Karten aufzudecken (je nach Einstellung). Nur die oberste Karte der Ablage kannst du spielen.
- Ist der Stapel leer, tippst du ihn an, und die Ablage wird wieder zum Stapel. Das geht beliebig oft, außer bei der Wertung „Streng“.

**Gewonnen:** wenn alle vier Ziele bis zum König reichen.

**Punkte (Wertung „Standard“):**

| Aktion | Punkte |
|---|---|
|Karte von der Ablage in eine Spalte | +5 |
|Karte aufs Ziel | +10 |
|Verdeckte Karte aufgedeckt | +5 |
|Karte vom Ziel zurück | −15 |
|Stapel umdrehen | −100 (bei 3 Karten −20) |

Die Punkte fallen nie unter 0. Beim Sieg gibt es einen Zeitbonus: 700.000 geteilt durch die Sekunden (ab 30 Sekunden Spielzeit). *Beispiel:* Sieg nach 350 Sekunden gibt 2.000 Bonuspunkte.

**Andere Wertungen** (Einstellung „Wertung“):
- **Streng:** Du startest mit −52 Punkten. Jede Karte aufs Ziel bringt +5, jede zurück −5. Mit „1 Karte“ darfst du nur einmal durch den Stapel, mit „3 Karten“ dreimal. Dann erscheint „Keine Durchgänge mehr“. Wer alle 52 Karten schafft, hat −52 + 260 = 208 Punkte.
- **Streng fortlaufend:** wie Streng, aber die Punkte zählen über alle Partien weiter.
- **Aus:** keine Punkte.

Das Tagesspiel zählt immer mit „Standard“.

**Tipp:** Decke zuerst verdeckte Karten auf. Das öffnet die meisten Möglichkeiten. Leere Spalten nur füllen, wenn ein König wirklich etwas freilegt.

## Spider

**Aufbau:** Zwei Blätter, also 104 Karten. Zehn Spalten: vier mit 6 Karten, sechs mit 5 Karten. Nur die oberste ist offen. 50 Karten bleiben im Stapel.

**Farben:** Mit „1 Farbe“ sind alle Karten Pik (am leichtesten). Mit „2 Farben“ Pik und Herz (Standard). Mit „4 Farben“ alle vier Farben (schwer; nicht jede Partie ist lösbar).

**Ziel:** Räume alle Karten ab. Eine vollständige Reihe von König bis Ass in einer Farbe wandert automatisch ab. Nach 8 solchen Reihen hast du gewonnen.

**So geht’s:**
- Lege eine Karte auf eine um eins höhere. Die Farbe ist dabei egal.
- Verschieben kannst du aber nur Reihen, die ganz in derselben Farbe sind.
- In eine leere Spalte darf jede Karte oder Reihe.
- Tippe auf den Stapel: Er legt auf jede der zehn Spalten eine neue Karte. Das geht nur, wenn keine Spalte leer ist. Insgesamt kannst du fünfmal austeilen.

**Punkte:** Du startest mit 500. Jeder Zug und jedes Austeilen kostet 1 Punkt. Jede fertige Reihe bringt 100. Die Punkte fallen nie unter 0.

**Tipp:** Halte Reihen möglichst einfarbig und leere früh eine Spalte. Sie ist dein wichtigster Spielraum.

## FreeCell

**Aufbau:** Alle 52 Karten liegen offen in acht Spalten (vier mit 7, vier mit 6 Karten). Oben links sind vier freie Zellen, oben rechts die vier Ziele.

**Ziel:** Lege alle Karten nach Farben von Ass bis König auf die vier Ziele.

**So geht’s:**
- Lege absteigend und abwechselnd rot und schwarz an.
- Jede freie Zelle parkt genau eine Karte.
- In eine leere Spalte darf jede Karte oder Reihe.
- Mehrere Karten auf einmal gehen, solange genug Platz frei ist: höchstens (freie Zellen + 1) mal 2 hoch der Zahl der leeren Spalten. *Beispiel:* 4 freie Zellen, keine leere Spalte: 5 Karten. 2 freie Zellen und 1 leere Spalte: 6 Karten. Die Spalte, in die du schiebst, zählt nicht mit.
- Vom Ziel zurück geht bei FreeCell nicht.

**Punkte:** keine. Jede Partie hat eine Nummer (1 bis 32.000), wie im bekannten FreeCell am Computer.

**Tipp:** Fast jede Partie ist lösbar. Lass die Zellen nicht zu früh volllaufen und leere lieber eine Spalte.

## Pyramide

**Aufbau:** 28 Karten liegen in sieben Reihen als Pyramide (oben 1 Karte, unten 7). 24 Karten sind im Stapel.

**Ziel:** Räume die Pyramide ab.

**So geht’s:**
- Entferne zwei Karten, die zusammen 13 ergeben. Ass zählt 1, Bube 11, Dame 12, König 13. Die Zahlen zählen ihren Wert.
- Die Paare sind also: Ass + Dame, 2 + Bube, 3 + 10, 4 + 9, 5 + 8, 6 + 7. Ein König geht allein.
- Nur freie Karten zählen. Frei ist eine Karte, wenn keine andere mehr auf ihr liegt.
- Eine der beiden Karten darf auch die oberste Karte der Ablage sein.
- Tippe eine Karte an, dann ihren Partner. Gibt es nur einen möglichen Partner, verschwindet das Paar sofort.
- Der Stapel deckt die nächste Ablagekarte auf. Ist er leer, darfst du die Ablage noch zweimal umdrehen (also 3 Durchgänge).

**Punkte:** keine.

**Tipp:** Zieh nicht zu früh vom Stapel. Schau erst, welche Paare in der Pyramide schon gehen.

## TriPeaks

**Aufbau:** Drei Gipfel aus 28 Karten. Eine Karte liegt offen auf der Ablage, 23 sind im Stapel.

**Ziel:** Bringe alle Karten der drei Gipfel auf die Ablage.

**So geht’s:**
- Eine freie Karte darf auf die Ablage, wenn sie genau einen Wert höher oder niedriger ist als die oberste Ablagekarte. Die Farbe ist egal.
- König und Ass gelten als Nachbarn (auf einen König passt ein Ass und umgekehrt).
- Geht nichts mehr, deckst du eine Karte vom Stapel auf die Ablage. Der Stapel geht nur einmal durch.

**Punkte:** Jede abgelegte Karte bringt so viele Punkte, wie deine Kette gerade lang ist: die erste 1, die zweite 2, die dritte 3 … Ziehen vom Stapel beginnt die Kette von vorn. Ein geräumter Gipfel bringt 15 Punkte, der letzte Gipfel 30. *Beispiel:* Eine Kette von 4 Karten bringt 1 + 2 + 3 + 4 = 10 Punkte.

**Tipp:** Plane die Kette voraus. Karten, die verdeckte Karten freilegen, kommen zuerst.

## Golf

**Aufbau:** Sieben Spalten mit je 5 offenen Karten (35 Karten). Eine Karte liegt auf der Ablage, 16 sind im Stapel.

**Ziel:** Bringe alle 35 Karten der Spalten auf die Ablage.

**So geht’s:**
- Nur die oberste Karte jeder Spalte darf auf die Ablage, und nur, wenn sie genau einen Wert höher oder niedriger ist.
- Anders als bei TriPeaks sind König und Ass keine Nachbarn. Auf einen König geht gar nichts.
- Dann hilft nur der Stapel: Er deckt eine neue Karte auf. Er geht nur einmal durch.

**Punkte:** Erst beim Sieg: so viele Punkte, wie Karten im Stapel übrig sind. *Beispiel:* 4 Karten übrig gibt 4 Punkte.

**Tipp:** Alle Karten sind offen. Plane die Kette und spar dir den Stapel für Könige und Sackgassen auf.

## Yukon

**Aufbau:** Alle 52 Karten liegen von Anfang an in sieben Spalten. Spalte 1 hat 1 offene Karte. Die Spalten 2 bis 7 haben je 5 offene Karten und darunter 1 bis 6 verdeckte. Es gibt keinen Stapel.

**Ziel:** Lege alle Karten nach Farben von Ass bis König auf die vier Ziele.

**So geht’s:**
- Lege absteigend und abwechselnd rot und schwarz an.
- Der Kniff: Jede offene Karte darfst du samt allem verschieben, was auf ihr liegt. Die Karten darüber müssen keine Reihe bilden. Nur die unterste bewegte Karte muss passen.
- In eine leere Spalte geht nur ein König.
- Karten vom Ziel zurück in eine Spalte sind erlaubt.

**Punkte:** wie Klondike „Standard“: aufs Ziel +10, aufgedeckt +5, vom Ziel zurück −15. Nie unter 0.

**Tipp:** Decke zuerst verdeckte Karten auf. Verschiebe dafür ganze Stapel, auch ungeordnete. Tippst du eine tiefere offene Karte an, geht die ganze Gruppe mit.

## Hilfen

- **Tipp:** zeigt dir einen möglichen Zug.
- **Zurück:** nimmt den letzten Zug zurück. Gedrückt halten spult schnell zurück.
- **Fertig spielen:** Sobald alle Karten aufgedeckt sind, legt die App den Rest für dich ab.
- **Karten ablegen:** Im Standard legst du Karten selbst aufs Ziel („Selbst“). Mit „Automatisch“ legt die App sichere Karten von allein ab (Klondike, FreeCell, Yukon).
- **Doppeltipp:** Bei Klondike, FreeCell und Yukon springt eine Karte mit zwei schnellen Tipps auf ihr Ziel. Bei Pyramide, TriPeaks und Golf tippst du nur, ziehen geht dort nicht.
- **Keine sinnvollen Züge mehr:** Steckst du fest, sagt dir die App das. Du kannst dann Züge zurücknehmen, ein neues Spiel beginnen oder dieselbe Partie noch einmal von vorn spielen.
- **Aufgeben:** unter „Menü“. Die Partie zählt dann als verloren. Bei lösbaren Partien kannst du dir danach die Lösung Schritt für Schritt ansehen oder abspielen lassen.
- **Partie wählen:** Unter „Menü“ → „Partie wählen …“ rufst du eine Partie über ihre Nummer auf, zum Beispiel eine FreeCell-Partie, die ein Freund auch gespielt hat.
- **Tastatur (iPad):** ⌘Z zurück, ⌘N neu, ⌘T oder Leertaste Tipp, ⌘F fertig spielen.

## Lösbare Partien und Schwierigkeit

Im Standard bekommst du nur **lösbare Partien**. Jede davon hat ein Computer vorab wirklich bis zum Sieg durchgespielt. Du kannst sie also immer gewinnen, den Weg musst du nur finden.

Unter „Schwierigkeit“ wählst du Gemischt (Standard), Leicht, Mittel oder Schwer. Schaltest du „Zufällige Partien“ ein, wird einfach gemischt. Dann ist nicht jede Partie lösbar. FreeCell nimmt immer eine Partie aus seiner festen Liste.

## Tagesspiel, Serien und Erfolge

Jeden Tag gibt es ein **Tagesspiel**: eine feste Partie, die alle am selben Tag bekommen. Im Kalender siehst du, welche Tage du geschafft hast. Zu jedem Tagesspiel gibt es ein **Tagesziel**, zum Beispiel: gewinnen, ohne „Zurück“, ohne „Tipp“, in einer bestimmten Zeit oder mit wenigen Zügen.

Gewonnene Partien zählen für **Serien**, **Erfolge** und **Wochenziele**. Jede Woche (Montag bis Sonntag) bekommst du drei Wochenziele, zum Beispiel „3 Siege ohne Tipp“ oder „An 4 Tagen das Tagesspiel gewinnen“. Im Tagesspiel zählen immer die Standard-Punkte.

## Einstellungen, die nur das Aussehen ändern

Kartengröße, vierfarbige Karten, Linkshänder-Modus, Tisch und Kartenrücken ändern nichts an den Regeln. Auch die Anzeige von Zeit, Zügen und Punkten kannst du ein- und ausschalten.
"""#
}
