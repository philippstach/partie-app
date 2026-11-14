// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// D3 „Rätsel per Link teilen“: Ein Link `partie://raetsel/<spiel>?schluessel=wert&…` trägt alles, was ein Spiel braucht,
/// um dasselbe Rätsel zu bauen (Seed, Stufe, Maße). Kein Netzwerk, kein Konto; der Link wird als Text über das Systemblatt geteilt.
public struct RaetselLink: Equatable, Sendable {
    public let spiel: String
    public let werte: [String: String]

    public init(spiel: String, werte: [String: String]) {
        self.spiel = spiel; self.werte = werte
    }

    public static let schema = "partie"
    public static let host = "raetsel"

    /// Der Link als Adresse; Werte sind sortiert, damit gleiche Rätsel gleiche Links ergeben.
    public var url: URL? {
        var c = URLComponents()
        c.scheme = Self.schema; c.host = Self.host; c.path = "/" + spiel
        c.queryItems = werte.sorted { $0.key < $1.key }.map { URLQueryItem(name: $0.key, value: $0.value) }
        return c.url
    }

    /// Liest einen Link; nil bei fremdem Schema, fremdem Host, leerem Spiel oder doppelten Schlüsseln.
    public init?(url: URL) {
        guard url.scheme == Self.schema, url.host == Self.host else { return nil }
        let teile = url.pathComponents.filter { $0 != "/" }
        guard teile.count == 1, let id = teile.first, !id.isEmpty else { return nil }
        var w: [String: String] = [:]
        for q in URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? [] {
            guard w[q.name] == nil, let v = q.value else { return nil }
            w[q.name] = v
        }
        self.init(spiel: id, werte: w)
    }

    public func zahl(_ schluessel: String) -> UInt64? { werte[schluessel].flatMap { UInt64($0) } }

    /// Text zum Teilen: Satz plus Link. `satz` ist schon lokalisiert (z. B. „Sudoku mittel: schaffst du das?“).
    public func teilenText(satz: String) -> String { url.map { "\(satz)\n\($0.absoluteString)" } ?? satz }
}

/// Übergabe eines geöffneten Links an das Spiel: die Hülle legt ihn ab und öffnet das Spiel, das Spiel holt ihn beim Erscheinen ab.
@MainActor
public enum RaetselPost {
    public private(set) static var offen: RaetselLink?
    private static var abgelegt = Date.distantPast
    /// So lange gilt ein abgelegter Link; danach ist er verfallen (sonst würde er einen späteren Spielstart kapern).
    public static let gueltig: TimeInterval = 600

    /// Legt den Link ab. Im Kindermodus wird er verworfen (false).
    @discardableResult
    public static func ablegen(_ l: RaetselLink, defaults: UserDefaults = .standard) -> Bool {
        guard TeilenFreigabe.erlaubt(defaults) else { offen = nil; return false }
        offen = l; abgelegt = Date(); return true
    }

    /// Nimmt den Link ab, wenn er für dieses Spiel bestimmt ist; sonst bleibt er liegen.
    public static func abholen(spiel: String, jetzt: Date = Date()) -> RaetselLink? {
        if jetzt.timeIntervalSince(abgelegt) > gueltig { offen = nil }
        guard let l = offen, l.spiel == spiel else { return nil }
        offen = nil
        return l
    }
}

#if canImport(UIKit)
import UIKit
public extension ErgebnisTeilen {
    /// Teilt reinen Text (z. B. Rätsel-Link) über das Systemblatt. Im Kindermodus tut es nichts.
    @MainActor static func zeigenText(_ text: String) {
        guard TeilenFreigabe.erlaubt() else { return }
        let szenen = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        guard let szene = szenen.first(where: { $0.activationState == .foregroundActive }) ?? szenen.first,
              var oben = szene.keyWindow?.rootViewController else { return }
        while let p = oben.presentedViewController { oben = p }
        let blatt = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let pop = blatt.popoverPresentationController {
            pop.sourceView = oben.view
            pop.sourceRect = CGRect(x: oben.view.bounds.midX, y: oben.view.bounds.midY, width: 0, height: 0)
            pop.permittedArrowDirections = []
        }
        oben.present(blatt, animated: true)
    }
}
#endif
