// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Wie ein Mensch würfelt (SPEZIFIKATION 8.1): in der App oder mit einem echten Würfel am Tisch (Zahl eintippen).
enum Wuerfelart: String, Codable, CaseIterable, Sendable {
    case app, echt
}

/// Ein Platz am Brett.
struct Spieler: Codable, Equatable, Hashable, Identifiable, Sendable {
    var name: String
    var avatar: String
    var strategie: Strategie
    /// Sitz (Farbe) 0…3.
    var sitz: Int
    /// Nur für Menschen: Computer würfeln immer in der App.
    var wuerfel = Wuerfelart.app

    var id: Int { sitz }
    var istComputer: Bool { strategie != .mensch }

    init(name: String, avatar: String, strategie: Strategie, sitz: Int, wuerfel: Wuerfelart = .app) {
        self.name = name
        self.avatar = avatar
        self.strategie = strategie
        self.sitz = sitz
        self.wuerfel = wuerfel
    }

    /// Gibt dieser Mensch seine Würfe ein?
    var wuerfeltEcht: Bool { strategie == .mensch && wuerfel == .echt }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? ""
        avatar = try c.decodeIfPresent(String.self, forKey: .avatar) ?? Avatare.standard(0)
        strategie = (try? c.decodeIfPresent(Strategie.self, forKey: .strategie)) ?? .mensch
        sitz = try c.decode(Int.self, forKey: .sitz)
        wuerfel = (try? c.decodeIfPresent(Wuerfelart.self, forKey: .wuerfel)) ?? .app
    }
}

/// Serie aus mehreren Partien (SPEZIFIKATION 11.3): Wer zuerst `ziel` Partien gewinnt (2 = Best of 3, 3 = Best of 5), gewinnt die Serie.
struct Serie: Codable, Equatable, Sendable {
    var ziel: Int
    /// Gewonnene Partien je Spieler-Index
    var siege: [Int]
    /// Laufende Partie (1-basiert)
    var partie = 1
    /// Der Sieger der laufenden Partie ist schon eingetragen
    var verbucht = false

    init(ziel: Int, spieler: Int) {
        self.ziel = ziel
        siege = Array(repeating: 0, count: spieler)
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        ziel = try c.decode(Int.self, forKey: .ziel)
        siege = try c.decode([Int].self, forKey: .siege)
        partie = try c.decodeIfPresent(Int.self, forKey: .partie) ?? 1
        verbucht = try c.decodeIfPresent(Bool.self, forKey: .verbucht) ?? false
    }

    /// Höchstens so viele Partien (Best of 3 = 3, Best of 5 = 5)
    var hoechstens: Int { 2 * ziel - 1 }
    var gewinner: Int? { siege.firstIndex { $0 >= ziel } }
    var entschieden: Bool { gewinner != nil }
}

/// Alles, was zu einer laufenden Partie gehört und gespeichert wird.
struct Spielzustand: Codable, Equatable, Sendable {
    /// Stabile Bildschirmphase. Animationen (`wuerfelt`, `zieht`) sind Sache der Oberfläche und werden nicht gespeichert.
    enum Phase: String, Sendable {
        case vorWurf, wahl, verfallen, computer, vorbei
    }

    /// Spieler in der Reihenfolge der Sitze (Index = Spieler-Index in `partie`).
    var spieler: [Spieler]
    var partie: Partie
    var quelle: SeedQuelle
    var statistikErfasst = false
    /// Läuft eine Serie? (nil = Einzelpartie)
    var serie: Serie?

    /// Neue Partie. Der Beginner wird einmal vor dem ersten Wurf aus der Würfelquelle gezogen.
    /// Mit `beginner` (Revanche: reihum der Nächste) wird nicht gelost, die Quelle zieht trotzdem einmal.
    init(spieler: [Spieler], optionen: Optionen, seed: UInt64, beginner: Int? = nil, serie: Serie? = nil) {
        let sortiert = spieler.sorted { $0.sitz < $1.sitz }
        var q = SeedQuelle(seed: seed)
        let gelost = q.naechster(unter: sortiert.count)
        let beginner = beginner.map { $0 % sortiert.count } ?? gelost
        self.spieler = sortiert
        partie = .neu(sitze: sortiert.map(\.sitz), beginner: beginner, optionen: optionen)
        quelle = q
        self.serie = serie
    }

    /// Zustand aus einer fertig aufgebauten Partie (Demo-Szenarien).
    init(spieler: [Spieler], partie: Partie, quelle: SeedQuelle) {
        self.spieler = spieler
        self.partie = partie
        self.quelle = quelle
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        spieler = try c.decode([Spieler].self, forKey: .spieler)
        partie = try c.decode(Partie.self, forKey: .partie)
        quelle = try c.decodeIfPresent(SeedQuelle.self, forKey: .quelle) ?? SeedQuelle(seed: UInt64.random(in: .min ... .max))
        statistikErfasst = try c.decodeIfPresent(Bool.self, forKey: .statistikErfasst) ?? false
        serie = try c.decodeIfPresent(Serie.self, forKey: .serie)
    }

    /// Spieler-Indizes der Menschen (für die Stufe „lieb“).
    var menschen: Set<Int> { Set(spieler.indices.filter { spieler[$0].strategie == .mensch }) }

    var lage: Lage { partie.lage }
    var optionen: Optionen { partie.optionen }
    var amZug: Int { partie.amZug }
    var aktuellerSpieler: Spieler { spieler[partie.amZug] }

    var phase: Phase {
        if partie.vorbei { return .vorbei }
        if aktuellerSpieler.istComputer { return .computer }
        switch partie.spielzug.stand {
        case .vorWurf, .ende: return .vorWurf
        case .wahl: return .wahl
        case .verfallen: return .verfallen
        }
    }

    /// Wartet die App auf die Zahl vom echten Würfel? (Ein Mensch mit „echt“ ist vor dem Wurf.)
    var erwartetEingabe: Bool {
        phase == .vorWurf && aktuellerSpieler.wuerfeltEcht
    }

    /// Ist die Partie vorbei, wird ihr Sieger (Platz 1) einmal in die Serie eingetragen.
    mutating func serieVerbuchen() {
        guard var s = serie, phase == .vorbei, !s.verbucht, let sieger = partie.platzierung.first, sieger < s.siege.count else { return }
        s.siege[sieger] += 1
        s.verbucht = true
        serie = s
    }

    /// Die Serie ist mit dieser Partie entschieden.
    var serieEntschieden: Bool { serie?.entschieden == true && phase == .vorbei }

    // MARK: Aktionen

    mutating func wuerfeln() {
        partie.wuerfeln(&quelle)
    }

    /// Die Zahl vom echten Würfel. Die Würfelquelle der App bleibt unberührt.
    mutating func eintippen(_ augen: Int) {
        partie.eintippen(augen)
    }

    @discardableResult
    mutating func waehle(_ zug: Zug) -> Bewegung? {
        partie.waehle(zug)
    }

    mutating func verfallenWeiter() {
        partie.weiter()
    }

    /// Ein Schritt des Computers, der gerade dran ist (würfeln, Zug wählen oder verfallenen Wurf quittieren).
    /// Die Wahl selbst kann auch außerhalb berechnet und mit `waehle` angewendet werden.
    @discardableResult
    mutating func computerSchritt() -> Bewegung? {
        switch partie.spielzug.stand {
        case .vorWurf: wuerfeln(); return nil
        case .verfallen: verfallenWeiter(); return nil
        case .wahl:
            let z = Computer.entscheide(aktuellerSpieler.strategie, lage, amZug, partie.spielzug.erlaubt, menschen: menschen)
            return waehle(z)
        case .ende: return nil
        }
    }
}

extension Spielzustand {
    /// Grobe Stimmigkeitsprüfung nach dem Laden: schützt vor Abstürzen durch beschädigte oder fremde Dateien.
    var istPlausibel: Bool {
        let n = spieler.count
        let l = partie.lage
        guard (2 ... 4).contains(n), l.sitze.count == n, l.figuren.count == n,
              l.sitze == l.sitze.sorted(), Set(l.sitze).count == n, l.sitze.allSatisfy({ (0 ... 3).contains($0) }),
              (0 ..< n).contains(partie.amZug), partie.spielzug.spieler == partie.amZug,
              partie.platzierung.allSatisfy({ (0 ..< n).contains($0) }), Set(partie.platzierung).count == partie.platzierung.count,
              l.figuren.allSatisfy({ !$0.isEmpty && $0.count <= 4 && $0.allSatisfy { (-1 ... 43).contains($0) } }),
              Set(l.figuren.map(\.count)).count == 1
        else { return false }
        let sp = partie.spielzug
        if let a = sp.augen, !(1 ... 6).contains(a) { return false }
        guard sp.erlaubt.allSatisfy({ z in (-1 ... 43).contains(z.von) && (0 ... 43).contains(z.nach) && z.schlaegt.map { (0 ..< n).contains($0) } != false }),
              sp.erlaubt.allSatisfy({ z in l.figuren[partie.amZug].contains(z.von) })
        else { return false }
        return true
    }
}
