// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern

/// Elfer raus : die eine Fassung des Spiels in der Sammlung.
/// Standard sind die echten Regeln (80 Karten 1–20, mehrere Karten je Zug, Nachziehen); die frühere Skat-Form gibt es als Variante „Kartendomino“.
@MainActor
public struct ElferRausModul: SpielModul {
    public init() {}
    public static let kennung = "elferraus-neu"
    public let id = ElferRausModul.kennung
    public let name = "Elfer raus"
    public let gattung = Gattung.karten
    public let farbe = AkzentFarbeWert.gruen
    public let symbol = "number.square.fill"
    public let spielerzahl = 2...6
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "Von der Elf nach oben und unten", farbe: farbe, spieler: 2...6, computerErlaubt: true,
                            regeln: "Vier Farben, Karten von 1 bis 20. Jeder bekommt zehn Karten, der Rest ist der Stapel. Die rote 11 liegt zuerst. Danach legst du Karten an: Jede Farbe beginnt mit ihrer 11 und wächst nach oben und unten, immer um genau eine Zahl. Du musst mindestens eine Karte legen, wenn eine passt, darfst so viele anlegen, wie du kannst und willst, und beendest dann deinen Zug. Passt keine Karte, ziehst du eine vom Stapel; ist der Stapel leer, passt du. Wer als Erster keine Karten mehr hat, gewinnt; die anderen werden nach der Summe ihrer Restkarten gereiht. Gehen alle nacheinander nur noch passen, gewinnt, wer die kleinste Restsumme hat. In der Variante Kartendomino (Skatblatt 7 bis Ass) beginnt der Herz-Bube, du legst nur eine Karte je Zug und passt, wenn nichts geht; Bube bis Ass zählen 11 bis 14.",
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            ElferNeuSpiel(teilnehmer: teilnehmer, ende: ende, abbrechen: abbrechen)
        }.mitZiel("Werde alle deine Karten los, bevor es die anderen schaffen.")
        .mitZielSchrittNeu(.ziel("Werde alle deine Karten los, bevor es die anderen schaffen. Elfer raus ist ein Anlegespiel für 2 bis 6 Personen, auch gegen den Computer. Jede Person bekommt 10 Karten aus vier Farben mit den Zahlen 1 bis 20."))   // B25: neue deutsche Anleitung (RegelTexteNeu), die alte bleibt für alle anderen Sprachen
        .mitAnleitung(RegelTexteNeu.anleitung(neu: [
            .figuren(symbol: "11.circle", titel: "Mit der Elf beginnen", text: "Die rote 11 liegt zuerst. Wer sie hat, legt sie automatisch und darf gleich weiter anlegen. Jede Farbe beginnt mit ihrer eigenen 11, und die darfst du jederzeit legen. So entstehen in der Mitte vier Reihen, eine pro Farbe.", figuren: ["🟥", "▫️"], bewegt: nil),
            .figuren(symbol: "arrow.left.and.right", titel: "Anlegen", text: "Jede Reihe wächst nach oben und unten, immer um genau eine Zahl. Liegt Gelb von 9 bis 13, passen Gelb 8 und Gelb 14. Passende Karten sind in deiner Hand hervorgehoben. Tippe sie an. Du darfst so viele anlegen, wie du willst, dann tippst du „Zug beenden“.", figuren: ["🟥", "🟥", "🟥"], bewegt: 2),
            .figuren(symbol: "rectangle.stack", titel: "Ziehen", text: "Passt eine Karte, musst du mindestens eine anlegen. Passt keine, ziehst du eine vom Stapel. Passt die gezogene, darfst du sie gleich anlegen. Ist der Stapel leer, passt du. Gehen alle nur noch passen, gewinnt, wer die kleinste Summe auf der Hand hat. Ist die kleinste Summe gleich, gibt es keinen Sieger.", figuren: ["🂠", "✋"], bewegt: 0),
            .figuren(symbol: "flag.checkered", titel: "Gewinnen", text: "Wer die letzte Karte anlegt, gewinnt sofort. Die anderen zählen ihre Restkarten als Minuspunkte zusammen. Ein Tipp: Halte Karten zurück, mit denen der Nächste etwas anfangen könnte, und öffne früh die Farbe, von der du viel hast.", figuren: ["🂡", "🏁"], bewegt: 0),
            .figuren(symbol: "slider.horizontal.3", titel: "Kartendomino und Hilfen", text: "Unter „Mehr“ → „Regeln“ kannst du bis zu deinem ersten Zug Kartendomino wählen: das Skatblatt, der Herz-Bube beginnt, eine Karte pro Zug, und wer nicht kann, passt. „Tipp“ zeigt dir eine gute Karte. Alles Weitere steht unter „Alle Regeln lesen“.", figuren: ["🃛", "💡"], bewegt: nil),
        ], alt: [
            .figuren(symbol: "11.circle", titel: "Mit der Elf beginnen", text: "Die rote 11 liegt zuerst (bei Kartendomino der Herz-Bube). Jede Farbe beginnt mit ihrer 11.", figuren: ["🟥", "▫️"], bewegt: nil),
            .figuren(symbol: "arrow.up.arrow.down", titel: "Anlegen", text: "Lege nach oben und unten an, immer die nächste Zahl. So viele Karten du kannst.", figuren: ["🟥", "🟥", "🟥"], bewegt: 2),
            .figuren(symbol: "flag.checkered", titel: "Hand leeren", text: "Passt eine Karte, musst du legen; sonst ziehst du eine Karte. Wer zuerst keine Karten mehr hat, gewinnt.", figuren: ["🂠", "🏁"], bewegt: nil),
        ])))
    }
}
#endif
