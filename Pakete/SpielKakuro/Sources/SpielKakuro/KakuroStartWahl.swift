// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern

/// T-038 (Tinte): Die Wahl vor dem Rätsel steht auf der Spielseite des Rahmens, wie bei Sudoku und Solitär. Dadurch bekommt die
/// Seite auf dem iPad die zweite Spalte. „Spielen“ startet, was hier gewählt ist: Tagesrätsel oder ein neues Rätsel in einer Größe.
/// `KakuroSpiel` holt die Wahl beim Start ab. In Klar und Salon bleibt die Ansicht leer; dort liegen Größe und Tagesrätsel wie bisher im Menü.
struct KakuroStartWahl: View {
    /// "" = neues Rätsel, "tag" = Tagesrätsel
    static let schluessel = "kakuro.start"
    /// Gewählte Größe als Stufe der Leiter (0 = 5 × 5, 1 = 6 × 6, 2 = 7 × 7); -1 = nichts gewählt (Vorgabe wie bisher)
    static let groesseSchluessel = "kakuro.groesse"
    @AppStorage("kakuro.start") private var start = ""
    @AppStorage("kakuro.groesse") private var groesse = -1
    @Environment(\.designArt) private var art

    private var neuesRaetsel: Bool { start != "tag" }
    private var vorgabeStufe: Int { Leiter.offen("kakuro", stufe: 1) ? 1 : 0 }

    var body: some View {
        if art == .tinte {
            VStack(alignment: .leading, spacing: Theme.kartenAbstand) {
                tagesZeile
                spielKarte
            }
            .onAppear { start = "" }   // jede Spielseite beginnt mit „neues Rätsel“
        }
    }

    private func zeichen(_ gewaehlt: Bool) -> some View {
        Image(systemName: gewaehlt ? "checkmark.circle.fill" : "circle").font(.title2)
            .foregroundStyle(gewaehlt ? Color.schrift : Color.schriftZweit).accessibilityHidden(true)
    }

    private var tagesZeile: some View {
        Button { start = (start == "tag") ? "" : "tag" } label: {
            HStack(spacing: Design.Abstand.m) {
                zeichen(start == "tag")
                VStack(alignment: .leading, spacing: 2) {
                    Label("Tagesrätsel", systemImage: "calendar").font(.headline).foregroundStyle(Color.schrift)
                    Text(verbatim: Date.now.formatted(date: .complete, time: .omitted)).font(.footnote).foregroundStyle(Color.schriftZweit)
                }
                Spacer(minLength: 8)
            }
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading).contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(start == "tag" ? [.isButton, .isSelected] : .isButton)
        .card()
    }

    private var spielKarte: some View {
        VStack(alignment: .leading, spacing: Design.Abstand.m) {
            Button { start = "" } label: {
                HStack(spacing: Design.Abstand.m) {
                    zeichen(neuesRaetsel)
                    Label("Neues Rätsel", systemImage: "plus.forwardslash.minus").font(.headline).foregroundStyle(Color.schrift)
                    Spacer(minLength: 0)
                }
                .frame(minHeight: 44).contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(neuesRaetsel ? [.isButton, .isSelected] : .isButton)
            LeiterWahl(spiel: "kakuro", namen: KakuroSpiel.groessen.map { LocalizedStringKey("\($0) × \($0)") }, stufe: Binding(
                get: { groesse >= 0 ? groesse : vorgabeStufe },
                set: { groesse = $0; start = "" }))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }
}
#endif
