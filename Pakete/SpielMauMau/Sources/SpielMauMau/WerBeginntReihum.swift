// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import SpieleKern
import KlarGlas

/// T-097: „Wer beginnt“ für Mau-Mau (zwei bis sechs Personen): „Reihum“ (jede neue Partie beginnt die nächste Person) oder eine feste Person.
/// Aufbau, Schrift und Abstände genau wie `WerBeginntKarte` aus SpieleKern (die gilt nur für zwei Personen); gleiche Speicherschlüssel.
enum MauMauBeginn {
    static let spiel = "maumau"
    private static var wahlKey: String { "partie.beginnt.\(spiel)" }
    private static var letzterKey: String { "partie.beginnt.letzter.\(spiel)" }

    /// Index (0-basiert) der Person, die die nächste Partie beginnt. Ohne Nebenwirkung.
    static func naechster(anzahl: Int) -> Int {
        guard anzahl > 0 else { return 0 }
        if let s = UserDefaults.standard.string(forKey: wahlKey), let i = Int(s) { return min(max(i, 0), anzahl - 1) }
        let letzter = UserDefaults.standard.integer(forKey: letzterKey)   // 0 = noch keiner, sonst Index + 1
        return letzter % anzahl
    }

    /// Wer die nächste Runde einer laufenden Partie beginnt: immer die Person nach dem letzten Beginner (reihum), unabhängig von der Wahl.
    static func rundeReihum(anzahl: Int) -> Int {
        guard anzahl > 0 else { return 0 }
        return UserDefaults.standard.integer(forKey: letzterKey) % anzahl
    }

    static func merke(_ index: Int) { UserDefaults.standard.set(index + 1, forKey: letzterKey) }
}

struct MauMauBeginnKarte: View {
    let eintraege: [SpielerEintrag]
    @AppStorage("partie.beginnt.maumau") private var wahl = "reihum"

    private func name(_ i: Int) -> String {
        let n = eintraege[i].name.trimmingCharacters(in: .whitespaces)
        return n.isEmpty ? String(localized: "Spieler \(i + 1)") : n
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Wer beginnt", systemImage: "flag").font(.headline).foregroundStyle(Color.accentText)
            Picker("Wer beginnt", selection: $wahl) {
                Text("Reihum").tag("reihum")
                ForEach(eintraege.indices, id: \.self) { i in Text(verbatim: name(i)).tag("\(i)") }
            }
            .pickerStyle(.segmented).labelsHidden()
            if wahl == "reihum" {
                Text("Bei jeder neuen Partie beginnt die nächste Person.").font(.footnote).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)   // Fund 42: nicht abschneiden
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading).card()
    }
}
