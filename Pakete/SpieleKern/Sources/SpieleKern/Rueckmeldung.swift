// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AVFoundation)
import AVFoundation
#endif
#if canImport(WidgetKit)
import WidgetKit
#endif

/// Haptik für alle Spiele (vorher je Spiel eine eigene Kopie `Haptics`). Jeder Aufruf beachtet den gemeinsamen Schalter der
/// Sammlung (`SpieleHaptik`, Einstellungen › Ton & Haptik). `enabled` ist nur für spielinterne Bedingungen da (z. B. „nur wenn ein
/// Mensch am Zug ist“), nicht für einen eigenen Schalter je Spiel.
public enum SpielHaptik {
    public static func tap(enabled: Bool = true, staerke: CGFloat = 1) { stoss(.light, staerke, enabled) }
    public static func medium(enabled: Bool = true) { stoss(.medium, 1, enabled) }
    public static func heavy(enabled: Bool = true) { stoss(.heavy, 1, enabled) }
    public static func soft(enabled: Bool = true, staerke: CGFloat = 1) { stoss(.soft, staerke, enabled) }
    public static func rigid(enabled: Bool = true, staerke: CGFloat = 1) { stoss(.rigid, staerke, enabled) }
    public static func select(enabled: Bool = true) { auswahl(enabled) }
    public static func selection(enabled: Bool = true) { auswahl(enabled) }
    public static func success(enabled: Bool = true) { meldung(.erfolg, enabled) }
    public static func warning(enabled: Bool = true) { meldung(.warnung, enabled) }
    public static func error(enabled: Bool = true) { meldung(.fehler, enabled) }

    public enum Stil { case light, medium, heavy, soft, rigid }
    public enum Meldung { case erfolg, warnung, fehler }

    /// Ein Stoß in der gewählten Stärke (0…1).
    public static func stoss(_ stil: Stil, _ staerke: CGFloat = 1, _ enabled: Bool = true) {
        guard enabled, SpieleHaptik.erlaubt else { return }
        #if canImport(UIKit) && !os(watchOS)
        let s: UIImpactFeedbackGenerator.FeedbackStyle = switch stil {
        case .light: .light
        case .medium: .medium
        case .heavy: .heavy
        case .soft: .soft
        case .rigid: .rigid
        }
        if staerke >= 1 { UIImpactFeedbackGenerator(style: s).impactOccurred() }
        else { UIImpactFeedbackGenerator(style: s).impactOccurred(intensity: staerke) }
        #endif
    }

    public static func auswahl(_ enabled: Bool = true) {
        guard enabled, SpieleHaptik.erlaubt else { return }
        #if canImport(UIKit) && !os(watchOS)
        UISelectionFeedbackGenerator().selectionChanged()
        #endif
    }

    public static func meldung(_ art: Meldung, _ enabled: Bool = true) {
        guard enabled, SpieleHaptik.erlaubt else { return }
        #if canImport(UIKit) && !os(watchOS)
        let t: UINotificationFeedbackGenerator.FeedbackType = switch art {
        case .erfolg: .success
        case .warnung: .warning
        case .fehler: .error
        }
        UINotificationFeedbackGenerator().notificationOccurred(t)
        #endif
    }
}

/// Kurze Soundeffekte aller Spiele (vorher je Spiel ein eigener Abspieler). Die Spiele behalten nur ihre
/// Tonliste; abgespielt wird `<datei>.m4a` aus dem App-Bundle. Beachtet den Spiel-Schalter und `SpieleTon`.
public enum SpielKlang {
    #if canImport(AVFoundation)
    nonisolated(unsafe) private static var abspieler: [String: AVAudioPlayer] = [:]
    #endif
    nonisolated(unsafe) private static var sitzungBereit = false

    /// Spielt `datei` (ohne Endung). `lautstaerke` 0…1, `rate` > 0 ändert die Tonhöhe über die Abspielgeschwindigkeit.
    public static func spielen(_ datei: String, enabled: Bool = true, lautstaerke: Float = 0.6, rate: Float? = nil) {
        guard enabled, SpieleTon.erlaubt else { return }
        #if canImport(AVFoundation)
        sitzungVorbereiten()
        if abspieler[datei] == nil, let url = Bundle.main.url(forResource: datei, withExtension: "m4a") {
            let p = try? AVAudioPlayer(contentsOf: url)
            p?.enableRate = true
            abspieler[datei] = p
        }
        guard let p = abspieler[datei] else { return }
        p.volume = lautstaerke
        p.rate = rate ?? 1
        p.currentTime = 0
        p.play()
        #endif
    }

    /// `.ambient` respektiert den Stumm-Schalter und unterbricht keine Musik.
    private static func sitzungVorbereiten() {
        guard !sitzungBereit else { return }
        sitzungBereit = true
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        #endif
    }
}

/// Tonliste eines Spiels: ein `enum … : String, SpielTon` mit den Tonnamen als Fälle. Abgespielt wird `<praefix>-<fall>.m4a`
/// aus dem App-Bundle; es gilt allein der gemeinsame Ton-Schalter der Sammlung (`SpieleTon`).
public protocol SpielTon: RawRepresentable where RawValue == String {
    /// Vorsatz der Tondateien des Spiels, z. B. „schocken“.
    static var praefix: String { get }
    /// Grundlautstärke 0…1 (Standard 0,6).
    static var lautstaerke: Float { get }
}

public extension SpielTon {
    static var lautstaerke: Float { 0.6 }
    func play() { SpielKlang.spielen(Self.praefix + "-" + rawValue, lautstaerke: Self.lautstaerke) }
}

/// Serie eines Tagesrätsels für das Widget (App-Gruppe, Schlüssel `<praefix>.serie` und `<praefix>.letzterTag` im Format jjjj-mm-tt).
/// Die Spiele rufen `melden` direkt mit ihrem Präfix auf.
public enum TagesSerieWidget {
    public static let gruppe = "group.de.philippstach.spiele"

    public static func melden(praefix: String, serie: Int, letzterTag: String?) {
        guard let defaults = UserDefaults(suiteName: gruppe) else { return }
        let letzter = letzterTag ?? ""
        guard defaults.integer(forKey: praefix + ".serie") != serie || defaults.string(forKey: praefix + ".letzterTag") != letzter else { return }
        defaults.set(serie, forKey: praefix + ".serie")
        defaults.set(letzter, forKey: praefix + ".letzterTag")
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
}
