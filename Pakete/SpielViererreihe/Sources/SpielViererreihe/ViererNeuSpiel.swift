// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import SpielHilfen

/// 1.0 (M7): „Wer beginnt“ über den gemeinsamen Baustein `StartSpieler` (SpieleKern), Schlüssel = Spielkennung.
enum NeuBeginn {
    static let spiel = "viererreihe-neu"
    static func naechster() -> Int { StartSpieler.naechster(spiel) }
    static func merke(_ beginner: Int) { StartSpieler.merke(beginner, spiel: spiel) }
}

/// Spielbildschirm der neuen Viererreihe: Kopf, Spielerleiste, Einwurf-Reihe, Brett, darunter Verlauf und Stand statt Leerraum.
/// Gegen den Computer mit Leiste; zu zweit steht das Brett aufrecht und mittig, Gegenüber-Chip oben um 180° gedreht.
struct ViererNeuSpiel: View {
    let teilnehmer: [SpielTeilnehmer]
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    /// (Siege, Partien) dieses Spiels – für die Karte „Stand“.
    let bilanz: () -> (siege: Int, partien: Int)
    /// Game Center: Online-Partie mit einem Freund. `nil` = wie bisher am Gerät oder gegen den Computer.
    let online: ViererOnlineLink?

    @State private var spiel: NeuSpiel
    @State private var vorschau: Int?
    @State private var denkt = false
    @State private var tipp: Int?
    @State private var tippRechnet = false
    @State private var faellt: Zelle?
    @State private var fall: CGFloat = 0
    @State private var gemeldet = false
    @State private var neuFragen = false
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.dynamicTypeSize) private var schrift
    @Environment(\.designArt) private var art
    @Environment(\.colorScheme) private var farbschema
    @Environment(\.accessibilityReduceTransparency) private var transparenzReduziert
    private var werte: BrettWerte { BrettWerte(art: art, dunkel: farbschema == .dark, transparenzReduziert: transparenzReduziert) }

    static let stufenSchluessel = "partie.stufe.viererreihe-neu"
    static var gespeicherteStufe: Stufe { Stufe(rawValue: UserDefaults.standard.string(forKey: stufenSchluessel) ?? "") ?? .mittel }

    init(teilnehmer: [SpielTeilnehmer], ende: @escaping (SpielEnde) -> Void, abbrechen: @escaping () -> Void, bilanz: @escaping () -> (siege: Int, partien: Int), vorgabe: NeuSpiel? = nil, online: ViererOnlineLink? = nil) {
        self.online = online
        self.teilnehmer = online == nil ? SpielTeilnehmer.menschZuerst(teilnehmer) : teilnehmer   // F21-013: Der Computer ist hier fest Spieler 2; steht er oben in der Liste, wird getauscht
        self.ende = ende; self.abbrechen = abbrechen; self.bilanz = bilanz
        _spiel = State(initialValue: vorgabe ?? NeuSpiel(zweiSpieler: !teilnehmer.contains(where: \.computer), stufe: Self.gespeicherteStufe, beginner: NeuBeginn.naechster()))
    }

    private func name(_ s: Int) -> String { teilnehmer[s].name }
    private var schriftStufe: Int { schrift >= .accessibility1 ? 2 : (schrift >= .xxxLarge ? 1 : 0) }
    private func steinFarbe(_ spieler: Int) -> Color { spieler == 1 ? Color(.systemRed) : Color(.systemBlue) }

    // MARK: Aufbau

    var body: some View {
        GeometryReader { geo in
            let layout = Layout.entscheide(breite: geo.size.width, hoehe: geo.size.height, kompakteBreite: sizeClass == .compact)
            Group {
                switch layout {
                case .kompakt: hoch(geo.size, rand: Theme.seitenRand)
                case .breitHoch:
                    if Tisch.aktiv && !schrift.isAccessibilitySize {   // Blatt 16 (iPad, Tinte): ganze Breite mit 20 pt Rand, Brett bis 113 pt je Zelle (vorher 680 pt Höchstbreite)
                        hoch(geo.size, rand: 20, hoechsteKante: 113, hoeheBegrenzt: true)
                    } else {
                        hoch(geo.size, rand: max(Theme.seitenRand, (geo.size.width - 680) / 2))
                    }
                case .breitQuer: quer(geo.size)
                }
            }
        }
        .aufTisch()   // Design-Runde 3: Tinte = Filz bis in die Ecken, sonst Seitengrund
        .modifier(LokalFortsetzbar(aktiv: online == nil, spiel: $spiel, standGeladen: { NeuBeginn.merke(spiel.partie.beginner); weiter() }))   // 1.0 (M7); Online-Partien liegen bei Game Center, nicht hier
        .onChange(of: online?.fern) { _, fern in uebernehmeFern(fern) }
        .onAppear { uebernehmeFern(online?.fern) }
        .weicheAnimation(bei: spiel.partie.zuege)
        .spielHaptik(zug: spiel.partie.zuege, erfolg: spiel.partie.status == .gewonnen && spiel.partie.gewinner == 1)
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .confirmationDialog("Neues Spiel beginnen?", isPresented: $neuFragen, titleVisibility: .visible) {
            Button("Neu beginnen", role: .destructive) { neuBeginnen() }
            Button("Abbrechen", role: .cancel) {}
        } message: { Text("Die laufende Partie geht verloren.") }
        .onAppear { weiter() }
        .onChange(of: spiel.partie.zuege.count) { _, _ in weiter() }
        .modifier(TastenEingabe { spalte in wirfMensch(spalte) })
        #if DEBUG
        .testEndeMelden { wirfMensch(0) }   // -testZustand ende: der Gewinnzug (Spalte 1) wird nach dem Laden als normaler Einwurf gespielt
        #endif
    }

    private func kopf() -> some View {
        SpielKopf(mitte: spiel.laeuft ? String(localized: "\(name(spiel.dran)) ist dran") : kopfEnde, mitteKurz: spiel.laeuft ? name(spiel.dran) : nil, linksAktion: abbrechen) {
            RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                FragNachDenRegelnMenuePunkt()   // KI-3 (Blatt 12): nur mit Apple Intelligence sichtbar
                if !spiel.zweiSpieler {
                    Picker("Stärke des Computers", selection: Binding(get: { spiel.stufe }, set: { stufeWaehlen($0) })) {
                        Text("Leicht").tag(Stufe.leicht); Text("Mittel").tag(Stufe.mittel)
                        Text("Geübt").tag(Stufe.geuebt); Text("Stark").tag(Stufe.stark)
                    }
                }
                if online == nil {
                    Button("Neues Spiel", systemImage: "arrow.counterclockwise") { if spiel.partie.zuege.isEmpty { neuBeginnen() } else { neuFragen = true } }
                }
                Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
            }
        }
    }

    private var kopfEnde: String {
        switch spiel.partie.gewinner { case .some(let g): String(localized: "\(name(g - 1)) gewinnt"); case nil: String(localized: "Unentschieden") }
    }

    // iPhone und iPad hoch
    private func hoch(_ groesse: CGSize, rand: CGFloat, hoechsteKante: CGFloat = 97, hoeheBegrenzt: Bool = false) -> some View {
        let m = NeuMasse.hochformat(breite: groesse.width, hoehe: groesse.height, rand: rand, hoechsteKante: hoechsteKante, hoeheBegrenzt: hoeheBegrenzt)
        let zweit = spiel.zweiSpieler
        return VStack(spacing: NeuMasse.abstand) {
            kopf()
            if zweit { chip(1).rotationEffect(.degrees(online == nil ? 180 : 0)).padding(.horizontal, rand) } else { leiste.padding(.horizontal, rand) }
            Spacer(minLength: 0).frame(maxHeight: zweit ? max((m.rest) / 2, 0) : 0)
            feld(m)
            if zweit { chip(0).padding(.horizontal, rand) }
            Spacer(minLength: 0).frame(maxHeight: zweit ? max((m.rest) / 2, 0) : 0)
            if !zweit { kartenReihe(m, rand: rand) }
            knoepfe.padding(.horizontal, rand)
            if !zweit { Spacer(minLength: 0) }
        }
        .padding(.bottom, 4)
    }

    // iPad quer: Brett links, Seitenleiste rechts
    private func quer(_ groesse: CGSize) -> some View {
        let seite = Layout.seitenleiste(breite: groesse.width)
        let m = NeuMasse.quer(breite: groesse.width, hoehe: groesse.height, seitenleiste: seite)
        return VStack(spacing: NeuMasse.abstand) {
            kopf()
            HStack(alignment: .top, spacing: Design.Abstand.xl) {
                feld(m).frame(maxHeight: .infinity, alignment: .center)
                VStack(spacing: NeuMasse.abstand) {
                    if spiel.zweiSpieler { chip(1).rotationEffect(.degrees(online == nil ? 180 : 0)); chip(0) } else { leiste }
                    verlaufKarte(anzahl: 20)
                    standKarte(mitQuote: true)
                    Spacer(minLength: 0)
                    knoepfe
                }
                .frame(width: seite)
            }
            .padding(.horizontal, 24)
        }
        .padding(.bottom, 8)
    }

    // MARK: Spielerleiste und Chips

    private var leiste: some View {
        SpielerLeiste(eintraege: (0..<2).map { i in
            SpielerLeiste.Eintrag(id: "\(i)", name: name(i), farbe: steinFarbe(i + 1), wert: String(localized: "\(spiel.partie.steine(von: i + 1)) Steine"))
        }, aktiv: spiel.laeuft ? "\(spiel.dran)" : nil)
    }

    /// Chip eines Spielers für „zu zweit“; der obere wird vom Aufrufer um 180° gedreht.
    private func chip(_ i: Int) -> some View {
        let dran = spiel.laeuft && spiel.dran == i
        return HStack(spacing: 10) {
            SpielerAvatar(name: name(i), farbe: steinFarbe(i + 1), groesse: 32)
            Text(verbatim: name(i)).font(.subheadline.weight(dran ? .semibold : .regular)).lineLimit(1)
            Spacer(minLength: 4)
            Text("\(spiel.partie.steine(von: i + 1)) Steine").font(.footnote.monospacedDigit()).foregroundStyle(Color.schrift.opacity(0.8))
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(Tisch.aktiv ? Color.white.opacity(dran ? 0.22 : 0.10) : (dran ? Color.accentSoft : Color.kartenGrund), in: .rect(cornerRadius: Tisch.aktiv ? 16 : Theme.cardRadius))   // Tinte: runde Fläche auf dem Filz
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "\(name(i)), ") + Text("\(spiel.partie.steine(von: i + 1)) Steine") + (dran ? Text(verbatim: ", ") + Text("ist dran") : Text(verbatim: "")))
    }

    // MARK: Einwurf-Reihe und Brett

    private func feld(_ m: NeuMasse) -> some View {
        VStack(spacing: 0) {
            einwurfReihe(m)
            brett(m)
        }
        .frame(width: m.brettBreite)
        .contentShape(Rectangle())
        .gesture(DragGesture(minimumDistance: 0)
            .onChanged { w in vorschau = spiel.laeuft && !denkt && !spiel.computerDran && meinZug ? spalte(bei: w.location, m) : nil }
            .onEnded { w in
                vorschau = nil
                if let s = spalte(bei: w.location, m) { wirfMensch(s) }
            })
        .accessibilityRepresentation {
            VStack {
                ForEach(0..<Partie.spalten, id: \.self) { s in
                    Button { wirfMensch(s) } label: { Text(spaltenText(s)) }
                        .disabled(!spiel.partie.legaleSpalten.contains(s) || denkt || spiel.computerDran || !meinZug)
                }
            }
        }
    }

    private func spalte(bei p: CGPoint, _ m: NeuMasse) -> Int? {
        guard p.x >= 0, p.x < m.brettBreite, p.y >= -8, p.y <= m.einwurfHoehe + m.brettHoehe + 8 else { return nil }
        return min(max(Int(p.x / m.kante), 0), Partie.spalten - 1)
    }

    private func spaltenText(_ s: Int) -> String {
        let frei = Partie.zeilen - spiel.partie.brett[s].filter { $0 != 0 }.count
        let kopf = frei == 0 ? String(localized: "Spalte \(s + 1), voll") : String(localized: "Spalte \(s + 1), frei")
        // C-043: Inhalt der Spalte von unten nach oben mit Namen der Steinbesitzer
        let steine = spiel.partie.brett[s].filter { $0 != 0 }.map { name($0 - 1) }
        return steine.isEmpty ? kopf : kopf + ": " + steine.joined(separator: ", ")
    }

    private func einwurfReihe(_ m: NeuMasse) -> some View {
        HStack(spacing: 0) {
            ForEach(0..<Partie.spalten, id: \.self) { s in
                ZStack {
                    if let v = vorschau, v == s, spiel.partie.legaleSpalten.contains(s) {
                        stein(spiel.partie.naechsterSpieler, kante: m.kante).transition(.opacity)
                    } else if tipp == s {
                        Image(systemName: "lightbulb.fill").foregroundStyle(.yellow).font(.system(size: m.kante * 0.45))   // design:spielinhalt (Größe folgt der Zellenkante)
                    } else {
                        spaltenZahl(s + 1, kante: m.kante)
                    }
                }
                .frame(width: m.kante, height: m.einwurfHoehe)
            }
        }
        .animation(.easeOut(duration: 0.12), value: vorschau)
        .accessibilityHidden(true)
    }

    /// Spaltenzahl über dem Brett: Klar wie bisher; Tinte und Salon in „Schrift zweit“, 15 pt (Salon Serife).
    @ViewBuilder
    private func spaltenZahl(_ n: Int, kante: CGFloat) -> some View {
        if art == .klar {
            Text(verbatim: "\(n)").font(.system(size: kante * 0.3, weight: .medium, design: Design.zahlDesign)).foregroundStyle(Color.schrift.opacity(0.8))   // design:spielinhalt; G-010/P-013: Kontrast mindestens 4,5:1
        } else {
            Text(verbatim: "\(n)")
                .font(art == .salon ? Design.Schrift.serif(15, gewicht: .medium, relativ: .callout, hoechstens: 1.3) : .system(size: 15, weight: .medium, design: Design.zahlDesign))
                .foregroundStyle(Color.schrift.opacity(0.8))
        }
    }

    private func brett(_ m: NeuMasse) -> some View {
        let reihen = Set(spiel.partie.gewinnZellen)
        let w = werte
        if w.glas { return AnyView(glasBrett(m, reihen: reihen, w: w)) }
        return AnyView(altesBrett(m, reihen: reihen, w: w))
    }

    /// Glasplatte (Tinte und Salon): echte Ausschnitte, Steine als Linsen; Werte in `Glas`.
    private func glasBrett(_ m: NeuMasse, reihen: Set<Zelle>, w: BrettWerte) -> some View {
        ZStack(alignment: .topLeading) {
            GlasPlatte(werte: w, spalten: Partie.spalten, zeilen: Partie.zeilen, kante: m.kante, glasFarbe: Color.appFlaeche)
            ZStack(alignment: .topLeading) {
                ForEach(0..<Partie.spalten, id: \.self) { s in
                    ForEach(0..<Partie.zeilen, id: \.self) { z in
                        let zelle = Zelle(spalte: s, zeile: z)
                        let besitzer = spiel.partie.brett[s][z]
                        ZStack {
                            if besitzer != 0 {
                                stein(besitzer, kante: m.kante)
                                    .offset(y: faellt == zelle ? -fall * CGFloat(Partie.zeilen - z) * m.kante : 0)
                                    .overlay { if reihen.contains(zelle) { Circle().strokeBorder(.white, lineWidth: 3).padding(w.steinAbstand(m.kante)) } }
                            }
                        }
                        .frame(width: m.kante, height: m.kante)
                        .offset(x: CGFloat(s) * m.kante, y: CGFloat(Partie.zeilen - 1 - z) * m.kante)
                    }
                }
            }
            .frame(width: m.brettBreite, height: m.brettHoehe, alignment: .topLeading)
            .clipShape(.rect(cornerRadius: Glas.radius))
        }
        .frame(width: m.brettBreite, height: m.brettHoehe, alignment: .topLeading)
        .accessibilityHidden(true)
    }

    private func altesBrett(_ m: NeuMasse, reihen: Set<Zelle>, w: BrettWerte) -> some View {
        ZStack(alignment: .topLeading) {
            // Designwechsel D.4: Maße und Farben stehen in `BrettWerte` (Klar wie bisher; Tinte: Feldgrund mit Tinte-Rand; Salon: Spielart-Farbe, gestanzte Löcher, Sockel)
            RoundedRectangle(cornerRadius: w.radius).fill(w.flaeche).frame(width: m.brettBreite, height: m.brettHoehe + w.sockel)
            if art == .tinte { RoundedRectangle(cornerRadius: w.radius).strokeBorder(Color.linieStark, lineWidth: BrettWerte.tintenLinie).frame(width: m.brettBreite, height: m.brettHoehe) }
            if w.sockel > 0 { Rectangle().fill(w.brettDunkel).frame(width: m.brettBreite, height: w.sockel).offset(y: m.brettHoehe) }
            ForEach(0..<Partie.spalten, id: \.self) { s in
                ForEach(0..<Partie.zeilen, id: \.self) { z in
                    let zelle = Zelle(spalte: s, zeile: z)
                    let besitzer = spiel.partie.brett[s][z]
                    ZStack {
                        Circle().fill(w.loch).padding(w.lochAbstand(m.kante))
                            .overlay { if w.gestanzt { Circle().strokeBorder(w.lochLinie, lineWidth: w.lochLinieBreite).padding(w.lochAbstand(m.kante)) } }
                        if besitzer != 0 {
                            stein(besitzer, kante: m.kante)
                                .offset(y: faellt == zelle ? -fall * CGFloat(Partie.zeilen - z) * m.kante : 0)
                                .overlay { if reihen.contains(zelle) { Circle().strokeBorder(.white, lineWidth: 3).padding(w.steinAbstand(m.kante)) } }
                        }
                    }
                    .frame(width: m.kante, height: m.kante)
                    .offset(x: CGFloat(s) * m.kante, y: CGFloat(Partie.zeilen - 1 - z) * m.kante)
                }
            }
        }
        .frame(width: m.brettBreite, height: m.brettHoehe + w.sockel, alignment: .topLeading)
        .clipShape(.rect(cornerRadius: w.radius))
        .accessibilityHidden(true)
    }

    @Environment(\.farbenUnterscheidbar) private var farbenUnterscheidbar

    @ViewBuilder
    private func stein(_ spieler: Int, kante: CGFloat) -> some View {
        if werte.glas {
            GlasLinse(farbe: steinFarbe(spieler), durchmesser: kante * werte.steinAnteil)
                .overlay { if farbenUnterscheidbar && spieler == 2 { Circle().strokeBorder(.white.opacity(0.85), lineWidth: kante * 0.07).padding(kante * 0.24) } }
                .frame(width: kante, height: kante)
        } else { alterStein(spieler, kante: kante) }
    }

    private func alterStein(_ spieler: Int, kante: CGFloat) -> some View {
        Circle().fill(steinFarbe(spieler)).padding(werte.steinAbstand(kante))
            .overlay { if werte.gestanzt { Circle().strokeBorder(BrettWerte.abdunkeln(steinFarbe(spieler), BrettWerte.steinDunkler), lineWidth: BrettWerte.steinRing).padding(werte.steinAbstand(kante) + kante * 0.07) } }
            .overlay { if art == .klar && werte.dunkel { Circle().strokeBorder(.white.opacity(0.55), lineWidth: 1.5).padding(werte.steinAbstand(kante)) } }   // M-022: heller Rand, Steine heben sich im Dunkeln ab
            .overlay { if farbenUnterscheidbar && spieler == 2 { Circle().strokeBorder(.white.opacity(0.85), lineWidth: kante * 0.07).padding(kante * 0.24) } }
            .frame(width: kante, height: kante)
    }

    // MARK: Karten

    @ViewBuilder
    private func kartenReihe(_ m: NeuMasse, rand: CGFloat) -> some View {
        let k = m.karten(schrift: schriftStufe)
        if !k.isEmpty {
            VStack(spacing: NeuMasse.abstand) {
                HStack(alignment: .top, spacing: NeuMasse.abstand) {
                    if k.contains(.verlauf) { verlaufKarte(anzahl: 8) }
                    if k.contains(.stand) { standKarte(mitQuote: false) }
                }
                if k.contains(.quote) { quoteKarte }
            }
            .padding(.horizontal, rand)
        }
    }

    private func verlaufKarte(anzahl: Int) -> some View {
        let zuege = NeuVerlauf.letzte(spiel.partie, anzahl: anzahl)
        return VStack(alignment: .leading, spacing: Design.Abstand.s) {
            Text("Letzte Züge").font(.footnote.weight(.semibold)).foregroundStyle(.secondary)
            if zuege.isEmpty {
                Text("Noch kein Zug").font(.footnote).foregroundStyle(.tertiary)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 34), spacing: 6)], alignment: .leading, spacing: 6) {
                    ForEach(zuege) { z in
                        VStack(spacing: 2) {
                            Circle().fill(steinFarbe(z.spieler)).frame(width: 20, height: 20)
                            Text(verbatim: "\(z.spalte + 1)").font(.caption2.monospacedDigit()).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(12)
        .tischFlaeche(Theme.cardRadius)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Letzte Züge")).accessibilityValue(Text(verbatim: zuege.map { "\($0.spalte + 1)" }.joined(separator: ", ")))
    }

    private func standKarte(mitQuote: Bool) -> some View {
        let b = bilanz()
        return VStack(alignment: .leading, spacing: 6) {
            Text("Stand").font(.footnote.weight(.semibold)).foregroundStyle(.secondary)
            Text("Zug \(spiel.partie.zuege.count + (spiel.laeuft ? 1 : 0)) von \(Partie.felder)").font(.subheadline.monospacedDigit())
            Text("\(spiel.partie.steine(von: 1)) : \(spiel.partie.steine(von: 2)) Steine").font(.subheadline.monospacedDigit()).foregroundStyle(.secondary)
            if mitQuote, let q = neuQuote(siege: b.siege, partien: b.partien) { quoteBalken(q, b) }
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(12)
        .tischFlaeche(Theme.cardRadius)
        .accessibilityElement(children: .combine)
    }

    private var quoteKarte: some View {
        let b = bilanz()
        return VStack(alignment: .leading, spacing: 6) {
            Text("Siegquote").font(.footnote.weight(.semibold)).foregroundStyle(.secondary)
            if let q = neuQuote(siege: b.siege, partien: b.partien) { quoteBalken(q, b) } else { Text("Noch keine Partie").font(.footnote).foregroundStyle(.tertiary) }
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(12)
        .tischFlaeche(Theme.cardRadius)
        .accessibilityElement(children: .combine)
    }

    private func quoteBalken(_ q: Double, _ b: (siege: Int, partien: Int)) -> some View {
        VStack(alignment: .leading, spacing: Design.Abstand.xs) {
            ProgressView(value: q).tint(Color.appFlaeche)
            Text("\(b.siege) Siege in \(b.partien) Partien").font(.caption).foregroundStyle(.secondary)
        }
    }

    // MARK: Knöpfe

    private var knoepfe: some View {
        ZugKnoepfe(kannZurueck: online == nil && spiel.kannZurueck && !denkt && spiel.laeuft, tippMoeglich: online == nil && spiel.laeuft && !spiel.computerDran && !denkt, rechnet: tippRechnet,
                   zurueck: { tipp = nil; spiel.zurueck() }, tipp: holeTipp)
    }

    // MARK: Ablauf

    private func wirfMensch(_ s: Int) {
        guard spiel.laeuft, !denkt, !spiel.computerDran, meinZug else { return }
        let vorher = spiel.partie.zuege.count
        setze(s)
        if let online, spiel.partie.zuege.count > vorher { online.senden(spiel.partie) }
    }

    /// Online: Bin ich dran? Sonst bleibt das Brett gesperrt, bis der Zug des Freundes ankommt.
    private var meinZug: Bool { online.map { spiel.partie.naechsterSpieler == $0.meineNummer } ?? true }

    /// Online: Übernimmt den Stand vom Netz, wenn er weiter ist als der eigene (gleiche Partie, mehr Züge).
    private func uebernehmeFern(_ fern: Partie?) {
        guard online != nil, let fern, ViererOnlineDaten.uebernehmen(fern: fern, eigen: spiel.partie) else { return }
        tipp = nil
        spiel.partie = fern
    }

    private func setze(_ s: Int) {
        guard let zeile = Optional(spiel.partie.brett[s].filter { $0 != 0 }.count), zeile < Partie.zeilen else { return }
        let zieher = spiel.dran
        guard spiel.wirf(s) else { return }
        if teilnehmer[zieher].computer { UIAccessibility.post(notification: .announcement, argument: name(zieher) + ": " + String(localized: "Spalte \(s + 1)")) }   // C-043
        tipp = nil
        faellt = Zelle(spalte: s, zeile: zeile); fall = 1
        withAnimation(.easeIn(duration: 0.3)) { fall = 0 }
    }

    /// Nach jedem Zug: Ende melden oder den Computer ziehen lassen.
    private func weiter() {
        if !spiel.laeuft { melden(); return }
        guard spiel.computerDran, !denkt else { return }
        denkt = true
        let stand = spiel.partie
        let stufe = spiel.stufe
        var zufall = spiel.zufall
        Task { @MainActor in
            await ComputerTempo.warte(.milliseconds(500))
            let (spalte, neuerZufall) = await Task.detached { () -> (Int, SplitMix64) in
                var z = zufall
                let s = Computer.waehle(stufe, stand, zufall: &z)
                return (s, z)
            }.value
            zufall = neuerZufall
            denkt = false
            guard spiel.partie == stand else { return }
            spiel.zufall = zufall
            setze(spalte)
        }
    }

    private func melden() {
        guard !gemeldet else { return }
        gemeldet = true
        if online == nil { NeuBeginn.merke(spiel.partie.beginner) }   // F21-005: Wer diese Partie begonnen hat, gilt sicher für die Revanche (nicht nur beim Erscheinen gemerkt)
        let stand = spiel.partie   // Wert festhalten: der Rahmen kennt den Spielstand danach nicht mehr
        let g = stand.gewinner
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(g == nil ? 600 : 1100))   // Gewinnreihe kurz zeigen
            let ordnung = g.map { [$0 - 1, 2 - $0] } ?? [0, 1]
            // G-017: Der Rahmen zeigt den Sieger bzw. „Remis“ schon als Überschrift; ein Untertitel „Anna gewinnt“ wäre doppelt.
            var e = SpielEnde(reihenfolge: ordnung.map(name), plaetze: g == nil ? [1, 1] : nil)
            if g != nil { e.info = String(localized: "Vier in einer Reihe nach \(stand.zuege.count) Zügen.") }   // Schritt 2; bei Unentschieden kein Satz
            // Blatt 22 (EB-3): Züge, Dauer und das Brett am Ende (die vier Steine markiert)
            e.werte = [EndeWert("Züge", "\(stand.zuege.count)"), .dauer]
            e.bild = EndeBild(Text("Brett am Ende"), hoehe: 290) { groesse in VierEndeBild(partie: stand, groesse: groesse) }
            ende(e)
        }
    }

    private func holeTipp() {
        tippRechnet = true
        let stand = spiel.partie
        Task { @MainActor in
            let s = await Task.detached { StarkerComputer(zeitlimit: 0.6).waehle(stand) }.value
            if spiel.partie == stand { tipp = s; spiel.tippBenutzt = true }
            tippRechnet = false
        }
    }

    private func neuBeginnen() {
        tipp = nil; faellt = nil
        let beginner = NeuBeginn.naechster()   // 1.0 (M7): Wer beginnt, abwechselnd = der andere
        spiel = NeuSpiel(zweiSpieler: spiel.zweiSpieler, stufe: spiel.stufe, beginner: beginner)
        NeuBeginn.merke(beginner)
        weiter()
    }

    private func stufeWaehlen(_ s: Stufe) {
        spiel.stufe = s
        UserDefaults.standard.set(s.rawValue, forKey: Self.stufenSchluessel)
    }
}

/// Speichert den Stand für „Weiterspielen“ (nur Partien am Gerät). Online-Partien liegen bei Game Center und würden sonst die gespeicherte Partie überschreiben.
private struct LokalFortsetzbar: ViewModifier {
    let aktiv: Bool
    @Binding var spiel: NeuSpiel
    let standGeladen: @MainActor () -> Void
    func body(content: Content) -> some View {
        if aktiv {
            content.fortsetzbar(ViererreiheModul.kennung, $spiel, pruefen: { $0.istFortsetzbar }, standGeladen: { _ in standGeladen() })
        } else {
            content
        }
    }
}

/// Tastatur am iPad: Ziffern 1–7 werfen in die Spalte.
private struct TastenEingabe: ViewModifier {
    let wirf: (Int) -> Void
    func body(content: Content) -> some View {
        content.focusable().onKeyPress(characters: CharacterSet(charactersIn: "1234567")) { taste in
            guard let n = taste.characters.first?.wholeNumberValue else { return .ignored }
            wirf(n - 1); return .handled
        }
    }
}
#endif
