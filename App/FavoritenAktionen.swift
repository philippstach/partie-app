// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import UIKit
import SwiftUI
import SpieleKern

/// Favoriten auf dem Home-Bildschirm: Langes Drücken auf das App-Symbol zeigt die Lieblingsspiele als Schnellaktionen.
enum FavoritenAktionen {
    /// Schnellaktionen zeigen im Kinder-Modus keine gesperrten Spiele.
    static func erlaubteIDs(_ ids: [String], kinder: Bool = Modi.kinder, gesperrt: Set<String> = Modi.gesperrt) -> [String] {
        ids.filter { Modi.erlaubt($0, kinder: kinder, gesperrt: gesperrt) }
    }

    @MainActor
    static func aktualisieren(_ ids: [String]) {
        UIApplication.shared.shortcutItems = erlaubteIDs(ids).prefix(4).compactMap { id in
            SpielKatalog.modul(id).map { m in
                UIApplicationShortcutItem(type: "partie.spiel", localizedTitle: m.name, localizedSubtitle: nil,
                                          icon: UIApplicationShortcutIcon(systemImageName: m.symbol), userInfo: ["id": id as NSString])
            }
        }
    }
}

extension Notification.Name { static let partieOeffneSpiel = Notification.Name("partie.oeffneSpiel") }

/// Übergabe eines Schnellaktions-Starts an die SwiftUI-Ansicht (auch beim Kaltstart, bevor sie zuhört).
@MainActor
enum AktionsPost {
    static var offen: String?
    /// Öffnet ein Spiel (Siri, Kurzbefehle, Spotlight): merkt die ID für den Kaltstart und benachrichtigt die laufende Ansicht.
    static func oeffnen(_ id: String) {
        offen = id
        NotificationCenter.default.post(name: .partieOeffneSpiel, object: id)
    }
    static func melden(_ item: UIApplicationShortcutItem) -> Bool {
        guard item.type == "partie.spiel", let id = item.userInfo?["id"] as? String else { return false }
        offen = id
        NotificationCenter.default.post(name: .partieOeffneSpiel, object: id)
        return true
    }
}

final class PartieSzenenDelegate: NSObject, UIWindowSceneDelegate {
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let item = connectionOptions.shortcutItem { MainActor.assumeIsolated { _ = AktionsPost.melden(item) } }
    }

    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        completionHandler(MainActor.assumeIsolated { AktionsPost.melden(shortcutItem) })
    }
}
