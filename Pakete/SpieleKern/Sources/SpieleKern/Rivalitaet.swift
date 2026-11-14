// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Rivalität (B5): Kopf-an-Kopf-Bilanz zweier Personen über alle Spiele, aktuelle Siegesserie und Bilanz je Spiel.
public struct Rivalitaet: Equatable, Sendable {
    public struct JeSpiel: Equatable, Sendable, Identifiable {
        public var id: String { spiel }
        public let spiel: String
        public var duell: StatistikDienst.Duell
    }
    /// Gesamtbilanz aus Sicht von `a`.
    public var gesamt = StatistikDienst.Duell()
    /// Wer zuletzt in Folge gewonnen hat (`nil`, wenn die letzte Begegnung unentschieden war oder es keine gibt) und wie oft.
    public var serieWer: UUID?
    public var serieLaenge = 0
    /// Bilanz aus Sicht von `a`, die meistgespielten Spiele zuerst.
    public var spiele: [JeSpiel] = []

    public init() {}
}

extension StatistikDienst {
    /// Alle Begegnungen von `a` und `b` (Partien, in denen beide mitspielten), in der Reihenfolge der Ereignisse.
    public func rivalitaet(_ a: UUID, gegen b: UUID) -> Rivalitaet {
        var r = Rivalitaet()
        var jeSpiel: [String: StatistikDienst.Duell] = [:]
        var sieger: [UUID?] = []
        for e in ereignisse {
            let pa = e.teilnehmer.filter { $0.spielerID == a }.map(\.platz).min()
            let pb = e.teilnehmer.filter { $0.spielerID == b }.map(\.platz).min()
            guard let pa, let pb else { continue }
            var d = jeSpiel[e.spiel] ?? .init()
            d.partien += 1; r.gesamt.partien += 1
            if pa < pb { d.siege += 1; r.gesamt.siege += 1; sieger.append(a) }
            else if pa > pb { d.niederlagen += 1; r.gesamt.niederlagen += 1; sieger.append(b) }
            else { d.unentschieden += 1; r.gesamt.unentschieden += 1; sieger.append(nil) }
            jeSpiel[e.spiel] = d
        }
        if let letzter = sieger.last, let wer = letzter {
            r.serieWer = wer
            r.serieLaenge = sieger.reversed().prefix { $0 == wer }.count
        }
        r.spiele = jeSpiel.map { Rivalitaet.JeSpiel(spiel: $0.key, duell: $0.value) }
            .sorted { ($0.duell.partien, $1.spiel) > ($1.duell.partien, $0.spiel) }
        return r
    }

    /// Die Rivalen einer Person, die meistgespielte Begegnung zuerst (nur Personen mit mindestens einer gemeinsamen Partie).
    public func rivalen(von a: UUID, unter ids: [UUID]) -> [(id: UUID, rivalitaet: Rivalitaet)] {
        ids.filter { $0 != a }.compactMap { b in
            let r = rivalitaet(a, gegen: b)
            return r.gesamt.partien > 0 ? (b, r) : nil
        }.sorted { $0.rivalitaet.gesamt.partien > $1.rivalitaet.gesamt.partien }
    }
}

extension Rivalitaet {
    /// Eine Zeile für den Siegerbildschirm: „Anna – Ben: 5 : 3 insgesamt · Anna gewinnt zum 3. Mal in Folge“.
    /// Nur für genau zwei Namen, die beide Personen im Verzeichnis sind, mit mindestens zwei gemeinsamen Partien.
    @MainActor
    public static func zeile(namen: [String], verzeichnis: SpielerVerzeichnis, statistik: StatistikDienst) -> String? {
        guard namen.count == 2 else { return nil }
        let p = namen.compactMap { n in verzeichnis.menschen.first { $0.name.caseInsensitiveCompare(n) == .orderedSame } }
        guard p.count == 2, p[0].id != p[1].id else { return nil }
        let r = statistik.rivalitaet(p[0].id, gegen: p[1].id)
        guard r.gesamt.partien >= 2 else { return nil }
        var t = "\(p[0].name) – \(p[1].name): \(r.gesamt.siege) : \(r.gesamt.niederlagen)"
        if r.gesamt.unentschieden > 0 { t += String(localized: " (\(r.gesamt.unentschieden) unentschieden)") }
        if let w = r.serieWer, r.serieLaenge >= 2, let n = [p[0], p[1]].first(where: { $0.id == w })?.name {
            t += " · " + String(localized: "\(n) gewinnt \(r.serieLaenge) Mal in Folge")
        }
        return t
    }
}
