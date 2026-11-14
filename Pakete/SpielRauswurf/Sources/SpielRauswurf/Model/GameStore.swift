// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation
import Observation

/// Führt Aktionen auf dem Spielzustand aus, speichert nach jeder Aktion und verwaltet „Rückgängig“.
@MainActor
@Observable
final class GameStore {
    static let maxRueckgaengig = 50

    private(set) var zustand: Spielzustand?
    /// Wechselt bei jeder neuen Partie (auch Revanche) und beim Beenden; die Oberfläche setzt dann ihren Ablauf neu auf.
    private(set) var partieID = UUID()
    var speicherFehler: String?
    /// Welcher Bildschirm gerade offen ist (wird nicht gespeichert).
    var screen: Screen = .home
    /// Die letzte ausgeführte Bewegung samt Zähler (für Animationen und Ansagen). Wird nicht gespeichert.
    private(set) var letzteBewegung: Bewegung?
    private(set) var bewegungsZaehler = 0

    enum Screen { case home, setup, game }

    /// Kopien des ganzen Spielzustands vor jeder Entscheidung eines Menschen. Nur im Speicher.
    @ObservationIgnored private var rueckgaengig: [Spielzustand] = []
    /// Spielzeit der laufenden Partie in Sekunden
    private(set) var dauerSekunden = 0.0
    /// Zeitpunkt der letzten Aktion (für die Spielzeit)
    @ObservationIgnored private var letzteAktion: Date?
    @ObservationIgnored private let repository: GameRepository
    @ObservationIgnored private let seedErzeuger: () -> UInt64

    init(repository: GameRepository = .standard, seed: @escaping () -> UInt64 = { .random(in: .min ... .max) }) {
        self.repository = repository
        seedErzeuger = seed
        let stand = repository.laden()
        zustand = stand?.zustand
        dauerSekunden = stand?.dauerSekunden ?? 0
    }

    var hatSpielstand: Bool { zustand != nil }

    #if DEBUG
    /// Sheet, das ein Demo-Szenario auf dem Startbildschirm öffnet.
    var demoSheet: String?

    /// Nur für Demo-Szenarien (`-demo`): Zustand und Bildschirm direkt setzen.
    func demoSetzen(_ z: Spielzustand?, screen: Screen) {
        rueckgaengig = []
        zustand = z
        self.screen = screen
    }
    #endif

    // MARK: Partie

    func neuePartie(spieler: [Spieler], optionen: Optionen, beginner: Int? = nil, serie: Serie? = nil) {
        rueckgaengig = []
        letzteBewegung = nil
        zustand = Spielzustand(spieler: spieler, optionen: optionen, seed: seedErzeuger(), beginner: beginner, serie: serie)
        partieID = UUID()
        letzteAktion = Date()
        dauerSekunden = 0
        screen = .game
        speichern()
    }

    /// Gleiche Spieler und Regeln noch einmal. Es fängt reihum der Nächste an.
    /// Läuft eine Serie, die noch nicht entschieden ist, ist das die nächste Partie der Serie; sonst beginnt (bei einer Serie) eine neue.
    func revanche() {
        guard let z = zustand else { return }
        let vorher = z.partie.verlauf.first?.spieler ?? z.amZug
        var neu: Serie?
        if var s = z.serie {
            if s.entschieden {
                neu = Serie(ziel: s.ziel, spieler: z.spieler.count)
            } else {
                s.partie += 1
                s.verbucht = false
                neu = s
            }
        }
        neuePartie(spieler: z.spieler, optionen: z.optionen, beginner: (vorher + 1) % z.spieler.count, serie: neu)
    }

    /// Verbucht eine beendete Partie einmal in der Statistik.
    func statistikErfassen(in stats: StatsStore) {
        guard var z = zustand, z.phase == .vorbei, !z.statistikErfasst else { return }
        // Erst merken, dass gezählt wird, dann zählen: Stirbt die App dazwischen, geht höchstens eine Partie verloren,
        // sie wird aber nie doppelt gezählt.
        let beendet = z
        z.statistikErfasst = true
        zustand = z
        speichern()
        stats.erfasse(beendet, dauerSekunden: dauerSekunden)
    }

    /// Zum Start, ohne die Partie zu verwerfen (E6: Home fragt nicht nach, die Partie bleibt gespeichert).
    func zumStart() { screen = .home }

    func beenden() {
        screen = .home
        zustand = nil
        partieID = UUID()
        rueckgaengig = []
        repository.loeschen()
    }

    // MARK: Aktionen des Menschen

    func wuerfeln() {
        guard let z = zustand, z.phase == .vorWurf, !z.aktuellerSpieler.wuerfeltEcht else { return }
        merkeFuerRueckgaengig(z)
        aendern { $0.wuerfeln() }
    }

    /// Echter Würfel: Die Zahl wird eingetippt und gilt sofort. „Ändern“ ist ein Rückgängig bis vor diese Eingabe.
    func eintippen(_ augen: Int) {
        guard let z = zustand, z.erwartetEingabe, (1 ... 6).contains(augen) else { return }
        merkeFuerRueckgaengig(z)
        aendern { $0.eintippen(augen) }
    }

    @discardableResult
    func ziehe(_ zug: Zug) -> Bewegung? {
        guard let z = zustand, z.phase == .wahl, z.partie.spielzug.erlaubt.contains(zug) else { return nil }
        merkeFuerRueckgaengig(z)
        return fuehreAus(zug)
    }

    /// Ein verfallener Wurf ist quittiert (Mensch oder Computer).
    func verfallenWeiter() {
        aendern { $0.verfallenWeiter() }
    }

    /// Der Computer zieht (keine Kopie für „Rückgängig“).
    @discardableResult
    func computerZug(_ zug: Zug) -> Bewegung? {
        guard let z = zustand, z.phase == .computer, z.partie.spielzug.stand == .wahl else { return nil }
        return fuehreAus(zug)
    }

    // MARK: Rückgängig

    var kannZuruecknehmen: Bool {
        guard let z = zustand else { return false }
        return !rueckgaengig.isEmpty && z.phase != .computer && z.phase != .vorbei
    }

    /// Stellt den Zustand vor der letzten Entscheidung eines Menschen wieder her (samt Würfelquelle,
    /// deshalb kommt dieselbe Augenzahl wieder). Alles danach, auch Züge der Computer, ist weg.
    func zuruecknehmen() {
        guard kannZuruecknehmen, let alt = rueckgaengig.popLast() else { return }
        zustand = alt
        letzteBewegung = nil
        speichern()
    }

    private func merkeFuerRueckgaengig(_ z: Spielzustand) {
        rueckgaengig.append(z)
        if rueckgaengig.count > Self.maxRueckgaengig { rueckgaengig.removeFirst(rueckgaengig.count - Self.maxRueckgaengig) }
    }

    // MARK: Computer

    /// Ein Schritt des Computers: würfeln, Zug wählen oder verfallenen Wurf quittieren. Die Berechnung der
    /// Wahl läuft außerhalb des Main-Actors.
    func computerSchritt() async {
        guard let z = zustand, z.phase == .computer else { return }
        switch z.partie.spielzug.stand {
        case .vorWurf: aendern { $0.wuerfeln() }
        case .verfallen: aendern { $0.verfallenWeiter() }
        case .wahl:
            let lage = z.lage, p = z.amZug, strategie = z.aktuellerSpieler.strategie, erlaubt = z.partie.spielzug.erlaubt, menschen = z.menschen
            let wahl = await Task.detached(priority: .userInitiated) {
                Computer.entscheide(strategie, lage, p, erlaubt, menschen: menschen)
            }.value
            guard zustand == z else { return }          // währenddessen zurückgenommen oder beendet
            fuehreAus(wahl)
        case .ende: break
        }
    }

    // MARK: intern

    @discardableResult
    private func fuehreAus(_ zug: Zug) -> Bewegung? {
        var b: Bewegung?
        aendern { b = $0.waehle(zug) }
        if let b { letzteBewegung = b; bewegungsZaehler += 1 }
        return b
    }

    private func aendern(_ aktion: (inout Spielzustand) -> Void) {
        guard var z = zustand else { return }
        aktion(&z)
        z.serieVerbuchen()
        // Spielzeit: Abstand zur letzten Aktion, Pausen über 2 Minuten zählen nicht
        let jetzt = Date()
        if let l = letzteAktion, z.phase != .vorbei || !z.statistikErfasst {
            let d = jetzt.timeIntervalSince(l)
            if d > 0 && d <= 120 { dauerSekunden += d }
        }
        letzteAktion = jetzt
        zustand = z
        speichern()
    }

    private func speichern() {
        guard let zustand else { return }
        do {
            try repository.speichern(Spielstand(zustand: zustand, dauerSekunden: dauerSekunden))
            speicherFehler = nil
        } catch {
            speicherFehler = error.localizedDescription
        }
    }
}
