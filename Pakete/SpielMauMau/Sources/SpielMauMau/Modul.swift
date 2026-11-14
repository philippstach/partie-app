// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern

/// Mau-Mau : die eine Fassung des Spiels in der Sammlung. Tisch als Spielfeld, Hand als Fächer, Farbwahl als Knöpfe,
/// iPad-Aufbau, frei kombinierbare Hausregeln, „Mau“ sagen, Mehrrunden.
@MainActor
public struct MauMauModul: SpielModul {
    public init() {}
    public static let kennung = "maumau-neu"
    public let id = MauMauModul.kennung
    public let name = "Mau-Mau"
    public let gattung = Gattung.karten
    public let farbe = AkzentFarbeWert.gruen
    public let symbol = "suit.club.fill"
    public let spielerzahl = 2...6
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "Zuerst ohne Karten gewinnt", farbe: farbe, spieler: 2...6, computerErlaubt: true,
                            regeln: "Jeder bekommt fünf Karten (wählbar: fünf bis sieben). Lege eine Karte gleicher Farbe oder gleichen Werts wie die oberste Karte ab. Kannst du nicht, ziehst du eine Karte. Besondere Karten: 7 – der Nächste zieht zwei (mit einer 7 weitergeben, dann zieht er vier …), 8 – der Nächste setzt aus, Bube – du wünschst dir eine Farbe. Wer als Erster keine Karten mehr hat, gewinnt. Die Hausregeln kombinierst du frei unter „Hausregeln“ (im Startblatt oder im Menü der Partie), solange noch keine Karte gespielt ist: „Mau“ sagen, die 9 wechselt die Richtung, Bube auf Bube (im Standard erlaubt), Bube als letzte Karte (im Standard erlaubt), Aussetzen mit 8 oder Ass, gezogene Karte gleich legen und mehrere Runden mit Punkten. Ab fünf Personen wird mit zwei Blättern gespielt.",
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            MauMauNeuSpiel(teilnehmer: teilnehmer, ende: ende, abbrechen: abbrechen)
        }.mitStartOptionen { MauMauOptionen(eintraege: $0) }   // 1.0 (M1): Hausregeln schon vor dem Start
        .mitZiel("Werde deine Karten als Erster los. Wer keine Karten mehr hat, gewinnt.")
        .mitZielSchrittNeu(.ziel("Werde deine Karten als Erste oder Erster los. Alle legen reihum eine Karte auf die Ablage in der Mitte. Wer keine Karten mehr hat, gewinnt. Mau-Mau ist ein schnelles Familienspiel für 2 bis 6 Personen, auch gegen den Computer. Die Grundregel lernst du in einer Minute, den Rest machen die Sonderkarten."))   // B25: neue deutsche Anleitung (RegelTexteNeu), die alte bleibt für alle anderen Sprachen
        .mitAnleitung(RegelTexteNeu.anleitung(neu: [
            .figuren(symbol: "suit.club.fill", titel: "Die Karten", text: "Gespielt wird mit 32 Karten. Es gibt vier Farben: Kreuz, Pik, Herz und Karo. Jede Farbe hat die Werte 7, 8, 9, 10, Bube, Dame, König und Ass. Zu Beginn bekommt jede Person 5 Karten. Eine Karte liegt offen in der Mitte, das ist die Ablage. Der Rest liegt verdeckt daneben, das ist der Stapel. Ab 5 Personen spielt die App mit zwei Blättern.", figuren: ["♣", "♠", "♥", "♦"], bewegt: nil),
            .figuren(symbol: "rectangle.on.rectangle", titel: "Farbe oder Wert", text: "Bist du dran, legst du eine Karte, die zur obersten Karte passt: gleiche Farbe oder gleicher Wert. Liegt oben Herz 9, darfst du jede Herz-Karte legen oder jede andere 9. Du legst immer nur eine Karte. Die Karten, die gerade passen, sind hell. Die anderen sind abgedunkelt. Tippe eine helle Karte an, um sie zu legen.", figuren: ["9♥", "→", "K♥", "9♦"], bewegt: 1),
            .figuren(symbol: "rectangle.stack", titel: "Ziehen", text: "Passt keine Karte, tippst du auf „Karte ziehen“. Du nimmst genau eine Karte vom Stapel, und die nächste Person ist dran. Du darfst auch ziehen, wenn du legen könntest. Manchmal lohnt es sich, eine gute Karte aufzuheben. Ist der Stapel leer, wird die Ablage gemischt und zum neuen Stapel. Nur die oberste Karte bleibt liegen.", figuren: ["🂠", "✋"], bewegt: 0),
            .figuren(symbol: "plus.circle", titel: "Die 7", text: "Legst du eine 7, muss die nächste Person 2 Karten ziehen. Hat sie selbst eine 7, legt sie diese drauf. Dann muss die Person danach 4 Karten ziehen, nach der nächsten 7 sogar 6. Solange gezogen werden muss, hilft nur eine 7, auch kein Bube. Wer keine 7 legt, tippt auf „2 Karten ziehen“ und ist danach nicht mehr dran.", figuren: ["7️⃣", "7️⃣", "➕"], bewegt: 1),
            .figuren(symbol: "forward.end", titel: "Die 8", text: "Legst du eine 8, muss die nächste Person aussetzen. Sie legt nichts und zieht nichts, sondern tippt auf „Aussetzen“. Hat sie selbst eine 8, darf sie diese drauflegen. Dann setzt die Person danach aus. Spielt ihr zu zweit, bist du nach deiner 8 gleich noch einmal dran. Unter „Hausregeln“ kann auch das Ass aussetzen lassen.", figuren: ["8️⃣", "🙋", "⏭️"], bewegt: 2),
            .figuren(symbol: "paintpalette", titel: "Der Bube", text: "Der Bube passt auf fast jede Karte. Legst du ihn, wünschst du dir eine Farbe. Danach muss eine Karte in dieser Farbe kommen, der Wert zählt nicht. Oder es kommt wieder ein Bube. Wünsch dir am besten die Farbe, von der du selbst die meisten Karten hast. Über der Hand siehst du immer, welche Farbe gerade gewünscht ist.", figuren: ["B♣", "♣", "♠", "♥", "♦"], bewegt: 0),
            .figuren(symbol: "flag.checkered", titel: "Gewinnen", text: "Wer die letzte Karte ablegt, gewinnt sofort. Lust auf mehr? Schalte „Mehrere Runden mit Punkten“ ein. Dann zählen am Ende jeder Runde die Karten, die noch auf der Hand sind: Bube 20, Ass 11, Dame und König 10, die anderen ihren Wert. Wer zuerst die Zielsumme erreicht, beendet die Partie. Mit mehreren Runden beginnt jede neue Runde die nächste Person reihum. Es gewinnt, wer die wenigsten Punkte hat. Bei gleichen Punkten gibt es keine Siegerin und keinen Sieger.", figuren: ["🂡", "🏁"], bewegt: 0),
            .figuren(symbol: "slider.horizontal.3", titel: "Hausregeln und Hilfen", text: "Jede Familie spielt Mau-Mau ein bisschen anders. Unter „Hausregeln“ stellst du deine Regeln ein, zum Beispiel „Mau“ sagen oder die 9 dreht die Richtung. Fertige Mischungen findest du unter „Schnellwahl“. Ändern geht nur vor dem ersten Zug. Steckst du fest, zeigt „Tipp“ eine gute Karte. Alles Weitere steht unter „Alle Regeln lesen“.  ---", figuren: ["⚙️", "💡", "📣"], bewegt: nil),
        ], alt: [
            .figuren(symbol: "rectangle.on.rectangle", titel: "Farbe oder Wert", text: "Lege eine Karte mit gleicher Farbe oder gleichem Wert wie die oberste Karte. Sonst ziehst du eine.", figuren: ["🂡","🂱"], bewegt: 0),
            .figuren(symbol: "exclamationmark.2", titel: "Sieben und Acht", text: "Eine Sieben lässt den Nächsten zwei Karten ziehen, eine Acht lässt ihn aussetzen. Mit dem Buben wünschst du dir eine Farbe.", figuren: ["7️⃣","8️⃣","🃏"], bewegt: 0),
            .figuren(symbol: "flag.checkered", titel: "Hand leeren", text: "Wer zuerst keine Karten mehr hat, gewinnt. Hausregeln wählst du vor dem ersten Zug unter „Hausregeln“.", figuren: ["🂡","🏁"], bewegt: 0),
        ])))
    }
}
#endif
