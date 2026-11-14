// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Eine beendete Partie im Verlauf (SPEZIFIKATION 11.2). Es bleiben die letzten 50.
struct VerlaufPartie: Codable, Equatable, Identifiable, Sendable {
    static let maximum = 50

    var id: UUID
    var datum: Date
    /// Name der Spielart (`Spielart.rawValue`) oder `eigene`
    var spielart: String
    var spieler: [Spieler]
    /// Spieler-Indizes in der Reihenfolge, in der sie fertig wurden
    var platzierung: [Int]
    var spielzuege: Int
    /// Spielzeit; Pausen über 2 Minuten zählen nicht
    var dauerSekunden: Int
    /// Rauswürfe (geschlagene fremde Figuren) je Spieler
    var rauswuerfe: [Int]
    /// Wie oft jede Zahl fiel, je Spieler (`[0]` = Einsen)
    var augen: [[Int]]

    var sieger: Spieler? { platzierung.first.flatMap { spieler[safe: $0] } }
    var minuten: Int { max(1, Int((Double(dauerSekunden) / 60).rounded())) }

    init(id: UUID = UUID(), datum: Date, spielart: String, spieler: [Spieler], platzierung: [Int], spielzuege: Int,
         dauerSekunden: Int, rauswuerfe: [Int], augen: [[Int]]) {
        self.id = id
        self.datum = datum
        self.spielart = spielart
        self.spieler = spieler
        self.platzierung = platzierung
        self.spielzuege = spielzuege
        self.dauerSekunden = dauerSekunden
        self.rauswuerfe = rauswuerfe
        self.augen = augen
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        datum = try c.decodeIfPresent(Date.self, forKey: .datum) ?? Date()
        spielart = try c.decodeIfPresent(String.self, forKey: .spielart) ?? "eigene"
        spieler = try c.decodeIfPresent([Spieler].self, forKey: .spieler) ?? []
        platzierung = try c.decodeIfPresent([Int].self, forKey: .platzierung) ?? []
        spielzuege = try c.decodeIfPresent(Int.self, forKey: .spielzuege) ?? 0
        dauerSekunden = try c.decodeIfPresent(Int.self, forKey: .dauerSekunden) ?? 0
        rauswuerfe = try c.decodeIfPresent([Int].self, forKey: .rauswuerfe) ?? []
        augen = try c.decodeIfPresent([[Int]].self, forKey: .augen) ?? []
    }

    /// Eintrag aus einer beendeten Partie.
    init?(aus z: Spielzustand, datum: Date = Date(), dauerSekunden: Double = 0) {
        guard z.partie.vorbei, !z.partie.platzierung.isEmpty else { return nil }
        let zaehlung = PartieZaehlung.zaehle(z.partie)
        let wuerfel = Wuerfelstatistik.zaehle(z.partie)
        self.init(datum: datum, spielart: Spielart.erkennen(z.optionen)?.rawValue ?? "eigene", spieler: z.spieler,
                  platzierung: z.partie.platzierung, spielzuege: z.partie.verlauf.count,
                  dauerSekunden: Int(dauerSekunden.rounded()), rauswuerfe: zaehlung.map(\.geschlagen), augen: wuerfel.map(\.augen))
    }
}

enum VerlaufAuswertung {
    /// Siegquote der letzten 10 Partien, an denen dieser Statistik-Schlüssel (Spielername bzw. Computer-Stufe) teilnahm.
    /// Ergebnis: je Partie `true` = Sieg, neueste zuerst, höchstens 10.
    static func letzte10(fuer schluessel: String, in verlauf: [VerlaufPartie]) -> [Bool] {
        var ergebnis: [Bool] = []
        for e in verlauf.sorted(by: { $0.datum > $1.datum }) {
            let plaetze = e.spieler.indices.filter { PartieZaehlung.schluessel(e.spieler[$0]) == schluessel }
            guard !plaetze.isEmpty else { continue }
            ergebnis.append(plaetze.contains { e.platzierung.first == $0 })
            if ergebnis.count == 10 { break }
        }
        return ergebnis
    }
}
