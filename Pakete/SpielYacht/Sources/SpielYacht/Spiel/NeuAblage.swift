// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern
import SpielHilfen

/// Eigene Ablage von „Yacht“: Spielstände, Rekorde und Einstellungen liegen unter eigener Speicherkennung,
/// Speicherkennung, bleibt für vorhandene Spielstände.
enum NeuAblage {
    static let id = "yacht-neu"
    static let suite = "de.philippstach.partie.yacht-neu"
    private static let regelnKey = "neu.regeln.v1"

    static var defaults: UserDefaults { UserDefaults(suiteName: suite) ?? .standard }

    static var ordner: URL {
        URL.applicationSupportDirectory.appending(path: "Games-yacht-neu", directoryHint: .isDirectory)
    }

    /// Merkzeichen im `SpielStand` des Rahmens: Eine Partie läuft, der Rahmen bietet „Partie fortsetzen“ an.
    struct Marker: Codable, Equatable { var spiel: UUID }

    /// Zuletzt gewählte Regeln (Vorgabe für die nächste Partie): Kniffel, wenn nichts gewählt wurde.
    static func regeln(_ d: UserDefaults = defaults) -> Rules {
        d.data(forKey: regelnKey).flatMap { try? JSONDecoder().decode(Rules.self, from: $0) } ?? Rules.fuer(.kniffel)
    }

    static func sichern(regeln: Rules, _ d: UserDefaults = defaults) {
        if let data = try? JSONEncoder().encode(regeln) { d.set(data, forKey: regelnKey) }
    }

    static func rekord(_ v: Variant, _ d: UserDefaults = defaults) -> Int? {
        d.object(forKey: NeuLogik.rekordSchluessel(v)) as? Int
    }

    static func rekordSichern(_ v: Variant, punkte: Int, _ d: UserDefaults = defaults) {
        if punkte > (rekord(v, d) ?? 0) { d.set(punkte, forKey: NeuLogik.rekordSchluessel(v)) }
    }

    static func neuerStore() -> GameStore {
        GameStore(repository: FileGameRepository(directory: ordner))
    }

    /// Setzt die laufende Partie fort oder startet eine neue aus den Teilnehmern des Rahmens.
    @MainActor static func starten(_ store: GameStore, teilnehmer: [SpielTeilnehmer], umgebung: SpielUmgebung) {
        let stufe = ComputerStufe.gespeichert(id)
        store.neuStufe = stufe
        // 1.0 (P5): „Spielen“ auf der Tageskarte der Startseite merkt die Würfelfolge von heute vor (einmalig, nur neue Partien)
        let tageswuerfel = Tagesraetsel.wunschAbholen(spiel: "yacht")
        if let m = SpielStand.laden(Marker.self, spiel: id), store.records.contains(where: { $0.id == m.spiel }) {
            store.resume(m.spiel)
            return
        }
        // Alles, was hier noch unfertig liegt, gehört zu einer verworfenen Partie
        for r in store.pausedGames { store.deleteGame(r.id) }
        // Tageswürfel: allein, mit den App-Würfeln (die Folge des Tages ist fest), für alle gleich
        let teilnehmer = tageswuerfel ? [teilnehmer.first { !$0.computer } ?? teilnehmer[0]] : teilnehmer
        let echt = !tageswuerfel && WuerfelWahl.quelle(id, vorgabe: umgebung.wuerfelQuelle) == .echt && !teilnehmer.contains { $0.computer }
        let spieler = teilnehmer.enumerated().map { i, t -> Player in
            let bekannt = umgebung.spieler.menschen.first { $0.name.caseInsensitiveCompare(t.name) == .orderedSame }
            // M-005: wie im Blatt „Neues Spiel“ das Zeichen der Person, sonst ihr Anfangsbuchstabe (vorher ein beliebiges Emoji)
            return Player(name: t.name, avatar: t.computer && !Design.ist(.tinte) ? "🤖" : Spieler.abzeichen(name: t.name, zeichen: t.computer ? nil : bekannt?.zeichen), colorIndex: i,   // Tinte: auch der Computer mit Buchstabe, wie die Spielerleiste
                          computer: t.computer ? NeuLogik.level(stufe) : nil)
        }
        store.startGame(players: spieler, settings: GameSettings(rules: regeln(), diceMode: echt ? .real : .digital, dailyKey: tageswuerfel ? DailyDice.todayKey() : nil))
        if let gid = store.game?.id { SpielStand.sichern(Marker(spiel: gid), spiel: id) }
    }
}
