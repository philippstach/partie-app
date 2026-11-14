// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// Erzeugt von Werkzeug/regelwissen_erzeugen.py aus plan/ki-regeltexte/schocken.md. Nicht von Hand ändern.
enum RegelWissenText_schocken {
    static let quelle = #"""
## Ziel
Stichwörter: Ziel, gewinnen, verlieren, Spielende, Partie, Hälfte, Finale, Spieler, Deckel
Schocken ist ein Würfelspiel für 2 bis 6 Personen mit 3 Würfeln und 13 Deckeln (Bierdeckeln). Man will nicht verlieren. Ein Spiel besteht aus Hälften. In einer Hälfte werden die Deckel nach und nach verteilt, bis einer alle hat. Wer alle Deckel einer Hälfte hat, verliert diese Hälfte. Eine Partie hat zwei Hälften. Verliert jemand beide, verliert er die Partie. Haben zwei verschiedene Personen je eine Hälfte verloren, spielen sie ein Finale gegeneinander. Wer das Finale verliert, verliert die Partie. Mit der Spiellänge „Nur eine Hälfte“ zählt eine einzige Hälfte. Wer sie verliert, verliert die Partie.

## Ablauf einer Runde
Stichwörter: Ablauf, Runde, Vorleger, Würfe, wer fängt an, Reihenfolge, stehen lassen, reihum
In jeder Runde würfelt jede aktive Person einmal der Reihe nach mit allen 3 Würfeln. Wer dran ist, hat bis zu 3 Würfe. Nach jedem Wurf kannst du „Stehen lassen“ oder weiterwürfeln.
Der Vorleger (die erste Person der Runde) bestimmt für alle: So viele Würfe, wie er benutzt hat, sind das Maximum der anderen. Steht der Vorleger nach 1 Wurf, würfeln alle anderen auch nur 1 Mal. Nach dem letzten erlaubten Wurf endet dein Zug automatisch.
Die erste Person der ersten Hälfte wird zufällig bestimmt. Danach beginnt die nächste Runde immer der Verlierer der letzten Runde. Eine neue Hälfte oder das Finale beginnt der Verlierer der letzten Hälfte.
Wer am schlechtesten würfelt, verliert die Runde.

## Herauslegen und Sechsen umdrehen
Stichwörter: herauslegen, rauslegen, beiseitelegen, Sechsen umdrehen, drehen, Einsen, Straße, General, einen Würfel
Beim Weiterwürfeln legst du Würfel heraus. Sie bleiben liegen und zählen mit. Die übrigen Würfel werden neu geworfen. Mindestens ein Würfel muss immer neu geworfen werden. Du darfst nie alle drei weglegen.
Mit „Nur Einsen“ (Standard) darfst du nur Einsen herauslegen. Mit „Beliebig“ darfst du jede Augenzahl herauslegen. Du darfst auch gar nichts herauslegen und alles neu werfen.
Sechsen umdrehen (Standard an): Hast du zwei Sechsen im Wurf, drehst du eine zur Eins um. Bei drei Sechsen drehst du bis zu zwei zu Einsen. Eine einzelne Sechs darfst du nicht umdrehen. Die Einsen liegen dann draußen. Wer Sechsen umdreht, darf in diesem Schritt keine Sechs herauslegen. Ist die Option aus, geht Umdrehen gar nicht.
Straße und General zählen nur, wenn alle drei Würfel im letzten Wurf gemeinsam gefallen sind, also nichts herausgelegt oder umgedreht wurde. Das geht auch im 2. oder 3. Wurf, wenn du dazwischen alle drei Würfel neu geworfen hast.

## Rangfolge und Deckel je Wurf
Stichwörter: Rangfolge, was schlägt was, Schock, Jule, General, Straße, Zahl, Wert, wie viele Deckel, besser
Vom besten zum schlechtesten:
1. Schock aus (1-1-1): alle Deckel (siehe Abschnitt Schock aus).
2. Jule (4-2-1), nur mit der Option Jule: 7 Deckel.
3. Schock (zwei Einsen plus eine Zahl): so viele Deckel wie die Zahl. Schock 6 (6-1-1) bringt 6, Schock 2 (2-1-1) bringt 2. Höhere Zahl ist besser.
4. General (drei gleiche Zahlen, nicht 1): 3 Deckel. 6-6-6 schlägt 2-2-2.
5. Straße (drei Zahlen hintereinander, zum Beispiel 4-5-6 oder 3-2-1): 2 Deckel. Höchste Zahl ist besser.
6. Zahl (alles andere): 1 Deckel. Die Würfel werden absteigend gelesen. 6-5-3 ist „653“. 664 schlägt 653.
Ohne die Option Jule ist 4-2-1 einfach die Zahl 421.
Gleiche Wertung (zum Beispiel zweimal Schock 4): Weniger Würfe sind besser. Bei gleichen Würfen ist die Person besser, die früher in der Runde dran war.

## Stock und Deckel verteilen
Stichwörter: Stock, Deckel, Bierdeckel, abgeben, verteilen, ausscheiden, raus, leer
Am Anfang jeder Hälfte liegen 13 Deckel im Stock (15 mit der Option). Der Verlierer der Runde bekommt so viele Deckel, wie der beste Wurf der Runde wert ist.
Solange Deckel im Stock liegen, nimmt der Verlierer sie aus dem Stock. Sind weniger Deckel im Stock als der Wurf wert ist, bekommt er nur den Rest.
Ist der Stock leer, gibt der Gewinner (der Besitzer des besten Wurfs) dem Verlierer Deckel ab, höchstens so viele, wie er selbst hat. Wer dann keine Deckel mehr hat, scheidet aus der Hälfte aus und würfelt nicht mehr mit.
Die Hälfte endet, wenn eine Person alle Deckel hat. Sie verliert die Hälfte.

## Schock aus und Optionen
Stichwörter: Schock aus, Optionen, Hausregeln, Vorlage, Kneipe, Familie, 15 Deckel, Einstellungen
Schock aus (1-1-1) ist der beste Wurf. Mit „Schock aus beendet die Hälfte“ (Standard an) bekommt der Verlierer der Runde sofort alle Deckel, 13 oder 15. Die Hälfte ist damit vorbei, er verliert sie. Ist die Option aus, zählt Schock aus wie ein Wurf mit so vielen Deckeln, wie die Hälfte hat (13 oder 15). Es gelten dieselben Regeln wie bei jedem Wurf: erst aus dem Stock, später vom Gewinner. Die Hälfte läuft weiter.
Die Hausregeln stellst du vor dem ersten Wurf ein (Menü „Hausregeln ändern“): Herauslegen (Nur Einsen oder Beliebig), Sechsen umdrehen, Jule 4-2-1, Deckel (13 oder 15), Spiellänge (Partie mit Finale oder Nur eine Hälfte), Schock aus beendet die Hälfte. Dazu zwei Vorlagen: „Kneipe“ (streng: nur Einsen, Jule an) und „Familie“ (locker: Jule aus, beliebig herauslegen). „Auf Standard zurücksetzen“ stellt alles auf Standard.

## Hälften, Finale und Ende
Stichwörter: Hälfte, Finale, Partie verlieren, Platz, Abend, Pechvogel, Schock-König, Auszeichnung, Spielende
Hälfte 1 und Hälfte 2 spielen alle. Verliert dieselbe Person beide, ist die Partie sofort vorbei und sie hat verloren. Sonst spielen die beiden Verlierer ein Finale gegeneinander. Wer es verliert, verliert die Partie. Mit „Nur eine Hälfte“ endet die Partie nach der ersten Hälfte.
In der Ergebnisliste steht der Verlierer zuletzt. Die anderen werden nach der Zahl der verlorenen Hälften geordnet, weniger ist besser. Gleich viele teilen sich den Platz.
Für „Euer Abend“ zählt die App Partien, Schock aus und Deckel über mehrere Partien. Ab der 2. Partie gibt es Auszeichnungen: Schock-König (meiste Schock aus, mindestens 1), Pechvogel (meiste Deckel bekommen) und Glückspilz (wenigste). Nach mehr als 6 Stunden Pause beginnt ein neuer Abend.

## Bedienung, Computer und echte Würfel
Stichwörter: Bedienung, Knopf, Tipp, Computer, Stufe, echte Würfel, eintippen, geführte Partie
Du würfelst mit „Würfeln“. Nach dem Wurf wählst du die Würfel zum Herauslegen, drehst Sechsen um („Sechsen umdrehen“) und tippst „Weiter würfeln“, oder du tippst „Stehen lassen“. Der „Tipp“ zeigt Chancen, wenn die Hilfen an sind.
Mit „Echte Würfel“ würfelst du am Tisch. In der Schnelleingabe trägst du nur das Endergebnis und die Zahl der Würfe ein; bei Straße und General fragt die App, ob alle drei Würfel in einem Wurf gefallen sind. Sonst gilt der Wurf als Zahl. Optional trägst du jeden Wurf einzeln ein.
Der Computer spielt in drei Stufen. Leicht spielt einfach. Mittel spielt zur Hälfte klug, zur Hälfte einfach. Schwer spielt immer klug. „Geführte Partie“ im Regelblatt startet eine kurze Übungspartie mit Hinweisen, nur eine Hälfte.

## Beispiele mit Rechnung
Stichwörter: Beispiel, rechnen, wie viele Deckel, Gleichstand
Runde mit 3 Personen, Stock 13. Anna (Vorleger) wirft Schock 4 in 2 Würfen, damit dürfen die anderen auch höchstens 2 Würfe. Ben wirft die Zahl 654 in 2 Würfen. Cem wirft die Straße 3-4-5 in 1 Wurf. Der beste Wurf ist Schock 4, er ist 4 Deckel wert. Der schlechteste Wurf ist Bens Zahl. Ben bekommt 4 Deckel aus dem Stock, im Stock bleiben 9. Ben beginnt die nächste Runde.
Stock 2, bester Wurf Schock 5: Der Verlierer bekommt nur 2.
Stock leer, Anna hat 9 Deckel, Ben 4. Ben wirft General 3-3-3 (3 Deckel), Anna ist die schlechteste: Anna bekommt 3 Deckel von Ben. Dann hat Anna 12 und Ben 1.
Gleichstand: Ben und Cem werfen beide die Zahl 653. Ben braucht 2 Würfe, Cem 3 Würfe. Ben ist besser, Cem ist schlechter. Brauchen beide gleich viele Würfe, ist der besser, der früher dran war.
Umdrehen: Wurf 6-6-1. Du drehst eine Sechs zur Eins um, legst die Einsen heraus und wirfst nur den letzten Würfel. Jede Zahl 2 bis 6 ergibt einen Schock, eine 1 ergibt Schock aus.
Mit 13 Deckeln und Schock aus (Standard) bekommt der Verlierer 13 und die Hälfte ist zu Ende.

## Begriffe
Stichwörter: Begriff, Zonk, was heißt, Stock, Vorleger
Deckel: die Spielmarken, in der Kneipe Bierdeckel. Stock: der Haufen mit den Deckeln, die noch keiner hat. Vorleger: wer die Runde beginnt. Schock: zwei Einsen plus eine Zahl. Schock aus: drei Einsen. Jule: 4-2-1. General: drei gleiche Zahlen. Hälfte: ein Durchgang, bis einer alle Deckel hat. Finale: Entscheidung zwischen den zwei Hälften-Verlierern. „Stehen lassen“: den Wurf behalten und nicht weiterwürfeln. „Raus sein“: keine Deckel mehr in der Hälfte.

## Was die App anders macht als die übliche Regel
Stichwörter: anders, Abweichung, üblich, Unterschied, Hausregel
Die App zählt Deckel so: Schock 6 = 6, General = 3, Straße = 2, Zahl = 1, Schock aus = alle Deckel. Die Jule mit 7 Deckeln ist eine Hausregel und steht standardmäßig aus. Ohne Jule ist 4-2-1 nur eine Zahl. Das Herauslegen gilt im Standard nur für Einsen. Straße und General brauchen alle drei Würfel im letzten Wurf. Gleiche Würfe entscheidet die Zahl der Würfe, dann die Reihenfolge der Runde (wer früher dran war, ist besser). Die Hausregeln lassen sich nur vor dem ersten Wurf ändern. Das Blatt der Hausregeln bietet nur 13 oder 15 Deckel an.
"""#
}
