// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern
import SudokuKern

/// Eigenes Rätsel eingeben: Zahlen aus Zeitung oder Buch abtippen, prüfen lassen (genau eine Lösung?), dann normal spielen.
struct NeuEditor: View {
    let zurueck: () -> Void
    let abbrechen: () -> Void
    let spielen: (SudokuRaetsel) -> Void
    @State private var form: SudokuForm
    @State private var gitter: [UInt8]
    @State private var gewaehlt: Int?
    @State private var ergebnis: SudokuPruefung?
    @State private var prueft = false
    @Environment(\.dynamicTypeSize) private var typeSize

    init(form: SudokuForm, zurueck: @escaping () -> Void, abbrechen: @escaping () -> Void, spielen: @escaping (SudokuRaetsel) -> Void) {
        self.zurueck = zurueck; self.abbrechen = abbrechen; self.spielen = spielen
        _form = State(initialValue: form)
        _gitter = State(initialValue: [UInt8](repeating: 0, count: form.zellen))
    }

    var body: some View {
        VStack(spacing: 0) {
            SpielKopf(linksSymbol: "chevron.left", linksBeschriftung: "Zurück", mitte: String(localized: "Eigenes Rätsel"), linksAktion: zurueck) {
                RundKnopf(symbol: "xmark", beschriftung: "Spiel beenden", aktion: abbrechen)
            }
            GeometryReader { geo in
                let seite = max(200, min(geo.size.width - 2 * Theme.seitenRand, geo.size.height - 330, 560))
                VStack(spacing: 10) {
                    Group {   // N-019: ab „xLarge“ ein Menü, weil Segmente ihre Schrift nicht mitwachsen lassen
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
                    }.padding(.horizontal, Theme.seitenRand)
                    .onChange(of: form) { _, f in gitter = [UInt8](repeating: 0, count: f.zellen); gewaehlt = nil; ergebnis = nil }
                    NeuFeld(form: form, werte: gitter, notizen: [UInt16](repeating: 0, count: form.zellen), fest: { _ in true }, seite: seite,
                            gewaehlt: gewaehlt, rot: SudokuPruefung.doppelte(form, gitter), gleicheZiffern: false, tipp: nil, tippen: { gewaehlt = $0 })
                        .padding(2).designFlaeche(Design.Ecke.klein)
                    meldung.frame(maxWidth: .infinity, minHeight: 56, alignment: .top).padding(.horizontal, Theme.seitenRand)
                    Spacer(minLength: 0)
                    HStack(spacing: 10) {
                        Button { loeschen() } label: { Label("Löschen", systemImage: "delete.left").frame(maxWidth: .infinity) }
                            .buttonStyle(ZweitKnopfStil()).disabled(gewaehlt == nil)
                        Button { pruefen() } label: { Label("Prüfen", systemImage: "checkmark.circle").frame(maxWidth: .infinity) }
                            .buttonStyle(ZweitKnopfStil()).disabled(prueft)
                    }.padding(.horizontal, Theme.seitenRand)
                    NeuZiffern(n: form.n, hoehe: 52, tippen: eintragen).padding(.horizontal, Theme.seitenRand)
                    if case .eindeutig(let loesung) = ergebnis {
                        Button { spielen(SudokuRaetsel(form: form, vorgaben: gitter, loesung: loesung, stufe: .mittel, seed: 0)) } label: {
                            Text("Spielen").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(HauptKnopfStil()).padding(.horizontal, Theme.seitenRand)
                        .accessibilityIdentifier("sudoku-neu-spielen")
                    }
                }
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity)
            }
        }
        .background(Color.seitenGrund)
    }

    @ViewBuilder private var meldung: some View {
        switch ergebnis {
        case .none:
            Text("Tippe ein Feld an und trage die Zahlen deines Rätsels ein. Dann lass es prüfen.").font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
        case .leer:
            Text("Trage zuerst ein paar Zahlen ein.").font(.footnote).foregroundStyle(.secondary)
        case .widerspruch:
            Label("Eine Zahl kommt doppelt vor (rot markiert).", systemImage: "exclamationmark.triangle").font(.footnote.weight(.semibold)).foregroundStyle(Color.meldungRot)
        case .unloesbar:
            Label("Dieses Rätsel hat keine Lösung. Prüfe die Zahlen noch einmal.", systemImage: "xmark.circle").font(.footnote.weight(.semibold)).foregroundStyle(Color.meldungRot)
        case .mehrdeutig:
            Label("Dieses Rätsel hat mehr als eine Lösung. Trage weitere Zahlen ein.", systemImage: "questionmark.circle").font(.footnote.weight(.semibold)).foregroundStyle(.orange)
        case .eindeutig:
            Label("Das Rätsel hat genau eine Lösung.", systemImage: "checkmark.seal").font(.footnote.weight(.semibold)).foregroundStyle(Color.accentText)
        }
    }

    private func eintragen(_ d: Int) {
        guard let g = gewaehlt else { return }
        gitter[g] = gitter[g] == UInt8(d) ? 0 : UInt8(d)
        ergebnis = nil
    }

    private func loeschen() {
        guard let g = gewaehlt else { return }
        gitter[g] = 0; ergebnis = nil
    }

    private func pruefen() {
        let f = form, g = gitter
        prueft = true
        Task {
            let r = await Task.detached(priority: .userInitiated) { SudokuPruefung.pruefe(f, g) }.value
            prueft = false
            guard g == gitter, f == form else { return }   // C-046: Gitter hat sich während der Prüfung geändert
            ergebnis = r
            AccessibilityNotification.Announcement(ansage(r)).post()
        }
    }

    private func ansage(_ r: SudokuPruefung) -> String {
        switch r {
        case .leer: String(localized: "Trage zuerst ein paar Zahlen ein.")
        case .widerspruch: String(localized: "Eine Zahl kommt doppelt vor (rot markiert).")
        case .unloesbar: String(localized: "Dieses Rätsel hat keine Lösung. Prüfe die Zahlen noch einmal.")
        case .mehrdeutig: String(localized: "Dieses Rätsel hat mehr als eine Lösung. Trage weitere Zahlen ein.")
        case .eindeutig: String(localized: "Das Rätsel hat genau eine Lösung.")
        }
    }
}
