// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation
import Observation

/// Was auf der Platte liegt. Fehlende Felder beim Laden → Standardwert.
struct Gespeichert: Codable, Sendable {
    var partie: Partie?
    var tagesTag: String?
    var statistik = Statistik()

    init(partie: Partie? = nil, tagesTag: String? = nil, statistik: Statistik = Statistik()) {
        self.partie = partie; self.tagesTag = tagesTag; self.statistik = statistik
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Schluessel.self)
        partie = try? c.decodeIfPresent(Partie.self, forKey: .partie)
        tagesTag = try? c.decodeIfPresent(String.self, forKey: .tagesTag)
        statistik = (try? c.decodeIfPresent(Statistik.self, forKey: .statistik)) ?? Statistik()
    }

    enum Schluessel: String, CodingKey { case partie, tagesTag, statistik }
}

struct Ablage: Sendable {
    let url: URL

    static var standard: Ablage {
        let ordner = (try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                                   appropriateFor: nil, create: true)) ?? FileManager.default.temporaryDirectory
        return Ablage(url: ordner.appending(path: "farbraetsel.json"))
    }

    func laden() -> Gespeichert {
        guard let daten = try? Data(contentsOf: url),
              let g = try? JSONDecoder().decode(Gespeichert.self, from: daten) else { return Gespeichert() }
        return g
    }

    func speichern(_ g: Gespeichert) {
        guard let daten = try? JSONEncoder().encode(g) else { return }
        try? daten.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }
}

/// Laufende Partie für „Fortsetzen“ (Kern: `SpielStand`); die Statistik bleibt in der Ablage.
struct Stand: Codable, Sendable {
    var partie: Partie
    var tagesTag: String?
}

/// Ergebnis einer gelösten Partie für den Sieger-Bildschirm.
struct Ergebnis: Equatable {
    let stufe: Stufe
    let zuege: Int
    let sekunden: Double
    let hilfen: Int
    let neuerBestwert: Bool
    let tagesraetsel: Bool
}

@MainActor
@Observable
final class GameStore {
    private(set) var partie: Partie?
    private(set) var statistik: Statistik
    private(set) var tagesTag: String?
    private(set) var ergebnis: Ergebnis?
    var ausgewaehlt: Int?
    /// Zeitpunkt, seit dem die Uhr läuft (nil = Pause).
    private(set) var laeuftSeit: Date?
    /// Letzte Tauschplätze, für die Tausch-Animation und VoiceOver.
    private(set) var letzterTausch: (Int, Int)?

    static let standKennung = "farbraetsel"
    private let ablage: Ablage
    private let jetzt: () -> Date
    private var zaehler: UInt64 = 0

    init(ablage: Ablage = .standard, jetzt: @escaping () -> Date = { .now }) {
        self.ablage = ablage
        self.jetzt = jetzt
        let g = ablage.laden()
        let stand = SpielStand.laden(Stand.self, spiel: Self.standKennung)
        let offen = (stand?.partie.geloest ?? true) ? nil : stand
        self.partie = offen?.partie
        self.tagesTag = offen?.tagesTag
        self.statistik = g.statistik
    }

    // MARK: Start

    var hatLaufendePartie: Bool { partie != nil }

    var laeuftTagesraetsel: Bool { partie != nil && tagesTag != nil }

    func neu(stufe: Stufe) {
        zaehler &+= 1
        let seed = UInt64(truncatingIfNeeded: Int(jetzt().timeIntervalSince1970 * 1000)) &+ zaehler
        beginnen(Raetsel.erzeugen(stufe: stufe, seed: seed), tag: nil)
    }

    func neuesTagesraetsel() {
        let heute = Tageskennung.text(jetzt())
        guard !statistik.tage.contains(heute) else { return }
        if let p = partie, tagesTag == heute, !p.geloest { uhrStarten(); return }
        beginnen(Raetsel.erzeugen(stufe: .mittel, seed: Tageskennung.seed(jetzt())), tag: heute)
    }

    var tagesraetselErledigt: Bool { statistik.tage.contains(Tageskennung.text(jetzt())) }

    private func beginnen(_ r: Raetsel, tag: String?) {
        partie = Partie(raetsel: r)
        tagesTag = tag
        ausgewaehlt = nil
        ergebnis = nil
        letzterTausch = nil
        uhrStarten()
        speichern()
    }

    // MARK: Spiel

    /// Tippen auf einen Platz: erst auswählen, dann mit einem zweiten tauschen.
    func tippen(_ platz: Int) {
        guard var p = partie, !p.istFest(platz), ergebnis == nil else { return }
        guard let erster = ausgewaehlt else { ausgewaehlt = platz; return }
        ausgewaehlt = nil
        guard erster != platz else { return }
        if p.tauschen(erster, platz) {
            letzterTausch = (erster, platz)
            uebernehmen(p)
        }
    }

    func zurueck() {
        guard var p = partie, p.zurueck() else { return }
        ausgewaehlt = nil
        uebernehmen(p)
    }

    func hilfe() {
        guard var p = partie, let plaetze = p.hilfe() else { return }
        ausgewaehlt = nil
        letzterTausch = plaetze
        uebernehmen(p)
    }

    private func uebernehmen(_ neu: Partie) {
        var p = neu
        p.sekunden = gespielteSekunden(zu: jetzt())
        partie = p
        laeuftSeit = laeuftSeit == nil ? nil : jetzt()
        if p.geloest { abschliessen(p) } else { speichern() }
    }

    private func abschliessen(_ p: Partie) {
        uhrAnhalten()
        let neuerBest = statistik.eintragen(stufe: p.raetsel.stufe, zuege: p.zuege, sekunden: p.sekunden, tag: tagesTag, hilfen: p.hilfen)
        TagesSerieWidget.melden(praefix: "farbraetsel", serie: statistik.serie(heute: jetzt()), letzterTag: statistik.tage.max())
        ergebnis = Ergebnis(stufe: p.raetsel.stufe, zuege: p.zuege, sekunden: p.sekunden, hilfen: p.hilfen,
                            neuerBestwert: neuerBest, tagesraetsel: tagesTag != nil)
        partie = nil
        speichern()
    }

    /// Sieger-Bildschirm schließen.
    func ergebnisSchliessen() {
        ergebnis = nil
    }

    // MARK: Uhr

    func gespielteSekunden(zu zeit: Date) -> Double {
        let basis = partie?.sekunden ?? 0
        guard let seit = laeuftSeit else { return basis }
        return basis + max(0, zeit.timeIntervalSince(seit))
    }

    func uhrStarten() { if partie != nil, laeuftSeit == nil { laeuftSeit = jetzt() } }

    func uhrAnhalten() {
        guard var p = partie, laeuftSeit != nil else { laeuftSeit = nil; return }
        p.sekunden = gespielteSekunden(zu: jetzt())
        partie = p
        laeuftSeit = nil
    }

    /// Beim Wechsel in den Hintergrund / zurück.
    func szenePhase(aktiv: Bool) {
        if aktiv { uhrStarten() } else { uhrAnhalten(); speichern() }
    }

    func speichern() {
        ablage.speichern(Gespeichert(statistik: statistik))
        // Fortsetzen über den Kern; ein bewusst beendeter Stand wird nicht wieder angelegt
        if let p = partie {
            if !SpielStand.verworfen.contains(Self.standKennung) { SpielStand.sichern(Stand(partie: p, tagesTag: tagesTag), spiel: Self.standKennung) }
        } else {
            SpielStand.loeschen(Self.standKennung)
        }
    }
}
