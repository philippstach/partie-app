// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Observation
import SpieleKern

/// E7: Verbindet den Abgleich mit der App (Schalter, Auslöser, Status für die Anzeige). Aus ist die Voreinstellung; solange der
/// Nutzer nichts einschaltet, wird CloudKit nicht einmal angesprochen.
@Observable @MainActor
final class IcloudVerwalter {
    private(set) var status: AbgleichStatus = .aus
    private let dienst: AbgleichDienst
    private let spieler: SpielerVerzeichnis
    private let statistik: StatistikDienst
    private var wartend: Task<Void, Never>?

    init(spieler: SpielerVerzeichnis, statistik: StatistikDienst, speicher: AbgleichSpeicher = CloudKitSpeicher()) {
        self.spieler = spieler; self.statistik = statistik
        dienst = AbgleichDienst(speicher: speicher)
        status = dienst.aktiv ? dienst.status : .aus
        dienst.nachAenderung = { [weak self] in
            guard let self else { return }
            Task { @MainActor in self.status = self.dienst.status }
        }
    }

    var aktiv: Bool {
        get { _ = status; return dienst.aktiv }
        set { dienst.aktiv = newValue; status = dienst.status; if newValue { jetzt() } }
    }

    /// C-002: „Alle Daten löschen“ schaltet den Abgleich aus und entfernt die Sicherung dieses Geräts aus iCloud.
    func zuruecksetzen() { wartend?.cancel(); dienst.zuruecksetzen(); status = dienst.status }

    /// Sofort abgleichen (Schalter, Knopf, App wird aktiv).
    func jetzt() {
        guard dienst.aktiv else { return }
        Task { await dienst.abgleichen(spieler: spieler, statistik: statistik, foto: { SpielerBilder.daten($0) }); status = dienst.status }
    }

    /// Nach einer Änderung (z. B. beendete Partie) gesammelt abgleichen, nicht bei jedem Schreiben.
    func spaeter() {
        guard dienst.aktiv else { return }
        wartend?.cancel()
        wartend = Task { [weak self] in
            try? await Task.sleep(for: .seconds(20))
            guard !Task.isCancelled else { return }
            self?.jetzt()
        }
    }
}
