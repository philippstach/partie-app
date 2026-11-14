// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import SpieleKern
import KlarGlas

/// Eigene Ablage von „10k“: Spielstände, Statistik und Einstellungen liegen unter eigener Speicherkennung,
/// Speicherkennung, bleibt für vorhandene Spielstände.
enum NeuAblage {
    static let id = "10k-neu"
    static let suite = "de.philippstach.partie.10k-neu"
    private static let regelnKey = "neu.regeln.v1"

    static var defaults: UserDefaults { UserDefaults(suiteName: suite) ?? .standard }

    static var ordner: URL {
        URL.applicationSupportDirectory.appending(path: "Games-10k-neu", directoryHint: .isDirectory)
    }

    /// Marker im `SpielStand` des Rahmens: welches Spiel des eigenen Stores gerade läuft.
    struct Marker: Codable, Equatable { var spiel: UUID }

    /// Zuletzt gewählte Regeln (Vorgabe für die nächste Partie).
    static func regeln(_ d: UserDefaults = defaults) -> GameRules {
        d.data(forKey: regelnKey).flatMap { try? JSONDecoder().decode(GameRules.self, from: $0) } ?? GameRules()
    }

    static func sichern(regeln: GameRules, _ d: UserDefaults = defaults) {
        var r = regeln
        r.diceMode = .digital   // der Würfelmodus kommt je Partie aus der Wahl des Rahmens
        if let data = try? JSONEncoder().encode(r) { d.set(data, forKey: regelnKey) }
    }

    @MainActor static func neuerStore() -> GameStore {
        GameStore(repository: FileGameRepository(directory: ordner), defaults: defaults)
    }

    /// Startet die Partie aus den Teilnehmern des Rahmens oder nimmt die gespeicherte wieder auf.
    @MainActor static func starten(_ store: GameStore, teilnehmer: [SpielTeilnehmer], umgebung: SpielUmgebung, preferences: AppPreferences) {
        if let m = SpielStand.laden(Marker.self, spiel: id),
           store.savedGames.contains(where: { $0.id == m.spiel }) {   // C-036: auch beendete, noch nicht gemeldete Partie weiterverwenden
            store.resume(m.spiel)
            return
        }
        // Alles, was hier noch unfertig liegt, gehört zu einer verworfenen Partie
        for r in store.pausedGames { store.deleteGame(r.id) }
        let spieler = spielerListe(teilnehmer, verzeichnis: umgebung.spieler)
        let quelle = WuerfelWahl.quelle(id, vorgabe: umgebung.wuerfelQuelle)
        var settings = GameSettings()
        settings.rules = regeln()
        // Computergegner würfeln nur mit App-Würfeln
        let echt = quelle == .echt && !spieler.contains { $0.isComputer }
        settings.diceMode = echt ? .real : .digital
        settings.realEntry = .points
        settings = preferences.applied(to: settings)
        store.startGame(players: spieler, settings: settings)
        if let gid = store.currentID { SpielStand.sichern(Marker(spiel: gid), spiel: id) }
    }

    @MainActor static func spielerListe(_ teilnehmer: [SpielTeilnehmer], verzeichnis: SpielerVerzeichnis) -> [Player] {
        let stufe: ComputerLevel = { switch ComputerStufe.gespeichert(id) { case .leicht: .einfach; case .mittel: .mittel; case .schwer: .gut } }()   // T-098: Mittel = Mischung
        return teilnehmer.enumerated().map { i, t in
            let bekannt = verzeichnis.menschen.first { $0.name.caseInsensitiveCompare(t.name) == .orderedSame }
            // M-005: wie im Blatt „Neues Spiel“ das Zeichen der Person, sonst ihr Anfangsbuchstabe (vorher ein beliebiges Emoji)
            var p = Player(name: t.name, avatar: t.computer && !Design.ist(.tinte) ? "🤖" : Spieler.abzeichen(name: t.name, zeichen: t.computer ? nil : bekannt?.zeichen), colorIndex: i)   // Tinte: auch der Computer mit Buchstabe, wie die Spielerleiste
            if t.computer { p.computer = stufe }
            return p
        }
    }
}
