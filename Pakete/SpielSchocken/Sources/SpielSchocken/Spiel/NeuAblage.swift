// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

/// Eigene Ablage von „Schocken“: Spielstand, Abend und Einstellungen liegen unter eigener Speicherkennung,
/// Speicherkennung, bleibt für vorhandene Spielstände.
enum NeuAblage {
    static let id = "schocken-neu"
    static let suite = "de.philippstach.partie.schocken-neu"

    static var defaults: UserDefaults { UserDefaults(suiteName: suite) ?? .standard }

    static var ordner: URL {
        URL.applicationSupportDirectory.appending(path: "Games-schocken-neu", directoryHint: .isDirectory)
    }

    @MainActor static func neuerStore() -> GameStore {
        GameStore(repository: GameRepository(url: ordner.appending(path: "spielstand.json")))
    }

    /// Setzt eine laufende Partie fort oder startet eine neue aus den Teilnehmern des Rahmens.
    @MainActor static func starten(_ store: GameStore, teilnehmer: [SpielTeilnehmer], umgebung: SpielUmgebung, preferences: AppPreferences) {
        let stufe = ComputerStufe.gespeichert(id)
        store.neuStufe = stufe
        // „Partie fortsetzen“ im Rahmen: der Marker liegt im SpielStand, der Spielstand selbst im eigenen Store
        // C-036: auch eine beendete, noch nicht gemeldete Partie bleibt stehen (ein Neuaufbau des Rahmens startet keine Geisterpartie)
        if SpielStand.laden(Marker.self, spiel: id) != nil, store.zustand != nil { return }
        let echt = WuerfelWahl.quelle(id, vorgabe: umgebung.wuerfelQuelle) == .echt
        let namen = teilnehmer.map(\.name)
        let avatare = teilnehmer.enumerated().map { i, t -> String in
            let bekannt = umgebung.spieler.menschen.first { $0.name.caseInsensitiveCompare(t.name) == .orderedSame }
            // Tinte: wie die runde Spielerleiste der anderen Spiele – eigenes Zeichen der Person, sonst Anfangsbuchstabe (auch der Computer)
            if Design.ist(.tinte) { return Spieler.abzeichen(name: t.name, zeichen: t.computer ? nil : bekannt?.zeichen) }
            return t.computer ? "🤖" : (bekannt.map(\.avatar) ?? Avatare.standard(i))
        }
        // Mittel und schwer rechnen „gut“; bei mittel patzt der Store ab und zu (siehe `neuStufe`)
        let strategien = teilnehmer.map { $0.computer ? (stufe == .leicht ? Strategie.einfach : .gut) : .mensch }
        store.neuePartie(namen: namen, strategien: strategien, avatare: avatare, optionen: preferences.hausregeln,
                         wuerfelModus: teilnehmer.map { !$0.computer && echt ? .echt : .app },
                         schnelleingabe: !preferences.echtWurfFuerWurf)
        SpielStand.sichern(Marker(offen: true), spiel: id)
    }

    /// Merkzeichen im `SpielStand` des Rahmens: Es läuft eine Partie, der Rahmen bietet „Partie fortsetzen“ an.
    struct Marker: Codable, Equatable { var offen: Bool }
}
