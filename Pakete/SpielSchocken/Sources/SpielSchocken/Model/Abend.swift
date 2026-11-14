// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation
import Observation

/// Ein Spieleabend: alle Partien, bis mehr als 6 Stunden Pause liegen oder jemand „Neuer Abend“ wählt (SPEZIFIKATION 13.3).
struct Abend: Codable, Equatable {
    static let pauseSekunden = 6 * 3600

    struct Eintrag: Codable, Equatable {
        var partien = 0
        var partienVerloren = 0
        var haelftenVerloren = 0
        /// Schock aus geworfen (Runde 2, SPEZIFIKATION 14.2)
        var schockAus = 0
        /// Deckel insgesamt bekommen (aus dem Stock und von Mitspielern)
        var deckel = 0
        /// Avatar des Spielers (damit die Abend-Karten dieselben Avatare zeigen wie überall)
        var avatar: String?

        init() {}

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            partien = try c.decodeIfPresent(Int.self, forKey: .partien) ?? 0
            partienVerloren = try c.decodeIfPresent(Int.self, forKey: .partienVerloren) ?? 0
            haelftenVerloren = try c.decodeIfPresent(Int.self, forKey: .haelftenVerloren) ?? 0
            schockAus = try c.decodeIfPresent(Int.self, forKey: .schockAus) ?? 0
            deckel = try c.decodeIfPresent(Int.self, forKey: .deckel) ?? 0
            avatar = try c.decodeIfPresent(String.self, forKey: .avatar)
        }
    }

    /// Eine Auszeichnung des Abends (SPEZIFIKATION 14.2). `namen` alphabetisch, bei Gleichstand teilen sich alle.
    struct Auszeichnung: Equatable {
        var id: String
        var namen: [String]
        var wert: Int
    }

    /// Nach Namen: Schock aus und bekommene Deckel. Vergeben wird ab der 2. Partie, in fester Reihenfolge
    /// `schockKoenig` (meiste Schock aus, mindestens 1), `pechvogel` und `glueckspilz` (meiste bzw. wenigste Deckel,
    /// nur wenn nicht alle gleich viele haben).
    static func auszeichnungen(werte: [String: (schockAus: Int, deckel: Int)], partien: Int) -> [Auszeichnung] {
        guard partien >= 2, !werte.isEmpty else { return [] }
        func beste(_ wert: ((schockAus: Int, deckel: Int)) -> Int, maximal: Bool) -> ([String], Int) {
            let zahlen = werte.mapValues(wert)
            let ziel = maximal ? zahlen.values.max()! : zahlen.values.min()!
            return (zahlen.filter { $0.value == ziel }.map(\.key).sorted(), ziel)
        }
        var erg: [Auszeichnung] = []
        let (k, z) = beste({ $0.schockAus }, maximal: true)
        if z >= 1 { erg.append(Auszeichnung(id: "schockKoenig", namen: k, wert: z)) }
        if Set(werte.values.map(\.deckel)).count > 1 {
            let (p, pz) = beste({ $0.deckel }, maximal: true)
            erg.append(Auszeichnung(id: "pechvogel", namen: p, wert: pz))
            let (g, gz) = beste({ $0.deckel }, maximal: false)
            erg.append(Auszeichnung(id: "glueckspilz", namen: g, wert: gz))
        }
        return erg
    }

    var auszeichnungen: [Auszeichnung] {
        Self.auszeichnungen(werte: eintraege.mapValues { ($0.schockAus, $0.deckel) }, partien: partien)
    }

    struct Zeile: Equatable {
        var name: String
        var partien: Int
        var partienVerloren: Int
        var haelftenVerloren: Int
        var avatar: String? = nil
    }

    var beginn: Int?
    var letzte: Int?
    var partien = 0
    var eintraege: [String: Eintrag] = [:]

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        beginn = try c.decodeIfPresent(Int.self, forKey: .beginn)
        letzte = try c.decodeIfPresent(Int.self, forKey: .letzte)
        partien = try c.decodeIfPresent(Int.self, forKey: .partien) ?? 0
        eintraege = try c.decodeIfPresent([String: Eintrag].self, forKey: .eintraege) ?? [:]
    }

    /// `zeit` in Sekunden (wird hineingereicht, damit sich die Logik testen lässt).
    mutating func partieBeendet(zeit: Int, spieler: [String], verlierer: String, haelftenVerlierer: [String],
                                schockAus: [String: Int] = [:], deckel: [String: Int] = [:], avatare: [String: String] = [:]) {
        if let l = letzte, zeit - l > Self.pauseSekunden { neu() }
        if beginn == nil { beginn = zeit }
        letzte = zeit
        partien += 1
        for name in spieler { eintraege[name, default: Eintrag()].partien += 1 }
        eintraege[verlierer, default: Eintrag()].partienVerloren += 1
        for name in haelftenVerlierer { eintraege[name, default: Eintrag()].haelftenVerloren += 1 }
        for (name, n) in schockAus { eintraege[name, default: Eintrag()].schockAus += n }
        for (name, n) in deckel { eintraege[name, default: Eintrag()].deckel += n }
        for (name, a) in avatare { eintraege[name, default: Eintrag()].avatar = a }
    }

    mutating func neu() {
        self = Abend()
    }

    /// Meiste verlorene Partien zuerst, dann meiste verlorene Hälften, dann Name.
    var bilanz: [Zeile] {
        eintraege.map { Zeile(name: $0.key, partien: $0.value.partien, partienVerloren: $0.value.partienVerloren,
                              haelftenVerloren: $0.value.haelftenVerloren, avatar: $0.value.avatar) }
            .sorted { a, b in
                (a.partienVerloren, a.haelftenVerloren, b.name) > (b.partienVerloren, b.haelftenVerloren, a.name)
            }
    }

    /// Die Karte „HEUTE“ erscheint ab der zweiten Partie.
    var karteZeigen: Bool { partien >= 2 }
}

/// Der Abend wird mit den Einstellungen gesichert (nicht mit dem Spielstand).
@MainActor
@Observable
final class AbendStore {
    private(set) var abend: Abend

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let jetzt: () -> Int

    init(defaults: UserDefaults = .standard, jetzt: @escaping () -> Int = { Int(Date().timeIntervalSince1970) }) {
        self.defaults = defaults
        self.jetzt = jetzt
        abend = defaults.data(forKey: "abend").flatMap { try? JSONDecoder().decode(Abend.self, from: $0) } ?? Abend()
    }

    func erfasse(_ z: Spielzustand) {
        guard let v = z.partieVerlierer else { return }
        var schockAus: [String: Int] = [:]
        var deckel: [String: Int] = [:]
        for (i, n) in z.zaehler.schockAus.enumerated() { schockAus[z.namen[i], default: 0] += n }
        for haelfte in z.verlaeufe { for r in haelfte.runden { deckel[z.namen[r.verlierer], default: 0] += r.deckel } }
        abend.partieBeendet(zeit: jetzt(), spieler: z.namen, verlierer: z.namen[v],
                            haelftenVerlierer: z.haelftenVerlierer.map { z.namen[$0] }, schockAus: schockAus, deckel: deckel,
                            avatare: Dictionary(z.namen.enumerated().map { ($1, z.avatare[$0]) }, uniquingKeysWith: { _, neu in neu }))
        speichern()
    }

    func neuerAbend() {
        abend.neu()
        speichern()
    }

    #if DEBUG
    /// Nur für Demo-Szenarien
    func demoSetzen(_ a: Abend) {
        abend = a
        speichern()
    }
    #endif

    private func speichern() {
        if let daten = try? JSONEncoder().encode(abend) { defaults.set(daten, forKey: "abend") }
    }
}
