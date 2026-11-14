// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import SpielHilfen
import AblegeKarten

/// Spielbildschirm Elfer raus: Tisch als Spielfeld mit Lücken und Anlegeplätzen, Hand als Fächer, darunter die Zugknöpfe.
struct ElferNeuSpiel: View {
    let teilnehmer: [SpielTeilnehmer]
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void

    @Environment(\.designArt) private var art   // zeichnet beim Designwechsel neu
    @State private var spiel: ErSpiel
    @State private var variante: ErVariante
    @State private var stufe = ComputerStufe.gespeichert("elferraus-neu", standard: .schwer)
    @State private var tipp: ErKarte?
    @State private var aufgedeckt = false
    @State private var denkt = false
    @State private var gemeldet = false
    @State private var neuFragen = false
    @State private var gesehenDran = -1

    static let schluessel = "partie.regeln.elferraus-neu"
    static var gespeicherteVariante: ErVariante { ErVariante(rawValue: UserDefaults.standard.string(forKey: schluessel) ?? "") ?? .echt }

    init(teilnehmer: [SpielTeilnehmer], ende: @escaping (SpielEnde) -> Void, abbrechen: @escaping () -> Void, vorgabe: ErSpiel? = nil) {   // vorgabe: nur für Bildtests
        self.teilnehmer = teilnehmer; self.ende = ende; self.abbrechen = abbrechen
        let v = Self.gespeicherteVariante
        var g = SystemRandomNumberGenerator()
        _variante = State(initialValue: v)
        _spiel = State(initialValue: vorgabe ?? ErSpiel(spieler: teilnehmer.count, regeln: .fuer(v), mit: &g))
    }

    private var v: ErVariante { spiel.regeln.variante }
    private var computerDran: Bool { teilnehmer[spiel.dran].computer }
    private var uebergabe: Bool { !computerDran && (teilnehmer.filter { !$0.computer }.count > 1) && !aufgedeckt && !spiel.rundeBeendet }
    private func name(_ i: Int) -> String { teilnehmer[i].name }

    // MARK: Farben

    private func farbe(_ f: Int) -> Color {
        switch v {
        case .echt:
            // Klar: Systemfarben wie bisher. Tinte und Salon: Rollen (Rot aus den Kartenwerten, die übrigen als feste Farbmarken des Designs).
            if KartenStil.ist(.klar) { [Color(.systemRed), Color(.systemYellow), Color(.systemGreen), Color(.systemBlue)][f] }
            else { [DesignWerte.fuer(KartenStil.aktuell.art).karten?.rot.color ?? FarbPaar(0xB3261E).color, FarbPaar(0xE0A91C).color, FarbPaar(0x2F7D4F).color, FarbPaar(0x2F5FA8).color][f] }
        case .kartendomino: f >= 2 ? Color(.systemRed) : Color(.label)
        }
    }
    private func schriftFarbe(_ f: Int) -> Color { v == .echt && f == 1 ? .black : (v == .echt ? .white : farbe(f)) }

    // MARK: Aufbau

    var body: some View {
        GeometryReader { geo in
            let breit = geo.size.width >= 700
            let quer = breit && geo.size.width > geo.size.height
            Group {
                if quer { querLayout(geo.size) } else { hochLayout(geo.size, breit: breit) }
            }
        }
        .aufTisch()   // Design-Runde 3: in Tinte Filz bis in die Ecken, sonst Seitengrund wie bisher
        // C-024 (Elfer raus): Stand nur übernehmen, wenn er zur aktuellen Spielerzahl passt. Vorher prüfte der Stand nur
        // `rundeBeendet`; mit anderer Spielerzahl griffen `teilnehmer[spiel.dran]` und `spiel.haende[i]` ins Leere (Absturz).
        .fortsetzbar(ElferRausModul.kennung, $spiel, pruefen: { [n = teilnehmer.count] in
            !$0.rundeBeendet && $0.spielerZahl == n && (0..<n).contains($0.dran) && $0.reihen.count == 4
        })
        .weicheAnimation(bei: spiel)
        .spielHaptik(zug: spiel, erfolg: spiel.rundeBeendet)
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .confirmationDialog("Neue Verteilung?", isPresented: $neuFragen, titleVisibility: .visible) {
            Button("Neue Partie", role: .destructive) { neuMischen() }
            Button("Abbrechen", role: .cancel) {}
        } message: { Text("Die laufende Partie geht verloren.") }
        .onAppear { weiter() }
        .onChange(of: spiel.dran) { _, _ in aufgedeckt = false; tipp = nil; weiter() }
        .onChange(of: spiel.verlauf.count) { _, _ in weiter() }
    }

    private func kopf() -> some View {
        SpielKopf(mitte: spiel.rundeBeendet ? (spiel.siegerEindeutig ? String(localized: "\(name(spiel.sieger ?? 0)) gewinnt") : String(localized: "Partie zu Ende")) : String(localized: "\(name(spiel.dran)) ist dran"),
                  mitteKurz: name(spiel.dran), linksAktion: abbrechen) {
            RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                FragNachDenRegelnMenuePunkt()   // KI-3 (Blatt 12): nur mit Apple Intelligence sichtbar
                if teilnehmer.contains(where: \.computer) { ComputerStufePicker(spiel: "elferraus-neu", stufe: $stufe) }
                Picker("Regeln", selection: Binding(get: { variante }, set: { varianteWaehlen($0) })) {
                    Text("Elfer raus (1–20)").tag(ErVariante.echt)
                    Text("Kartendomino (Skatblatt)").tag(ErVariante.kartendomino)
                }
                .disabled(!spiel.vorErstemEigenenZug)   // nur vor dem ersten eigenen Zug (RT-003: der automatische Startzug zählt nicht)
                Button("Neue Partie", systemImage: "arrow.counterclockwise") { if spiel.vorErstemEigenenZug { neuMischen() } else { neuFragen = true } }
                Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
            }
        }
    }

    private var leiste: some View {
        SpielerLeiste(eintraege: teilnehmer.indices.map { .init(id: "\($0)", name: name($0), farbe: Spieler.farbe($0), wert: String(localized: "\(spiel.haende[$0].count) Karten")) },
                      aktiv: spiel.rundeBeendet ? nil : "\(spiel.dran)")
            .padding(.horizontal, Theme.seitenRand)
    }

    /// Höhe, die die Hand höchstens bekommt (F-AWS-G-013): kleine iPhones zwei, sonst drei Zeilen; darüber scrollt sie.
    /// Die Hand nimmt nur die Höhe, die ihre Karten brauchen, der Tisch bekommt den Rest.
    private func handPlatz(_ g: CGSize, breit: Bool) -> CGFloat {
        if breit { return 342 }
        return g.height < 700 ? 134 : 264
    }

    /// Kartengrößen der Hand, größte zuerst (gemeinsame Größen der Kartenfläche).
    private func handGroessen(breit: Bool) -> [KartenGroesse] { breit ? [.gross, .normal, .klein] : [.normal, .klein] }

    private func hochLayout(_ g: CGSize, breit: Bool) -> some View {
        let rand = breit ? max(Theme.seitenRand, (g.width - 700) / 2) : Theme.seitenRand
        return VStack(spacing: Theme.kartenAbstand) {
            kopf()
            leiste.padding(.horizontal, rand - Theme.seitenRand)
            tisch.padding(.horizontal, rand)
            statusZeile.padding(.horizontal, rand)
            handBereich(breite: g.width - 2 * rand, platz: handPlatz(g, breit: breit), groessen: handGroessen(breit: breit)).padding(.horizontal, rand)
            knoepfe.padding(.horizontal, rand)
        }
        .padding(.bottom, 6)
    }

    private func querLayout(_ g: CGSize) -> some View {
        let seite = min(max(g.width / 3, 320), 380)
        return VStack(spacing: Theme.kartenAbstand) {
            kopf()
            HStack(alignment: .top, spacing: Design.Abstand.xl) {
                VStack(spacing: Theme.kartenAbstand) {
                    tisch
                    handBereich(breite: g.width - 48 - seite - Design.Abstand.xl, platz: 342, groessen: handGroessen(breit: true))
                }
                .frame(maxWidth: .infinity)
                VStack(spacing: Theme.kartenAbstand) {
                    leiste.padding(.horizontal, -Theme.seitenRand)
                    verlaufKarte
                    regelnKarte
                    Spacer(minLength: 0)
                    statusZeile
                    knoepfe
                }
                .frame(width: seite)
            }
            .padding(.horizontal, 24)
        }
        .padding(.bottom, 8)
    }

    // MARK: Tisch

    private var tisch: some View {
        let werte = spiel.regeln.werte
        let anlegbar = Set(spiel.moegliche)   // Anlegeplätze des Spielers am Zug
        let zeigen = !computerDran && !uebergabe && !spiel.rundeBeendet
        return GeometryReader { g in
            let labelBreite: CGFloat = 22
            let innen = g.size.width - 2 * Theme.spielfeldRand - labelBreite - 6
            // B18 (F-AWS-K-018): Bei 20 Werten liegt jede Farbe in zwei Zeilen (1–10, 11–20), damit die Felder nicht auf 15 pt schrumpfen
            let zeilenJeFarbe = werte.count > 10 ? 2 : 1
            let jeZeile = (werte.count + zeilenJeFarbe - 1) / zeilenJeFarbe
            let abstand: CGFloat = 4
            let slotB = (innen - CGFloat(jeZeile - 1) * abstand) / CGFloat(jeZeile)
            let reiheH = (g.size.height - 2 * Theme.spielfeldRand - 3 * 6) / 4
            let slotH = max(min((reiheH - CGFloat(zeilenJeFarbe - 1) * 3) / CGFloat(zeilenJeFarbe), slotB * 2.2, 120), 18)
            let alleWerte = Array(werte)
            VStack(spacing: 6) {
                ForEach(0..<4, id: \.self) { f in
                    HStack(spacing: 6) {
                        Text(verbatim: ErNamen.zeichen(f, v)).font(.callout.weight(.bold)).foregroundStyle(farbe(f)).frame(width: labelBreite)
                        VStack(spacing: 3) {
                            ForEach(0..<zeilenJeFarbe, id: \.self) { z in
                                HStack(spacing: abstand) {
                                    ForEach(Array(alleWerte[(z * jeZeile)..<min((z + 1) * jeZeile, alleWerte.count)]), id: \.self) { w in
                                        slot(ErKarte(f, w), breite: slotB, hoehe: slotH, anlegbar: zeigen && anlegbar.contains(ErKarte(f, w)))
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxHeight: .infinity)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(reiheText(f))
                }
            }
            .padding(Theme.spielfeldRand)
            .frame(width: g.size.width, height: g.size.height)
            .tischFlaeche(Theme.cardRadius)
        }
        .frame(minHeight: 150)
    }

    private func reiheText(_ f: Int) -> Text {
        let n = ErNamen.farbName(f, v)
        guard let r = spiel.reihen[f] else { return Text("\(n): noch nicht begonnen") }
        return Text("\(n): \(r.lowerBound) bis \(r.upperBound) ausgelegt")
    }

    private func slot(_ k: ErKarte, breite: CGFloat, hoehe: CGFloat, anlegbar: Bool) -> some View {
        let da = spiel.reihen[k.farbe]?.contains(k.wert) == true
        // B18 (F-AWS-N-002): Die 80 Felder sind keine Knöpfe ohne Namen mehr. Die Reihe darüber trägt den Vorlesetext,
        // gespielt wird über die beschrifteten Handkarten; Antippen eines anlegbaren Felds geht weiter.
        return ZStack {
            ZStack {
                if da {
                    RoundedRectangle(cornerRadius: 3).fill(farbe(k.farbe).opacity(v == .echt ? 0.9 : 0.14))
                    Text(verbatim: ErNamen.name(k, v)).font(.system(size: max(min(breite * 0.62, 18), 7), weight: .bold, design: Design.zahlDesign))   // design:spielinhalt (Ziffer folgt der Platzbreite)
                        .minimumScaleFactor(0.5).lineLimit(1).foregroundStyle(schriftFarbe(k.farbe))
                } else {
                    if Design.art == .klar {
                        RoundedRectangle(cornerRadius: 3).strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [2, 2])).foregroundStyle(Color.secondary.opacity(0.4))
                    } else {
                        RoundedRectangle(cornerRadius: 3).strokeBorder(Color.linie, lineWidth: 1)   // Tinte, Salon: durchgezogene 1-pt-Linie in der Linien-Rolle
                    }
                }
                if anlegbar {
                    RoundedRectangle(cornerRadius: 3).fill(Color.accentSoft)
                    RoundedRectangle(cornerRadius: 3).strokeBorder(Color.primary.opacity(0.7), lineWidth: 2)
                }
            }
            .frame(width: breite, height: hoehe)
        }
        .contentShape(Rectangle())
        .onTapGesture { if anlegbar { lege(k) } }
        .allowsHitTesting(anlegbar)
        .accessibilityHidden(true)
    }

    // MARK: Status, Hand, Knöpfe

    private var letzteAktion: String {
        guard let e = spiel.verlauf.last else { return String(localized: "Die rote 11 liegt. Wer legt an?") }
        switch e.art {
        case .legt(let k): return String(localized: "\(name(e.spieler)) legt \(ErNamen.farbName(k.farbe, v)) \(ErNamen.name(k, v))")
        case .zieht: return String(localized: "\(name(e.spieler)) zieht eine Karte")
        case .passt: return String(localized: "\(name(e.spieler)) passt")
        case .beendet: return String(localized: "\(name(e.spieler)) beendet den Zug")
        }
    }

    private var statusZeile: some View {
        VStack(spacing: 2) {
            Text(computerDran && !spiel.rundeBeendet ? String(localized: "\(name(spiel.dran)) denkt nach …") : letzteAktion)
                .font(.subheadline).multilineTextAlignment(.center).lineLimit(2).tischHinweis()
            if spiel.regeln.ziehen { Text("Stapel: \(spiel.stapel.count)").font(.caption).foregroundStyle(art == .tinte ? AnyShapeStyle(Tisch.hinweisLeise) : AnyShapeStyle(HierarchicalShapeStyle.tertiary)) }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func handBereich(breite: CGFloat, platz: CGFloat, groessen: [KartenGroesse]) -> some View {
        let hoehe = min(platz, groessen.last!.masse.height * 2 + 6)
        if spiel.rundeBeendet {
            Text("Runde beendet").font(.headline).frame(maxWidth: .infinity, minHeight: hoehe)
        } else if computerDran {
            Color.clear.frame(height: hoehe)
        } else if uebergabe {
            SichtschutzKarte(name: name(spiel.dran), farbe: Spieler.farbe(spiel.dran)) { aufgedeckt = true }
            .frame(maxWidth: .infinity, minHeight: hoehe)
        } else {
            // F-AWS-G-013, K-029, T-020: Raster ohne Überlappung statt Fächer in zwei überlappenden Reihen, jede Karte ganz sichtbar.
            let m = RasterMasse.berechne(anzahl: spiel.haende[spiel.dran].count, breite: breite, groessen: groessen.map(\.masse), hoechstHoehe: platz)
            KartenRaster(karten: spiel.haende[spiel.dran], spielbar: Set(spiel.moegliche), tipp: tipp, masse: m,
                         beschriftung: { k in Text("\(ErNamen.farbName(k.farbe, v)) \(ErNamen.name(k, v))") },
                         aktion: { k in lege(k) },
                         bild: { k, sp, groesse in kartenBild(k, groesse: groessen.first { $0.masse == groesse } ?? .klein, spielbar: sp) })
                .frame(height: m.passt ? m.hoehe : platz)
        }
    }

    @ViewBuilder
    private func kartenBild(_ k: ErKarte, groesse: KartenGroesse, spielbar: Bool) -> some View {
        switch v {
        case .echt:
            // Gemeinsame Kartenfläche des Kerns in der Farbe der Reihe: Zahl groß in der Mitte, Farbzeichen darunter (zweites Merkmal neben der Farbe).
            let b = groesse.masse.width
            KartenFlaeche(groesse: groesse, flaeche: farbe(k.farbe), gedimmt: !spielbar,
                          beschriftung: Text("\(ErNamen.farbName(k.farbe, v)) \(ErNamen.name(k, v))")) {
                VStack(spacing: 0) {
                    Text(verbatim: "\(k.wert)").font(.system(size: b * 0.46, weight: .bold, design: Design.zahlDesign)).lineLimit(1).minimumScaleFactor(0.6)   // design:spielinhalt (Kartenzahl wächst mit der Kartengröße)
                    Text(verbatim: ErNamen.zeichen(k.farbe, v)).font(.system(size: b * 0.26))   // design:spielinhalt (Farbzeichen)
                }
                .foregroundStyle(schriftFarbe(k.farbe))
            }
            .markiert(spielbar)
        case .kartendomino:
            SkatKartenBild(SkatKarte(farbIndex: k.farbe, wert: k.wert), groesse: groesse, gedimmt: !spielbar, markiert: spielbar)
        }
    }

    private var knoepfe: some View {
        HStack(spacing: Design.Abstand.m) {
            if !spiel.rundeBeendet && !computerDran && !uebergabe {
                Button { tipp = spiel.computerSchritt(mit: &zufall).karte; tippAnsage() } label: { Label("Tipp", systemImage: "lightbulb") }
                    .tischNebenKnopf().dynamicTypeSize(...DynamicTypeSize.xxxLarge).disabled(spiel.moegliche.isEmpty)
                if spiel.kannZiehenOderPassen {
                    Button(spiel.zieht ? "Karte ziehen" : "Passen") { spiel.ziehenOderPassen() }.buttonStyle(HauptKnopfStil())
                } else if spiel.kannBeenden {
                    Button("Zug beenden") { spiel.beende() }.buttonStyle(HauptKnopfStil())
                }
            }
        }
        .frame(minHeight: 44)
    }

    @State private var zufall = SystemRandomNumberGenerator()

    // MARK: Ablauf

    private func lege(_ k: ErKarte) {
        guard !computerDran, !uebergabe else { return }
        tipp = nil
        spiel.lege(k)
    }

    private func tippAnsage() {
        guard let k = tipp else { return }
        UIAccessibility.post(notification: .announcement, argument: String(localized: "Tipp: \(ErNamen.farbName(k.farbe, v)) \(ErNamen.name(k, v)) anlegen."))
    }

    private func weiter() {
        if spiel.rundeBeendet { melden(); return }
        guard computerDran, !denkt else { return }
        denkt = true
        let fehler = stufe == .leicht ? 0.7 : (stufe == .mittel ? 0.25 : 0)
        Task { @MainActor in
            await ComputerTempo.warte(.milliseconds(700))
            denkt = false
            guard !spiel.rundeBeendet, computerDran else { return }
            let a = spiel.computerSchritt(fehler: fehler, mit: &zufall)
            spiel.fuehreAus(a)
            weiter()
        }
    }

    private func melden() {
        guard !gemeldet else { return }
        gemeldet = true
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(900))
            let ordnung = spiel.rangfolge
            let rest = spiel.rest
            let punkte = ordnung.map { -rest[$0] }
            let e = SpielEnde.nachPunkten(namen: ordnung.map(name), punkte: punkte, hoeherIstBesser: true,
                                          info: spiel.siegerEindeutig ? String(localized: "\(name(spiel.sieger ?? ordnung[0])) gewinnt") : nil)   // T-082: bei Gleichstand ohne Sieger-Satz
            var fertig = SpielEnde(reihenfolge: e.reihenfolge, punkte: punkte.map { $0 == 0 ? "0" : "−\(-$0)" }, plaetze: e.plaetze, info: e.info)
            // Blatt 22 (EB-1): Dauer und gelegte Karten als Werte, dazu die vier Farbreihen als Bild.
            let gelegt = spiel.reihen.reduce(0) { $0 + ($1?.count ?? 0) }
            fertig.werte = [.dauer, EndeWert("Gelegte Karten", "\(gelegt)")]
            fertig.bild = ElferEndeBild.bild(reihen: spiel.reihen, werte: spiel.regeln.werte, variante: v)
            ende(fertig)
        }
    }

    private func neuMischen() {
        tipp = nil; aufgedeckt = false
        var g = SystemRandomNumberGenerator()
        spiel = ErSpiel(spieler: teilnehmer.count, regeln: .fuer(variante), mit: &g)
        weiter()
    }

    private func varianteWaehlen(_ neu: ErVariante) {
        variante = neu
        UserDefaults.standard.set(neu.rawValue, forKey: Self.schluessel)
        neuMischen()
    }

    // MARK: iPad-Seitenspalte

    private var verlaufKarte: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Verlauf").font(.footnote.weight(.semibold)).tischHinweis()
            if spiel.verlauf.isEmpty {
                Text("Noch kein Zug").font(.footnote).foregroundStyle(art == .tinte ? AnyShapeStyle(Tisch.hinweisLeise) : AnyShapeStyle(HierarchicalShapeStyle.tertiary))
            } else {
                ForEach(Array(spiel.verlauf.suffix(8).enumerated()), id: \.offset) { _, e in
                    Text(verbatim: beschreibe(e)).font(.footnote).lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .spielTischKarte()
    }

    private func beschreibe(_ e: ErEreignis) -> String {
        switch e.art {
        case .legt(let k): String(localized: "\(name(e.spieler)) legt \(ErNamen.farbName(k.farbe, v)) \(ErNamen.name(k, v))")
        case .zieht: String(localized: "\(name(e.spieler)) zieht eine Karte")
        case .passt: String(localized: "\(name(e.spieler)) passt")
        case .beendet: String(localized: "\(name(e.spieler)) beendet den Zug")
        }
    }

    private var regelnKarte: some View {
        VStack(alignment: .leading, spacing: Design.Abstand.xs) {
            Text("Regeln dieser Partie").font(.footnote.weight(.semibold)).tischHinweis()
            Text(v == .echt ? "Elfer raus: mehrere Karten je Zug, Karte ziehen statt passen." : "Kartendomino: eine Karte je Zug, passen erlaubt.").font(.footnote)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .spielTischKarte()
    }
}

private extension ErAktion {
    /// Die Karte, die der Computer als nächste legen würde (für den Tipp).
    var karte: ErKarte? { if case .lege(let k) = self { k } else { nil } }
}
#endif
