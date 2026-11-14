// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern
import UIKit

/// Drehen ist erlaubt, nur nicht mitten im Ziehen einer Karte: solange der Finger eine Karte hält, bleibt die Ausrichtung stehen,
/// nach dem Loslassen dreht sich der Tisch dann weich nach.
enum OrientationLock {
    /// Frei: iPhone ohne „Kopfüber“, iPad alle vier Ausrichtungen
    static var unlocked: UIInterfaceOrientationMask { UIDevice.current.userInterfaceIdiom == .pad ? .all : .allButUpsideDown }
    static var mask: UIInterfaceOrientationMask = OrientationLock.unlocked

    static func lock() {
        guard mask == unlocked else { return }
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        switch scene?.interfaceOrientation {
        case .landscapeLeft: mask = .landscapeLeft
        case .landscapeRight: mask = .landscapeRight
        case .portraitUpsideDown: mask = .portraitUpsideDown
        default: mask = .portrait
        }
    }

    static func unlock() {
        guard mask != unlocked else { return }
        mask = unlocked
        // Das System fragt die erlaubten Ausrichtungen neu ab und dreht, falls das Gerät inzwischen anders liegt
        // (ersetzt das veraltete `attemptRotationToDeviceOrientation`)
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        scene?.windows.forEach { $0.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations() }
    }
}

