// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern
import SudokuKern

/// Spielbildschirm von „Sudoku“: kein Scrollen. Von oben: Kopf · Chips (immer 28 pt) · Feld · Rest (Hinweis, Tipp, Lernweg) ·
/// Aktionsleiste · Ziffernblock fest unten im Daumenbereich. iPad hoch: Feld mittig, Ziffern 72 pt; iPad quer: Feld links, Spalte rechts.
struct NeuPartieAnsicht: View {
    @Binding var partie: SudokuPartie
    let name: String
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    let neuesRaetsel: () -> Void
    /// Nach einer Übung: nächste Übung (`ref`) oder zurück zum Lernweg (`nil`)
    let uebungWeiter: (SudokuUebungRef?) -> Void

    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.designArt) private var art
    @Environment(\.geraeteSchema) private var geraet
    /// Gerätefarbschema von außen: `geraet` setzt erst das `aufTisch()` dieser Ansicht (für die Kinder) und ist hier selbst nil.
    @Environment(\.colorScheme) private var geraeteFarbschema
    @AppStorage("sudoku-neu.fehlerSofort") private var fehlerSofort = true
    @AppStorage("sudoku-neu.gleiche") private var gleiche = true
    @AppStorage("sudoku-neu.autoStreichen") private var autoStreichen = true
    @State private var gewaehlt: Int?
    @State private var notizModus = false
    @State private var tipp: NeuBruecke.Tipp?
    @State private var segment = Date()
    @State private var uebungFertig = false
    @State private var uebungVerborgen = false
    @State private var uebungText: String?
    @State private var beendet = false

    private var form: SudokuForm { partie.form }

    var body: some View {
        VStack(spacing: 0) {
            kopf
            GeometryReader { geo in inhalt(geo.size) }
        }
        .aufTisch()   // Design-Runde 3: Tinte = Filz bis in die Ecken, sonst Seitengrund
        .spielHaptik(zug: partie.zuege.count, erfolg: partie.fertig, fehler: partie.limitErreicht)
        .onChange(of: partie.fertig) { _, f in if f && partie.uebung == nil { abschliessen() } }
        .onChange(of: partie.zuege.count) { _, _ in pruefeUebung() }
        // T-4: Beim Zurückkehren läuft die Szene background → inactive → active. Das zweite „nicht aktiv“ (inactive) rechnete die ganze Zeit im
        // Hintergrund noch einmal zu. Gezählt wird nur beim Verlassen von „active“.
        .onChange(of: scenePhase) { alt, p in if p == .active { segment = Date() } else if alt == .active { falten() } }
        .onAppear { segment = Date(); pruefeUebung() }
        .task(id: partie.uebung) { uebungText = Self.erklaerung(partie.uebung) }
        #if DEBUG
        .testEndeMelden {   // -testZustand ende: die letzte leere Zelle wird nach dem Laden als normaler Zug mit der richtigen Ziffer gesetzt
            guard let z = partie.werte.firstIndex(of: 0) else { return }
            aenderung { p in _ = p.setze(z, Int(p.raetsel.loesung[z])) }
        }
        #endif
    }

    // MARK: Aufbau

    private struct Mass {
        var rand: CGFloat, taste: CGFloat, ziffernH: CGFloat, seite: CGFloat, restH: CGFloat
        static let chipsH = Theme.chipHoehe, aktionenH: CGFloat = 64, luecken: CGFloat = 40
    }

    private func mass(_ size: CGSize, breit: Bool) -> Mass {
        let rand: CGFloat = breit ? 24 : Theme.seitenRand
        let taste: CGFloat = breit ? 72 : (size.height < 560 ? 48 : 58)
        let zweiReihen = typeSize.isAccessibilitySize && form.n > 6
        let ziffernH = zweiReihen ? taste * 2 + 6 : taste
        let fest = Mass.chipsH + Mass.aktionenH + ziffernH + Mass.luecken
        let feldMax = size.height - (fest + (breit ? 100 : 44))
        let seite = max(180, min(size.width - 2 * rand, feldMax, breit ? 640 : .infinity))
        return Mass(rand: rand, taste: taste, ziffernH: ziffernH, seite: seite, restH: max(0, size.height - (fest + seite)))
    }

    private func inhalt(_ size: CGSize) -> some View {
        let layout = SpielLayout.entscheide(breite: size.width, hoehe: size.height + 56, sizeClass: sizeClass, grosseSchrift: typeSize.isAccessibilitySize)
        let m = mass(size, breit: layout.breit)
        // Das Blatt (Tipp, Fehlerlimit, Übung) sitzt im Rest; ist der zu niedrig (iPhone SE), schwebt es über dem unteren Rand
        let imRest = layout == .breitQuer || m.restH >= 180
        return Group {
            if layout == .breitQuer { quer(size) } else { hochformat(m, size, imRest: imRest) }
        }
        .frame(width: size.width, height: size.height)
        .overlay(alignment: .bottom) {
            if !imRest, let b = blatt { b.padding(.bottom, 8).transition(.move(edge: .bottom).combined(with: .opacity)) }
        }
        .animation(.snappy, value: blatt != nil)
    }

    private func hochformat(_ m: Mass, _ size: CGSize, imRest: Bool) -> some View {
        VStack(spacing: Design.Abstand.s) {
            chips.frame(height: Mass.chipsH)
            feld(m.seite)
            restBereich(m, imRest: imRest)
            aktionen
            ziffern(hoehe: m.taste, raster: false).padding(.horizontal, m.rand)
        }
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity)
    }

    /// Rest-Bereich mit fester Höhe. Bei größter Schrift ist der Inhalt oft höher als der Platz: Er scrollt dann im Bereich
    /// und liegt nie über Aktionsleiste und Ziffernblock (A-001). Bei normaler Schrift bleibt alles wie bisher.
    @ViewBuilder
    private func restBereich(_ m: Mass, imRest: Bool) -> some View {
        if typeSize.isAccessibilitySize {
            ScrollView {
                rest(hoehe: m.restH, blattHier: imRest).frame(maxWidth: .infinity, alignment: .top)
            }
            .scrollBounceBehavior(.basedOnSize)
            .frame(maxWidth: max(m.seite, 300), minHeight: m.restH, maxHeight: m.restH, alignment: .top)
            .clipped()
        } else {
            rest(hoehe: m.restH, blattHier: imRest).frame(maxWidth: max(m.seite, 300), minHeight: m.restH, maxHeight: m.restH, alignment: .top)
        }
    }

    private func quer(_ size: CGSize) -> some View {
        let seite = max(240, min(size.height - 32, size.width * 0.56))
        return HStack(alignment: .top, spacing: Design.Abstand.xl) {
            feld(seite).padding(.top, 8)
            VStack(spacing: Design.Abstand.m) {
                chips.frame(height: Theme.chipHoehe)
                rest(hoehe: 200, blattHier: true).frame(maxHeight: .infinity, alignment: .top)
                aktionen
                ziffern(hoehe: 60, raster: true).padding(.horizontal, Theme.seitenRand)
            }
            .frame(maxWidth: 420)
        }
        .padding(.horizontal, 24).padding(.bottom, 8)
    }

    // MARK: Teile

    private var kopf: some View {
        TimelineView(.periodic(from: .now, by: 1)) { ctx in
            let sek = Int(partie.verstrichen + (partie.fertig ? 0 : ctx.date.timeIntervalSince(segment)))
            let zeit = Zeitformat.text(sekunden: max(0, sek))
            SpielKopf(mitte: partie.uebung == nil ? "\(NeuBruecke.titel(partie)) · \(zeit)" : NeuBruecke.titel(partie),
                      mitteKurz: partie.uebung == nil ? zeit : nil, mitteMinimal: partie.uebung == nil ? zeit : nil, linksAktion: abbrechen) { menue }
        }
    }

    private var menue: some View {
        RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
            FragNachDenRegelnMenuePunkt()   // KI-3 (Blatt 12): nur mit Apple Intelligence sichtbar
            Button("Wiederholen", systemImage: "arrow.uturn.forward") { aenderung { $0.wiederholen() } }.disabled(!partie.kannWiederholen || partie.fertig)
            Button("Notizen füllen", systemImage: "square.grid.3x3.topleft.filled") { aenderung { $0.notizenFuellen() } }.disabled(partie.fertig)
            Section("Anzeige") {
                Toggle("Fehler sofort zeigen", systemImage: "exclamationmark.circle", isOn: $fehlerSofort)
                Toggle("Gleiche Zahlen hervorheben", systemImage: "equal.circle", isOn: $gleiche)
                Toggle("Notizen automatisch streichen", systemImage: "pencil.slash", isOn: $autoStreichen)
            }
            Button("Neues Rätsel", systemImage: "shuffle", action: neuesRaetsel)
            Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
        }
    }

    private var chips: some View {
        HStack(spacing: Design.Abstand.s) {
            if partie.uebung == nil {
                // T-095: Nach „Weiterspielen“ liegt die Fehlerzahl über dem Limit; dann nur die Zahl („4“, „4 Fehler“), nicht „4 / 3“ oder „4 von 3“
                let ueberLimit = partie.fehler > SudokuPartie.fehlerLimit
                StatusChip(symbol: "exclamationmark.circle", text: Text(verbatim: ueberLimit ? "\(partie.fehler)" : "\(partie.fehler) / \(SudokuPartie.fehlerLimit)"),
                           ton: partie.fehler > 0 ? .warnung : .akzent,
                           beschriftung: ueberLimit ? Text("\(partie.fehler) Fehler") : Text("Fehler \(partie.fehler) von \(SudokuPartie.fehlerLimit)"))
            }
            StatusChip(symbol: "square.grid.3x3", text: Text(verbatim: "\(Int((partie.fortschritt * 100).rounded())) %"), ton: .neutral,
                       beschriftung: Text("Fortschritt \(Int((partie.fortschritt * 100).rounded())) Prozent"))
            if partie.tipps > 0 {
                StatusChip(symbol: "lightbulb", text: Text(verbatim: "\(partie.tipps)"), beschriftung: Text("\(partie.tipps) Tipps"))
            }
            if partie.form != .klassisch && partie.uebung == nil {
                StatusChip(text: Text(verbatim: NeuBruecke.formName(partie.form)), ton: .neutral)
            }
        }
        .lineLimit(1)
    }

    private func feld(_ seite: CGFloat) -> some View {
        let rot: Set<Int> = fehlerSofort ? partie.konflikte().union(partie.falsche()) : partie.konflikte()
        let blatt = art == .tinte && (geraet ?? geraeteFarbschema) == .light
        return NeuFeld(form: form, werte: partie.werte, notizen: partie.notizen, fest: { partie.istVorgabe($0) }, seite: seite,
                       gewaehlt: gewaehlt, rot: rot, gleicheZiffern: gleiche, tipp: tipp, imBlatt: blatt, tippen: waehlen)
            .raetselBlatt(Design.Ecke.klein, innen: 4)   // Große Tinte-Runde, Punkt 9: nur Tinte bei hellem Gerät, helles Blatt auf dem Filz
            .padding(blatt ? 0 : 2)
            .tischFlaeche(Design.Ecke.klein)   // Tinte dunkel: helle Fassung um das Gitter auf dem Filz
    }

    private var aktionen: some View {
        let eintraege = [
            AktionsEintrag(symbol: "arrow.uturn.backward", titel: "Rückgängig", gesperrt: !partie.kannZurueck || partie.fertig) { aenderung { $0.zurueck() } },
            AktionsEintrag(symbol: "delete.left", titel: "Löschen", gesperrt: gewaehlt == nil || partie.fertig) { if let g = gewaehlt { aenderung { $0.loesche(g) } } },
            AktionsEintrag(symbol: "pencil", titel: "Notizen", aktiv: notizModus, gesperrt: partie.fertig) { notizModus.toggle() },
            AktionsEintrag(symbol: "lightbulb", titel: "Tipp", aktiv: tipp != nil, gesperrt: partie.fertig, aktion: tippZeigen),
        ]
        return Group {
            if art == .tinte { TischAktionen(eintraege: eintraege) }   // Punkt 10: runde Knöpfe auf dem Filz
            else { AktionsLeiste(eintraege: eintraege) }
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }

    private func ziffern(hoehe: CGFloat, raster: Bool) -> some View {
        let aktiveZiffer = gewaehlt.map { Int(partie.werte[$0]) }.flatMap { $0 == 0 ? nil : $0 }
        return NeuZiffern(n: form.n, fehlt: { partie.fehltNoch($0) }, hoehe: hoehe, raster: raster, gesperrt: partie.fertig || partie.limitErreicht,
                          hervorgehoben: notizModus ? nil : aktiveZiffer, tippen: ziffer)
    }

    // MARK: Rest

    @ViewBuilder
    private func rest(hoehe: CGFloat, blattHier: Bool) -> some View {
        if blattHier, let b = blatt { b }
        else if partie.uebung != nil, let t = uebungText {
            kartenOderZeile(hoehe, symbol: "scope", titel: Text("Finde: \(NeuBruecke.titel(partie))"), text: t)
        } else {
            kartenOderZeile(hoehe, symbol: info.symbol, titel: Text(verbatim: info.titel), text: info.text)
        }
    }

    @ViewBuilder
    private func kartenOderZeile(_ hoehe: CGFloat, symbol: String, titel: Text, text: String) -> some View {
        if hoehe >= 96 { HinweisKarte(symbol: symbol, titel: titel, text: Text(verbatim: text)) }
        else {
            Text(verbatim: text).font(.footnote).multilineTextAlignment(.center)
                .frame(maxWidth: .infinity).padding(.horizontal, 8)
                .tischHinweis()   // Punkt 11: auf dem Filz hell, höchstens zwei Zeilen
        }
    }

    private var info: (symbol: String, titel: String, text: String) {
        if let k = partie.tagesschluessel {
            return ("calendar", String(localized: "Tagesrätsel"), String(localized: "Heutiges Rätsel, \(k). Löse es, um deine Serie zu halten."))
        }
        if partie.eigen { return ("square.and.pencil", String(localized: "Eigenes Rätsel"), String(localized: "Dein eingegebenes Rätsel. Es hat genau eine Lösung.")) }
        switch form {
        case .klassisch: return ("hand.tap", String(localized: "So geht’s"), String(localized: "Tippe ein Feld an und dann unten die Zahl. Der Stift merkt dir Möglichkeiten."))
        case .kinder: return ("figure.and.child.holdinghands", String(localized: "Kinder-Sudoku"), String(localized: "Die Zahlen 1 bis 6 stehen in jeder Zeile, Spalte und jedem Kästchen aus 3 × 2 Feldern genau einmal."))
        case .x: return ("xmark.square", String(localized: "X-Sudoku"), String(localized: "Auch die beiden Diagonalen enthalten jede Zahl von 1 bis 9 genau einmal."))
        }
    }

    /// Das Blatt (Tipp, Fehlerlimit, Übung fertig), falls eines offen ist
    private var blatt: ErklaerSheet? {
        if partie.limitErreicht {
            return ErklaerSheet(symbol: "exclamationmark.triangle", titel: "Drei Fehler", text: Text("Du kannst zum letzten fehlerfreien Stand zurück oder einfach weiterspielen."),
                                sekundaerTitel: "Weiterspielen", primaerTitel: "Zurücksetzen",
                                sekundaer: { partie.limitBestaetigt = true }, primaer: { aenderung { $0.zuruecksetzen() }; tipp = nil })
        }
        if uebungFertig && !uebungVerborgen, let ref = partie.uebung {
            let weiter = Exercises.series(for: NeuBruecke.technik(ref) ?? .nakedSingle).count > ref.nummer
            return ErklaerSheet(symbol: "checkmark.seal", titel: "Gut gemacht!", text: Text(verbatim: NeuBruecke.titel(partie)),
                                sekundaerTitel: "Weiterspielen", primaerTitel: weiter ? "Nächste Übung" : "Zum Lernweg",
                                sekundaer: { uebungVerborgen = true },
                                primaer: { uebungWeiter(weiter ? SudokuUebungRef(technik: ref.technik, nummer: ref.nummer + 1) : nil) })
        }
        if let t = tipp {
            return ErklaerSheet(symbol: "lightbulb", titel: Text(verbatim: t.titel), text: Text(verbatim: t.text), hinweis: t.zusatz.map { Text(verbatim: $0) },
                                sekundaerTitel: "Nur zeigen", primaerTitel: "Eintragen",
                                sekundaer: { tipp = nil }, primaer: { eintragen(t) })
        }
        return nil
    }

    // MARK: Eingaben

    private func waehlen(_ i: Int) {
        gewaehlt = i
        if let t = tipp, t.zelle != i, !t.falsch { /* Tipp bleibt sichtbar, bis er geschlossen wird */ }
    }

    private func ziffer(_ d: Int) {
        guard let z = gewaehlt, !partie.istVorgabe(z), !partie.fertig, !partie.limitErreicht else { return }
        tipp = nil
        falten()
        if notizModus {
            guard partie.werte[z] == 0 else { return }
            partie.notiz(z, d)
        } else {
            let e = partie.setze(z, d, notizenStreichen: autoStreichen)
            if e == .falsch {
                AccessibilityNotification.Announcement(String(localized: "Das passt nicht.")).post()
            }
        }
    }

    private func eintragen(_ t: NeuBruecke.Tipp) {
        falten()
        partie.tippEintragen(t.zelle)
        gewaehlt = t.zelle
        tipp = nil
    }

    private func tippZeigen() {
        if tipp != nil { tipp = nil; return }
        guard let t = NeuBruecke.tipp(partie, bevorzugt: gewaehlt) else { return }
        tipp = t
        gewaehlt = t.zelle
        AccessibilityNotification.Announcement("\(t.titel). \(t.text)").post()
    }

    private func aenderung(_ f: (inout SudokuPartie) -> Void) {
        falten()
        f(&partie)
        tipp = nil
    }

    private func falten() {
        guard !partie.fertig else { return }
        let jetzt = Date()
        partie.verstrichen += jetzt.timeIntervalSince(segment)
        segment = jetzt
    }

    private func pruefeUebung() {
        guard let ref = partie.uebung, !uebungFertig, NeuBruecke.uebungErledigt(partie) else { return }
        uebungFertig = true
        NeuAblage.uebungGeschafft(ref)
        AccessibilityNotification.Announcement(String(localized: "Gut gemacht!")).post()
    }

    private func abschliessen() {
        guard !beendet else { return }
        beendet = true
        falten()
        if let k = partie.tagesschluessel { NeuAblage.tagGeloest(k) }
        else if let i = NeuBruecke.leiterStufe(partie) {
            Leiter.sieg("sudoku", stufe: i, mitTipp: partie.tipps > 0)   // D4; RT-041: nur klassisch
        }
        // Blatt 22 (EB-3): ein Satz, zwei bis drei Werte, das gelöste Gitter als Bild
        let sekunden = Int(partie.verstrichen)
        var satz = String(localized: "Gelöst in \(Zeitformat.text(sekunden: sekunden)).")
        if partie.tagesschluessel == nil, partie.uebung == nil, !partie.eigen, partie.tipps == 0,
           NeuAblage.bestzeitMelden(partie.form, partie.raetsel.stufe, sekunden: sekunden) {
            satz = String(localized: "Neue Bestzeit in „\(NeuBruecke.stufeName(partie.raetsel.stufe))“.")   // C-017: Bestzeit je Spielart und Stufe, lokal
        }
        var e = SpielEnde(reihenfolge: [name], info: satz)
        let stufeText = NeuBruecke.titel(partie)
        // Fund 15: Steht die Zeit schon im Satz („Gelöst in 1:36.“), kommt sie nicht noch einmal als Wert dazu
        let zeitImSatz = satz == String(localized: "Gelöst in \(Zeitformat.text(sekunden: sekunden)).")
        e.werte = [EndeWert("Stufe", stufeText)] + (zeitImSatz ? [] : [EndeWert("Zeit", Zeitformat.text(sekunden: sekunden))]) + [
                   partie.tipps > 0 ? EndeWert("Tipps", "\(partie.tipps)") : EndeWert("Fehler", "\(partie.fehler)")]
        let stand = partie   // Wert festhalten: der Rahmen kennt den Spielstand danach nicht mehr
        e.bild = EndeBild(Text("Gelöstes Gitter"), hoehe: 320) { groesse in SudokuEndeBild(partie: stand, groesse: groesse) }
        e.dauer = partie.verstrichen   // C-027: reine Lösezeit statt Wanduhr des Rahmens
        // Statistik je Stufe im Kern: nur das klassische 9×9 (Kinder- und X-Sudoku hätten andere Zeiten), keine Übungen und keine
        // eigenen Rätsel; das Tagesrätsel zählt eigens.
        if partie.tagesschluessel != nil { e.kennzahlen["tages"] = 1 }
        else if partie.uebung == nil, !partie.eigen, partie.form == .klassisch,
                let i = SudokuStufe.allCases.firstIndex(of: partie.raetsel.stufe) { e.kennzahlen["stufe"] = Double(i) }
        Task {
            try? await Task.sleep(for: .milliseconds(700))
            ende(e)
        }
    }

    private static func erklaerung(_ ref: SudokuUebungRef?) -> String? {
        guard let ref, let t = NeuBruecke.technik(ref), let e = Exercises.exercise(t, ref.nummer) else { return nil }
        let gesamt = Exercises.series(for: t).count
        let satz = e.step.map { $0.explanation(reveal: false) } ?? ""
        return satz + (satz.isEmpty ? "" : "\n") + String(localized: "Übung \(ref.nummer) von \(gesamt)")
    }
}

/// Große Tinte-Runde, Punkt 10: Aktionen unter dem Gitter als runde Knöpfe auf dem Filz statt kleiner unterstrichener Wörter.
/// Brechen nie um; wird die Reihe zu eng (kleines iPhone, große Schrift), stehen die Knöpfe in zwei Reihen.
private struct TischAktionen: View {
    let eintraege: [AktionsEintrag]

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) { ForEach(eintraege) { knopf($0) } }
            VStack(spacing: 8) {
                HStack(spacing: 8) { ForEach(eintraege.prefix(2)) { knopf($0) } }
                HStack(spacing: 8) { ForEach(eintraege.dropFirst(2)) { knopf($0) } }
            }
        }
        .padding(.horizontal, Theme.seitenRand)
    }

    private func knopf(_ e: AktionsEintrag) -> some View {
        Button(action: e.aktion) { Text(e.titel).frame(maxWidth: .infinity) }
            .buttonStyle(TischAktionStil(aktiv: e.aktiv))
            .disabled(e.gesperrt)
            .accessibilityAddTraits(e.aktiv ? .isSelected : [])
    }
}

/// Wie `TischKnopfStil`; ist die Aktion an (zum Beispiel Notizen), steht der Knopf gefüllt in Elfenbein.
private struct TischAktionStil: ButtonStyle {
    let aktiv: Bool
    @Environment(\.isEnabled) private var an

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(aktiv ? Tisch.auge : Tisch.elfenbein)
            .lineLimit(1).minimumScaleFactor(0.5)   // Fund 117: „Rückgängig“ wurde zu „Rückgän…“ abgeschnitten
            .padding(.horizontal, 8)
            .frame(minHeight: Theme.tapSize)
            .background(Capsule().fill(aktiv ? Tisch.elfenbein : Color.white.opacity(configuration.isPressed ? 0.26 : 0.14)))
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.24), lineWidth: aktiv ? 0 : 1))
            .opacity(an ? 1 : 0.45)
            .contentShape(.capsule)
    }
}
