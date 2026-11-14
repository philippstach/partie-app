// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern
import SudokuKern

/// Auswahl nach „Neues Spiel“ im Rahmen: Tagesrätsel mit Serie, Spielart und Stufe, Lernweg, eigenes Rätsel.
struct NeuWahl: View {
    @Binding var form: SudokuForm
    @Binding var stufe: SudokuStufe
    @Environment(\.dynamicTypeSize) private var typeSize
    let tage: Set<String>
    let abbrechen: () -> Void
    let starten: (SudokuStufe) -> Void
    let teilenStart: (SudokuStufe) -> Void
    let tagesraetsel: (String) -> Void
    let lernweg: () -> Void
    let editor: () -> Void

    private var heute: String { DailyPuzzle.key(for: .now) }
    private var stufen: [SudokuStufe] { form == .klassisch ? [.leicht, .mittel, .schwer, .experte] : [.leicht, .mittel, .schwer] }

    var body: some View {
        VStack(spacing: 0) {
            SpielKopf(mitte: String(localized: "Neues Rätsel"), linksAktion: abbrechen)
            ScrollView {
                VStack(spacing: Theme.kartenAbstand) {
                    tagesKarte
                    spielKarte
                    weitereKarte(symbol: "graduationcap", titel: "Lernweg", text: "Übe Schritt für Schritt die Tricks der Profis, von der einzigen Möglichkeit bis zum X-Wing.", knopf: "Techniken üben", aktion: lernweg)
                    weitereKarte(symbol: "square.and.pencil", titel: "Eigenes Rätsel", text: "Tippe ein Rätsel aus Zeitung oder Buch ab. Die App prüft, ob es genau eine Lösung hat, und du spielst es mit Tipps und Notizen.", knopf: "Rätsel eingeben", aktion: editor)
                }
                .padding(.horizontal, Theme.seitenRand).padding(.bottom, 24)
                .frame(maxWidth: Theme.wideColumnWidth).frame(maxWidth: .infinity)
            }
        }
        .background(Color.seitenGrund)
    }

    private var tagesKarte: some View {
        let serie = DailyStreak.compute(solved: tage, today: heute)
        let gesehen = tage.contains(heute)
        return VStack(alignment: .leading, spacing: 10) {
            Label("Tagesrätsel", systemImage: "calendar").font(.headline).foregroundStyle(Color.accentText)
            Text(verbatim: Date.now.formatted(date: .complete, time: .omitted)).font(.subheadline).foregroundStyle(.secondary)
            if serie.length > 0 {
                Label(serie.resting ? String(localized: "Serie: \(serie.length) Tage, heute ist noch Zeit") : String(localized: "Serie: \(serie.length) Tage"), systemImage: "flame")
                    .font(.subheadline.weight(.semibold))
            }
            Button { tagesraetsel(heute) } label: {
                Text(gesehen ? "Heute gelöst – noch einmal spielen" : "Heute spielen").frame(maxWidth: .infinity)
            }
            .buttonStyle(gesehen ? AnyButtonStyle(ZweitKnopfStil()) : AnyButtonStyle(HauptKnopfStil()))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    private var spielKarte: some View {
        VStack(alignment: .leading, spacing: Design.Abstand.m) {
            Label("Neues Rätsel", systemImage: "square.grid.3x3.fill").font(.headline).foregroundStyle(Color.accentText)
            // F-AWS-N-019: Segmente behalten bei großer Schrift ihre kleine Schrift – ab „xLarge“ ein Menü mit mitwachsendem Text.
            Group {
                if typeSize >= .xLarge {
                    Picker("Spielart", selection: $form) {
                        ForEach(SudokuForm.allCases, id: \.self) { Text(verbatim: NeuBruecke.formName($0)).tag($0) }
                    }
                    .pickerStyle(.menu).frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Picker("Spielart", selection: $form) {
                        ForEach(SudokuForm.allCases, id: \.self) { Text(verbatim: NeuBruecke.formName($0)).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .onChange(of: form) { _, f in if f != .klassisch && stufe == .experte { stufe = .schwer } }
            Text(verbatim: beschreibung).font(.footnote).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            LeiterWahl(spiel: "sudoku", namen: stufen.map { LocalizedStringKey(NeuBruecke.stufeName($0)) }, stufe: Binding(   // D4
                get: { SudokuStufe.allCases.firstIndex(of: stufe) ?? 0 },
                set: { stufe = SudokuStufe.allCases[min(max($0, 0), SudokuStufe.allCases.count - 1)] }))
            if form == .klassisch {
                Text(verbatim: NeuBruecke.difficulty(stufe).detail).font(.footnote).foregroundStyle(.secondary)
            }
            Button { starten(stufe) } label: { Text("Rätsel starten").frame(maxWidth: .infinity) }
                .buttonStyle(HauptKnopfStil())
                .accessibilityIdentifier("sudoku-neu-starten")
            if TeilenFreigabe.erlaubt() {
                Button { teilenStart(stufe) } label: {
                    Label("Rätsel per Link teilen", systemImage: "link").frame(maxWidth: .infinity)
                }
                .buttonStyle(ZweitKnopfStil())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    private var beschreibung: String {
        switch form {
        case .klassisch: String(localized: "Das bekannte Sudoku: Zahlen 1 bis 9 in einem 9 × 9-Gitter.")
        case .kinder: String(localized: "Kleineres Gitter mit 6 × 6 Feldern und den Zahlen 1 bis 6 – ideal für Kinder und zum Einstieg.")
        case .x: String(localized: "Wie das klassische Sudoku, aber auch die beiden Diagonalen enthalten jede Zahl einmal.")
        }
    }

    private func weitereKarte(symbol: String, titel: LocalizedStringKey, text: LocalizedStringKey, knopf: LocalizedStringKey, aktion: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(titel, systemImage: symbol).font(.headline).foregroundStyle(Color.accentText)
            Text(text).font(.subheadline).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            Button(action: aktion) { Text(knopf).frame(maxWidth: .infinity) }.buttonStyle(ZweitKnopfStil())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }
}

/// Löscht den Stiltyp, damit ein Knopf je nach Zustand zwei Stile haben kann
struct AnyButtonStyle: ButtonStyle {
    private let maker: @MainActor (Configuration) -> AnyView
    init<S: ButtonStyle>(_ style: S) { maker = { AnyView(style.makeBody(configuration: $0)) } }
    func makeBody(configuration: Configuration) -> some View { maker(configuration) }
}
