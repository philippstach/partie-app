// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
#if canImport(UIKit)
import SwiftUI
import KlarGlas
#endif

/// 1.0 (M7): „Wer beginnt“ für Zweier-Spiele. Gewählt im Neues-Spiel-Blatt (`WerBeginntKarte`), gemerkt je Spiel.
/// „Abwechselnd“: die Revanche beginnt der andere (Seitenwechsel). Spieler 1 = erster Eintrag (bzw. Mensch), 2 = zweiter (bzw. Computer).
public enum StartSpieler: String, CaseIterable, Sendable {
    case abwechselnd, erster, zweiter

    static func wahlSchluessel(_ spiel: String) -> String { "partie.beginnt.\(spiel)" }
    static func letzterSchluessel(_ spiel: String) -> String { "partie.beginnt.letzter.\(spiel)" }

    /// Gemerkte Wahl (Standard: erster, also wie bisher).
    public static func wahl(_ spiel: String) -> StartSpieler {
        StartSpieler(rawValue: UserDefaults.standard.string(forKey: wahlSchluessel(spiel)) ?? "") ?? .erster
    }

    /// Wer zuletzt begonnen hat (1 oder 2), falls bekannt.
    public static func letzter(_ spiel: String) -> Int? {
        let w = UserDefaults.standard.integer(forKey: letzterSchluessel(spiel))
        return w == 1 || w == 2 ? w : nil
    }

    /// Wer die nächste neue Partie beginnt (1 oder 2). Ohne Nebenwirkung; gemerkt wird erst mit `merke`.
    public static func naechster(_ spiel: String) -> Int {
        switch wahl(spiel) {
        case .erster: return 1
        case .zweiter: return 2
        case .abwechselnd: return letzter(spiel) == 1 ? 2 : 1
        }
    }

    /// Merkt, wer die laufende Partie begonnen hat (beim Start und beim Fortsetzen aufrufen).
    public static func merke(_ beginner: Int, spiel: String) {
        UserDefaults.standard.set(beginner, forKey: letzterSchluessel(spiel))
    }
}

#if canImport(UIKit)
/// Karte „Wer beginnt“ für das Neues-Spiel-Blatt: Abwechselnd, erster Spieler, zweiter Spieler.
public struct WerBeginntKarte: View {
    let spiel: String
    let eintraege: [SpielerEintrag]
    @AppStorage private var wahlRaw: String

    public init(spiel: String, eintraege: [SpielerEintrag]) {
        self.spiel = spiel; self.eintraege = eintraege
        _wahlRaw = AppStorage(wrappedValue: StartSpieler.erster.rawValue, StartSpieler.wahlSchluessel(spiel))
    }

    private var mitComputer: Bool { eintraege.contains { $0.art == "computer" } }
    private func name(_ i: Int, ersatz: String) -> String {
        guard eintraege.indices.contains(i) else { return ersatz }
        let n = eintraege[i].name.trimmingCharacters(in: .whitespaces)
        return n.isEmpty ? ersatz : n
    }
    private var erster: String { mitComputer ? String(localized: "Ich") : name(0, ersatz: String(localized: "Spieler 1")) }
    private var zweiter: String { mitComputer ? String(localized: "Computer") : name(1, ersatz: String(localized: "Spieler 2")) }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Wer beginnt", systemImage: "flag").font(.headline).foregroundStyle(Color.accentText)
            Picker("Wer beginnt", selection: $wahlRaw) {
                Text("Abwechselnd").tag(StartSpieler.abwechselnd.rawValue)
                Text(verbatim: erster).tag(StartSpieler.erster.rawValue)
                Text(verbatim: zweiter).tag(StartSpieler.zweiter.rawValue)
            }
            .pickerStyle(.segmented).labelsHidden()
            if wahlRaw == StartSpieler.abwechselnd.rawValue {
                Text("In der Revanche beginnt der andere.").font(.footnote).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading).card()
    }
}
#endif
