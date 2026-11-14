// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation
import Observation

/// Führt Aktionen auf dem Spielzustand aus und speichert nach jeder Aktion.
@MainActor
@Observable
final class GameStore {
    private(set) var zustand: Spielzustand?
    private(set) var quelle: SeedQuelle
    var speicherFehler: String?
    /// Nur „Schocken“: Stufe des Computers. Bei „mittel“ patzt er ab und zu (die einfache Strategie rechnet).
    var neuStufe: ComputerStufe?

    private let repository: GameRepository

    init(repository: GameRepository = .standard, seed: UInt64 = .random(in: .min ... .max)) {
        self.repository = repository
        let stand = repository.laden()
        zustand = stand?.zustand
        quelle = stand?.quelle ?? SeedQuelle(seed: seed)
    }

    var hatSpielstand: Bool { zustand != nil }

    func neuePartie(namen: [String], strategien: [Strategie], avatare: [String]? = nil, optionen: Optionen,
                    beginner: Int? = nil, gefuehrt: Bool = false,
                    wuerfelModus: [WuerfelModus]? = nil, schnelleingabe: Bool = true) {
        let beginner = beginner ?? quelle.naechster(unter: namen.count)
        var z = Spielzustand(namen: namen, strategien: strategien, avatare: avatare, optionen: optionen, beginner: beginner,
                             wuerfelModus: wuerfelModus, schnelleingabe: schnelleingabe)
        z.gefuehrt = gefuehrt
        zustand = z
        speichern()
    }

    /// Geführte erste Partie: Mensch („Du“) gegen Computer gut und einfach, Mensch ist Vorleger, nur eine Hälfte,
    /// die ersten drei Würfe sind fest 6-6-1 (SPEZIFIKATION 13.5).
    func gefuehrtePartie(du: String) {
        quelle.vorgabe = Hinweise.gefuehrtStart
        neuePartie(namen: [du, "Ben", "Clara"], strategien: [.mensch, .gut, .einfach],
                   optionen: Optionen(spiellaenge: .haelfte), beginner: 0, gefuehrt: true)
    }

    /// „Schocken“: verbucht eine beendete Partie einmal im Abend (die Statistik führt der SpielRahmen).
    func abendErfassen(in abend: AbendStore) {
        guard var z = zustand, z.phase == .partieVorbei, !z.statistikErfasst else { return }
        abend.erfasse(z)
        z.statistikErfasst = true
        zustand = z
        speichern()
    }

    /// „Schocken“: Hausregeln ändern, solange noch kein Wurf gefallen ist. Baut dieselbe Partie mit den neuen Regeln neu auf.
    @discardableResult
    func regelnVorStart(_ o: Optionen) -> Bool {
        guard let z = zustand, z.phase == .vorWurf || z.phase == .computer, z.runde.zuege.isEmpty, !z.zugLaeuft,
              z.haelfte.runden == 0, z.haelftenVerlierer.isEmpty else { return false }
        var neu = Spielzustand(namen: z.namen, strategien: z.strategien, avatare: z.avatare, optionen: o, beginner: z.runde.beginner,
                               wuerfelModus: z.wuerfelModus, schnelleingabe: z.schnelleingabe)
        neu.gefuehrt = z.gefuehrt
        zustand = neu
        speichern()
        return true
    }

    /// Ist die Partie noch unberührt (Hausregeln änderbar)?
    var vorErstemZug: Bool {
        guard let z = zustand else { return false }
        return (z.phase == .vorWurf || z.phase == .computer) && z.runde.zuege.isEmpty && !z.zugLaeuft
            && z.haelfte.runden == 0 && z.haelftenVerlierer.isEmpty
    }

    func beenden() {
        zustand = nil
        repository.loeschen()
    }

    func wuerfeln() { aendern { $0.wuerfeln(&quelle) } }

    @discardableResult
    func weiter(herauslegen: [Int], umdrehen: Int) -> Bool {
        var ok = false
        aendern { ok = $0.weiter(herauslegen: herauslegen, umdrehen: umdrehen, &quelle) }
        return ok
    }

    func stehen() { aendern { $0.stehen() } }
    func zugWeiter() { aendern { $0.zugWeiter() } }

    // MARK: Echte Würfel: Eingabe mit „Ändern“ (3 Sekunden)

    /// Zustand vor der letzten Eingabe; die Ansicht bietet 3 s lang „Ändern“ an.
    private(set) var vorEingabe: Spielzustand?

    func eingabeWuerfeln(_ werte: [Int]) {
        vorEingabe = zustand
        aendern(behalteEingabe: true) { $0.wuerfeln(eingabe: werte) }
    }

    @discardableResult
    func eingabeWeiter(herauslegen: [Int], umdrehen: Int, werte: [Int]) -> Bool {
        let davor = zustand
        var ok = false
        aendern(behalteEingabe: true) { ok = $0.weiter(herauslegen: herauslegen, umdrehen: umdrehen, eingabe: werte) }
        if ok { vorEingabe = davor }
        return ok
    }

    @discardableResult
    func eingabeEndergebnis(wuerfel: [Int], wuerfe: Int, ausEinemWurf: Bool) -> Bool {
        let davor = zustand
        var ok = false
        aendern(behalteEingabe: true) { ok = $0.endergebnis(wuerfel: wuerfel, wuerfe: wuerfe, ausEinemWurf: ausEinemWurf) }
        if ok { vorEingabe = davor }
        return ok
    }

    /// „Ändern“: die letzte Eingabe rückgängig machen (die Würfelquelle wurde nicht verbraucht).
    func eingabeAendern() {
        guard let alt = vorEingabe else { return }
        vorEingabe = nil
        zustand = alt
        speichern()
    }

    func eingabeAbschliessen() { vorEingabe = nil }
    func rundeWeiter() { aendern { $0.rundeWeiter() } }
    func haelfteWeiter() { aendern { $0.haelfteWeiter() } }

    /// Ein Schritt des Computers: erster Wurf oder eine Entscheidung. Die Rechnung läuft außerhalb des Main-Actors.
    func computerSchritt() async {
        guard let z = zustand, z.phase == .computer, let spieler = z.aktuellerSpieler else { return }
        guard let lage = z.lage else { wuerfeln(); return }
        let strategie = neuStufe.map { NeuLogik.strategie(stufe: $0, zufall: .random(in: 0..<1)) } ?? z.strategien[spieler]
        let aktion = await Task.detached(priority: .userInitiated) { Computer.entscheide(strategie, lage) }.value
        guard zustand == z else { return }
        // Sicherheitsnetz: Lehnt der Kern die Aktion ab, lässt der Computer stehen, damit die Partie nie hängen bleibt.
        aendern { if !$0.fuehreAus(aktion, &quelle) { _ = $0.fuehreAus(.stehen, &quelle) } }
    }

    private func aendern(behalteEingabe: Bool = false, _ aktion: (inout Spielzustand) -> Void) {
        if !behalteEingabe { vorEingabe = nil }
        guard var z = zustand else { return }
        aktion(&z)
        zustand = z
        speichern()
    }

    private func speichern() {
        guard let zustand else { return }
        do {
            try repository.speichern(Spielstand(zustand: zustand, quelle: quelle))
            speicherFehler = nil
        } catch {
            speicherFehler = error.localizedDescription
        }
    }
}
