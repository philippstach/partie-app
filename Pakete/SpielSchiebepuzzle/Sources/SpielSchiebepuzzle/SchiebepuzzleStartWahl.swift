// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern

/// Blatt 20 / AUS-016 (Tinte): Die Wahl vor dem Rätsel steht auf der Spielseite des Rahmens, wie bei Sudoku, Solitär und Kakuro.
/// „Spielen“ startet, was hier gewählt ist: Tagesrätsel oder ein neues Rätsel in einer Größe (3 × 3 bis 6 × 6).
/// `SchiebepuzzleSpiel` holt die Wahl beim Start ab. In Klar und Salon bleibt die Ansicht leer; dort liegen Größe und Tagesrätsel im Menü.
struct SchiebepuzzleStartWahl: View {
    /// "" = neues Rätsel, "tag" = Tagesrätsel
    static let schluessel = "schiebepuzzle.start"
    /// Gewählte Kantenlänge (3 bis 6); 0 = nichts gewählt (Vorgabe 4 wie bisher)
    static let groesseSchluessel = "schiebepuzzle.groesse"
    static let groessen = [3, 4, 5, 6]
    @AppStorage("schiebepuzzle.start") private var start = ""
    @AppStorage("schiebepuzzle.groesse") private var groesse = 0
    @Environment(\.designArt) private var art

    private var neuesRaetsel: Bool { start != "tag" }

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
                    Label("Neu mischen", systemImage: "shuffle").font(.headline).foregroundStyle(Color.schrift)
                    Spacer(minLength: 0)
                }
                .frame(minHeight: 44).contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(neuesRaetsel ? [.isButton, .isSelected] : .isButton)
            Picker("Größe", selection: Binding(get: { groesse == 0 ? 4 : groesse }, set: { groesse = $0; start = "" })) {
                ForEach(Self.groessen, id: \.self) { Text(verbatim: "\($0) × \($0)").tag($0) }
            }
            .pickerStyle(.segmented)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }
}
#endif
