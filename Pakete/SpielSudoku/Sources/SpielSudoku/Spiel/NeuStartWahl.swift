// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern
import SudokuKern

/// Design-Runde 3 (Tinte, R1): Die Wahl vor dem Rätsel steht auf der Spielseite des Rahmens statt auf einer eigenen Seite danach.
/// Der eine Knopf „Spielen“ der Spielseite startet, was hier gewählt ist: Tagesrätsel, Lernweg, eigenes Rätsel oder ein neues
/// Rätsel in Spielart und Stufe. Die Wahl merkt `start`; `NeuSpiel` holt sie beim Start ab. In den anderen Designs bleibt die Ansicht leer.
struct NeuStartWahl: View {
    /// Schlüssel der vorgemerkten Wahl: "" = neues Rätsel, "tag", "lernweg", "editor", "teilen".
    static let schluessel = "sudoku-neu.start"
    @AppStorage("sudoku-neu.start") private var start = ""
    @AppStorage("sudoku-neu.form") private var formRoh = SudokuForm.klassisch.rawValue
    @AppStorage("sudoku-neu.stufe") private var stufeRoh = SudokuStufe.leicht.rawValue
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.designArt) private var art
    @State private var tage = NeuAblage.geloesteTage()

    private var form: Binding<SudokuForm> { Binding(get: { SudokuForm(rawValue: formRoh) ?? .klassisch }, set: { formRoh = $0.rawValue }) }
    private var stufe: Binding<SudokuStufe> { Binding(get: { SudokuStufe(rawValue: stufeRoh) ?? .leicht }, set: { stufeRoh = $0.rawValue }) }
    private var heute: String { DailyPuzzle.key(for: .now) }
    private var stufen: [SudokuStufe] { form.wrappedValue == .klassisch ? [.leicht, .mittel, .schwer, .experte] : [.leicht, .mittel, .schwer] }
    private var neuesRaetsel: Bool { start == "" || start == "teilen" }

    var body: some View {
        if art == .tinte {
            VStack(alignment: .leading, spacing: Theme.kartenAbstand) {
                tagesZeile
                spielKarte
                wahlZeile("lernweg", symbol: "graduationcap", titel: "Lernweg", text: "Übe Schritt für Schritt die Tricks der Profis, von der einzigen Möglichkeit bis zum X-Wing.")
                wahlZeile("editor", symbol: "square.and.pencil", titel: "Eigenes Rätsel", text: "Tippe ein Rätsel aus Zeitung oder Buch ab. Die App prüft, ob es genau eine Lösung hat, und du spielst es mit Tipps und Notizen.")
            }
            .onAppear { start = ""; tage = NeuAblage.geloesteTage() }   // jede Spielseite beginnt mit „neues Rätsel“
        }
    }

    private func umschalten(_ kennung: String) { start = (start == kennung) ? "" : kennung }

    private func zeichen(_ gewaehlt: Bool) -> some View {
        Image(systemName: gewaehlt ? "checkmark.circle.fill" : "circle").font(.title2)
            .foregroundStyle(gewaehlt ? Color.schrift : Color.schriftZweit).accessibilityHidden(true)
    }

    private var tagesZeile: some View {
        let serie = DailyStreak.compute(solved: tage, today: heute)
        let gesehen = tage.contains(heute)
        return Button { umschalten("tag") } label: {
            HStack(spacing: Design.Abstand.m) {
                zeichen(start == "tag")
                VStack(alignment: .leading, spacing: 2) {
                    Label("Tagesrätsel", systemImage: "calendar").font(.headline).foregroundStyle(Color.schrift)
                    Text(verbatim: Date.now.formatted(date: .complete, time: .omitted)).font(.footnote).foregroundStyle(Color.schriftZweit)
                    if serie.length > 0 {
                        Text(serie.resting ? String(localized: "Serie: \(serie.length) Tage, heute ist noch Zeit") : String(localized: "Serie: \(serie.length) Tage"))
                            .font(.footnote.weight(.semibold)).foregroundStyle(Color.schriftZweit)
                    }
                }
                Spacer(minLength: 8)
                if gesehen { Image(systemName: "checkmark.seal.fill").foregroundStyle(Color.meldungGruen).accessibilityHidden(true) }
            }
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading).contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(start == "tag" ? [.isButton, .isSelected] : .isButton)
        .card()
    }

    private func wahlZeile(_ kennung: String, symbol: String, titel: LocalizedStringKey, text: LocalizedStringKey) -> some View {
        Button { umschalten(kennung) } label: {
            HStack(spacing: Design.Abstand.m) {
                zeichen(start == kennung)
                VStack(alignment: .leading, spacing: 2) {
                    Label(titel, systemImage: symbol).font(.headline).foregroundStyle(Color.schrift)
                    Text(text).font(.footnote).foregroundStyle(Color.schriftZweit).fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading).contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(start == kennung ? [.isButton, .isSelected] : .isButton)
        .card()
    }

    private var spielKarte: some View {
        VStack(alignment: .leading, spacing: Design.Abstand.m) {
            Button { start = "" } label: {
                HStack(spacing: Design.Abstand.m) {
                    zeichen(neuesRaetsel)
                    Label("Neues Rätsel", systemImage: "square.grid.3x3.fill").font(.headline).foregroundStyle(Color.schrift)
                    Spacer(minLength: 0)
                }
                .frame(minHeight: 44).contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(neuesRaetsel ? [.isButton, .isSelected] : .isButton)
            Group {
                if typeSize >= .xLarge {
                    Picker("Spielart", selection: form) {
                        ForEach(SudokuForm.allCases, id: \.self) { Text(verbatim: NeuBruecke.formName($0)).tag($0) }
                    }
                    .pickerStyle(.menu).frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Picker("Spielart", selection: form) {
                        ForEach(SudokuForm.allCases, id: \.self) { Text(verbatim: NeuBruecke.formName($0)).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .onChange(of: formRoh) { _, _ in
                start = start == "teilen" ? "teilen" : ""
                if form.wrappedValue != .klassisch && stufe.wrappedValue == .experte { stufe.wrappedValue = .schwer }
            }
            Text(verbatim: beschreibung).font(.footnote).foregroundStyle(Color.schriftZweit).fixedSize(horizontal: false, vertical: true)
            LeiterWahl(spiel: "sudoku", namen: stufen.map { LocalizedStringKey(NeuBruecke.stufeName($0)) }, stufe: Binding(
                get: { SudokuStufe.allCases.firstIndex(of: stufe.wrappedValue) ?? 0 },
                set: { stufe.wrappedValue = SudokuStufe.allCases[min(max($0, 0), SudokuStufe.allCases.count - 1)]; if start != "teilen" { start = "" } }))
            if form.wrappedValue == .klassisch {
                Text(verbatim: NeuBruecke.difficulty(stufe.wrappedValue).detail).font(.footnote).foregroundStyle(Color.schriftZweit)
            }
            if TeilenFreigabe.erlaubt() {
                Toggle(isOn: Binding(get: { start == "teilen" }, set: { start = $0 ? "teilen" : "" })) {
                    Label("Rätsel per Link teilen", systemImage: "link")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    private var beschreibung: String {
        switch form.wrappedValue {
        case .klassisch: String(localized: "Das bekannte Sudoku: Zahlen 1 bis 9 in einem 9 × 9-Gitter.")
        case .kinder: String(localized: "Kleineres Gitter mit 6 × 6 Feldern und den Zahlen 1 bis 6 – ideal für Kinder und zum Einstieg.")
        case .x: String(localized: "Wie das klassische Sudoku, aber auch die beiden Diagonalen enthalten jede Zahl von 1 bis 9 genau einmal.")
        }
    }
}
