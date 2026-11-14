// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// F7: Gemeinsamer Schalter „Schütteln zum Würfeln“ der Sammlung (Einstellungen › Würfel).
public enum SpieleSchuetteln {
    public static let schluessel = "schuettelnAn"
    public static var erlaubt: Bool { UserDefaults.standard.object(forKey: schluessel) as? Bool ?? true }
}

#if canImport(UIKit)
import SwiftUI

/// Erkennt das Schütteln des Geräts, solange die Ansicht, an der es hängt, im Bild ist.
struct SchuettelFlaeche: UIViewControllerRepresentable {
    let aktion: () -> Void

    final class Controller: UIViewController {
        var aktion: () -> Void = {}
        override var canBecomeFirstResponder: Bool { true }
        override func viewDidAppear(_ animated: Bool) { super.viewDidAppear(animated); becomeFirstResponder() }
        override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
            if motion == .motionShake { aktion() }
        }
    }

    func makeUIViewController(context: Context) -> Controller { let c = Controller(); c.aktion = aktion; return c }
    func updateUIViewController(_ c: Controller, context: Context) { c.aktion = aktion }
}

public extension View {
    /// Schütteln löst dieselbe Aktion aus wie der Würfeln-Knopf. An den Knopf hängen: er gilt nur, solange der Knopf zu sehen ist.
    /// Gilt nicht bei VoiceOver oder wenn die Einstellung „Schütteln zum Würfeln“ aus ist; `aktiv: false` sperrt es (z. B. bei echten Würfeln).
    func beimSchuetteln(aktiv: Bool = true, _ aktion: @escaping () -> Void) -> some View {
        background {
            if aktiv, SpieleSchuetteln.erlaubt, !UIAccessibility.isVoiceOverRunning { SchuettelFlaeche(aktion: aktion).frame(width: 0, height: 0) }
        }
    }
}
#endif
