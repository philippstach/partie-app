// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

/// Spielbildschirm von „Yacht“: kein Scrollen in keiner Richtung. Der Wertungsblock nimmt die Resthöhe, die Würfelzone sitzt unten.
/// iPhone und iPad hoch: Kopf · Block · Würfelzone. iPad quer: links der Block (45 %), rechts „Diese Runde“, Würfel und Knöpfe groß.
struct NeuSpielView: View {
    let abbrechen: () -> Void
    let ende: () -> Void
    @Environment(GameStore.self) private var store
    @Environment(AppPreferences.self) private var preferences
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @State private var gewaehlt: Category?
    @State private var stufe = ComputerStufe.gespeichert(NeuAblage.id)
    @State private var wirbelnd = Set<Int>()
    @State private var gezeigt = [1, 1, 1, 1, 1]
    @State private var rat: HoldAdvice?
    @State private var tippAn = false
    @State private var zeigeEcht = false
    @State private var streichen: Category?
    @State private var verlauf = false
    @State private var regeln = false
    @Environment(\.regelnOeffnen) private var regelnOeffnen   // T-091: „Regeln“ im Menü öffnet die Regelseite des Rahmens
    @State private var regelnWahl = false
    @State private var size: CGSize = .zero

    private var gross: Bool { typeSize.isAccessibilitySize }
    private var regular: Bool { sizeClass == .regular }
    private var quer: Bool { regular && size.width > size.height }
    private var ohneBewegung: Bool { preferences.reduceAnimations || systemReduceMotion }

    var body: some View {
        if let r = store.game {
            Group {
                if r.finished { NeuEndeKarte(record: r, ende: ende, verlauf: { verlauf = true }) } else { spiel(r) }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .aufTisch()   // Design-Runde 3: Tinte = Filz bis in die Ecken, sonst Seitengrund
            .sheet(isPresented: $verlauf) { HistorySheet(record: r) }
            .sheet(isPresented: $regeln) { RulesView() }
            .sheet(isPresented: $regelnWahl) { NeuRegelnBlatt() }
        } else {
            Color.clear
        }
    }

    private func spiel(_ r: GameRecord) -> some View {
        let s = r.state
        let computer = istComputer(r)
        // Blatt 16 / Abschnitt T2 (iPad hoch, nur Tinte): ganze Breite mit 20 pt Rand statt 680 pt; die Würfel wachsen mit, höchstens auf das Anderthalbfache der iPhone-Größe (72 → 108)
        let breitTisch = regular && !quer && Tisch.aktiv
        let spaltenMax: CGFloat = breitTisch ? .infinity : (regular ? 680 : 520)
        let basisKante = NeuLogik.wuerfelKante(hoehe: size.height, regular: regular, grosseSchrift: gross)
        let kante = min(breitTisch && !gross ? 108 : basisKante,
                        size.width > 0 && !quer ? max(40, (min(size.width - (breitTisch ? 40 : 0), spaltenMax) - 48) / 5 - 6) : .infinity)   // M-009: Würfelleiste breiter als die Karte
        let zone = NeuWuerfelZone(record: r, kante: kante, gewaehlt: $gewaehlt, computerAmZug: computer, wirbelnd: wirbelnd, gezeigt: gezeigt, rat: rat, tippAn: $tippAn,
                                  wuerfeln: { wuerfeln(r) }, eintragen: { festlegen(r, $0) })
        return Group {
            if quer {
                HStack(alignment: .top, spacing: Design.Abstand.l) {
                    NeuBlock(record: r, gewaehlt: $gewaehlt, bedienbar: !computer).frame(width: size.width * 0.45)
                    VStack(spacing: Design.Abstand.m) {
                        NeuRundeKarte(record: r)
                        Spacer(minLength: 0)
                    }
                }
                .padding(.horizontal, 16).padding(.top, 4)
                .safeAreaInset(edge: .bottom, spacing: 0) { zone }
            } else {
                NeuBlock(record: r, gewaehlt: $gewaehlt, bedienbar: !computer)
                    .padding(.horizontal, breitTisch ? 20 : 10).padding(.top, 4).padding(.bottom, 4)
                    .frame(maxWidth: spaltenMax)
                    .frame(maxWidth: .infinity)
                    .safeAreaInset(edge: .bottom, spacing: 0) { zone.padding(.horizontal, breitTisch ? 8 : 0).frame(maxWidth: spaltenMax).frame(maxWidth: .infinity) }   // Zone hat 12 pt Eigenrand, mit 8 pt dazu 20 pt wie der Block
            }
        }
        .onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }
        .safeAreaInset(edge: .top, spacing: 0) { kopf(r) }
        .alert(streichenTitel, isPresented: Binding(get: { streichen != nil }, set: { if !$0 { streichen = nil } })) {
            Button("Streichen", role: .destructive) { if let c = streichen { festlegen(r, c, bestaetigt: true) } }
            Button("Abbrechen", role: .cancel) {}
        } message: { Text("Das Feld bekommt 0 Punkte und kann nicht mehr benutzt werden.") }
        .onChange(of: s.current) { gewaehlt = nil; tippAn = false }
        .task(id: ratSchluessel(r)) { await ratBerechnen(r) }
        .task(id: computerSchluessel(r)) { await computerSchritt(r) }
        .sheet(isPresented: $zeigeEcht) {
            RealEntrySheet(dice: s.dice, held: Set(r.held), rollNumber: s.rollsUsed + 1) { werte in
                if store.rollReal(werte) { nachWurf() }
            }
        }
    }

    // MARK: Kopf

    private func kopf(_ r: GameRecord) -> some View {
        let s = r.state
        let runde = min(s.players[s.current].scores.count + 1, s.rules.variant.fields.count)
        return SpielKopf(mitte: String(localized: "Runde \(runde) von \(s.rules.variant.fields.count)"),
                         mitteKurz: "\(runde)/\(s.rules.variant.fields.count)", linksAktion: abbrechen) {
            if !istComputer(r), s.rollsUsed == 0, store.canUndo {
                RundKnopf(symbol: "arrow.uturn.backward", beschriftung: "Letzten Eintrag zurücknehmen") { store.undo(); gewaehlt = nil }
            } else if r.settings.diceMode == .real, s.rollsUsed > 0, store.canUndoRoll, !istComputer(r) {
                RundKnopf(symbol: "arrow.uturn.backward", beschriftung: "Wurf korrigieren") { store.undoRoll(); gewaehlt = nil }
            }
            RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                if store.vorErstemZug { Button("Wertung und Regeln ändern", systemImage: "slider.horizontal.3") { regelnWahl = true } }
                FragNachDenRegelnMenuePunkt()   // KI-3 (Blatt 12): nur mit Apple Intelligence sichtbar
                if r.players.contains(where: { $0.computer != nil }) {
                    ComputerStufePicker(spiel: NeuAblage.id, stufe: $stufe).onChange(of: stufe) { _, neu in store.neuStufe = neu }   // C-038 (2)
                }
                NeuePartieMenuePunkt()   // G-019
                Button("Spielverlauf", systemImage: "chart.xyaxis.line") { verlauf = true }
                Button("Regeln", systemImage: "book") { if let regelnOeffnen { regelnOeffnen() } else { regeln = true } }
                Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
            }
        }
        .overlay(alignment: .bottom) { rekordZeile(r) }
    }

    /// Solo: Bestmarke der Wertung im Kopf.
    @ViewBuilder private func rekordZeile(_ r: GameRecord) -> some View {
        if r.settings.dailyKey != nil {
            // 1.0 (P5): Tageswürfel sichtbar machen: dieselbe Würfelfolge für alle am selben Tag
            Label("Tageswürfel · für alle gleich", systemImage: "calendar").font(.caption2.weight(.semibold)).offset(y: 6).tischHinweis(zeilen: 1)
        } else if r.players.count == 1, let rekord = NeuAblage.rekord(r.state.rules.variant) {
            Text("Rekord \(rekord)").font(.caption2.weight(.semibold)).offset(y: 6).tischHinweis(zeilen: 1)
        }
    }

    // MARK: Aktionen

    private func istComputer(_ r: GameRecord) -> Bool { !r.state.finished && r.players[r.state.current].isComputer }

    private func wuerfeln(_ r: GameRecord) {
        if r.settings.diceMode == .real { zeigeEcht = true; return }
        let behalten = Set(r.held)
        guard store.roll() else { return }
        animiere(behalten)
    }

    private func animiere(_ behalten: Set<Int>) {
        nachWurf()
        guard !ohneBewegung else { return }
        wirbelnd = Set((0..<5).filter { !behalten.contains($0) })
        Task { @MainActor in
            for _ in 0..<6 {
                gezeigt = (0..<5).map { _ in Int.random(in: 1...6) }
                SpielHaptik.stoss(.rigid, 0.5)   // kurzes Klackern während der Würfelanimation
                try? await Task.sleep(for: .milliseconds(70))
            }
            wirbelnd = []
        }
    }

    private func nachWurf() {
        gewaehlt = nil
        tippAn = false
        Sound.roll.play()
        SpielHaptik.tap()
        guard let s = store.game?.state else { return }
        if s.isYacht { SpielHaptik.success() }
        AccessibilityNotification.Announcement(String(localized: "Gewürfelt: ") + s.dice.map(String.init).joined(separator: ", ") + (s.isYacht ? String(localized: ". Yacht!") : "")).post()
    }

    private func festlegen(_ r: GameRecord, _ c: Category, bestaetigt: Bool = false) {
        let punkte = r.state.potentialScore(c)
        if punkte == 0, !bestaetigt, !istComputer(r) { streichen = c; return }
        let wer = r.players[r.state.current].name
        let titel = c.title(r.state.rules.variant)
        if store.score(c) {
            AccessibilityNotification.Announcement(String(localized: "\(wer) trägt \(titel) ein: \(punkte) Punkte")).post()
            gewaehlt = nil
            tippAn = false
            (punkte == 0 ? Sound.strike : Sound.score).play()
            punkte == 0 ? SpielHaptik.error() : SpielHaptik.success()
        }
    }

    private var streichenTitel: String {
        streichen.map { String(localized: "„\($0.title(store.game?.state.rules.variant ?? .kniffel))“ streichen?") } ?? String(localized: "Feld streichen?")
    }

    // MARK: Tipp

    private func ratSchluessel(_ r: GameRecord) -> String {
        guard tippAn, !istComputer(r) else { return "aus" }
        let s = r.state
        return "\(s.current)-\(s.rollsUsed)-\(s.dice)-\(s.players[s.current].scores.count)"
    }

    private func ratBerechnen(_ r: GameRecord) async {
        guard tippAn, !istComputer(r) else { rat = nil; return }
        let state = r.state
        rat = nil
        let ergebnis = await Task.detached(priority: .userInitiated) { HoldAdvisor.advise(state) }.value
        guard !Task.isCancelled else { return }
        rat = ergebnis
    }

    // MARK: Computer

    private func computerSchluessel(_ r: GameRecord) -> String {
        guard istComputer(r) else { return "" }
        let s = r.state
        return "\(s.current)-\(s.rollsUsed)-\(s.players[s.current].scores.count)"
    }

    private func computerSchritt(_ r: GameRecord) async {
        guard istComputer(r) else { return }
        let state = r.state
        let stufe = store.neuStufe ?? .schwer
        let schnell = ohneBewegung
        try? await Task.sleep(for: schnell ? .milliseconds(300) : ComputerTempo.angepasst(.milliseconds(900)))
        guard !Task.isCancelled else { return }
        let zufall = Double.random(in: 0..<1)
        let entscheidung = await Task.detached(priority: .userInitiated) { NeuLogik.entscheide(state, stufe: stufe, zufall: zufall) }.value
        guard !Task.isCancelled, store.game?.id == r.id, store.game?.state == state else { return }
        switch entscheidung {
        case .roll(let keep):
            if state.rollsUsed > 0 {
                store.setHeld(keep)
                SpielHaptik.tap()
                try? await Task.sleep(for: schnell ? .milliseconds(200) : ComputerTempo.angepasst(.milliseconds(800)))
                guard !Task.isCancelled else { return }
            }
            if store.computerRoll(keep: keep) { animiere(Set(keep)) }
        case .score(let c):
            gewaehlt = c
            try? await Task.sleep(for: schnell ? .milliseconds(300) : ComputerTempo.angepasst(.milliseconds(1100)))
            guard !Task.isCancelled else { return }
            festlegen(r, c, bestaetigt: true)
        }
    }
}

/// iPad quer: „Diese Runde“ – wer dran ist und wie die Würfel liegen.
struct NeuRundeKarte: View {
    let record: GameRecord

    var body: some View {
        let s = record.state
        let p = record.players[s.current]
        return VStack(alignment: .leading, spacing: Design.Abstand.s) {
            TischUeberschrift("Diese Runde")
            HStack(spacing: 10) {
                AvatarAbzeichen(avatar: p.avatar, farbe: p.color, groesse: 40)
                VStack(alignment: .leading) {
                    Text(record.players.count > 1 ? String(localized: "\(p.name) ist dran") : p.name).font(.headline)
                    Text(s.rollsUsed == 0 ? String(localized: "Noch nicht gewürfelt") : String(localized: "Wurf \(s.rollsUsed) von 3")).font(.subheadline).foregroundStyle(Color.schriftZweit).tischHinweis(zeilen: 1, sonst: Color.schriftZweit)
                }
                Spacer()
            }
            .accessibilityElement(children: .combine)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .tischFlaeche(16)
    }
}

/// Spiel zu Ende: Endstand, „Ergebnis“ (weiter zum Rahmen) und der Punkteverlauf als Blatt.
struct NeuEndeKarte: View {
    let record: GameRecord
    let ende: () -> Void
    let verlauf: () -> Void

    var body: some View {
        let rekord: Bool = record.players.count == 1
            && NeuLogik.istNeuerRekord(punkte: record.total(0), bisher: NeuAblage.rekord(record.state.rules.variant))
        VStack(spacing: 14) {
            Spacer(minLength: 0)
            Text("Spielende").font(.title2.weight(.bold))   // B18 K-023: Überschrift im Endbild
            Text(record.state.rules.variant.titel).font(.footnote.weight(.semibold)).tischHinweis(zeilen: 1)
            VStack(spacing: Design.Abstand.s) {
                ForEach(record.players.indices.sorted { record.total($0) > record.total($1) }, id: \.self) { i in
                    HStack {
                        Text(record.players[i].avatar)
                        Text(record.players[i].name).font(.subheadline.weight(.semibold))
                        Spacer()
                        Text("\(record.total(i))").font(.system(.title3, design: Design.zahlDesign, weight: .heavy)).monospacedDigit()
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            .padding(14)
            .tischFlaeche(16)
            if rekord { Label("Neuer Rekord!", systemImage: "trophy.fill").font(.headline).foregroundStyle(Tisch.aktiv ? Tisch.elfenbein : Color.accentText) }
            Spacer(minLength: 0)
            VStack(spacing: Design.Abstand.s) {
                Button(action: ende) { Text("Ergebnis").font(.headline).frame(maxWidth: .infinity) }.hauptKnopf().accessibilityIdentifier("ergebnis")
                Button(action: verlauf) { Label("Punkteverlauf", systemImage: "chart.xyaxis.line").frame(maxWidth: .infinity) }.zweitKnopf()
            }
        }
        .padding()
        .frame(maxWidth: 520)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
