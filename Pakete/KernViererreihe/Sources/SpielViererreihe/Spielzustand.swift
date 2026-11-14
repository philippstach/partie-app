// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

enum Modus: String, Codable, CaseIterable, Sendable {
    case gegenComputer, zuZweit
}

enum BeginnerWahl: String, Codable, CaseIterable, Sendable {
    case abwechselnd, ich, computer
}

struct Spieler: Codable, Equatable, Sendable {
    var name: String
    var avatar: String

    init(name: String, avatar: String = "") {
        self.name = name
        self.avatar = avatar
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? ""
        avatar = try c.decodeIfPresent(String.self, forKey: .avatar) ?? ""
    }

    static var standard: [Spieler] {
        [Spieler(name: String(localized: "Spieler 1"), avatar: Avatare.standard(6)),
         Spieler(name: String(localized: "Spieler 2"), avatar: Avatare.standard(5))]
    }

    /// Der Standardname in allen Sprachen: gespeicherte Namen folgen keinem Sprachwechsel
    static func istStandardName(_ name: String) -> Bool {
        let n = name.trimmingCharacters(in: .whitespaces)
        return n.isEmpty || n == Spieler.ich.name || ["Du", "You", "Tú", "Toi"].contains(n)
    }

    static var ich: Spieler { Spieler(name: String(localized: "Du"), avatar: Avatare.standard(0)) }

    static var computer: Spieler { Spieler(name: String(localized: "Computer"), avatar: Avatare.standard(11)) }
}

/// „Bis 2 Siege“ / „Bis 3 Siege“ zu zweit (SPEZIFIKATION 15.5). `ziel` 1 = einzelne Partie, kein Match.
struct Match: Codable, Equatable, Sendable {
    var ziel = 1
    /// Siege von Spieler 1 und 2. Unentschieden zählt für niemanden.
    var siege = [0, 0]
    /// Nummer der laufenden Partie im Match (ab 1).
    var partieNummer = 1

    init(ziel: Int = 1) { self.ziel = min(max(ziel, 1), 3) }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        ziel = min(max((try? c.decodeIfPresent(Int.self, forKey: .ziel)) ?? 1, 1), 3)
        let gelesen = (try? c.decodeIfPresent([Int].self, forKey: .siege)) ?? []
        siege = gelesen.count == 2 ? gelesen : [0, 0]
        partieNummer = max((try? c.decodeIfPresent(Int.self, forKey: .partieNummer)) ?? 1, 1)
    }

    var istMatch: Bool { ziel >= 2 }
    /// Wer das Match gewonnen hat (1 oder 2), sonst `nil`.
    var sieger: Int? { istMatch ? siege.firstIndex { $0 >= ziel }.map { $0 + 1 } : nil }
}

/// Wo der Bildschirm gerade steht (wird nicht gespeichert, sondern berechnet).
enum Phase: Equatable, Sendable {
    case menschAmZug, computerDenkt, vorbei
}

/// Übungspartie ab einer Stellung („Ab hier nochmal“, SPEZIFIKATION 16.1): zählt nicht in Statistik, Serie und Meilensteinen.
struct Uebung: Codable, Equatable, Sendable {
    /// Anzahl der Züge der Ausgangsstellung. Rückgängig geht nicht weiter zurück.
    var startZug = 0

    init(startZug: Int) { self.startZug = max(startZug, 0) }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        startZug = max((try? c.decodeIfPresent(Int.self, forKey: .startZug)) ?? 0, 0)
    }
}

/// Die laufende (oder gerade beendete) Partie mit ihren Einstellungen.
struct Spielzustand: Codable, Equatable, Sendable {
    /// Gegen den Computer ist der Mensch immer Rot (1) und der Computer immer Blau (2).
    static let computerSpieler = 2

    var modus: Modus
    var stufe: Stufe
    var beginnerWahl: BeginnerWahl
    var partie: Partie
    var spieler: [Spieler]
    var rueckgaengigBenutzt = false
    var aufgegeben = false
    /// Der Mensch hat in dieser Partie mindestens einen Tipp geholt (kein „Sieg ohne Hilfe“).
    var tippBenutzt = false
    var statistikErfasst = false
    /// Der Sieg hat die beste Siegesserie dieser Stufe verbessert (für das Abzeichen im Ende-Banner).
    var neueBestserie = false
    /// Meilensteine, die diese Partie neu erreicht hat (`Meilenstein.rawValue`), für das Abzeichen im Ende-Banner.
    var neueMeilensteine: [String] = []
    /// Das Match, zu dem diese Partie gehört (zu zweit). Fehlt es beim Laden, ist es eine einzelne Partie.
    var match = Match()
    /// Gesetzt bei einer Übungspartie. Fehlt es beim Laden, ist es keine Übung.
    var uebung: Uebung?
    /// Wie zwei Spieler am Gerät sitzen (nur zu zweit). Fehlt es beim Laden: nebeneinander.
    var sitzordnung = Sitzordnung.nebeneinander

    init(modus: Modus, stufe: Stufe, beginnerWahl: BeginnerWahl, partie: Partie, spieler: [Spieler]) {
        self.modus = modus
        self.stufe = stufe
        self.beginnerWahl = beginnerWahl
        self.partie = partie
        self.spieler = spieler
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        modus = (try? c.decodeIfPresent(Modus.self, forKey: .modus)) ?? .gegenComputer
        stufe = (try? c.decodeIfPresent(Stufe.self, forKey: .stufe)) ?? .mittel
        beginnerWahl = (try? c.decodeIfPresent(BeginnerWahl.self, forKey: .beginnerWahl)) ?? .abwechselnd
        partie = try c.decode(Partie.self, forKey: .partie)
        let gelesen = (try? c.decodeIfPresent([Spieler].self, forKey: .spieler)) ?? []
        spieler = gelesen.count == 2 ? gelesen : Spieler.standard
        rueckgaengigBenutzt = (try? c.decodeIfPresent(Bool.self, forKey: .rueckgaengigBenutzt)) ?? false
        aufgegeben = (try? c.decodeIfPresent(Bool.self, forKey: .aufgegeben)) ?? false
        tippBenutzt = (try? c.decodeIfPresent(Bool.self, forKey: .tippBenutzt)) ?? false
        statistikErfasst = (try? c.decodeIfPresent(Bool.self, forKey: .statistikErfasst)) ?? false
        neueBestserie = (try? c.decodeIfPresent(Bool.self, forKey: .neueBestserie)) ?? false
        neueMeilensteine = (try? c.decodeIfPresent([String].self, forKey: .neueMeilensteine)) ?? []
        match = (try? c.decodeIfPresent(Match.self, forKey: .match)) ?? Match()
        uebung = try? c.decodeIfPresent(Uebung.self, forKey: .uebung)
        sitzordnung = (try? c.decodeIfPresent(Sitzordnung.self, forKey: .sitzordnung)) ?? .nebeneinander
    }

    /// Spielernummer des Computers, `nil` zu zweit.
    var computer: Int? { modus == .gegenComputer ? Spielzustand.computerSpieler : nil }

    var phase: Phase {
        if aufgegeben || partie.status != .laeuft { return .vorbei }
        return partie.naechsterSpieler == computer ? .computerDenkt : .menschAmZug
    }

    /// Wer gewonnen hat (1 oder 2). Aufgeben gegen den Computer: der Computer. `nil` = unentschieden oder läuft noch.
    var sieger: Int? { aufgegeben ? computer : partie.gewinner }

    /// Ein Match läuft noch (auch zwischen zwei Partien).
    var matchLaeuft: Bool { modus == .zuZweit && match.istMatch && match.sieger == nil }

    /// In einer Übungspartie endet Rückgängig am Startpunkt.
    var kannRueckgaengig: Bool {
        guard phase == .menschAmZug, let neu = try? partie.rueckgaengig(computer: computer) else { return false }
        return neu.zuege.count >= (uebung?.startZug ?? 0)
    }

    /// Ausgang für den Menschen gegen den Computer; `nil`, wenn die Partie noch läuft.
    var ausgangFuerMensch: Ausgang? {
        guard phase == .vorbei else { return nil }
        if aufgegeben { return .niederlage }
        switch partie.gewinner {
        case 1: return .sieg
        case .some: return .niederlage
        case nil: return .unentschieden
        }
    }
}




