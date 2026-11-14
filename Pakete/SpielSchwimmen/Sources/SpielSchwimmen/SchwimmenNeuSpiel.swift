// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import SpielHilfen

/// Spielbildschirm Schwimmen: Tisch und Hand teilen sich die Resthöhe, Karten wachsen mit, vor dem Tausch erscheint eine Vorschau.
struct SchwimmenNeuSpiel: View {
    let teilnehmer: [SpielTeilnehmer]
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void

    @State private var spiel: SchwimmenNeu
    @State private var regeln: SchwimmenRegeln
    @State private var zufall = SystemRandomNumberGenerator()
    @State private var aufgedeckt = false
    @State private var gewaehltHand: Int?
    @State private var gewaehltTisch: Int?
    @State private var alleGewaehlt = false
    @State private var tippHand: Int?
    @State private var tippTisch: Int?
    @State private var tippText: String?
    @State private var denkt = false
    @State private var gemeldet = false
    @State private var stufe = ComputerStufe.gespeichert("schwimmen-neu")

    @Environment(\.horizontalSizeClass) private var sizeClass
    /// Blatt 16: auf dem iPad in Tinte drei gleich breite Knöpfe.
    private var gleichBreit: CGFloat? { sizeClass == .regular && Tisch.aktiv ? .infinity : nil }

    static let schluessel = "partie.regeln.schwimmen-neu"
    static var gespeicherteRegeln: SchwimmenRegeln {
        UserDefaults.standard.data(forKey: schluessel).flatMap { try? JSONDecoder().decode(SchwimmenRegeln.self, from: $0) } ?? .standard
    }

    init(teilnehmer: [SpielTeilnehmer], ende: @escaping (SpielEnde) -> Void, abbrechen: @escaping () -> Void) {
        self.teilnehmer = teilnehmer; self.ende = ende; self.abbrechen = abbrechen
        let r = Self.gespeicherteRegeln
        var g = SystemRandomNumberGenerator()
        _regeln = State(initialValue: r)
        _spiel = State(initialValue: SchwimmenNeu(spieler: teilnehmer.count, regeln: r, mit: &g))
    }

    private func name(_ i: Int) -> String { teilnehmer[i].name }
    private var computerDran: Bool { teilnehmer[spiel.dran].computer }
    private var mehrereMenschen: Bool { teilnehmer.filter { !$0.computer }.count > 1 }
    private var weitergabe: Bool { !sichtbar && !computerDran && !spiel.rundeVorbei }
    private var sichtbar: Bool { (aufgedeckt || !mehrereMenschen) && !computerDran && !spiel.rundeVorbei }
    private var auswahlVollstaendig: Bool { alleGewaehlt || (gewaehltHand != nil && gewaehltTisch != nil) }

    // MARK: Aufbau

    var body: some View {
        GeometryReader { geo in
            let breit = geo.size.width >= 700
            if breit && geo.size.width > geo.size.height { quer(geo.size) } else { hoch(geo.size, breit: breit) }
        }
        .aufTisch()   // Design-Runde 3: Tinte = Filz bis in die Ecken, sonst Seitengrund
        // S4: Der Computer wird erst angestoßen, wenn der Stand geladen ist (vorher lief `pruefe` im eigenen onAppear,
        // dessen Reihenfolge zum Laden nicht festliegt: Nach „Fortsetzen“ mit Computer am Zug blieb das Spiel stehen).
        #if DEBUG
        .testEndeMelden { if spiel.spielZuEnde { melden() } }   // -testZustand ende: das Ende wird nach dem Laden des Endstands selbst gemeldet
        #endif
        .fortsetzbar(SchwimmenModul.kennung, $spiel, pruefen: { [n = teilnehmer.count] in $0.leben.count == n && $0.summen.count == n && $0.hand.count == n && $0.geschoben.count == n && $0.dran >= 0 && $0.dran < n }, standGeladen: { _ in pruefe() })
        .weicheAnimation(bei: spiel)
        .spielHaptik(zug: spiel, erfolg: spiel.spielZuEnde)
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
    }

    private func kopf() -> some View {
        SpielKopf(mitte: spiel.rundeVorbei ? String(localized: "Runde \(spiel.runde) vorbei") : String(localized: "\(name(spiel.dran)) ist dran"),
                  mitteKurz: name(spiel.dran), linksAktion: abbrechen) {
            RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                if teilnehmer.contains(where: \.computer) { ComputerStufePicker(spiel: "schwimmen-neu", stufe: $stufe) }
                regelnMenue
                FragNachDenRegelnMenuePunkt()   // KI-3 (Blatt 12): nur mit Apple Intelligence sichtbar
                NeuePartieMenuePunkt()   // F-AWS-G-019: „Neue Partie“ wie in allen Spielen
                Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
            }
        }
    }

    private var regelnAenderbar: Bool { spiel.runde == 1 && spiel.verlauf.isEmpty && !spiel.rundeVorbei }

    @ViewBuilder
    private var regelnMenue: some View {
        Menu("Hausregeln") {
            Picker("Spielart", selection: aendern(\.modus)) {
                Text("Leben").tag(SwModus.leben)
                Text("Punkte (5 Runden)").tag(SwModus.punkte)
            }
            Picker("Leben", selection: aendern(\.leben)) { Text("3 Leben").tag(3); Text("4 Leben").tag(4) }
                .disabled(regeln.modus == .punkte)   // RT-009: im Punktemodus ohne Wirkung, also ausgegraut (nicht entfernt)
            Toggle("31 beendet die Runde sofort", isOn: aendern(\.feuerSofort))
            Toggle("33 mit drei Assen", isOn: aendern(\.dreiAssen33))
            Picker("Schieben", selection: Binding(get: { regeln.schiebenLimit ?? 0 }, set: { n in setze { $0.schiebenLimit = n == 0 ? nil : n } })) {
                Text("Beliebig oft").tag(0); Text("Höchstens einmal").tag(1)
            }
            Picker("Drei Gleiche", selection: aendern(\.dreiGleiche)) { Text("30,5 Punkte").tag(30.5); Text("30 Punkte").tag(30.0) }
        }
        .disabled(!regelnAenderbar)
    }

    private func aendern<T>(_ pfad: WritableKeyPath<SchwimmenRegeln, T>) -> Binding<T> {
        Binding(get: { regeln[keyPath: pfad] }, set: { neu in setze { $0[keyPath: pfad] = neu } })
    }

    private func setze(_ f: (inout SchwimmenRegeln) -> Void) {
        var r = regeln; f(&r)
        guard r != regeln, regelnAenderbar else { return }
        regeln = r
        if let d = try? JSONEncoder().encode(r) { UserDefaults.standard.set(d, forKey: Self.schluessel) }
        var g = SystemRandomNumberGenerator()
        spiel = SchwimmenNeu(spieler: teilnehmer.count, regeln: r, mit: &g)
        auswahlLoeschen(); pruefe()
    }

    private var leiste: some View {
        SpielerLeiste(eintraege: teilnehmer.indices.map { i in .init(id: "\(i)", name: name(i), farbe: Spieler.farbe(i), wert: wertText(i)) },
                      aktiv: spiel.rundeVorbei ? nil : "\(spiel.dran)")
            .padding(.horizontal, Theme.seitenRand)
    }

    private func wertText(_ i: Int) -> String {
        if regeln.modus == .punkte { return "Σ \(SwNamen.zahl(spiel.summen[i]))" }
        let l = spiel.leben[i]
        return l < 0 ? String(localized: "raus") : (l == 0 ? String(localized: "schwimmt") : "♥ \(l)")
    }

    private func hoch(_ g: CGSize, breit: Bool) -> some View {
        // Blatt 16 (nur Tinte): ganze Breite mit 20 pt Rand, Karten 1,45-fach
        let rand = breit && !Tisch.aktiv ? max(Theme.seitenRand, (g.width - 700) / 2) : Theme.seitenRand
        return VStack(spacing: Theme.kartenAbstand) {
            kopf()
            leiste.padding(.horizontal, rand - Theme.seitenRand)
            if spiel.rundeVorbei { rundenBlatt.padding(.horizontal, rand) } else { felder(maxKarte: breit ? (Tisch.aktiv ? 218 : 190) : 150).padding(.horizontal, rand) }
            if !spiel.rundeVorbei { knoepfe.padding(.horizontal, rand) }
        }
        .padding(.bottom, 6)
    }

    private func quer(_ g: CGSize) -> some View {
        let seite = min(max(g.width / 3, 320), 380)
        return VStack(spacing: Theme.kartenAbstand) {
            kopf()
            HStack(alignment: .top, spacing: Design.Abstand.xl) {
                Group { if spiel.rundeVorbei { rundenBlatt } else { felder(maxKarte: 170) } }.frame(maxWidth: .infinity)
                VStack(spacing: Theme.kartenAbstand) {
                    leiste.padding(.horizontal, -Theme.seitenRand)
                    verlaufKarte
                    regelnKarte
                    Spacer(minLength: 0)
                    if !spiel.rundeVorbei { knoepfe }
                }
                .frame(width: seite)
            }
            .padding(.horizontal, 24)
        }
        .padding(.bottom, 8)
    }

    // MARK: Tisch und Hand (Resthöhe)

    private func felder(maxKarte: CGFloat) -> some View {
        GeometryReader { g in
            // Kartenhöhe = (Resthöhe − 200) / 2, begrenzt auf 72…maxKarte. Die 200 pt sind die Köpfe und Ränder der beiden Reihen (je 44 pt)
            // plus die Vorschaukarte (B18, F-AWS-K-008: mit 150 ragte die Vorschaukarte unter die Knopfleiste).
            let h = min(max((g.size.height - 200) / 2, 72), maxKarte)
            VStack(spacing: Theme.kartenAbstand) {
                reihe(titel: Text("Tisch"), punkte: tischUeberschrift) {
                    HStack(spacing: 10) {
                        ForEach(0..<3, id: \.self) { t in
                            Button { tippeTisch(t) } label: { karte(spiel.tisch[t], hoehe: h, gewaehlt: gewaehltTisch == t || alleGewaehlt, tipp: tippTisch == t) }
                                .buttonStyle(.plain).disabled(!sichtbar)
                                .accessibilityLabel(Text("Tischkarte \(t + 1): \(SwNamen.karte(spiel.tisch[t]))"))
                        }
                    }
                }
                if weitergabe {
                    // Während der Weitergabe nur die Weitergabe-Karte (wie Mau-Mau), kein leerer Handbereich und keine Vorschau.
                    // F-AWS-P-017: auch in Klar, dort ragte „Ich bin …“ aus der fest 1 Kartenhöhe hohen Handreihe.
                    if Design.art == .klar {
                        SichtschutzKarte(name: name(spiel.dran), farbe: Spieler.farbe(spiel.dran)) { aufgedeckt = true }
                            .padding(Design.Abstand.l).frame(maxWidth: .infinity, minHeight: h).designFlaeche(Theme.cardRadius)
                    } else {
                        SichtschutzKarte(name: name(spiel.dran), farbe: Spieler.farbe(spiel.dran)) { aufgedeckt = true }.frame(maxWidth: .infinity, minHeight: h)
                    }
                } else {
                reihe(titel: Text(verbatim: name(spiel.dran)), punkte: handUeberschrift) {
                    if sichtbar {
                        HStack(spacing: 10) {
                            ForEach(0..<3, id: \.self) { i in
                                Button { tippeHand(i) } label: { karte(spiel.hand[spiel.dran][i], hoehe: h, gewaehlt: gewaehltHand == i || alleGewaehlt, tipp: tippHand == i) }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel(Text("Handkarte \(i + 1): \(SwNamen.karte(spiel.hand[spiel.dran][i]))"))
                            }
                        }
                    } else if computerDran {
                        HStack(spacing: 10) { ForEach(0..<3, id: \.self) { _ in karte(nil, hoehe: h, gewaehlt: false, tipp: false) } }
                    } else {
                        SichtschutzKarte(name: name(spiel.dran), farbe: Spieler.farbe(spiel.dran)) { aufgedeckt = true }.frame(minHeight: h)
                    }
                }
                // B18 (F-AWS-K-028): Während der Weitergabe ist die Vorschau leer, also auch keine leere Karte reservieren
                if sichtbar || computerDran { vorschauKarte }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(minHeight: 344)
    }

    private func reihe<Inhalt: View>(titel: Text, punkte: String, @ViewBuilder inhalt: () -> Inhalt) -> some View {
        VStack(spacing: 6) {
            HStack {
                titel.font(.footnote.weight(.semibold)).tischHinweis(zeilen: 1)
                Spacer()
                Text(verbatim: punkte).font(.footnote.monospacedDigit()).tischHinweis(zeilen: 1)
            }
            .zIndex(1)
            inhalt().frame(maxWidth: .infinity).padding(.top, 8)   // Fund 7: Platz für die hochgehobene (gewählte) Karte, sie deckt die Beschriftung nicht mehr ab
        }
        .padding(10)
        .tischFlaeche(Theme.cardRadius)
        .accessibilityElement(children: .contain)
    }

    private var tischUeberschrift: String { String(localized: "Tisch zählt \(SwNamen.zahl(swPunkte(spiel.tisch, regeln)))") }
    private var handUeberschrift: String { sichtbar ? beschreibe(spiel.hand[spiel.dran]) : "" }

    private func beschreibe(_ h: [SwKarte]) -> String {
        let p = SwNamen.zahl(swPunkte(h, regeln))
        if let f = swBesteFarbe(h) { return "\(SwNamen.farbName(f)) \(p)" }
        return String(localized: "Drei Gleiche \(p)")
    }

    @ViewBuilder
    private func karte(_ k: SwKarte?, hoehe: CGFloat, gewaehlt: Bool, tipp: Bool) -> some View {
        let b = hoehe * 0.69
        SkatKartenBild(k.flatMap { SkatKarte(farbIndex: $0.farbe, wert: $0.wert) }, groesse: .normal, gewaehlt: gewaehlt)
            .scaleEffect(hoehe / KartenGroesse.normal.masse.height)
            .frame(width: b, height: hoehe)
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.yellow, lineWidth: 4).opacity(tipp ? 1 : 0))
            .offset(y: gewaehlt ? -6 : 0)
            .animation(.easeOut(duration: 0.12), value: gewaehlt)
    }

    // MARK: Vorschau

    private var vorschauText: String {
        guard sichtbar else { return computerDran ? String(localized: "\(name(spiel.dran)) denkt nach …") : "" }
        let hand = spiel.hand[spiel.dran]
        if alleGewaehlt { return String(localized: "Alle drei tauschen → \(beschreibe(spiel.tisch))") }
        if let h = gewaehltHand, let t = gewaehltTisch {
            var n = hand; n[h] = spiel.tisch[t]
            return String(localized: "Tausch: \(SwNamen.karte(hand[h])) gegen \(SwNamen.karte(spiel.tisch[t])) → \(beschreibe(n))")
        }
        if gewaehltHand != nil || gewaehltTisch != nil { return String(localized: "Wähle noch eine Karte.") }
        if let k = spiel.klopfer { return String(localized: "\(name(k)) hat geklopft: letzte Runde!") }
        return String(localized: "Tippe eine Hand- und eine Tischkarte zum Tauschen.")
    }

    private var vorschauKarte: some View {
        VStack(spacing: Design.Abstand.xs) {
            Text(verbatim: vorschauText).font(.subheadline.weight(auswahlVollstaendig ? .semibold : .regular)).multilineTextAlignment(.center)
            if let t = tippText { Text(verbatim: t).font(.footnote).multilineTextAlignment(.center).tischHinweis(zeilen: 3) }
        }
        .frame(maxWidth: .infinity, minHeight: 44).padding(10)
        .background(Tisch.aktiv ? Color.white.opacity(auswahlVollstaendig ? 0.22 : 0.10) : (auswahlVollstaendig ? Color.accentSoft : Color.kartenGrund), in: .rect(cornerRadius: Tisch.aktiv ? 16 : Theme.cardRadius))
        .accessibilityElement(children: .combine)
    }

    // MARK: Knöpfe

    private var knoepfe: some View {
        HStack(spacing: Design.Abstand.s) {
            if sichtbar {
                Button { alleGewaehlt.toggle(); gewaehltHand = nil; gewaehltTisch = nil; tippHand = nil; tippTisch = nil } label: { Text("Alle tauschen").lineLimit(2).minimumScaleFactor(0.6).multilineTextAlignment(.center).frame(maxWidth: gleichBreit) }
                    .buttonStyle(ZweitKnopfStil())
                Button { act { $0.schieben() } } label: { Text("Schieben").lineLimit(2).minimumScaleFactor(0.6).multilineTextAlignment(.center).frame(maxWidth: gleichBreit) }.buttonStyle(ZweitKnopfStil()).disabled(!spiel.kannSchieben)
                if auswahlVollstaendig { Button { tauschen() } label: { Text("Tauschen").frame(maxWidth: gleichBreit) }.buttonStyle(HauptKnopfStil()) }
                else if spiel.kannKlopfen { Button { act { $0.klopfen() } } label: { Text("Klopfen").frame(maxWidth: gleichBreit) }.buttonStyle(HauptKnopfStil()) }
                Button { tippBerechnen() } label: { Image(systemName: "lightbulb") }.tischNebenKnopf().accessibilityLabel("Tipp")
            }
        }
        .frame(minHeight: 44)
    }

    // MARK: Rundenblatt

    private var rundenBlatt: some View {
        VStack(spacing: Theme.kartenAbstand) {
            VStack(alignment: .leading, spacing: Design.Abstand.s) {
                if regeln.modus == .punkte {
                    Text("Runde \(spiel.runde) von \(regeln.runden)").font(.footnote.weight(.semibold)).tischHinweis(zeilen: 1)
                }
                if let f = spiel.feuerVon { Text("\(name(f)) hat \(spiel.hand[f].count == 3 && swPunkte(spiel.hand[f], regeln) >= 33 ? "33" : "31")!").font(.subheadline.weight(.semibold)) }
                ForEach(spiel.teilnehmerDieserRunde, id: \.self) { i in
                    HStack(spacing: Design.Abstand.s) {
                        Text(verbatim: name(i)).font(.headline).lineLimit(1).frame(maxWidth: .infinity, alignment: .leading)
                        HStack(spacing: Design.Abstand.xs) { ForEach(spiel.hand[i], id: \.self) { k in karte(k, hoehe: 62, gewaehlt: false, tipp: false) } }
                        Text(verbatim: SwNamen.zahl(swPunkte(spiel.hand[i], regeln))).font(.headline.monospacedDigit()).frame(width: 44, alignment: .trailing)
                        if spiel.verlierer.contains(i) { Text(verbatim: "−♥").foregroundStyle(Tisch.aktiv ? Tisch.elfenbein : Color.meldungRot).accessibilityLabel("Verliert ein Leben") }
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            .padding(12).frame(maxWidth: .infinity)
            .tischFlaeche(Theme.cardRadius)
            Button(spiel.spielZuEnde ? "Weiter" : "Nächste Runde") { weiterNachRunde() }.buttonStyle(HauptKnopfStil())
            Spacer(minLength: 0)
        }
    }

    // MARK: iPad-Seitenspalte

    private func ereignisText(_ e: SwEreignis) -> String {
        switch e.art {
        case .tauscht(let h, let t): String(localized: "\(name(e.spieler)) tauscht \(SwNamen.karte(h)) gegen \(SwNamen.karte(t))")
        case .tauschtAlle: String(localized: "\(name(e.spieler)) tauscht alle drei")
        case .schiebt: String(localized: "\(name(e.spieler)) schiebt")
        case .klopft: String(localized: "\(name(e.spieler)) klopft")
        case .feuer: String(localized: "\(name(e.spieler)) hat Feuer")
        }
    }

    private var verlaufKarte: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Verlauf").font(.footnote.weight(.semibold)).tischHinweis(zeilen: 1)
            if spiel.verlauf.isEmpty { Text("Noch kein Zug").font(.footnote).tischHinweis(zeilen: 1) }
            else { ForEach(Array(spiel.verlauf.suffix(8).enumerated()), id: \.offset) { _, e in Text(verbatim: ereignisText(e)).font(.footnote).lineLimit(1) } }
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(12)
        .tischFlaeche(Theme.cardRadius)
    }

    private var regelnKarte: some View {
        let r = regeln
        let zeilen: [String] = [
            r.modus == .leben ? String(localized: "\(r.leben) Leben") : String(localized: "Punkte, \(r.runden) Runden"),
            r.feuerSofort ? String(localized: "31 beendet sofort") : String(localized: "31 zählt nur beim Klopfen"),
            r.dreiAssen33 ? String(localized: "Drei Asse = 33") : String(localized: "Drei Gleiche = \(SwNamen.zahl(r.dreiGleiche))"),
            r.schiebenLimit.map { String(localized: "Schieben höchstens \($0)×") } ?? String(localized: "Schieben beliebig oft"),
        ]
        return VStack(alignment: .leading, spacing: Design.Abstand.xs) {
            Text("Regeln dieser Partie").font(.footnote.weight(.semibold)).tischHinweis(zeilen: 1)
            ForEach(zeilen, id: \.self) { Text(verbatim: $0).font(.footnote) }
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(12)
        .tischFlaeche(Theme.cardRadius)
    }

    // MARK: Ablauf

    private func tippeHand(_ i: Int) { alleGewaehlt = false; tippHand = nil; gewaehltHand = gewaehltHand == i ? nil : i }
    private func tippeTisch(_ t: Int) { alleGewaehlt = false; tippTisch = nil; gewaehltTisch = gewaehltTisch == t ? nil : t }

    private func auswahlLoeschen() {
        gewaehltHand = nil; gewaehltTisch = nil; alleGewaehlt = false; tippHand = nil; tippTisch = nil; tippText = nil
    }

    private func tauschen() {
        if alleGewaehlt { act { $0.tauscheAlle() } }
        else if let h = gewaehltHand, let t = gewaehltTisch { act { $0.tauscheEine(hand: h, tisch: t) } }
    }

    private func act(_ f: (inout SchwimmenNeu) -> Void) {
        f(&spiel)
        auswahlLoeschen(); aufgedeckt = false
        pruefe()
    }

    private func tippBerechnen() {
        let hand = spiel.hand[spiel.dran], jetzt = swPunkte(hand, regeln)
        var best: (Double, Int, Int)? = nil
        for h in 0..<3 { for t in 0..<3 {
            let p = spiel.vorschauEine(hand: h, tisch: t)
            if p > jetzt, p > (best?.0 ?? 0) { best = (p, h, t) }
        } }
        if let b = best {
            tippHand = b.1; tippTisch = b.2
            tippText = String(localized: "Tipp: Handkarte \(b.1 + 1) gegen Tischkarte \(b.2 + 1) tauschen bringt \(SwNamen.zahl(b.0)) Punkte.")
        } else {
            tippHand = nil; tippTisch = nil
            tippText = jetzt >= 25 ? String(localized: "Tipp: Klopfen – \(SwNamen.zahl(jetzt)) Punkte sind gut.") : String(localized: "Tipp: Kein Tausch hilft – schieben oder alle drei tauschen.")
        }
        if let t = tippText { UIAccessibility.post(notification: .announcement, argument: t) }
    }

    private func pruefe() {
        guard !spiel.rundeVorbei, computerDran, !denkt else { return }
        denkt = true
        Task { @MainActor in
            await ComputerTempo.warte(.milliseconds(800))
            denkt = false
            guard !spiel.rundeVorbei, computerDran else { return }
            let z = spiel.computerWahl(stufe: stufe.rawValue, mit: &zufall)
            act { $0.fuehreAus(z) }
        }
    }

    private func weiterNachRunde() {
        if spiel.spielZuEnde { melden(); return }
        spiel.neueRunde(mit: &zufall)
        auswahlLoeschen(); aufgedeckt = false
        pruefe()
    }

    /// Blatt 22 (EB-1): Runden und Dauer als Werte, dazu das Blatt des Siegers als Bild.
    private func endeMitInhalt(_ e: SpielEnde, sieger s: Int) -> SpielEnde {
        var e = e
        // Blatt 22 (EB2): „Bestes Blatt“ nur, wenn der Stand es kennt (Stände von vor dem Update: keine Zeile).
        var w = [EndeWert("Runden", "\(spiel.runde)")]
        if let b = spiel.bestesBlatt, let von = spiel.bestesBlattVon, teilnehmer.indices.contains(von) { w.append(EndeWert("Bestes Blatt", "\(SwNamen.zahl(b)) (\(name(von)))")) }
        e.werte = w + [.dauer]
        e.bild = SchwimmenEndeBild.bild(hand: spiel.hand[s], name: name(s))
        return e
    }

    private func melden() {
        guard !gemeldet else { return }
        gemeldet = true
        let ordnung = spiel.rangfolge
        let s = spiel.sieger ?? ordnung[0]
        if regeln.modus == .punkte {
            let doppelt = ordnung.map { Int(spiel.summen[$0] * 2) }
            let e = SpielEnde.nachPunkten(namen: ordnung.map(name), punkte: doppelt, info: String(localized: "\(name(s)) gewinnt"))
            ende(endeMitInhalt(SpielEnde(reihenfolge: e.reihenfolge, punkte: ordnung.map { SwNamen.zahl(spiel.summen[$0]) }, plaetze: e.plaetze, info: e.info), sieger: s))
        } else {
            ende(endeMitInhalt(SpielEnde(reihenfolge: ordnung.map(name), punkte: ordnung.map(wertText), info: String(localized: "\(name(s)) bleibt übrig")), sieger: s))
        }
    }
}
#endif
