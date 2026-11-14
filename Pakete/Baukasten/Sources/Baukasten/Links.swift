// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Nur-lesen-Infos über die laufende App.
public enum AppInfo {
    public static var version: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0" }
    public static var build: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0" }
    public static var bundleID: String { Bundle.main.bundleIdentifier ?? "de.philippstach.unbekannt" }
}

/// Adressen der App-Webseite (CloudFront-Seite, erzeugt von tools/web/erzeuge_webseiten.py).
public struct AppLinks: Sendable {
    public static let basis = "https://d2mb1iyjufn965.cloudfront.net"
    public let key: String          // wie in erzeuge_webseiten.py, z. B. "yacht"
    public let appStoreID: String?  // erst eintragen, wenn die App live ist

    /// Voller Ordner der Seiten, falls sie nicht unter `<basis>/<key>/` liegen (z. B. 10k im Wurzelverzeichnis: `URL(string: Self.basis)`).
    public let seitenOrdner: URL

    public init(key: String, appStoreID: String? = nil, seitenOrdner: URL? = nil) {
        self.key = key; self.appStoreID = appStoreID
        self.seitenOrdner = seitenOrdner ?? URL(string: "\(Self.basis)/\(key)")!
    }

    public var startseite: URL { seite("index.html") }
    public var support: URL { seite("support.html") }
    public var datenschutz: URL { seite("datenschutz.html") }
    public var impressum: URL { seite("impressum.html") }
    private func seite(_ name: String) -> URL { seitenOrdner.appendingPathComponent(name) }

    /// Normaler Store-Link zum Teilen/Empfehlen.
    public var storeURL: URL? { appStoreID.flatMap { URL(string: "https://apps.apple.com/app/id\($0)") } }

    /// Öffnet direkt das Bewertungsfeld im App Store (Knopf in den Einstellungen; ersetzt keine Anfrage per System-Dialog).
    public var bewertenURL: URL? { appStoreID.flatMap { URL(string: "https://apps.apple.com/app/id\($0)?action=write-review") } }
}
