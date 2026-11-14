// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern

/// Viererreihe : die eine Fassung des Spiels in der Sammlung.
/// Kern geteilt (Verweise auf dieselben Dateien), eigene Spielstände (`viererreihe-neu`), Hülle über `SpielRahmen`.
@MainActor
public struct ViererreiheModul: SpielModul {
    public init() {}
    public static let kennung = "viererreihe-neu"
    public let id = ViererreiheModul.kennung
    public let name = "Viererreihe"
    public let gattung = Gattung.brett
    public let farbe = AkzentFarbeWert.tuerkis
    public let symbol = "circle.grid.2x2.fill"
    public let spielerzahl = 1...2
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        let kennung = id
        return AnyView(SpielRahmen(id: id, name: name, untertitel: "Vier in einer Reihe", farbe: farbe, spieler: 2...2, computerErlaubt: true,
                            regeln: "Abwechselnd wirft jeder einen Stein in eine Spalte. Der Stein fällt bis ganz nach unten oder auf den obersten Stein. Wer zuerst vier eigene Steine in einer Reihe hat – waagerecht, senkrecht oder schräg –, gewinnt. Ist das Brett voll, endet die Partie unentschieden. Wer beginnt, wählst du vor dem Start; bei „Abwechselnd“ beginnt in der Revanche der andere.",
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            ViererNeuSpiel(teilnehmer: teilnehmer, ende: ende, abbrechen: abbrechen,
                           bilanz: { let b = umgebung.statistik.bilanz(spiel: kennung, ich: umgebung.spieler.ich?.id); return (b.siege, b.partien) })
        }.mitStartOptionen { eintraege in
            VStack(spacing: 12) {
                WerBeginntKarte(spiel: ViererreiheModul.kennung, eintraege: eintraege)   // 1.0 (M7): Wer beginnt
                #if canImport(GameKit)
                ViererOnlineKarte(verzeichnis: umgebung.spieler)   // 1.0: Online mit Freund über Game Center
                #endif
            }
        }
        .mitZiel("Bring als Erster vier eigene Steine in eine Reihe.").mitZielSchrittNeu(.ziel("Bring als Erster vier eigene Steine in eine Reihe. Ihr werft abwechselnd Steine in ein Brett mit sieben Spalten. Rot spielt gegen Blau. Gegen den Computer bist du Rot. Ist das Brett voll und keiner hat vier, ist es unentschieden."))
        .mitAnleitung(RegelTexteNeu.anleitung(neu: Self.anleitungNeu, alt: Self.anleitung)))
    }

    static var anleitung: [AnleitungSchritt] { [
            .figuren(symbol: "hand.point.up", titel: "Spalte wählen", text: "Lege den Finger auf eine Spalte: Dein Stein schwebt darüber. Lass los, und er fällt.", figuren: ["🔴","⚪️","⚪️"], bewegt: 0),
            .figuren(symbol: "arrow.down", titel: "Steine fallen", text: "Jeder Stein fällt bis ganz nach unten oder auf den obersten Stein der Spalte.", figuren: ["🔴","🔵","🔴"], bewegt: 2),
            .figuren(symbol: "sparkles", titel: "Vier in einer Reihe", text: "Wer zuerst vier eigene Steine nebeneinander, übereinander oder schräg hat, gewinnt.", figuren: ["🔴","🔴","🔴","🔴"], bewegt: 3),
            ] }

    /// Neue deutsche Fassung (Regeltexte neu, Build 25) ohne Zielseite.
    static var anleitungNeu: [AnleitungSchritt] { [
        .figuren(symbol: "hand.point.up", titel: "Spalte wählen", text: "Leg den Finger über eine Spalte: Dein Stein schwebt darüber. Lass los, und er fällt. Er fällt immer bis ganz nach unten oder auf den obersten Stein. Eine volle Spalte ist gesperrt. Aussetzen gibt es nicht.", figuren: ["🔴","⚪️","⚪️"], bewegt: 0),
        .figuren(symbol: "sparkles", titel: "Vier in einer Reihe", text: "Wer zuerst vier eigene Steine nebeneinander, übereinander oder schräg hat, gewinnt. Achte auch auf den Gegner: Hat er schon drei in einer Reihe, setz deinen Stein in die Lücke. Die mittlere Spalte ist besonders wertvoll.", figuren: ["🔴","🔴","🔴","🔴"], bewegt: 3),
        .figuren(symbol: "lightbulb", titel: "Hilfen", text: "„Tipp“ lässt eine gute Spalte aufleuchten, „Zug zurück“ nimmt deinen letzten Zug zurück. Wer beginnt, wählst du vor dem Spiel. Die Stärke des Computers stellst du im Spiel unter „Mehr“ ein. Mit Game Center spielst du auch online mit einem Freund.", figuren: ["💡","↩️","🔴"]),
    ] }
}

#endif
