// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas

/// Anleitung zum Durchwischen für den `SpielRahmen`; die ausführlichen Regeln dahinter sind `RulesDetailView`.
@MainActor
enum WortpfeilAnleitung {
    private static func wort(_ buchstaben: [String], sichtbar: Int, markiert: Int? = nil) -> some View {
        HStack(spacing: 5) {
            ZStack {
                RoundedRectangle(cornerRadius: Design.Ecke.klein).fill(Color.kwAkzent.opacity(0.25)).frame(width: 58, height: 52)
                VStack(spacing: 0) {
                    Text("Gefrorenes Wasser").font(.system(size: 8, weight: .semibold)).multilineTextAlignment(.center) // design:spielinhalt
                    Image(systemName: "arrow.right").font(.system(size: 11, weight: .bold)) // design:spielinhalt
                }.foregroundStyle(Color.kwAkzent).padding(3)
            }
            ForEach(0..<buchstaben.count, id: \.self) { i in
                AnleitungKachel(i < sichtbar ? buchstaben[i] : "", groesse: 46, hervorgehoben: markiert == i)
            }
        }
    }

    static let schritte: [AnleitungSchritt] = [
        AnleitungSchritt.ziel("Fülle alle Felder mit den Lösungswörtern, die die Fragen in den Pfeilfeldern verlangen."),
        AnleitungSchritt(symbol: "arrow.right.square", titel: "Der Pfeil zeigt den Weg",
                         text: "Im Pfeilfeld steht die Frage, das Wort läuft in Pfeilrichtung. „Gefrorenes Wasser“ nach rechts ergibt EIS.",
                         geste: .keine) { p, _ in
            wort(["E", "I", "S"], sichtbar: Int(p * 4.2))
        },
        AnleitungSchritt(symbol: "hand.tap", titel: "Buchstaben eintragen",
                         text: "Tippe ein Feld an und schreibe den Buchstaben. Tippst du dasselbe Feld nochmal, wechselt die Richtung.",
                         geste: .tippen(UnitPoint(x: 0.55, y: 0.5))) { p, _ in
            wort(["E", "I", "S"], sichtbar: p > 0.6 ? 1 : 0, markiert: p < 0.6 ? 0 : nil)
        },
        AnleitungSchritt(symbol: "star", titel: "Hilfen und Stern",
                         text: "„Aufdecken“ und „Prüfen“ helfen dir weiter. Wer ganz ohne Hilfe löst, bekommt einen Stern.",
                         geste: .keine) { p, _ in
            Image(systemName: "star.fill").font(.system(.largeTitle).weight(.regular)).imageScale(.large).foregroundStyle(.yellow)
                .scaleEffect(0.8 + 0.25 * anleitungAbschnitt(p, von: 0.2, bis: 0.5))
                .rotationEffect(.degrees(12 * sin(p * .pi * 2)))
        },
    ]
}
#endif
