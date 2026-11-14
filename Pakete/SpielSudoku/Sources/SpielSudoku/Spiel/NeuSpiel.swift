// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern
import SudokuKern

/// „Sudoku“ im `SpielRahmen`: Start, Neues-Spiel-Blatt und Ende kommen vom Rahmen. Hier liegt, was das Rätsel braucht:
/// die Wahl (Spielart, Stufe, Tagesrätsel, Lernweg, eigenes Rätsel), das Spiel selbst und das Fortsetzen (`fortsetzbar`).
struct NeuSpiel: View {
    let name: String
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    @State private var partie: SudokuPartie?
    @State private var seite: Seite = .wahl
    @State private var baut = false
    @State private var tage = NeuAblage.geloesteTage()
    @State private var angestartet = false
    @AppStorage("sudoku-neu.form") private var formRoh = SudokuForm.klassisch.rawValue
    @AppStorage("sudoku-neu.stufe") private var stufeRoh = SudokuStufe.leicht.rawValue

    enum Seite { case wahl, lernweg, editor }

    init(name: String, ende: @escaping (SpielEnde) -> Void, abbrechen: @escaping () -> Void) {
        self.name = name; self.ende = ende; self.abbrechen = abbrechen
        // Fortsetzen: ein gespeicherter, stimmiger und nicht beendeter Stand öffnet gleich das Spiel
        let alt = SpielStand.laden(SudokuPartie.self, spiel: NeuAblage.id).flatMap { $0.stimmig && !$0.fertig ? $0 : nil }
        _partie = State(initialValue: alt)
    }

    private var form: Binding<SudokuForm> { Binding(get: { SudokuForm(rawValue: formRoh) ?? .klassisch }, set: { formRoh = $0.rawValue }) }
    private var stufe: Binding<SudokuStufe> { Binding(get: { SudokuStufe(rawValue: stufeRoh) ?? .leicht }, set: { stufeRoh = $0.rawValue }) }

    var body: some View {
        ZStack {
            if let b = Binding($partie) {
                NeuPartieAnsicht(partie: b, name: name, ende: ende, abbrechen: abbrechen, neuesRaetsel: verwerfen, uebungWeiter: uebungWeiter)
            } else {
                switch seite {
                case .wahl:
                    NeuWahl(form: form, stufe: stufe, tage: tage, abbrechen: abbrechen,
                            starten: { bauen(form.wrappedValue, $0) }, teilenStart: { bauen(form.wrappedValue, $0, teilen: true) }, tagesraetsel: { bauen(.klassisch, .mittel, tag: $0) },
                            lernweg: { seite = .lernweg }, editor: { seite = .editor })
                case .lernweg:
                    NeuLernweg(zurueck: { seite = .wahl }, abbrechen: abbrechen, uebung: { starteUebung($0) })
                case .editor:
                    NeuEditor(form: form.wrappedValue, zurueck: { seite = .wahl }, abbrechen: abbrechen) { r in
                        partie = SudokuPartie(raetsel: r, eigen: true)
                    }
                }
            }
        }
        .overlay { if baut { bautAnzeige } }
        .fortsetzbar(NeuAblage.id, $partie, pruefen: { $0.stimmig && !$0.fertig })
        .onAppear { tage = NeuAblage.geloesteTage(); linkAnnehmen(); startenNachWahl() }
    }

    private var bautAnzeige: some View {
        VStack(spacing: Design.Abstand.m) {
            ProgressView()
            Text("Rätsel wird gebaut …").font(.subheadline)
        }
        .padding(24)
        .toast()
        .accessibilityElement(children: .combine)
    }

    // MARK: Aktionen

    private func bauen(_ form: SudokuForm, _ stufe: SudokuStufe, tag: String? = nil, seed vorgabe: UInt64? = nil, teilen: Bool = false) {
        guard !baut else { return }
        baut = true
        let seed = vorgabe ?? UInt64.random(in: 1...UInt64(Int32.max))
        Task {
            let r: SudokuRaetsel
            if let tag {
                r = await Task.detached(priority: .userInitiated) { NeuBruecke.tagesraetsel(tag) }.value
            } else {
                r = await Task.detached(priority: .userInitiated) { NeuBruecke.raetsel(form, stufe, seed: seed) }.value
            }
            baut = false
            partie = SudokuPartie(raetsel: r, tagesschluessel: tag)
            if teilen { raetselTeilen(form, stufe, seed) }
        }
    }

    /// D3: Link zum eben gebauten Rätsel an das Systemblatt geben (im Kindermodus tut das nichts).
    private func raetselTeilen(_ form: SudokuForm, _ stufe: SudokuStufe, _ seed: UInt64) {
        let l = RaetselLink(spiel: NeuAblage.id, werte: ["form": form.rawValue, "stufe": stufe.rawValue, "seed": String(seed)])
        ErgebnisTeilen.zeigenText(l.teilenText(satz: String(localized: "Sudoku \(NeuBruecke.formName(form)), \(NeuBruecke.stufeName(stufe)): Schaffst du dieses Rätsel?")))
    }

    /// Design-Runde 3 (Tinte): „Spielen“ der Spielseite startet, was dort gewählt ist; die eigene Wahlseite entfällt.
    /// Nur beim ersten Erscheinen und nur ohne offene Partie (Fortsetzen und Links gehen vor).
    private func startenNachWahl() {
        guard Design.ist(.tinte), !angestartet, partie == nil, !baut else { return }
        angestartet = true
        let wahl = UserDefaults.standard.string(forKey: NeuStartWahl.schluessel) ?? ""
        UserDefaults.standard.removeObject(forKey: NeuStartWahl.schluessel)
        switch wahl {
        case "tag": bauen(.klassisch, .mittel, tag: DailyPuzzle.key(for: .now))
        case "lernweg": seite = .lernweg
        case "editor": seite = .editor
        case "teilen": bauen(form.wrappedValue, stufe.wrappedValue, teilen: true)
        default: bauen(form.wrappedValue, stufe.wrappedValue)
        }
    }

    /// Link von außen: dasselbe Rätsel bauen (nur wenn gerade keine Partie offen ist; der Link bleibt sonst liegen).
    private func linkAnnehmen() {
        guard partie == nil, !baut, let l = RaetselPost.abholen(spiel: NeuAblage.id),
              let f = l.werte["form"].flatMap(SudokuForm.init(rawValue:)), let s = l.werte["stufe"].flatMap(SudokuStufe.init(rawValue:)),
              let seed = l.zahl("seed"), seed > 0 else { return }
        bauen(f, s, seed: seed)
    }

    private func starteUebung(_ ref: SudokuUebungRef) {
        guard let t = NeuBruecke.technik(ref), let p = NeuBruecke.uebungPartie(t, ref.nummer) else { return }
        partie = p
    }

    /// Zurück zur Wahl; ein offener Stand wird verworfen (der Rahmen zählt das nicht als Niederlage)
    private func verwerfen() {
        SpielStand.verworfen.insert(NeuAblage.id)
        SpielStand.loeschen(NeuAblage.id)
        partie = nil
        seite = .wahl
        tage = NeuAblage.geloesteTage()
        // Tinte: „Neues Rätsel“ im Menü baut gleich ein neues in der gewählten Spielart und Stufe (keine zweite Wahlseite)
        if Design.ist(.tinte) { bauen(form.wrappedValue, stufe.wrappedValue) }
    }

    private func uebungWeiter(_ ref: SudokuUebungRef?) {
        SpielStand.loeschen(NeuAblage.id)
        if let ref { starteUebung(ref) } else { partie = nil; seite = .lernweg }
    }
}
