// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import CoreMotion
import UIKit

extension Notification.Name {
    /// Das iPhone wurde geschüttelt (CoreMotion oder System-Schüttelgeste).
    static let schockenGeschuettelt = Notification.Name("schocken.geschuettelt")
}

/// Erkennt Schütteln über den Beschleunigungssensor (Schwelle ca. 2,2 g) und meldet es als Notification.
/// Die Entprellung (0,8 s) macht die Ansicht.
@MainActor
final class ShakeDetector {
    static let shared = ShakeDetector()
    private let manager = CMMotionManager()
    /// Wie viele Bildschirme gerade Schütteln wollen. Beim Wechsel zwischen zwei Bildschirmen kann „stop“ des alten
    /// nach „start“ des neuen kommen; ohne Zähler wäre das Schütteln dann aus.
    private var nutzer = 0

    func start() {
        nutzer += 1
        guard manager.isAccelerometerAvailable, !manager.isAccelerometerActive else { return }
        manager.accelerometerUpdateInterval = 1.0 / 30.0
        manager.startAccelerometerUpdates(to: .main) { daten, _ in
            guard let a = daten?.acceleration else { return }
            if (a.x * a.x + a.y * a.y + a.z * a.z).squareRoot() > 2.2 {
                NotificationCenter.default.post(name: .schockenGeschuettelt, object: nil)
            }
        }
    }

    func stop() {
        nutzer = max(0, nutzer - 1)
        guard nutzer == 0 else { return }
        manager.stopAccelerometerUpdates()
    }
}

extension UIWindow {
    /// Auch die System-Schüttelgeste zählt (im Simulator: Gerät → Schütteln).
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake { NotificationCenter.default.post(name: .schockenGeschuettelt, object: nil) }
        super.motionEnded(motion, with: event)
    }
}
