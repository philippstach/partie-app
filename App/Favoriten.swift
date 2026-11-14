// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Observation

/// Favoriten der Sammlung (Spiel-IDs), lokal gespeichert.
@Observable @MainActor
final class Favoriten {
    static let schluessel = "partie.favoriten"
    private(set) var ids: [String]
    @ObservationIgnored private var beobachter: NSObjectProtocol?

    /// Funde 134/146: Dieselbe Liste wie die Reihe der Startseite (`StartLayout`). Gibt es noch keine Favoriten, wohl aber ein gespeichertes Layout
    /// (frühere Version), gilt das Layout.
    init() {
        ids = UserDefaults.standard.stringArray(forKey: Self.schluessel) ?? StartLayout.gespeichert() ?? []
        beobachter = NotificationCenter.default.addObserver(forName: .partieFavoritenGeaendert, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.neuLaden() }
        }
    }
    deinit { if let beobachter { NotificationCenter.default.removeObserver(beobachter) } }

    private func neuLaden() { ids = UserDefaults.standard.stringArray(forKey: Self.schluessel) ?? [] }

    func enthaelt(_ id: String) -> Bool { ids.contains(id) }

    /// C-002: Leert die Favoriten im Speicher und auf dem Gerät (Schnellaktionen am App-Symbol inklusive).
    func zuruecksetzen() {
        ids = []
        UserDefaults.standard.removeObject(forKey: Self.schluessel)
        UserDefaults.standard.removeObject(forKey: "startLayout")   // eine Liste: auch die Reihe der Startseite beginnt wieder bei der Vorgabe
        NotificationCenter.default.post(name: .partieStartLayoutGeaendert, object: nil)
        FavoritenAktionen.aktualisieren([])
    }

    func umschalten(_ id: String) {
        if let i = ids.firstIndex(of: id) { ids.remove(at: i) } else { ids.append(id) }
        UserDefaults.standard.set(ids, forKey: Self.schluessel)
        UserDefaults.standard.set(ids.joined(separator: ","), forKey: "startLayout")   // dieselbe Liste für die Reihe der Startseite
        NotificationCenter.default.post(name: .partieStartLayoutGeaendert, object: nil)
        FavoritenAktionen.aktualisieren(ids)
    }
}
