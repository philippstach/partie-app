// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import LocalAuthentication
import SpieleKern

/// Schutz des Kinder-Modus: Ausschalten und Ändern der Spiele-Auswahl verlangt Face ID, Touch ID oder den Gerätecode.
/// Ohne eingerichteten Gerätecode gibt es keinen Schutz (iOS bietet dann nichts an, das man prüfen könnte).
enum KinderSchutz {
    /// Kann dieses Gerät die Person überhaupt prüfen?
    static var moeglich: Bool {
        var fehler: NSError?
        return LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: &fehler)
    }

    /// `true`, wenn die Person sich ausgewiesen hat (oder das Gerät keine Prüfung kennt).
    @MainActor
    static func freigeben(grund: String) async -> Bool {
        #if targetEnvironment(simulator)
        return true  // Der Simulator hat keinen echten Gerätecode; sonst bliebe man ohne Ausweg in der Abfrage.
        #else
        guard moeglich else { return true }
        return (try? await LAContext().evaluatePolicy(.deviceOwnerAuthentication, localizedReason: grund)) ?? false
        #endif
    }
}

/// Schließen-Knopf der Blätter der Hülle: schlichtes Symbol, den Rahmen zeichnet die Symbolleiste (iOS 26) – kein doppelter Rahmen.
struct SchliessenKnopf: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        Button { dismiss() } label: { Image(systemName: "xmark") }
            .accessibilityLabel(Text("Schließen"))
    }
}

/// Entwicklermodus: schaltet man durch siebenmaliges Tippen auf die Versionszeile frei.
enum Entwickler {
    static let key = "entwicklerModus"
    static var an: Bool { UserDefaults.standard.bool(forKey: key) }

    /// Setzt Partie zurück wie nach der Installation (Statistik, Spieler, Favoriten, Einstellungen, Spielstände, App-Symbol).
    @MainActor
    static func alleDatenLoeschen(statistik: StatistikDienst, spieler: SpielerVerzeichnis, favoriten: Favoriten, icloud: IcloudVerwalter) {
        statistik.zuruecksetzen()
        for s in spieler.alle { spieler.loeschen(s.id) }
        favoriten.zuruecksetzen()
        icloud.zuruecksetzen()
        AllesLoeschen.aufraeumen()
        UIApplication.shared.setAlternateIconName(nil)
    }
}
