// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// Erzeugt von Werkzeug/regelwissen_erzeugen.py aus plan/ki-regeltexte/rauswurf.md. Nicht von Hand ändern.
enum RegelWissenText_rauswurf {
    static let quelle = #"""
## Ziel und Brett
Stichwörter: Mensch ärgere dich nicht, Figuren, Haus, Start, Ziel, Spieleranzahl, Felder, Gewinn, wer fängt an
Jeder Spieler (2 bis 4) hat ein Haus, ein Startfeld und ein Ziel mit 4 Feldern. Standardmäßig hat jeder 4 Figuren, in den Hausregeln sind auch 3 oder 2 möglich. Die Laufbahn hat 40 Felder, die Startfelder liegen je 10 Felder auseinander. Zu zweit sitzen die Spieler gegenüber. Wer zuerst alle Figuren im Ziel hat, gewinnt (Standard „Erster Sieger“). Zu Beginn stehen alle Figuren im Haus, es sei denn, „Start mit einer Figur draußen“ ist an. Wer beginnt, wird bei jeder Partie ausgelost, auch bei einer neuen Partie danach.

## Ablauf und Ziehen
Stichwörter: Würfeln, ziehen, Zug zurück, rückgängig, automatisch, passen, genau treffen, Zielfeld
Du würfelst und ziehst eine Figur genau so viele Felder vorwärts, wie der Würfel zeigt. Du kannst nur ziehen, wenn der Zug erlaubt ist: Du darfst nicht auf ein Feld mit einer eigenen Figur und nicht über das letzte Zielfeld hinaus. Im Ziel darfst du nicht über das letzte Zielfeld hinaus. Jedes freie Zielfeld davor ist erlaubt. Eine Figur auf dem vierten Zielfeld kann nicht mehr ziehen, auf dem ersten Zielfeld sind höchstens 3 Felder erlaubt. Gibt es keinen erlaubten Zug, verfällt der Wurf und der Nächste ist dran. Gibt es nur einen erlaubten Zug, zieht die App von selbst. Mit „Zug zurück“ (Rückgängig) nimmst du deine letzten Entscheidungen zurück, bis zu 50.

## Rauskommen und Sechs
Stichwörter: raus, Sechs, Figur rausbringen, nochmal würfeln, Extrawurf, Startfeld
Aus dem Haus kommt eine Figur nur mit einer 6. Sie steht dann auf deinem Startfeld. Mit „Mit 6 raus“ (Standard an) musst du bei einer 6 eine Figur aus dem Haus holen, wenn das geht. Nach einer 6 mit Zug würfelst du noch einmal („Nochmal nach 6“, Standard an), auch nach dem Rauskommen. Eine 6 ohne möglichen Zug gibt keinen Extrawurf. Bei „Nochmal nach 6“ aus würfelst du immer nur einmal.

## Drei Versuche
Stichwörter: dreimal würfeln, drei Mal, Würfelversuche, keine Figur draußen, warten auf Sechs
Ist „Drei Versuche“ an (Standard), gilt: Kannst du mit keiner Zahl von 1 bis 5 ziehen (zum Beispiel weil alle Figuren im Haus stehen), darfst du bis zu 3-mal würfeln, um eine 6 zu bekommen. Eine Zahl, mit der du nicht ziehen kannst, verbraucht einen Versuch. Nach 3 Fehlversuchen ist der Nächste dran. Hast du irgendeine Figur auf der Bahn, die ziehen kann, würfelst du nur einmal. Ist die Hausregel aus (Spielart „Offiziell“), gibt es immer nur einen Wurf, dann aber startet man mit einer Figur draußen.

## Schlagen und Pflichten
Stichwörter: schlagen, rauswerfen, werfen, Pflicht, Schlagzwang, Hausregel, Kinder, Zwang
Landest du auf einer fremden Figur, wird sie rausgeworfen und kommt zurück ins Haus. Das gilt auch für Figuren auf deren Startfeld. Mit „Rauswerfen“ aus (Spielart „Kinder“) darfst du nicht auf Felder mit fremden Figuren, niemand fliegt raus. Mit „Schlagpflicht“ (Standard aus) musst du schlagen, wenn du kannst. Pflichten gelten in dieser Reihenfolge: Erst Raus bei einer 6, dann Startfeld räumen (steht eine Figur auf dem Startfeld und warten Figuren im Haus, muss die Startfigur ziehen, wenn sie mit dieser Zahl kann), dann Schlagpflicht. Fremde Figuren im Ziel gibt es nicht, im Ziel wird nicht geschlagen.

## Im Ziel überspringen
Stichwörter: springen, überspringen, Haus, eigene Figur, streng
Mit „Im Ziel überspringen“ (Standard an) darfst du im Ziel über deine eigenen Figuren springen. Ist es aus (Spielart „Streng“), darfst du im Ziel nicht an einer eigenen Figur vorbeiziehen. Auf der normalen Laufbahn darfst du immer über Figuren springen, auch über fremde.

## Teams und Spielende
Stichwörter: zu viert, Partner, 2 gegen 2, Team, Reihenfolge, Platz, Ende, aussetzen
Mit 4 Spielern kannst du „Teams (2 gegen 2)“ einschalten: Spieler 1 und 3 sowie 2 und 4 sitzen gegenüber und gewinnen gemeinsam, sobald beide alle ihre Figuren im Ziel haben. Den Partner schlägst du nicht: Ein Feld mit einer Figur deines Partners ist für dich gesperrt wie ein eigenes. Wer fertig ist, setzt aus, sein Partner spielt weiter. Beim Spielende „Ganze Reihenfolge“ wird weitergespielt, bis alle außer einem fertig sind; der Letzte bekommt den letzten Platz automatisch. Bei Teams zählt nur das Teamende.

## Computer und Würfel
Stichwörter: Gegner, KI, Schwierigkeit, lieb, echter Würfel, Augenzahl eintippen, Mensch gewinnen lassen
Gegen Computer wählst du „Leicht“, „Mittel“ oder „Schwer“, Standard ist Mittel. Leicht: Der Computer schlägt, wenn er kann, holt sonst Figuren aus dem Haus und wählt sonst ohne Plan. Mittel und Schwer sind derzeit gleich: Er bevorzugt Schlagen, dann Ziel erreichen, dann Rauskommen, dann sichere Felder. Mit „Computer lässt Menschen gewinnen“ wirft er Menschen nur raus, wenn es nicht anders geht. Mit der Karte „Echt“ würfelst du am Tisch und tippst die Augenzahl ein; Computer würfeln immer in der App.

## Beispiele
Stichwörter: Beispiel, Rechnung, Feld, Position
Beispiel Feldzahl: Eine Figur auf deinem Startfeld (Position 0) braucht 40 Felder, um das erste Zielfeld zu erreichen, 43 für das letzte. Beispiel Schlagen: Deine Figur steht 2 Felder vor dem Startfeld eines Gegners, auf dem dessen Figur wartet. Du würfelst eine 2 und landest darauf: Seine Figur geht zurück ins Haus. Beispiel Ziel: Deine Figur steht auf Position 38 und du würfelst 4: 38 + 4 = 42, das ist das dritte Zielfeld, erlaubt. Mit einer 6 wären es 44, das geht nicht.

## Begriffe und Umgangssprache
Stichwörter: Haus, Startfeld, rausschmeißen, Hausregeln, Spielart
Bekannt ist das Spiel als „Mensch ärgere dich nicht“. „Raus“ oder „Rauskommen“ heißt: Figur aus dem Haus aufs Startfeld. „Rauswerfen“ oder „Schlagen“ ist dasselbe. „Haus“ ist der Platz der wartenden Figuren, „Ziel“ der Zielbereich, „Startfeld“ der Eintritt auf die Bahn. „Hausregeln“ sind die Einstellungen vor der Partie.

## Was die App anders macht als die übliche Regel
Stichwörter: Spielart, Familie, Offiziell, Kinder, Schnell, Streng, Standard, Variante
Üblich ist je nach Familie unterschiedlich. In der App ist Standard „Familie“: alle Figuren im Haus, Rauspflicht, Startfeld räumen, 3 Versuche, Nochmal nach 6, Überspringen im Ziel erlaubt, keine Schlagpflicht. Neu sind die Spielarten, Teams, 2 bis 4 Figuren und das Spielende „Ganze Reihenfolge“. Die Abfolge der Pflichten (Raus vor Startfeld vor Schlagen) ist fest. Mit „Drei Versuche“ zählen nur Zahlen 1 bis 5 als blockiert.
"""#
}
