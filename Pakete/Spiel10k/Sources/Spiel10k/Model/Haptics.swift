// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import UIKit
import SpieleKern

/// Haptik kommt aus dem Gemeinsamen Kern (`SpielHaptik`); hier nur die Zehntausend-eigenen Muster. Es gilt der Schalter der Sammlung.
extension SpielHaptik {
    static func celebrate() {
        guard SpieleHaptik.erlaubt else { return }   // C-047
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        let heavy = UIImpactFeedbackGenerator(style: .heavy)
        heavy.prepare()
        for (i, delay) in [0.18, 0.34, 0.56].enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                heavy.impactOccurred(intensity: [1.0, 0.8, 1.0][i])
            }
        }
    }

    /// Ein Würfel landet (leichter, weicher Stoß)
    static func land(intensity: CGFloat = 0.6) {
        guard SpieleHaptik.erlaubt else { return }   // C-047
        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: intensity)
    }

    /// Strafe nach 3 Nieten: drei mittelstarke Stöße im Takt des „Fail“-Tons, dann ein langer, schwacher Ausklang
    static func penalty(after delay: Double) {
        guard SpieleHaptik.erlaubt else { return }   // C-047
        let medium = UIImpactFeedbackGenerator(style: .medium)
        let soft = UIImpactFeedbackGenerator(style: .soft)
        medium.prepare()
        for step in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay + Double(step) * 0.17) {
                medium.impactOccurred(intensity: 0.7)
            }
        }
        for step in 0..<6 {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay + 0.51 + Double(step) * 0.1) {
                soft.impactOccurred(intensity: 0.45 - Double(step) * 0.06)
            }
        }
    }
}
