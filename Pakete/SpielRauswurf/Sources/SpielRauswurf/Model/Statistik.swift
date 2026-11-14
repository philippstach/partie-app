// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation
import Observation

/// Statistik je Spielername (Computer: je Stärke), SPEZIFIKATION Abschnitt 11.
struct SpielerStatistik: Codable, Equatable, Identifiable, Sendable {
    var id: String
    var partien = 0
    var siege = 0
    var geschlagen = 0
    var rausgeworfen = 0
    var sechsen = 0
    /// Beste (kleinste) Zahl eigener Spielzüge bis zum Sieg.
    var zuegeBisSieg: Int?
    /// Wie oft jede Zahl fiel (`augen[0]` = Einsen), alle Würfe dieses Spielers in beendeten Partien
    var augen = [Int](repeating: 0, count: 6)
    /// Längste Durststrecke ohne 6 in einer beendeten Partie
    var ohneSechs = 0

    init(id: String) { self.id = id }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        partien = try c.decodeIfPresent(Int.self, forKey: .partien) ?? 0
        siege = try c.decodeIfPresent(Int.self, forKey: .siege) ?? 0
        geschlagen = try c.decodeIfPresent(Int.self, forKey: .geschlagen) ?? 0
        rausgeworfen = try c.decodeIfPresent(Int.self, forKey: .rausgeworfen) ?? 0
        sechsen = try c.decodeIfPresent(Int.self, forKey: .sechsen) ?? 0
        zuegeBisSieg = try c.decodeIfPresent(Int.self, forKey: .zuegeBisSieg)
        let a = try c.decodeIfPresent([Int].self, forKey: .augen) ?? []
        augen = a.count == 6 ? a : [Int](repeating: 0, count: 6)
        ohneSechs = try c.decodeIfPresent(Int.self, forKey: .ohneSechs) ?? 0
    }
}

/// Zählt eine beendete Partie einmal aus dem Verlauf aus. So zählt ein zurückgenommener Zug nie doppelt.
enum PartieZaehlung {
    /// Schlüssel der Computer-Zeilen
    static let computerEinfach = "#computer-einfach"
    static let computerGut = "#computer-gut"
    static let computerLieb = "#computer-lieb"

    struct Zahlen: Equatable, Sendable {
        var geschlagen = 0
        var rausgeworfen = 0
        var sechsen = 0
        var spielzuege = 0
    }

    /// Zahlen je Spieler-Index.
    static func zaehle(_ partie: Partie) -> [Zahlen] {
        var z = Array(repeating: Zahlen(), count: partie.spielerzahl)
        for e in partie.verlauf {
            z[e.spieler].spielzuege += 1
            for w in e.wuerfe {
                if w.augen == 6 { z[e.spieler].sechsen += 1 }
                if let s = w.zug?.schlaegt {
                    z[e.spieler].geschlagen += 1
                    z[s].rausgeworfen += 1
                }
            }
        }
        return z
    }

    static func schluessel(_ s: Spieler) -> String {
        switch s.strategie {
        case .mensch: s.name
        case .einfach: computerEinfach
        case .gut: computerGut
        case .lieb: computerLieb
        }
    }
}

@MainActor
@Observable
final class StatsStore {
    private(set) var eintraege: [SpielerStatistik]
    /// Die letzten beendeten Partien (neueste zuerst, höchstens 50)
    private(set) var verlauf: [VerlaufPartie]

    @ObservationIgnored private let url: URL
    @ObservationIgnored private var verlaufURL: URL { url.deletingPathExtension().appendingPathExtension("verlauf.json") }

    init(url: URL = StatsStore.standardURL) {
        self.url = url
        let verlaufURL = url.deletingPathExtension().appendingPathExtension("verlauf.json")
        eintraege = Self.ladeOderSichere(url) { try JSONDecoder().decode([SpielerStatistik].self, from: $0) } ?? []
        verlauf = (Self.ladeOderSichere(verlaufURL) {
            let dec = JSONDecoder()
            dec.dateDecodingStrategy = .secondsSince1970
            return try dec.decode([VerlaufPartie].self, from: $0)
        } ?? []).sorted { $0.datum > $1.datum }
    }

    /// Fehlt die Datei: nil. Ist sie beschädigt: zur Seite legen (statt sie beim nächsten Speichern zu überschreiben).
    private static func ladeOderSichere<T>(_ url: URL, _ lesen: (Data) throws -> T) -> T? {
        guard let daten = try? Data(contentsOf: url) else { return nil }
        do { return try lesen(daten) } catch {
            let ziel = url.deletingPathExtension().appendingPathExtension("defekt.json")
            try? FileManager.default.removeItem(at: ziel)
            try? FileManager.default.moveItem(at: url, to: ziel)
            return nil
        }
    }

    nonisolated static var standardURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appending(path: "statistik.json")
    }

    /// Verteilung 1–6 über alle Würfe aller Spieler in beendeten Partien.
    var augenGesamt: [Int] {
        (0 ..< 6).map { k in eintraege.reduce(0) { $0 + $1.augen[k] } }
    }

    var sortiert: [SpielerStatistik] {
        eintraege.sorted { ($0.partien, $1.id) > ($1.partien, $0.id) }
    }

    /// Verbucht eine beendete Partie. Abgebrochene Partien zählen nicht.
    func erfasse(_ z: Spielzustand, datum: Date = Date(), dauerSekunden: Double = 0) {
        guard z.partie.vorbei else { return }
        let fertig = z.partie.platzierung
        let rest = z.spieler.indices.filter { !fertig.contains($0) }
        let ordnung = fertig + rest
        PartieMeldung.melden(spiel: "rauswurf", reihenfolge: ordnung.map { z.spieler[$0].name }, dauer: dauerSekunden)
        if let eintrag = VerlaufPartie(aus: z, datum: datum, dauerSekunden: dauerSekunden) {
            verlauf.append(eintrag)
            verlauf.sort { $0.datum > $1.datum }          // neueste zuerst, egal in welcher Reihenfolge erfasst wird
            if verlauf.count > VerlaufPartie.maximum { verlauf.removeLast(verlauf.count - VerlaufPartie.maximum) }
        }
        let zahlen = PartieZaehlung.zaehle(z.partie)
        let wuerfel = Wuerfelstatistik.zaehle(z.partie)
        let sieger = z.partie.platzierung.first
        for (i, s) in z.spieler.enumerated() {
            let key = PartieZaehlung.schluessel(s)
            var e = eintraege.first { $0.id == key } ?? SpielerStatistik(id: key)
            e.partien += 1
            e.geschlagen += zahlen[i].geschlagen
            e.rausgeworfen += zahlen[i].rausgeworfen
            e.sechsen += zahlen[i].sechsen
            for k in 0 ..< 6 { e.augen[k] += wuerfel[i].augen[k] }
            e.ohneSechs = max(e.ohneSechs, wuerfel[i].ohneSechs)
            if sieger == i {
                e.siege += 1
                e.zuegeBisSieg = min(e.zuegeBisSieg ?? .max, zahlen[i].spielzuege)
            }
            eintraege.removeAll { $0.id == key }
            eintraege.append(e)
        }
        speichern()
    }

    func zuruecksetzen() {
        eintraege = []
        verlauf = []
        speichern()
    }

    private func speichern() {
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? JSONEncoder().encode(eintraege).write(to: url, options: .atomic)
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .secondsSince1970
        try? enc.encode(verlauf).write(to: verlaufURL, options: .atomic)
    }
}
