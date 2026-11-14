// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// Erzeugt von Werkzeug/regelwissen_erzeugen.py aus plan/ki-regeltexte/minensuche.md. Nicht von Hand ändern.
enum RegelWissenText_minensuche {
    static let quelle = #"""
## Ziel und Zahlen
Stichwörter: Spielregeln, Minenfeld, Feldgröße, Brettgröße, wie viele Minen, Schwierigkeit, Leicht, Mittel, Schwer, sichere Felder
Du deckst alle Felder auf, unter denen keine Mine liegt. Eine aufgedeckte Zahl sagt, wie viele der bis zu acht Nachbarfelder eine Mine enthalten. Ein Feld ohne Zahl (leer) hat keine Mine in der Nähe; es öffnet automatisch alle Nachbarn. Du gewinnst, wenn alle Felder ohne Mine offen sind. Die Minen bekommen dann von selbst eine Fahne. Eine Mine aufzudecken beendet die Partie, außer du nimmst die zweite Chance. Beispiel Leicht: 7 × 9 = 63 Felder und 8 Minen, also 55 Felder ohne Mine. Mittel: 9 × 14 = 126 Felder, 22 Minen, 104 sichere Felder. Schwer: 11 × 18 = 198 Felder, 44 Minen, 154 sichere Felder.

## Ablauf und Bedienung
Stichwörter: aufdecken, antippen, Fahne, Flagge, markieren, Zeit, erster Zug, lang drücken, Minen übrig, Zähler
Tippen deckt ein Feld auf. Die Minen werden erst beim ersten Aufdecken gelegt: Das Feld und alle Nachbarn sind frei, der erste Zug ist also immer sicher. Lang drücken setzt eine Fahne auf ein vermutetes Minenfeld (und nimmt sie wieder weg). Wie lange du drücken musst, stellst du vor dem Start ein: 0,2 s, 0,3 s oder 0,5 s. Der Knopf „Fahne“ vertauscht beides: Dann setzt Tippen die Fahne und langes Drücken deckt auf. Auf einem Fahnenfeld bewirkt Aufdecken nichts. Oben steht „n Minen übrig“: Minen minus gesetzte Fahnen; der Wert kann auch negativ sein, wenn du mehr Fahnen setzt als Minen da sind. Die Zeit läuft ab dem ersten Aufdecken und ruht, wenn die App im Hintergrund ist.

## Zahl antippen und Rest öffnen
Stichwörter: Chord, Doppeltipp, Nachbarn öffnen, Zahl tippen, Fahnen, automatisch öffnen, Abkürzung
Tippst du auf eine aufgedeckte Zahl und rundherum stehen genau so viele Fahnen, wie die Zahl angibt, deckt die App alle übrigen verdeckten Nachbarn auf. Das spart Tipparbeit. Stimmt eine Fahne nicht, trifft das eine Mine, und die Partie ist verloren. Ohne passende Fahnenzahl passiert nichts. Eine zweite Abkürzung: Sind alle Minen richtig mit einer Fahne markiert und keine falsche Fahne gesetzt, sind alle übrigen Felder sicher und öffnen sich von selbst. Das beendet die Partie als Sieg. Beispiel: Eine 2 mit zwei Fahnen daneben öffnet die anderen sechs Nachbarn, wenn sie noch verdeckt sind.

## Ohne Raten und Hinweis
Stichwörter: fair, raten, Glück, lösbar, Logik, Tipp, Hilfe, Hinweis, Strafzeit, Strafe, Sekunden
Mit „Ohne Raten lösbar“ (Standard an) baut die App das Brett so, dass es sich mit zwei Logikregeln lösen lässt: Einzelzahl (alle Minen einer Zahl gefunden, dann ist der Rest sicher; so viele Minen wie offene Felder, dann sind alle Minen) und Teilmengenvergleich (ein Feldbereich liegt im anderen, die Differenz der Minenzahlen sagt mehr). Die App probiert bis zu 5000 Anordnungen. Der Schalter gilt ab dem nächsten Spiel; Tagesrätsel und geteilte Rätsel sind immer so gebaut. Der Knopf „Hinweis“ (erst nach dem ersten Aufdecken) deckt das sichere Feld mit der kleinsten Nummer auf, das sich aus dem Sichtbaren ergibt, und entfernt eine falsche Fahne darauf. Er kostet 10 Sekunden Strafzeit je Hinweis; zwei Hinweise sind +20 s. Mit einem Hinweis zählt ein Sieg nicht als Bestzeit. Gibt es kein sicheres Feld, passiert nichts und es kostet nichts.

## Mine getroffen: Weiterspielen oder Aufhören
Stichwörter: Bombe, Explosion, verloren, Game over, zweite Chance, nochmal, weiter, aufgeben, Strafe 30 Sekunden
Triffst du eine Mine, bleibt das Brett stehen. Es zeigt nur die getroffene Mine; alle anderen Minen bleiben verdeckt. Die App fragt: „Mine getroffen. Weiterspielen?“ mit „Weiterspielen (+30 s)“ und „Aufhören“. Weiterspielen nimmt den letzten Zug zurück, setzt auf die getroffene Mine eine Fahne und addiert 30 Sekunden. Die Niederlage wird nicht verbucht. Das geht einmal je Partie. Gewinnst du danach, zählt der Sieg (und die Serie), aber die Zeit nicht als Bestzeit. Wählst du „Aufhören“, zeigt das Brett alle Minen; „Zum Ergebnis“ führt zum Endbildschirm, die Niederlage zählt. Triffst du nach der zweiten Chance eine Mine, siehst du gleich alle Minen und es endet.

## Tagesrätsel, Stufen, Statistik
Stichwörter: täglich, Serie, Tagesaufgabe, freischalten, gesperrt, Schloss, Bestzeit, Rekord, Statistik, Link teilen
Das Tagesrätsel ist Stufe Mittel (9 × 14, 22 Minen), für alle am selben Tag gleich. Das Startfeld ist fest und schon aufgedeckt. Es ist immer „ohne Raten“ gebaut. Gelöste Tage in Folge bilden eine Serie; ein verpasster Tag reißt sie (kein Ruhetag). Stufen schalten sich frei: Mittel nach 3 Siegen ohne Hinweis auf Leicht, Schwer nach 3 Siegen ohne Hinweis auf Mittel; im Kindermodus oder mit „Alle Stufen offen“ ist nichts gesperrt. Die Statistik je Stufe zeigt Gespielt, Gewonnen, Bestzeit und Serie. Wer eine laufende Stufen-Partie durch ein neues Spiel ersetzt oder aufgibt, bekommt eine Niederlage. Ein Brett per Link teilen ist möglich; es zählt als normale Stufen-Partie.

## Begriffe und Besonderheiten der App
Stichwörter: Begriffe, Umgangssprache, Besonderheit, anders als normal, Beispiel Zeit
Fahne = Flag, Mine = Bombe, „Zahl antippen“ heißt bei Kennern Chord oder Doppelklick. Anders als üblich: Der erste Zug ist immer sicher, das Brett ist (standardmäßig) ohne Raten lösbar, es gibt Hinweise gegen Strafzeit, und nach einer Mine ist eine zweite Chance gegen 30 s möglich. Der Rest öffnet sich selbst, sobald alle Minen richtig markiert sind. Es gibt nur drei feste Stufen, keine freien Maße. Beispiel Zeit: Du brauchst 95 Sekunden, nutzt 2 Hinweise und die zweite Chance; dann stehen 95 + 20 + 30 = 145 Sekunden in der Zeit, und der Sieg zählt nicht als Bestzeit.
"""#
}
