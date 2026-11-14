// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// Erzeugt von Werkzeug/regellesen_erzeugen.py aus plan/regeln-neu/viererreihe/regeln.md. Nicht von Hand ändern.
enum RegelLeseText_viererreihe {
    static let quelle = #"""
## Worum es geht

Zwei Spieler werfen abwechselnd Steine in ein senkrechtes Brett. Wer zuerst **vier eigene Steine in einer Reihe** hat, gewinnt.

## Was du brauchst

- **Spieler:** 2. Zu zweit an einem Gerät, gegen den Computer oder online mit einem Freund.
- **Brett:** 7 Spalten und 6 Zeilen, also 42 Felder.
- **Farben:** Spieler 1 spielt Rot, Spieler 2 Blau. Gegen den Computer bist du immer Rot.

## So wird gespielt

1. Wer dran ist, wirft **einen Stein** in eine Spalte.
2. Der Stein fällt bis ganz nach unten oder auf den obersten Stein der Spalte.
3. Eine volle Spalte (6 Steine) ist gesperrt.
4. Passen gibt es nicht. Dann ist der andere dran.

## Wer gewinnt

Wer zuerst vier eigene Steine in einer Reihe hat, gewinnt sofort. Die Reihe darf **waagerecht, senkrecht oder schräg** sein. Die App hebt die vier Steine hervor.

Ist das Brett voll und keiner hat eine Reihe, endet die Partie **unentschieden**.

## Wer beginnt

Vor dem Start wählst du in der Karte „Wer beginnt“: Spieler 1 (Standard), Spieler 2 oder abwechselnd. Bei „Abwechselnd“ beginnt in der Revanche der andere. Beginnt der Computer, wirft er seinen ersten Stein selbst.

## Gegen den Computer

Die Stärke wählst du im Spiel unter „Mehr“ → „Stärke des Computers“. Sie gilt ab seinem nächsten Zug.

- **Leicht:** gewinnt, wenn er sofort kann, und blockt deine sofortige Vier. Sonst zieht er zufällig.
- **Mittel** (Standard): denkt vier Züge voraus.
- **Geübt:** denkt sechs Züge voraus, wählt aber ab und zu absichtlich den zweitbesten Zug.
- **Stark:** rechnet so tief, wie er in einer Sekunde schafft. Er ist schwer zu schlagen.

## Online mit einem Freund

Mit Game Center spielt ihr jeder auf dem eigenen Gerät. Wer die Partie startet, ist Rot und beginnt. Ist der Freund dran, bekommst du eine Mitteilung, sobald er gezogen hat. Online gibt es kein Zug zurück und keinen Tipp.

## So bedienst du das Spiel

- **Stein werfen:** Leg den Finger über eine Spalte, der Stein schwebt darüber. Lass los, und er fällt. Auf dem iPad mit Tastatur gehen auch die Tasten 1 bis 7.
- **Zug zurück:** Zu zweit nimmt es den letzten Zug zurück, gegen den Computer deinen Zug samt seiner Antwort.
- **Tipp:** Eine Spalte leuchtet auf. So würde der starke Computer ziehen.
- **Unter dem Brett:** die letzten Züge, der Stand („Zug 12 von 42“) und deine Siegquote.
- **Neues Spiel:** unter „Mehr“, mit Rückfrage.
- **Frag nach den Regeln:** nur auf Geräten mit Apple Intelligence.

## Kleine Tipps

- Die mittlere Spalte ist die wertvollste. Von dort gehen die meisten Reihen aus.
- Schau vor jedem Zug: Hat der Gegner schon drei in einer Reihe mit freiem Platz? Dann blocke.
- Pass auf, dass dein Stein dem Gegner nicht den Platz direkt darunter für seine Vier freimacht.
"""#
}
