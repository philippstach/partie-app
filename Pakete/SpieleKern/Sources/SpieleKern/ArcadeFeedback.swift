// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import UIKit
import AudioToolbox
import ArcadeKern

/// Spielt die Rückmeldung, die `ArcadeRueckmeldung` (ArcadeKern) festgelegt hat: Haptik und kurze Systemtöne.
/// Beides hängt an den Schaltern in den Einstellungen (`SpieleHaptik`, `SpieleTon`).
@MainActor
enum ArcadeFeedback {
    static func abspielen(_ a: ArcadeAusgabe) {
        switch a.haptik {
        case .leicht?: UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.7)
        case .mittel?: UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: 0.9)
        case .erfolg?: UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .fehler?: UINotificationFeedbackGenerator().notificationOccurred(.error)
        case nil: break
        }
        switch a.ton {
        case .tick?: AudioServicesPlaySystemSound(1104)       // kurzer Tick
        case .aus?: AudioServicesPlaySystemSound(1053)        // tiefer, kurzer Ton
        case .fanfare?: AudioServicesPlaySystemSound(1025)    // aufsteigender Ton
        case nil: break
        }
    }
}
#endif
