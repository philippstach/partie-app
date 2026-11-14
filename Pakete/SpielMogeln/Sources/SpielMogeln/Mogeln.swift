// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import MogelnKern

@MainActor
public struct MogelnModul: SpielModul {
    public init() {}
    public let id = "mogeln"
    public let name = "Mogeln"
    public let gattung = Gattung.karten
    public let farbe = AkzentFarbeWert.gruen
    public let symbol = "theatermasks.fill"
    public let spielerzahl = 3...6
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "Ablegen, behaupten, erwischen", farbe: farbe, spieler: 3...6, computerErlaubt: true,
                            regeln: "Alle Karten werden verteilt. Reihum legst du ein bis vier Karten verdeckt auf den Haufen und behauptest, es seien Karten des geforderten Rangs (zuerst 7, dann 8, 9, 10, Bube, Dame, König, Ass und wieder von vorn). Das darf gelogen sein. Der Nächste kann „Gelogen!“ rufen: Die Karten werden aufgedeckt. Stimmte die Behauptung, nimmt der Zweifler den ganzen Haufen, sonst der Lügner. Wer zuerst keine Karten mehr hat und nicht überführt wird, gewinnt.",
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            MogelnSpiel(teilnehmer: teilnehmer, ende: ende, abbrechen: abbrechen)
        }.mitZiel("Werde alle Karten los, ohne beim Mogeln erwischt zu werden. Wer zuerst keine hat, gewinnt.")
        .mitZielSchrittNeu(.ziel("Werde alle Karten los, ohne beim Mogeln erwischt zu werden. Ihr legt Karten verdeckt ab und behauptet, sie hätten den geforderten Rang. Lügen ist erlaubt. Ihr spielt zu dritt bis zu sechst, gern auch mit dem Computer."))   // B25: neue deutsche Anleitung (RegelTexteNeu), die alte bleibt für alle anderen Sprachen
        .mitAnleitung(RegelTexteNeu.anleitung(neu: [
            .figuren(symbol: "arrow.up.right", titel: "Der Rang steigt", text: "In der Mitte steht, welcher Rang gefordert ist. Es beginnt mit der 7. Mit jedem Zug steigt er um eins: 8, 9, 10, Bube, Dame, König, Ass, dann wieder 7. Die Farbe ist egal. Den Rang suchst du dir nicht aus.", figuren: ["7", "→", "8", "→", "9", "→", "10"], bewegt: nil),
            .figuren(symbol: "square.and.arrow.down", titel: "Verdeckt legen", text: "Lege ein bis vier Karten verdeckt ab und behaupte, es seien Karten des geforderten Rangs. Passen gibt es nicht. Hast du keine passende Karte, lügst du einfach. Auch ehrlich darfst du weniger legen, als du hast.", figuren: ["🂠", "🂠"], bewegt: nil),
            .figuren(symbol: "exclamationmark.bubble", titel: "Gelogen!", text: "Nur der Nächste entscheidet: glauben oder „Gelogen!“ rufen. Dann werden die zuletzt gelegten Karten aufgedeckt. Stimmte die Behauptung, nimmt der Zweifler den ganzen Haufen, sonst der Lügner. Wer den Haufen nimmt, legt als Nächster.", figuren: ["🤥", "❗️"], bewegt: nil),
            .figuren(symbol: "tray.full", titel: "Gewinnen", text: "Wer seine letzte Karte legt, gewinnt erst, wenn er dabei nicht erwischt wird. Eine Tipp-Zeile sagt dir beim Entscheiden, wie wahrscheinlich die Ansage stimmt. Sie rechnet mit deinen eigenen Karten. Hast du selbst drei Damen, kann „zwei Damen“ nicht stimmen.", figuren: ["🂡", "🏁"], bewegt: nil),
        ], alt: [
            .figuren(symbol: "square.and.arrow.down", titel: "Verdeckt legen", text: "Lege ein bis vier Karten verdeckt ab und behaupte, es seien Karten des geforderten Rangs.", figuren: ["🂠", "🂠"], bewegt: nil),
            .figuren(symbol: "exclamationmark.bubble", titel: "Gelogen!", text: "Du darfst lügen. Der Nächste kann „Gelogen!“ rufen, dann werden die Karten aufgedeckt.", figuren: ["🤥", "❗️"], bewegt: nil),
            .figuren(symbol: "tray.full", titel: "Haufen nehmen", text: "Stimmte es, nimmt der Zweifler den Haufen, sonst der Lügner. Wer zuerst keine Karten hat, gewinnt.", figuren: ["🂡", "🏁"], bewegt: nil),
        ])))
    }
}

/// Karte der eigenen Hand (Designwechsel D.2: Papier, Rand, Rot/Schwarz vom Kartenstil; in „Klar & Glas“ wie bisher).
struct MHandKarte: View {
    let karte: MoKarte
    var gewaehlt = false
    var breit = false   // Blatt 16b (iPad, nur Tinte): 58 × 84 statt 52 × 76
    var body: some View {
        let b: CGFloat = breit ? 58 : 52, h: CGFloat = breit ? 84 : 76
        Group {
            if KartenSatz.istGewaehlt {   // gewählter Kartensatz (Blatt 17/19): Kartenbild und Figuren vom Satz
                KartenIndex(rang: karte.kurz, zeichen: karte.symbol, farbe: KartenStil.aktuell.farbe(rot: karte.farbe >= 2), breite: b, hoehe: h)
            } else {
                VStack(spacing: 0) { Text(karte.kurz).font(.system(.title3, design: Design.zahlDesign).weight(.bold)); Text(karte.symbol).font(.title2) }
            }
        }
            .foregroundStyle(KartenStil.aktuell.farbe(rot: karte.farbe >= 2))
            .frame(width: b, height: h)
            .kartenPapier(ecke: Design.Ecke.klein, breite: b, gewaehlt: gewaehlt)
    }
}

/// Blatt 16b (iPad): Karten in Zeilen, jede Zeile mittig (das Gitter `.adaptive` setzt die letzte Zeile nach links).
private struct MittigeZeilen: Layout {
    var abstand: CGFloat = 6
    private func zeilen(_ breite: CGFloat, _ subviews: Subviews) -> [[Int]] {
        var z: [[Int]] = [[]]; var x: CGFloat = 0
        for (i, v) in subviews.enumerated() {
            let w = v.sizeThatFits(.unspecified).width
            if x > 0, x + abstand + w > breite { z.append([]); x = 0 }
            x += (x > 0 ? abstand : 0) + w; z[z.count - 1].append(i)
        }
        return z
    }
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let b = proposal.width ?? 600
        let z = zeilen(b, subviews)
        let h = subviews.first?.sizeThatFits(.unspecified).height ?? 0
        return CGSize(width: b, height: CGFloat(z.count) * h + CGFloat(max(0, z.count - 1)) * abstand)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let z = zeilen(bounds.width, subviews)
        var y = bounds.minY
        for zeile in z {
            let ws = zeile.map { subviews[$0].sizeThatFits(.unspecified).width }
            let gesamt = ws.reduce(0, +) + CGFloat(max(0, zeile.count - 1)) * abstand
            var x = bounds.minX + (bounds.width - gesamt) / 2
            var hoehe: CGFloat = 0
            for (n, i) in zeile.enumerated() {
                let sz = subviews[i].sizeThatFits(.unspecified)
                subviews[i].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(sz))
                x += ws[n] + abstand; hoehe = max(hoehe, sz.height)
            }
            y += hoehe + abstand
        }
    }
}

struct MogelnSpiel: View {
    let teilnehmer: [SpielTeilnehmer]
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    @State private var spiel: Mogeln
    @State private var zufall = SystemRandomNumberGenerator()
    @State private var aufgedeckt = false
    @State private var gewaehlt: Set<Int> = []
    @State private var meldung: String?
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.dynamicTypeSize) private var schrift
    /// Blatt 16b (iPad, nur Tinte): Handkarten 58 pt und mittig. iPhone unverändert.
    private var breitTisch: Bool { sizeClass == .regular && Tisch.aktiv && !schrift.isAccessibilitySize }

    init(teilnehmer: [SpielTeilnehmer], ende: @escaping (SpielEnde) -> Void, abbrechen: @escaping () -> Void, vorgabe: Mogeln? = nil) {   // vorgabe: nur für Bildtests
        self.teilnehmer = teilnehmer; self.ende = ende; self.abbrechen = abbrechen
        var g = SystemRandomNumberGenerator()
        _spiel = State(initialValue: vorgabe ?? Mogeln(spieler: teilnehmer.count, mit: &g))
    }

    @State private var stufe = ComputerStufe.gespeichert("mogeln")
    /// Hinweis für den Menschen am Zug: Wie wahrscheinlich ist die Behauptung, und lohnt sich das Anzweifeln?
    private var tippText: LocalizedStringKey {
        let p = MogelnComputer.wahrheitsChance(spiel, spieler: spiel.dran)
        let prozent = Int((p * 100).rounded())
        if p == 0 { return "Tipp: Das kann nicht stimmen – anzweifeln lohnt sich." }
        if p < 0.3 { return "Tipp: Die Ansage ist nur zu etwa \(prozent) % wahr – anzweifeln lohnt sich." }
        return "Tipp: Die Ansage ist zu etwa \(prozent) % wahr."
    }
    /// Name des geforderten Rangs in der Sprache des Geräts. Der Kern liefert nur den Wert (7…14);
    /// die Wörter Bube, Dame, König, Ass stehen wie bei den anderen Kartenspielen im Katalog.
    private func rangName(_ wert: Int) -> String {
        switch wert {
        case 11: String(localized: "Bube")
        case 12: String(localized: "Dame")
        case 13: String(localized: "König")
        case 14: String(localized: "Ass")
        default: "\(wert)"
        }
    }
    private var computerDran: Bool { teilnehmer[spiel.dran].computer }

    var body: some View {
        VStack(spacing: Theme.kartenAbstand) {
            SpielKopf(mitte: teilnehmer[spiel.dran].name, linksAktion: abbrechen) {
                RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                    FragNachDenRegelnMenuePunkt()   // KI-3 (Blatt 12): nur mit Apple Intelligence sichtbar
                    if teilnehmer.contains(where: \.computer) { ComputerStufePicker(spiel: "mogeln", stufe: $stufe) }
                    NeuePartieMenuePunkt()   // T-075: „Neue Partie“ wie in allen Spielen
                    Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
                }
            }
            SpielerLeiste(eintraege: teilnehmer.indices.map { .init(id: "\($0)", name: teilnehmer[$0].name, farbe: Spieler.farbe($0), wert: "\(spiel.haende[$0].count)") }, aktiv: "\(spiel.dran)")
                .padding(.horizontal, Theme.seitenRand)
            VStack(spacing: 6) {
                TischUeberschrift("Gefordert")
                Text(rangName(spiel.rang)).font(.system(.largeTitle, design: Design.zahlDesign).weight(.bold)).foregroundStyle(Tisch.aktiv ? Tisch.elfenbein : Color.accentText)
                Text("Haufen: \(spiel.haufen.count) Karten").font(.footnote).tischHinweis(zeilen: 1)
                if let m = meldung { Text(m).font(.subheadline.weight(.semibold)).multilineTextAlignment(.center) }
            }.frame(maxWidth: .infinity).spielTischKarte().padding(.horizontal, Theme.seitenRand)
            Spacer(minLength: 0)
            if let w = spiel.gewinner {
                Button("Ergebnis") { fertig(w) }.buttonStyle(HauptKnopfStil()).padding(.horizontal, Theme.seitenRand).padding(.bottom, 8)
            } else if computerDran {
                Text("\(teilnehmer[spiel.dran].name) denkt nach …").tischHinweis(zeilen: 1).padding(.bottom, 16)
            } else if spiel.phase == .entscheiden, let letzter = spiel.letzter {
                VStack(spacing: Design.Abstand.s) {
                    Text(spiel.letzteAnzahl == 1 ? String(localized: "\(teilnehmer[letzter].name) legt 1 Karte (\(rangName(spiel.rang))). Glaubst du das?") : String(localized: "\(teilnehmer[letzter].name) legt \(spiel.letzteAnzahl) Karten (\(rangName(spiel.rang))). Glaubst du das?")).font(.headline).multilineTextAlignment(.center)
                    Text(tippText).font(.footnote).multilineTextAlignment(.center).tischHinweis(zeilen: 3)
                    HStack(spacing: Design.Abstand.s) {
                        Button("Glauben") { spiel.glauben(); meldung = nil; aufgedeckt = true }.buttonStyle(ZweitKnopfStil())   // T-096: dieselbe Person hält das Gerät schon, kein zweiter Sichtschutz
                        Button("Gelogen!") { zweifeln() }.buttonStyle(HauptKnopfStil())
                    }
                }.padding(.horizontal, Theme.seitenRand).padding(.bottom, 8)
            } else if !aufgedeckt && teilnehmer.mehrereMenschen {
                SichtschutzKarte(name: teilnehmer[spiel.dran].name, farbe: Spieler.farbe(spiel.dran)) { aufgedeckt = true }
                    .padding(.horizontal, Theme.seitenRand).padding(.bottom, 8)
            } else {
                // Die Hand umbricht in Zeilen, damit keine Karte aus dem Bild läuft.
                ScrollView(.vertical, showsIndicators: false) {
                    handKarten.padding(.horizontal, Theme.seitenRand)
                }
                .scrollBounceBehavior(.basedOnSize).frame(maxHeight: 250)
                Button(gewaehlt.isEmpty ? String(localized: "Karten wählen") : String(localized: "\(gewaehlt.count) Karte(n) als \(rangName(spiel.rang)) ablegen")) { lege() }
                    .buttonStyle(HauptKnopfStil()).disabled(gewaehlt.isEmpty).padding(.horizontal, Theme.seitenRand).padding(.bottom, 8)
            }
        }
        .aufTisch()   // Design-Runde 3: in Tinte Filz bis in die Ecken, sonst Seitengrund wie bisher
        #if DEBUG
        .testEndeMelden { if let w = spiel.gewinner { fertig(w) } }   // -testZustand ende: das Ende wird nach dem Laden des Endstands selbst gemeldet
        #endif
        .fortsetzbar("mogeln", $spiel, pruefen: { $0.haende.count == teilnehmer.count && $0.istKonsistent })
        .weicheAnimation(bei: [spiel.haufen.count, spiel.dran, spiel.haende.reduce(0) { $0 + $1.count }])
        .spielHaptik(zug: [spiel.haufen.count, spiel.dran, spiel.haende.reduce(0) { $0 + $1.count }], erfolg: spiel.gewinner != nil)
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        // Der Computer hängt am Stand, nicht am Erscheinen: Er zieht auch nach dem Laden eines Stands, in dem er am Zug ist.
        .computerZug(aktiv: spiel.gewinner == nil && computerDran, id: "\(spiel.dran)-\(spiel.phase)-\(spiel.rang)-\(spiel.haufen.count)") {
            guard spiel.gewinner == nil, computerDran else { return }
            switch spiel.phase {
            case .legen: spiel.lege(MogelnComputer.lege(spiel))
            case .entscheiden:
                if MogelnComputer.zweifelt(spiel, spieler: spiel.dran, stufe: stufe.rawValue, mit: &zufall) { zweifeln() } else { spiel.glauben() }
            }
        }
    }

    /// Die Hand: auf dem iPad (Tinte) mittig in Zeilen mit 58-pt-Karten, sonst wie bisher das adaptive Gitter.
    @ViewBuilder private var handKarten: some View {
        if breitTisch {
            MittigeZeilen { handKnoepfe }.frame(maxWidth: .infinity)
        } else {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 52), spacing: 6)], spacing: 6) { handKnoepfe }
        }
    }

    @ViewBuilder private var handKnoepfe: some View {
        ForEach(Array(spiel.haende[spiel.dran].enumerated()), id: \.offset) { i, k in
            Button { if gewaehlt.contains(i) { gewaehlt.remove(i) } else if gewaehlt.count < 4 { gewaehlt.insert(i) } } label: {
                MHandKarte(karte: k, gewaehlt: gewaehlt.contains(i), breit: breitTisch)
            }.buttonStyle(.plain)
                .accessibilityLabel(Text(verbatim: Kartensprache.name(rang: k.kurz, symbol: k.symbol)))
                .accessibilityAddTraits(gewaehlt.contains(i) ? .isSelected : [])
        }
    }

    private func lege() {
        guard spiel.lege(Array(gewaehlt)) else { return }
        gewaehlt = []; aufgedeckt = false
    }

    private func zweifeln() {
        spiel.anzweifeln()
        if let a = spiel.aufdeckung {
            let karten = a.karten.map { $0.kurz + $0.symbol }.joined(separator: " ")
            let nimmt = teilnehmer[a.verlierer].name
            meldung = a.gelogen ? String(localized: "Gelogen! Aufgedeckt: \(karten). \(nimmt) nimmt den Haufen.")
                                : String(localized: "Stimmte! Aufgedeckt: \(karten). \(nimmt) nimmt den Haufen.")
        }
        aufgedeckt = false
    }

    private func fertig(_ w: Int) {
        let rest = teilnehmer.indices.filter { $0 != w }.sorted { spiel.haende[$0].count < spiel.haende[$1].count }
        let o = [w] + rest
        var e = SpielEnde(reihenfolge: o.map { teilnehmer[$0].name }, punkte: o.map { "\(spiel.haende[$0].count)" }, info: String(localized: "\(teilnehmer[w].name) gewinnt"))
        // Blatt 22 (EB-1): Dauer als Wert, dazu die Resthände der anderen als Bild.
        // Blatt 22 (EB2): Zweifel-Zähler, nur wenn der Stand sie kennt (Stände von vor dem Update: keine Zeilen).
        var zweifel: [EndeWert] = []
        if let r = spiel.richtigGezweifelt, let f = spiel.falschGezweifelt { zweifel = [EndeWert("Richtig gezweifelt", "\(r.reduce(0, +))"), EndeWert("Falsch gezweifelt", "\(f.reduce(0, +))")] }
        e.werte = zweifel + [.dauer]
        e.bild = MogelnEndeBild.bild(haende: spiel.haende, sieger: w, namen: teilnehmer.map(\.name))
        ende(e)
    }
}
#endif
