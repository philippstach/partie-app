// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Was ein Spieler nach einem Wurf tun kann.
enum Aktion: Codable, Hashable {
    case stehen
    case weiter(herauslegen: [Int], umdrehen: Int)

    private enum CodingKeys: String, CodingKey { case typ, herauslegen, umdrehen }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if try c.decode(String.self, forKey: .typ) == "stehen" {
            self = .stehen
        } else {
            self = .weiter(herauslegen: try c.decodeIfPresent([Int].self, forKey: .herauslegen) ?? [],
                           umdrehen: try c.decodeIfPresent(Int.self, forKey: .umdrehen) ?? 0)
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .stehen:
            try c.encode("stehen", forKey: .typ)
        case let .weiter(h, u):
            try c.encode("weiter", forKey: .typ)
            try c.encode(h, forKey: .herauslegen)
            try c.encode(u, forKey: .umdrehen)
        }
    }
}

/// Ein erlaubtes (Herauslegen, Umdrehen)-Paar.
struct Zugwahl: Hashable {
    var herauslegen: [Int]
    var umdrehen: Int
}

/// Wie viele Sechsen darf man im Wurf umdrehen? (zwei → 1, drei → 2)
func maxUmdrehen(_ wurf: [Int]) -> Int {
    switch wurf.filter({ $0 == 6 }).count {
    case 2: 1
    case 3: 2
    default: 0
    }
}

/// Darf der Spieler `herauslegen` (Augenzahlen aus dem letzten Wurf) herauslegen, `umdrehen`
/// Sechsen zu Einsen drehen und dann weiterwerfen?
func weiterErlaubt(draussen: [Int], wurf: [Int], wuerfe: Int, maxWuerfe: Int,
                   herauslegen: [Int], umdrehen: Int, optionen: Optionen) -> Bool {
    if wuerfe < 1 || wuerfe >= maxWuerfe { return false }
    var rest = wurf
    for w in herauslegen {
        guard let i = rest.firstIndex(of: w) else { return false }
        rest.remove(at: i)
        if optionen.herauslegen == .einsen && w != 1 { return false }
    }
    if umdrehen != 0 {
        if !optionen.sechsenUmdrehen || umdrehen > maxUmdrehen(wurf) || herauslegen.contains(6) { return false }
    }
    return 3 - draussen.count - herauslegen.count - umdrehen >= 1
}

/// Alle erlaubten Züge in fester Reihenfolge: umdrehen aufsteigend, darin herauslegen
/// nach (Länge, lexikografisch aufsteigend).
func moeglicheZuege(draussen: [Int], wurf: [Int], wuerfe: Int, maxWuerfe: Int, optionen: Optionen) -> [Zugwahl] {
    let sortiert = wurf.sorted()
    var teilmengen: Set<[Int]> = [[]]
    for maske in 1..<(1 << sortiert.count) {
        teilmengen.insert((0..<sortiert.count).filter { maske & (1 << $0) != 0 }.map { sortiert[$0] })
    }
    let geordnet = teilmengen.sorted { a, b in
        a.count != b.count ? a.count < b.count : a.lexicographicallyPrecedes(b)
    }
    var erg: [Zugwahl] = []
    for u in 0..<3 {
        for h in geordnet where weiterErlaubt(draussen: draussen, wurf: wurf, wuerfe: wuerfe, maxWuerfe: maxWuerfe,
                                              herauslegen: h, umdrehen: u, optionen: optionen) {
            erg.append(Zugwahl(herauslegen: h, umdrehen: u))
        }
    }
    return erg
}

/// Zustand eines laufenden Zugs. `draussen` = herausgelegte (oder umgedrehte) Würfel,
/// `wurf` = zuletzt geworfene Würfel.
struct Zug: Codable, Equatable {
    var maxWuerfe: Int
    var optionen: Optionen
    var draussen: [Int] = []
    var wurf: [Int] = []
    var wuerfe = 0
    var fertig = false
    /// Was der Spieler getan hat (ohne den ersten Wurf und ohne das automatische Ende nach dem letzten Wurf)
    var aktionen: [Aktion] = []

    init(maxWuerfe: Int, optionen: Optionen = .standard) {
        self.maxWuerfe = maxWuerfe
        self.optionen = optionen
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        maxWuerfe = try c.decodeIfPresent(Int.self, forKey: .maxWuerfe) ?? 3
        optionen = try c.decodeIfPresent(Optionen.self, forKey: .optionen) ?? .standard
        draussen = try c.decodeIfPresent([Int].self, forKey: .draussen) ?? []
        wurf = try c.decodeIfPresent([Int].self, forKey: .wurf) ?? []
        wuerfe = try c.decodeIfPresent(Int.self, forKey: .wuerfe) ?? 0
        fertig = try c.decodeIfPresent(Bool.self, forKey: .fertig) ?? false
        aktionen = try c.decodeIfPresent([Aktion].self, forKey: .aktionen) ?? []
    }

    /// Alle drei Würfel, absteigend.
    var alleWuerfel: [Int] { (draussen + wurf).sorted(by: >) }

    var darfWeiter: Bool { !fertig && wuerfe < maxWuerfe }

    func wertung() -> Wertung {
        werte(draussen + wurf, ausEinemWurf: draussen.isEmpty, optionen: optionen)
    }

    func istErlaubt(herauslegen: [Int], umdrehen: Int) -> Bool {
        weiterErlaubt(draussen: draussen, wurf: wurf, wuerfe: wuerfe, maxWuerfe: maxWuerfe,
                      herauslegen: herauslegen.sorted(), umdrehen: umdrehen, optionen: optionen)
    }

    func moeglicheZuege() -> [Zugwahl] {
        SpielSchocken.moeglicheZuege(draussen: draussen, wurf: wurf, wuerfe: wuerfe, maxWuerfe: maxWuerfe, optionen: optionen)
    }

    mutating func werfen<Q: Wuerfelquelle>(_ quelle: inout Q) {
        let n = 3 - draussen.count
        precondition(n >= 1 && wuerfe < maxWuerfe && !fertig)
        wurf = (0..<n).map { _ in quelle.naechster() }
        wuerfe += 1
    }

    /// Legt heraus, dreht um und wirft neu. `false` (und keine Änderung), wenn unerlaubt.
    @discardableResult
    mutating func weiter<Q: Wuerfelquelle>(herauslegen: [Int], umdrehen: Int, quelle: inout Q) -> Bool {
        guard istErlaubt(herauslegen: herauslegen, umdrehen: umdrehen) else { return false }
        aktionen.append(.weiter(herauslegen: herauslegen.sorted(), umdrehen: umdrehen))
        draussen += herauslegen.sorted() + Array(repeating: 1, count: umdrehen)
        wurf = []
        werfen(&quelle)
        return true
    }

    mutating func stehen() {
        precondition(wuerfe >= 1)
        aktionen.append(.stehen)
        fertig = true
    }
}
