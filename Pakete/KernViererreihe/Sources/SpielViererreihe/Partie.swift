// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Ungültige Aktion (SPEZIFIKATION Abschnitt 4 und 5). Die Partie bleibt dabei unverändert.
enum PartieFehler: String, Error, Equatable {
    case ungueltigeSpalte, spielVorbei, spalteVoll, nichtMoeglich
}

/// Ein Feld des Bretts: Spalte 0…6 von links, Zeile 0…5 von unten.
struct Zelle: Hashable, Comparable, Codable, Sendable {
    var spalte: Int
    var zeile: Int

    static func < (a: Zelle, b: Zelle) -> Bool { (a.spalte, a.zeile) < (b.spalte, b.zeile) }
}

/// Eine Partie: Brett 7 × 6, Spieler 1 = Rot, Spieler 2 = Blau.
/// Vollständig beschrieben durch `beginner` und `zuege`; alles andere wird daraus berechnet
/// (so wird auch gespeichert). Reine Logik, ohne UI.
struct Partie: Equatable, Codable, Sendable {
    static let spalten = 7
    static let zeilen = 6
    static let felder = spalten * zeilen
    static let richtungen = [(1, 0), (0, 1), (1, 1), (1, -1)]

    enum Status: String, Codable, Sendable {
        case laeuft, gewonnen, unentschieden
    }

    private(set) var beginner: Int
    private(set) var zuege: [Int]
    /// `brett[spalte][zeile]`: 0 = leer, 1 = Rot, 2 = Blau.
    private(set) var brett: [[Int]]
    private(set) var hoehen: [Int]
    private(set) var status: Status
    private(set) var gewinner: Int?
    private(set) var gewinnZellen: [Zelle]

    /// Baut die Stellung aus den Zügen nach. Wirft, wenn ein Zug ungültig ist.
    init(beginner: Int = 1, zuege: [Int] = []) throws {
        guard beginner == 1 || beginner == 2 else { throw PartieFehler.nichtMoeglich }
        self.beginner = beginner
        self.zuege = []
        brett = Array(repeating: Array(repeating: 0, count: Partie.zeilen), count: Partie.spalten)
        hoehen = Array(repeating: 0, count: Partie.spalten)
        status = .laeuft
        gewinner = nil
        gewinnZellen = []
        self.zuege.reserveCapacity(Partie.felder)
        for s in zuege { try einwerfen(s) }
    }

    private enum CodingKeys: String, CodingKey { case beginner, zuege }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let beginner = try c.decodeIfPresent(Int.self, forKey: .beginner) ?? 1
        let zuege = try c.decodeIfPresent([Int].self, forKey: .zuege) ?? []
        do {
            try self.init(beginner: beginner, zuege: zuege)
        } catch {
            throw DecodingError.dataCorruptedError(forKey: .zuege, in: c, debugDescription: "Ungültige Züge")
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(beginner, forKey: .beginner)
        try c.encode(zuege, forKey: .zuege)
    }

    // MARK: Abfragen

    /// Spieler, der den nächsten Stein setzt (auch nach Spielende: wer es wäre).
    var naechsterSpieler: Int { Partie.spieler(zug: zuege.count, beginner: beginner) }

    /// `nil` nach Spielende.
    var amZug: Int? { status == .laeuft ? naechsterSpieler : nil }

    var legaleSpalten: [Int] {
        guard status == .laeuft else { return [] }
        return (0..<Partie.spalten).filter { hoehen[$0] < Partie.zeilen }
    }

    /// Wer den Zug mit dieser Nummer (0 = erster) macht.
    static func spieler(zug i: Int, beginner: Int) -> Int { i % 2 == 0 ? beginner : 3 - beginner }

    /// Der letzte Stein: Spalte und Zeile.
    var letzterStein: Zelle? {
        guard let s = zuege.last else { return nil }
        return Zelle(spalte: s, zeile: hoehen[s] - 1)
    }

    /// Die Reihen (je mindestens 4 Zellen, von einem Ende zum anderen) durch den letzten Stein, wenn gewonnen.
    var gewinnReihen: [[Zelle]] {
        guard status == .gewonnen, let letzter = letzterStein else { return [] }
        let spieler = brett[letzter.spalte][letzter.zeile]
        var reihen: [[Zelle]] = []
        for (ds, dz) in Partie.richtungen {
            var reihe = [letzter]
            for vz in [1, -1] {
                var cs = letzter.spalte + vz * ds, cz = letzter.zeile + vz * dz
                while cs >= 0, cs < Partie.spalten, cz >= 0, cz < Partie.zeilen, brett[cs][cz] == spieler {
                    let zelle = Zelle(spalte: cs, zeile: cz)
                    if vz == 1 { reihe.append(zelle) } else { reihe.insert(zelle, at: 0) }
                    cs += vz * ds
                    cz += vz * dz
                }
            }
            if reihe.count >= 4 { reihen.append(reihe) }
        }
        return reihen
    }

    /// Anzahl der Steine, die `spieler` gesetzt hat.
    func steine(von spieler: Int) -> Int {
        zuege.indices.filter { Partie.spieler(zug: $0, beginner: beginner) == spieler }.count
    }

    /// Text-Bild wie in den Regeltests: oberste Zeile zuerst, `.` leer, `G` Rot, `B` Blau.
    var bild: [String] {
        let zeichen = [".", "G", "B"]
        return (0..<Partie.zeilen).reversed().map { z in
            (0..<Partie.spalten).map { s in zeichen[brett[s][z]] }.joined()
        }
    }

    // MARK: Einwerfen

    /// Wirft einen Stein des Spielers am Zug in Spalte `s` und gibt die Zeile zurück.
    /// Fehler in der Reihenfolge: `ungueltigeSpalte`, `spielVorbei`, `spalteVoll`.
    @discardableResult
    mutating func einwerfen(_ s: Int) throws -> Int {
        guard s >= 0, s < Partie.spalten else { throw PartieFehler.ungueltigeSpalte }
        guard status == .laeuft else { throw PartieFehler.spielVorbei }
        guard hoehen[s] < Partie.zeilen else { throw PartieFehler.spalteVoll }
        let spieler = naechsterSpieler
        let z = hoehen[s]
        brett[s][z] = spieler
        hoehen[s] += 1
        zuege.append(s)
        let zellen = Partie.gewinnZellen(brett, s, z)
        if !zellen.isEmpty {
            status = .gewonnen
            gewinner = spieler
            gewinnZellen = zellen
        } else if zuege.count == Partie.felder {
            status = .unentschieden
        }
        return z
    }

    /// Alle Zellen aller Reihen mit mindestens 4 gleichen Steinen durch (s, z), sortiert.
    static func gewinnZellen(_ brett: [[Int]], _ s: Int, _ z: Int) -> [Zelle] {
        let spieler = brett[s][z]
        var ergebnis: [Zelle] = []
        for (ds, dz) in richtungen {
            var reihe = [Zelle(spalte: s, zeile: z)]
            for vz in [1, -1] {
                var cs = s + vz * ds, cz = z + vz * dz
                while cs >= 0, cs < spalten, cz >= 0, cz < zeilen, brett[cs][cz] == spieler {
                    reihe.append(Zelle(spalte: cs, zeile: cz))
                    cs += vz * ds
                    cz += vz * dz
                }
            }
            if reihe.count >= 4 { ergebnis.append(contentsOf: reihe) }
        }
        guard !ergebnis.isEmpty else { return [] }
        return Array(Set(ergebnis)).sorted()
    }

    /// Spalten, in denen `spieler` mit dem nächsten Stein gewinnen würde (unabhängig davon, wer am Zug ist).
    func sofortgewinne(fuer spieler: Int) -> [Int] {
        var erg: [Int] = []
        var b = brett
        for s in 0..<Partie.spalten where hoehen[s] < Partie.zeilen {
            let z = hoehen[s]
            b[s][z] = spieler
            if Partie.hatReihe(b, s, z) { erg.append(s) }
            b[s][z] = 0
        }
        return erg
    }

    /// Schnelle Prüfung, ob durch (s, z) eine Reihe von 4 entsteht.
    private static func hatReihe(_ brett: [[Int]], _ s: Int, _ z: Int) -> Bool {
        let spieler = brett[s][z]
        for (ds, dz) in richtungen {
            var n = 1
            for vz in [1, -1] {
                var cs = s + vz * ds, cz = z + vz * dz
                while cs >= 0, cs < spalten, cz >= 0, cz < zeilen, brett[cs][cz] == spieler {
                    n += 1
                    cs += vz * ds
                    cz += vz * dz
                }
            }
            if n >= 4 { return true }
        }
        return false
    }

    // MARK: Rückgängig (SPEZIFIKATION 5)

    /// `computer` = Spielernummer des Computers (gegen Computer) oder `nil` (zu zweit).
    /// Zu zweit geht der letzte Zug zurück, gegen den Computer alles bis einschließlich des letzten Zugs des Menschen.
    /// Nach Spielende oder ohne passenden Zug: `nichtMoeglich`.
    func rueckgaengig(computer: Int?) throws -> Partie {
        guard status == .laeuft else { throw PartieFehler.nichtMoeglich }
        var rest = zuege
        if let computer {
            let mensch = 3 - computer
            guard zuege.indices.contains(where: { Partie.spieler(zug: $0, beginner: beginner) == mensch }) else {
                throw PartieFehler.nichtMoeglich
            }
            while let i = rest.indices.last {
                rest.removeLast()
                if Partie.spieler(zug: i, beginner: beginner) == mensch { break }
            }
        } else {
            guard !rest.isEmpty else { throw PartieFehler.nichtMoeglich }
            rest.removeLast()
        }
        return try Partie(beginner: beginner, zuege: rest)
    }

    func kannRueckgaengig(computer: Int?) -> Bool {
        (try? rueckgaengig(computer: computer)) != nil
    }
}
