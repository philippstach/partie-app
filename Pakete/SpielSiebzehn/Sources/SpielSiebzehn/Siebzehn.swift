// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import SiebzehnKern

@MainActor
public struct SiebzehnModul: SpielModul {
    public init() {}
    public let id = "siebzehnundvier"
    public let name = "Siebzehn und Vier"
    public let gattung = Gattung.karten
    public let farbe = AkzentFarbeWert.gruen
    public let symbol = "suit.diamond.fill"
    public let spielerzahl = 1...4
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "So nah wie möglich an 21", farbe: farbe, spieler: 1...4, computerErlaubt: true,   // K-011/M-013: Computer als Mitspieler wählbar
                            regeln: "Du spielst gegen die Bank. Jeder startet mit 100 Chips (wählbar) und setzt pro Hand 10 (wählbar: 10, 25, 50 oder 100, vor dem Start oder zwischen den Händen). Ziehe Karten, um möglichst nah an 21 zu kommen – wer darüber liegt, verliert. Ass zählt 11 (oder 1), Bilder 10, die übrigen ihren Wert. Mit den ersten zwei Karten darfst du verdoppeln: Der Einsatz wird doppelt, du bekommst genau eine Karte, dann ist deine Hand zu Ende. Die Bank zieht bis mindestens 17. Wer mehr als die Bank hat (ohne 21 zu überschreiten), gewinnt den Einsatz; Ass plus Zehnwert (Siebzehn und Vier) zahlt 1,5-fach, abgerundet. Wer weniger Chips hat, als ein Einsatz kostet, scheidet aus; beende das Spiel jederzeit über das Menü.",
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            SiebzehnSpiel(teilnehmer: teilnehmer, ende: ende, abbrechen: abbrechen)
        }.mitStartOptionen { SiebzehnOptionen(eintraege: $0) }   // 1.0 (M5): Einsatz und Start-Chips schon vor dem Start
        .mitZiel("Komm mit deinen Karten näher an 21 als die Bank, ohne darüber zu kommen. So gewinnst du Chips.")
        .mitZielSchrittNeu(.ziel("Komm mit deinen Karten näher an 21 als die Bank, ohne darüber zu kommen. Jeder spielt für sich gegen die Bank, nicht gegen die anderen. Gespielt wird um Chips: Jede Hand kostet einen Einsatz. Gewinnst du, bekommst du ihn dazu. Das Spiel ist auch als Blackjack bekannt."))   // B25: neue deutsche Anleitung (RegelTexteNeu), die alte bleibt für alle anderen Sprachen
        .mitAnleitung(RegelTexteNeu.anleitung(neu: [
            .figuren(symbol: "plus.rectangle.on.rectangle", titel: "Karten ziehen", text: "Du bekommst zwei Karten. Mit „Karte“ ziehst du eine weitere, mit „Halten“ hörst du auf. Bube, Dame und König zählen 10, das Ass 11 oder 1, die anderen ihre Zahl. Das rechnet die App für dich. Kommst du über 21, hast du dich überkauft und verlierst die Hand sofort.", figuren: ["🂡", "🂻"], bewegt: nil),
            .figuren(symbol: "building.columns", titel: "Die Bank", text: "Eine Karte der Bank siehst du, die zweite liegt verdeckt. Sind alle Spieler fertig, deckt sie auf. Die Bank zieht, bis sie mindestens 17 hat, dann hält sie. Kommt sie über 21, gewinnt jeder, der selbst nicht über 21 ist. Sonst gewinnt, wer mehr hat als die Bank. Gleich viel heißt gleichauf.", figuren: ["🏦", "17"], bewegt: nil),
            .figuren(symbol: "star", titel: "Siebzehn und Vier", text: "Ass und eine Zehnerkarte als erste zwei Karten sind „Siebzehn und Vier“, die beste Hand. Sie zahlt das 1,5-Fache deines Einsatzes, abgerundet. Bei Einsatz 10 bekommst du also 15 Chips. Hat die Bank Siebzehn und Vier, deckt sie sofort auf: Wer auch eins hat, spielt gleichauf, alle anderen verlieren. Eine 21 aus drei Karten ist nur eine gewöhnliche 21.", figuren: ["🪙", "🂡"], bewegt: nil),
            .figuren(symbol: "multiply.circle", titel: "Verdoppeln", text: "Mit den ersten zwei Karten darfst du verdoppeln. Dann setzt du doppelt so viel und bekommst genau eine Karte, danach ist deine Hand fertig. Das lohnt sich, wenn du gut liegst, etwa mit 10 oder 11, und die Bank eine schwache Karte zeigt. Deine Chips müssen für den doppelten Einsatz reichen.", figuren: ["🪙", "→", "🪙🪙"], bewegt: nil),
            .figuren(symbol: "lightbulb", titel: "Chips, Tipp und Ende", text: "Startchips und Einsatz wählst du vor dem Spiel, den Einsatz auch zwischen den Händen unter „Mehr“. Wer den Einsatz nicht mehr zahlen kann, scheidet aus. Unter „Mehr“ → „Spiel abschließen“ beendest du das Spiel, wer die meisten Chips hat, gewinnt. Die Glühbirne rät dir, was du tun solltest.", figuren: ["🪙", "💡", "🏁"], bewegt: nil),
        ], alt: [
            .figuren(symbol: "plus.circle", titel: "Karten ziehen", text: "Ziehe Karten, um möglichst nah an 21 zu kommen. Wer darüber liegt, verliert.", figuren: ["🂡", "🂻"], bewegt: nil),
            .figuren(symbol: "building.columns", titel: "Gegen die Bank", text: "Die Bank zieht bis mindestens 17. Wer mehr hat, gewinnt den Einsatz.", figuren: ["🏦", "17"], bewegt: nil),
            .figuren(symbol: "dollarsign.circle", titel: "Chips", text: "Ass plus Zehnwert zahlt 1,5-fach (abgerundet). Reichen deine Chips nicht mehr für den Einsatz, scheidest du aus.", figuren: ["🪙", "🂡"], bewegt: nil),
        ])))
    }
}

/// 1.0 (M5): Schlüssel der Wahl vor dem Start.
enum SiebzehnWahl {
    static let chipsSchluessel = "partie.regeln.siebzehn.chips"
    static let einsatzSchluessel = "partie.regeln.siebzehn.einsatz"
    static var chips: Int { let c = UserDefaults.standard.integer(forKey: chipsSchluessel); return c == 0 ? 100 : c }
    /// Gewählter Einsatz, nie höher als die Start-Chips (sonst könnte niemand setzen).
    static var einsatz: Int {
        let e = UserDefaults.standard.integer(forKey: einsatzSchluessel)
        let wahl = Siebzehn.einsatzStufen.contains(e) ? e : Siebzehn.einsatz
        return wahl <= chips ? wahl : (Siebzehn.einsatzStufen.last { $0 <= chips } ?? Siebzehn.einsatz)
    }
}

/// 1.0 (M5): Karte im Blatt „Neues Spiel“: Einsatz je Hand (10 / 25 / 50 / 100) und Start-Chips.
struct SiebzehnOptionen: View {
    let eintraege: [SpielerEintrag]
    @AppStorage(SiebzehnWahl.chipsSchluessel) private var chips = 100
    @AppStorage(SiebzehnWahl.einsatzSchluessel) private var einsatz = Siebzehn.einsatz
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Start-Chips", systemImage: "dollarsign.circle").font(.headline).foregroundStyle(Color.accentText)
            Picker("Start-Chips", selection: $chips) {
                Text("50").tag(50); Text("100").tag(100); Text("200").tag(200); Text("500").tag(500)
            }.pickerStyle(.segmented).labelsHidden()
            Label("Einsatz je Hand", systemImage: "circle.stack").font(.headline).foregroundStyle(Color.accentText)
            Picker("Einsatz je Hand", selection: $einsatz) {
                ForEach(Siebzehn.einsatzStufen, id: \.self) { e in Text(verbatim: "\(e)").tag(e) }
            }.pickerStyle(.segmented).labelsHidden()
            if einsatz > chips { Text("Der Einsatz ist höher als die Start-Chips, es gilt der höchste, der passt.").font(.footnote).foregroundStyle(.secondary) }
        }
        .frame(maxWidth: .infinity, alignment: .leading).card()
    }
}

private struct SKartenBild: View {
    let karte: SKarte?
    /// Große Tinte-Runde, Punkt 13: Auf dem iPad sind die Karten in Tinte größer (sonst bleibt die Größe wie bisher).
    var gross = false
    var body: some View {
        SkatKartenBild(karte.flatMap { SkatKarte(farbIndex: $0.farbe, wert: $0.wert) }, groesse: gross ? .gross : .normal)
    }
}

struct SiebzehnSpiel: View {
    let teilnehmer: [SpielTeilnehmer]
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    @AppStorage("partie.regeln.siebzehn.chips") private var chips = 100
    @AppStorage(SiebzehnWahl.einsatzSchluessel) private var einsatzWahl = Siebzehn.einsatz   // 1.0 (M5)
    @State private var spiel: Siebzehn
    @State private var tipp: String?   // F4
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.designArt) private var art   // zeichnet beim Designwechsel neu
    /// Große Tinte-Runde, Punkt 13: größere Karten auf dem iPad, nur in Tinte.
    private var grosseKarten: Bool { art == .tinte && sizeClass == .regular }
    @Environment(\.dynamicTypeSize) private var schriftStufe
    /// Bauplan T3-1 Punkt 2 / Blatt 27: Bank und Spieler teilen die Höhe gleichmäßig (nur breiter Tintentisch, bis zu drei Flächen, nicht bei größter Schrift); sonst die ScrollView wie bisher.
    private var gleicheHoehe: Bool { grosseKarten && !schriftStufe.isAccessibilitySize && spiel.spieler.filter { !$0.isEmpty }.count <= 2 }
    private var summenSchrift: Font { gleicheHoehe ? .system(size: 56, weight: .bold).monospacedDigit() : .title2.weight(.bold).monospacedDigit() }
    @ViewBuilder private func flaechenBehaelter<C: View>(@ViewBuilder _ inhalt: () -> C) -> some View {
        if gleicheHoehe { inhalt().frame(maxHeight: .infinity) } else { ScrollView { inhalt() } }
    }

    /// Grundstrategie: bis 11 immer Karte; 12–16 je nach offener Bankkarte; ab 17 halten.
    private func grundstrategie() -> String {
        guard spiel.spieler.indices.contains(spiel.dran) else { return "" }
        let summe = siebzehnSumme(spiel.spieler[spiel.dran])
        let bank = spiel.bank.first?.augen ?? 10
        if spiel.kannVerdoppeln, Siebzehn.computerVerdoppelt(hand: spiel.spieler[spiel.dran], bankOffen: bank) {   // 1.0 (M5)
            return String(localized: "Tipp: Verdoppeln – \(summe) gegen \(bank) der Bank ist eine gute Lage.")
        }
        if summe <= 11 { return String(localized: "Tipp: Noch eine Karte – mehr als 21 ist unmöglich.") }
        if summe >= 17 { return String(localized: "Tipp: Halten – \(summe) ist stark genug.") }
        return bank >= 7 ? String(localized: "Tipp: Karte – die Bank zeigt \(bank), da reicht \(summe) selten.")
                         : String(localized: "Tipp: Halten – die Bank zeigt \(bank) und überkauft sich oft.")
    }
    @State private var zufall = SystemRandomNumberGenerator()

    /// K-011: Ein Computer-Spieler ist am Zug (er zieht selbst, die Knöpfe ruhen).
    private var computerDran: Bool {
        !spiel.vorbei && !spiel.bankDran && spiel.dran < teilnehmer.count && teilnehmer[spiel.dran].computer
    }

    /// Noch keine Hand gespielt und noch keine Karte gezogen: Wechsel der Chips gibt neu aus.
    private var unberuehrt: Bool { spiel.ausgaenge.isEmpty && !spiel.vorbei && !spiel.bankDran && spiel.dran == 0 && spiel.spieler.allSatisfy { $0.count <= 2 } && spiel.chips.allSatisfy { $0 == spiel.chips[0] } }

    init(teilnehmer: [SpielTeilnehmer], ende: @escaping (SpielEnde) -> Void, abbrechen: @escaping () -> Void) {
        self.teilnehmer = teilnehmer; self.ende = ende; self.abbrechen = abbrechen
        var g = SystemRandomNumberGenerator()
        _spiel = State(initialValue: Siebzehn(spieler: teilnehmer.count, chips: SiebzehnWahl.chips, einsatz: SiebzehnWahl.einsatz, mit: &g))   // 1.0 (M5): gewählter Einsatz
    }

    /// 1.0 (M5): Einsatz je Hand; gilt ab der nächsten Austeilung und wird für die nächste Partie gemerkt.
    private var einsatzBinding: Binding<Int> {
        Binding(get: { spiel.einsatzJeHand }, set: { spiel.setzeEinsatz($0); einsatzWahl = $0 })
    }

    private func ausgangText(_ a: SiebzehnAusgang) -> String {
        switch a {
        case .gewinn: String(localized: "gewinnt")
        case .blackjack: String(localized: "Siebzehn und Vier!")
        case .verlust: String(localized: "verliert")
        case .unentschieden: String(localized: "gleichauf")
        }
    }

    private var tippKnopf: some View {
        Button { tipp = grundstrategie(); UIAccessibility.post(notification: .announcement, argument: tipp) } label: {
            if art == .tinte {
                // Große Tinte-Runde, Punkt 4: In Tinte ein rundes Zeichen ohne Wort, damit Halten, Verdoppeln und Karte nie umbrechen
                Image(systemName: "lightbulb").accessibilityLabel(Text("Tipp"))
            } else {
                Label("Tipp", systemImage: "lightbulb")
            }
        }.tischNebenKnopf().dynamicTypeSize(...DynamicTypeSize.xxxLarge)   // F4
    }
    private var halteKnopf: some View {
        Button("Halten") { tipp = nil; spiel.halten() }.buttonStyle(ZweitKnopfStil()).lineLimit(1).minimumScaleFactor(0.7)
    }
    @ViewBuilder private var verdoppelKnopf: some View {
        if spiel.kannVerdoppeln {   // 1.0 (M5): Verdoppeln nach den ersten zwei Karten
            Button("Verdoppeln") { tipp = nil; spiel.verdoppeln() }.buttonStyle(ZweitKnopfStil()).lineLimit(1).minimumScaleFactor(0.7)
        }
    }
    private var karteKnopf: some View {
        Button("Karte") { tipp = nil; spiel.karte() }.buttonStyle(HauptKnopfStil()).lineLimit(1).minimumScaleFactor(0.7)
    }
    /// Große Tinte-Runde, Punkt 4: Knöpfe brechen nie um. Reicht die Breite nicht (kleines iPhone, große Schrift), stehen sie in zwei Reihen.
    /// Blatt 23: „Über 21“. Auf dem Filz eine helle Marke (Tinte), sonst roter Text wie bisher (S1-013).
    @ViewBuilder private var ueber21Marke: some View {
        if Tisch.aktiv {
            Text("Über 21").font(.caption.weight(.semibold)).foregroundStyle(Tisch.auge)
                .padding(.horizontal, 8).padding(.vertical, 2)
                .background(Capsule().fill(Tisch.elfenbein))
        } else {
            Text("Über 21").font(.caption.weight(.semibold)).foregroundStyle(Color.meldungRot)
        }
    }

    /// Blatt 23: Einsatz für die nächste Hand. Auf dem Filz ein runder heller Knopf mit Menü, sonst der Picker wie bisher.
    @ViewBuilder private var einsatzWahlLeiste: some View {
        if Tisch.aktiv {
            Menu {
                Picker("Einsatz je Hand", selection: einsatzBinding) {
                    ForEach(spiel.moeglicheEinsaetze, id: \.self) { e in Text("Einsatz \(e)").tag(e) }
                }
            } label: {
                Label("Einsatz \(einsatzBinding.wrappedValue)", systemImage: "chevron.up.chevron.down")
                    .labelStyle(.titleAndIcon)
            }
            .tischNebenKnopf()
        } else {
            Picker("Einsatz je Hand", selection: einsatzBinding) {
                ForEach(spiel.moeglicheEinsaetze, id: \.self) { e in Text("Einsatz \(e)").tag(e) }
            }.pickerStyle(.menu)
        }
    }

    private var aktionsReihe: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Design.Abstand.s) { tippKnopf; halteKnopf; verdoppelKnopf; karteKnopf }
            VStack(spacing: Design.Abstand.s) {
                HStack(spacing: Design.Abstand.s) { tippKnopf; halteKnopf }
                HStack(spacing: Design.Abstand.s) { verdoppelKnopf; karteKnopf }
            }
        }
    }

    var body: some View {
        VStack(spacing: Theme.kartenAbstand) {
            SpielKopf(mitte: spiel.vorbei ? String(localized: "Hand beendet") : (spiel.dran < teilnehmer.count ? teilnehmer[spiel.dran].name : String(localized: "Bank")), linksAktion: abbrechen) {
                RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                    FragNachDenRegelnMenuePunkt()   // KI-3 (Blatt 12): nur mit Apple Intelligence sichtbar
                    Picker("Start-Chips", selection: $chips) {
                        Text("50 Chips").tag(50); Text("100 Chips").tag(100); Text("200 Chips").tag(200); Text("500 Chips").tag(500)
                    }
                    .disabled(!unberuehrt)   // nur vor der ersten Entscheidung
                    Picker("Einsatz je Hand", selection: einsatzBinding) {   // 1.0 (M5)
                        ForEach(spiel.moeglicheEinsaetze, id: \.self) { e in Text("Einsatz \(e)").tag(e) }
                    }
                    .disabled(!(unberuehrt || spiel.vorbei))   // vor dem ersten Zug oder zwischen den Händen
                    Button("Spiel abschließen", systemImage: "flag.checkered") { abschliessen() }.disabled(unberuehrt)
                    Button("Spiel verlassen", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
                }
            }
            flaechenBehaelter {
                VStack(spacing: Theme.kartenAbstand) {
                    VStack(alignment: .leading, spacing: 6) {
                        TischUeberschrift("Bank")
                        HStack { ForEach(Array(spiel.bank.enumerated()), id: \.offset) { i, k in SKartenBild(karte: (!spiel.bankDran && i == 1) ? nil : k, gross: grosseKarten) }; Spacer()
                            if spiel.bankDran { Text("\(siebzehnSumme(spiel.bank))").font(summenSchrift).foregroundStyle(Tisch.aktiv ? Tisch.elfenbein : Color.primary).accessibilityLabel(Text("Summe \(siebzehnSumme(spiel.bank))")) } }
                    }.padding(Design.art == .klar || Tisch.aktiv ? 0 : 12).frame(maxHeight: gleicheHoehe ? .infinity : nil).modifier(KartenFlaeche()).accessibilityElement(children: .contain)   // Tinte/Salon: Innenabstand 12 pt, damit der Rahmen des aktiven Spielers nichts anschneidet
                    ForEach(spiel.chips.indices, id: \.self) { i in
                        if !spiel.spieler[i].isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    TischUeberschrift(verbatim: teilnehmer[i].name); Spacer()
                                    Text("\(spiel.chips[i]) Chips · Einsatz \(spiel.einsatzFuer(i))\(spiel.verdoppelt.indices.contains(i) && spiel.verdoppelt[i] ? " ×2" : "")").font(.footnote.weight(.semibold)).tischHinweis(zeilen: 1, sonst: Color.secondary)   // 1.0 (M5): Stand und Einsatz in der Leiste
                                }
                                HStack {
                                    ForEach(Array(spiel.spieler[i].enumerated()), id: \.offset) { _, k in SKartenBild(karte: k, gross: grosseKarten) }; Spacer()
                                    let summe = siebzehnSumme(spiel.spieler[i])
                                    VStack(alignment: .trailing, spacing: 0) {
                                        Text("\(summe)").font(summenSchrift).foregroundStyle(Tisch.aktiv ? Tisch.elfenbein : (summe > 21 ? Color.meldungRot : Color.primary))   // Blatt 23: auf dem Filz kein Rot, „Über 21“ zeigt es
                                        if summe > 21 { ueber21Marke }   // S1-013
                                    }
                                    .accessibilityElement(children: .ignore)
                                    .accessibilityLabel(summe > 21 ? Text("Summe \(summe), über 21") : Text("Summe \(summe)"))
                                }
                                if spiel.vorbei, i < spiel.ausgaenge.count { Text(ausgangText(spiel.ausgaenge[i])).font(.subheadline.weight(.semibold)).foregroundStyle(Tisch.aktiv ? Tisch.elfenbein : Color.accentText) }
                            }
                            .padding(Design.art == .klar || Tisch.aktiv ? 0 : 12)   // Innenabstand im Rahmen (Salon; Tinte: Innenabstand der Tischkarte)
                            .frame(maxHeight: gleicheHoehe ? .infinity : nil)
                            .modifier(KartenFlaeche())
                            .modifier(DranMarke(aktiv: spiel.dran == i && !spiel.vorbei))   // Markierung: Tinte weiche helle Fläche (Punkt 14d), sonst der Rahmen wie bisher
                        }
                    }
                }
                .padding(.horizontal, Theme.seitenRand)
            }
            if spiel.vorbei {
                if spiel.moeglicheEinsaetze.count > 1 && !spiel.aktive.isEmpty && !(teilnehmer.count > 1 && spiel.aktive.count < 2) {   // 1.0 (M5): Einsatz für die nächste Hand
                    einsatzWahlLeiste.padding(.horizontal, Theme.seitenRand)
                }
                Button(spiel.aktive.isEmpty || (teilnehmer.count > 1 && spiel.aktive.count < 2) ? "Ergebnis" : "Nächste Hand") { weiter() }
                    .buttonStyle(HauptKnopfStil()).padding(.horizontal, Theme.seitenRand).padding(.bottom, 8)
            } else {
                if let t = tipp { Text(t).font(.footnote).tischHinweis(sonst: Color.secondary).padding(.horizontal, Theme.seitenRand) }
                aktionsReihe.padding(.horizontal, Theme.seitenRand).padding(.bottom, 8)
                .disabled(computerDran)
            }
        }
        .aufTisch()   // Design-Runde 3: Tinte = Filz bis in die Ecken, sonst Seitengrund
        // K-011/M-013: Computer-Spieler ziehen nach der Grundstrategie, eine Karte nach der anderen
        .task(id: spiel) {
            guard computerDran else { return }
            await ComputerTempo.warte(.milliseconds(700))
            guard !Task.isCancelled, computerDran else { return }
            if spiel.kannVerdoppeln, Siebzehn.computerVerdoppelt(hand: spiel.spieler[spiel.dran], bankOffen: spiel.bank.first?.augen ?? 10) { spiel.verdoppeln(); return }   // 1.0 (M5)
            if Siebzehn.computerNimmtKarte(hand: spiel.spieler[spiel.dran], bankOffen: spiel.bank.first?.augen ?? 10) { spiel.karte() } else { spiel.halten() }
        }
        #if DEBUG
        .testEndeMelden { if spiel.vorbei { weiter() } }   // -testZustand ende: das Ende wird nach dem Laden des Endstands selbst gemeldet
        #endif
        .fortsetzbar("siebzehnundvier", $spiel, pruefen: { [n = teilnehmer.count] in $0.chips.count == n && $0.spieler.count == n && $0.dran >= 0 && $0.dran < n && $0.verdoppelt.count == n && Siebzehn.einsatzStufen.contains($0.einsatzJeHand) })   // C-024
        .weicheAnimation(bei: spiel)
        .spielHaptik(zug: spiel, erfolg: (spiel.vorbei))
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .onChange(of: chips) { _, neu in
            if unberuehrt { var g = SystemRandomNumberGenerator(); spiel = Siebzehn(spieler: teilnehmer.count, chips: neu, einsatz: SiebzehnWahl.einsatz, mit: &g) }
        }
    }

    private func weiter() {
        if spiel.aktive.isEmpty || (teilnehmer.count > 1 && spiel.aktive.count < 2) { abschliessen() } else { spiel.austeilen(mit: &zufall) }
    }

    private func abschliessen() {
        // S1: Allein gespielt gibt es keinen Gegner, also keinen Sieg: Der Chip-Stand zählt als Punktespiel (Bestwert).
        // Wer den Einsatz nicht mehr aufbringen kann, hat verloren.
        if teilnehmer.count == 1 {
            let stand = spiel.chips[0], info = String(localized: "\(stand) Chips")
            var e: SpielEnde = Siebzehn.alleinVerloren(chips: stand) ? .verloren(teilnehmer[0].name, punkte: "\(stand)", info: info)
                                                                    : .punktespiel(teilnehmer[0].name, punkte: "\(stand)", info: info)
            mitInhalt(&e)   // Blatt 22 (EB2): auch das Alleinspiel zeigt Werte und die letzte Hand
            ende(e)
            return
        }
        let o = teilnehmer.indices.sorted { spiel.chips[$0] > spiel.chips[$1] }
        let platz = o.map { i in spiel.chips.filter { $0 > spiel.chips[i] }.count + 1 }
        // Blatt 22 (EB2): Satz nur bei genau einer ersten Person.
        let erste = o.filter { platz[o.firstIndex(of: $0)!] == 1 }
        var e = SpielEnde(reihenfolge: o.map { teilnehmer[$0].name }, punkte: o.map { "\(spiel.chips[$0])" }, plaetze: platz,
                          info: erste.count == 1 ? String(localized: "\(teilnehmer[erste[0]].name) hat die meisten Chips.") : nil)
        mitInhalt(&e)
        ende(e)
    }

    /// Blatt 22 (EB-1, EB2): Hände und größter Gewinn (nur wenn der Stand sie kennt), Dauer, dazu die letzte Hand (Bank und alle Personen) als Bild.
    private func mitInhalt(_ e: inout SpielEnde) {
        var w: [EndeWert] = []
        if let h = spiel.haendeGespielt, let g = spiel.groessterGewinn { w = [EndeWert("Hände", "\(h)"), EndeWert("Größter Gewinn", "\(g)")] }
        e.werte = w + [.dauer]
        e.bild = SiebzehnEndeBild.bild(bank: spiel.bank, haende: spiel.spieler, namen: teilnehmer.map(\.name))
    }
}

/// Große Tinte-Runde, Punkt 14d: Wer dran ist, zeigt in Tinte eine weiche helle Fläche (wie bei Mau-Mau) statt eines harten Rahmens.
/// In Klar und Salon bleibt der Rahmen, wie er war.
private struct DranMarke: ViewModifier {
    let aktiv: Bool
    @Environment(\.designArt) private var art

    @ViewBuilder func body(content: Content) -> some View {
        if art == .tinte {
            content.background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.white.opacity(aktiv ? 0.06 : 0)))
        } else {
            content.overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).strokeBorder(Tisch.aktiv ? Tisch.elfenbein : Color.appFlaeche, lineWidth: aktiv ? 2 : 0))   // design:spielinhalt (Markierung auf dem Spielmaterial)
        }
    }
}

/// Fläche der Spielerkarten: Tinte = runde Tischkarte auf dem Filz (Design-Runde 3), sonst wie bisher `card()`.
private struct KartenFlaeche: ViewModifier {
    func body(content: Content) -> some View {
        if Tisch.aktiv { content.spielTischKarte() } else { content.card() }
    }
}
#endif
