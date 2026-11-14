// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import WidgetKit
import SwiftUI
import AppIntents
import KlarGlas

// E6: Steuerelemente für Kontrollzentrum, Sperrbildschirm und Aktionsknopf (iOS 18). Sie öffnen die App über partie://-Adressen:
//   partie://zufall         zufällig gewähltes Spiel
//   partie://letztes        zuletzt gespieltes Spiel (Name steht im Steuerelement, gelesen aus der App Group)
//   partie://tagesraetsel   erstes noch offenes Tagesrätsel
// Die App behandelt die Adressen in `WurzelAnsicht.onOpenURL`.

/// Wert eines Steuerelements, der aus der App Group gelesen wird.
@available(iOS 18.0, *)
struct WeiterWert {
    let name: String?
}

@available(iOS 18.0, *)
struct WeiterWertQuelle: ControlValueProvider {
    var previewValue: WeiterWert { WeiterWert(name: "Sudoku") }
    func currentValue() async throws -> WeiterWert { WeiterWert(name: PartieGeteilt.zuletzt()?.name) }
}

@available(iOS 18.0, *)
struct TagesWert {
    let offen: Int
}

@available(iOS 18.0, *)
struct TagesWertQuelle: ControlValueProvider {
    var previewValue: TagesWert { TagesWert(offen: 3) }
    func currentValue() async throws -> TagesWert {
        let heute = Tagesschluessel.text(.now)
        let offen = TagesSpielInfo.alle.filter { PartieGeteilt.tag(praefix: $0.praefix).letzterTag != heute }.count
        return TagesWert(offen: offen)
    }
}

@available(iOS 18.0, *)
struct ZufallsSteuerung: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "de.philippstach.partie.steuerung.zufall") {
            ControlWidgetButton(action: OpenURLIntent(URL(string: "partie://zufall")!)) {
                Label("Zufälliges Spiel", systemImage: "dice")
            }
        }
        .displayName("Zufälliges Spiel")
        .description("Öffnet ein zufällig gewähltes Spiel.")
    }
}

@available(iOS 18.0, *)
struct WeiterSteuerung: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "de.philippstach.partie.steuerung.weiter", provider: WeiterWertQuelle()) { wert in
            ControlWidgetButton(action: OpenURLIntent(URL(string: "partie://letztes")!)) {
                if let name = wert.name {
                    Label("Weiter: \(name)", systemImage: "play.circle")
                } else {
                    Label("Weiterspielen", systemImage: "play.circle")
                }
            }
        }
        .displayName("Weiterspielen")
        .description("Öffnet das Spiel, das du zuletzt gespielt hast.")
    }
}

@available(iOS 18.0, *)
struct TagesraetselSteuerung: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "de.philippstach.partie.steuerung.tagesraetsel", provider: TagesWertQuelle()) { wert in
            ControlWidgetButton(action: OpenURLIntent(URL(string: "partie://tagesraetsel")!)) {
                if wert.offen > 0 {
                    Label("Tagesrätsel: \(wert.offen) offen", systemImage: "calendar.badge.clock")
                } else {
                    Label("Tagesrätsel geschafft", systemImage: "calendar.badge.checkmark")
                }
            }
        }
        .displayName("Tagesrätsel")
        .description("Öffnet das nächste offene Tagesrätsel.")
    }
}
