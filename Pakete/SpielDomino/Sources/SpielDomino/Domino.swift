// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import SpielHilfen
import DominoKern

@MainActor
public struct DominoModul: SpielModul {
    /// `hoechstAugen` 6 = klassisches Domino, 9 = Doppel-Neun (Dominó Cubano: `DominoModul(id: "dominocubano", name: "Dominó Cubano", hoechstAugen: 9, handgroesse: 10)`).
    public init(id: String = "domino", name: String = "Domino", hoechstAugen: Int = 6, handgroesse: Int? = nil) {
        self.id = id; self.name = name; self.hoechstAugen = hoechstAugen; self.handgroesse = handgroesse
    }
    public let id: String
    public let name: String
    let hoechstAugen: Int
    let handgroesse: Int?
    public let gattung = Gattung.brett
    public let farbe = AkzentFarbeWert.schiefer
    public let symbol = "rectangle.split.2x1.fill"
    public let spielerzahl = 2...4
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "Lege Stein an Stein", farbe: farbe, spieler: 2...4, computerErlaubt: true,
                            regeln: hoechstAugen == 9 ? "Es gibt 55 Steine mit Augen von 0 bis 9. Jeder bekommt zehn Steine, der Rest ist der Vorrat. Gespielt wird wie beim klassischen Domino: Steine passend an eines der beiden Kettenenden legen, ohne passenden Stein ziehst du nach, ist der Vorrat leer, passt du. Wer zuerst alle Steine los ist, gewinnt; kommt niemand weiter, gewinnt die kleinste Augensumme." : "Es gibt 28 Steine mit Augen von 0 bis 6. Jeder bekommt sieben Steine (zu dritt oder viert fünf), der Rest ist der Vorrat. Es beginnt, wer den höchsten Pasch (Stein mit zwei gleichen Seiten) hat, sonst den Stein mit den meisten Augen. Wer dran ist, legt einen Stein an ein Ende der Kette, und zwar so, dass die Augen aneinanderpassen. Hast du keinen passenden Stein, ziehst du aus dem Vorrat, bis einer passt; ist der Vorrat leer, musst du passen. Wer als Erster keine Steine mehr hat, gewinnt. Kommt niemand mehr weiter, gewinnt, wer die wenigsten Augen auf der Hand hat. Tippe einen Stein an, dann das Kettenende, wo er hin soll (passt er nur an eine Seite, geht er gleich dorthin).",
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            DominoSpiel(hoechstAugen: hoechstAugen, handgroesse: handgroesse, teilnehmer: teilnehmer, ende: ende, abbrechen: abbrechen, spielID: id)
        }.mitZiel("Lege als Erster alle deine Steine an die Kette. Kommt niemand mehr weiter, gewinnt, wer die wenigsten Augen hat.").mitAnleitung([
            .figuren(symbol: "rectangle.split.2x1", titel: "Anlegen", text: "Lege einen Stein so an, dass die Augen an einem Ende der Reihe übereinstimmen.", figuren: ["🁣", "🁤"], bewegt: nil),
            .figuren(symbol: "tray.and.arrow.down", titel: "Ziehen oder passen", text: "Kannst du nicht anlegen, ziehst du aus dem Vorrat oder passt.", figuren: ["🁣", "📥"], bewegt: nil),
            .figuren(symbol: "flag.checkered", titel: "Hand leeren", text: "Wer zuerst alle Steine gelegt hat, gewinnt die Runde.", figuren: ["🁣", "🏁"], bewegt: nil),
        ]))
    }
}

struct DominoStein: View {
    let stein: Stein
    var senkrecht = true
    var gewaehlt = false
    var gedimmt = false
    var body: some View {
        let layout = senkrecht ? AnyLayout(VStackLayout(spacing: 0)) : AnyLayout(HStackLayout(spacing: 0))
        layout {
            Hälfte(augen: stein.a)
            Rectangle().fill(.secondary.opacity(0.5)).frame(width: senkrecht ? 30 : 1.5, height: senkrecht ? 1.5 : 30)
            Hälfte(augen: stein.b)
        }
        .padding(2)
        .background(RoundedRectangle(cornerRadius: 7).fill(Color.kartenGrund))
        .overlay(RoundedRectangle(cornerRadius: 7).stroke(gewaehlt ? Color.appFlaeche : .secondary.opacity(0.5), lineWidth: gewaehlt ? 3 : 1))
        .opacity(gedimmt ? 0.4 : 1)
        .accessibilityLabel(Text(verbatim: "\(stein.a)-\(stein.b)"))
    }
}

struct Hälfte: View {
    let augen: Int
    var body: some View {
        // Punktmuster auf 3×3-Raster
        let muster: [Int: [Int]] = [0: [], 1: [4], 2: [0, 8], 3: [0, 4, 8], 4: [0, 2, 6, 8], 5: [0, 2, 4, 6, 8], 6: [0, 2, 3, 5, 6, 8], 7: [0, 2, 3, 4, 5, 6, 8], 8: [0, 1, 2, 3, 5, 6, 7, 8], 9: [0, 1, 2, 3, 4, 5, 6, 7, 8]]
        Canvas { ctx, size in
            for i in muster[augen] ?? [] {
                let c = CGPoint(x: size.width * (CGFloat(i % 3) + 0.5) / 3, y: size.height * (CGFloat(i / 3) + 0.5) / 3)
                ctx.fill(Path(ellipseIn: CGRect(x: c.x - 3, y: c.y - 3, width: 6, height: 6)), with: .color(.primary))
            }
        }.frame(width: 30, height: 30)
    }
}

struct DominoSpiel: View {
    let teilnehmer: [SpielTeilnehmer]
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    let spielID: String
    @State private var spiel: Domino
    @State private var tipp: Int?   // F4
    @State private var zufall = SystemRandomNumberGenerator()
    @State private var gewaehlt: Int?
    @State private var gemeldet = false
    @State private var tick = 0
    @State private var stufe = ComputerStufe.gespeichert("domino")
    private var fehler: Double { switch stufe { case .leicht: 0.5; case .mittel: 0.15; case .schwer: 0 } }

    init(hoechstAugen: Int = 6, handgroesse: Int? = nil, teilnehmer: [SpielTeilnehmer], ende: @escaping (SpielEnde) -> Void, abbrechen: @escaping () -> Void, spielID: String = "domino") {
        self.teilnehmer = teilnehmer; self.ende = ende; self.abbrechen = abbrechen; self.spielID = spielID
        var g = SystemRandomNumberGenerator()
        _spiel = State(initialValue: Domino(spieler: teilnehmer.count, hoechstAugen: hoechstAugen, handgroesse: handgroesse, mit: &g))
    }

    private var amZugComputer: Bool { teilnehmer[spiel.amZug].computer }
    private var sicht: Int { teilnehmer.sicht(amZug: spiel.amZug) }
    private var kannHandeln: Bool { spiel.sieger == nil && !amZugComputer }

    var body: some View {
        VStack(spacing: Theme.kartenAbstand) {
            SpielKopf(mitte: spiel.sieger == nil ? String(localized: "\(teilnehmer[spiel.amZug].name) ist dran") : String(localized: "Spielende"), linksAktion: abbrechen) {
                RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                    if teilnehmer.contains(where: \.computer) { ComputerStufePicker(spiel: "domino", stufe: $stufe) }
                    Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
                }
            }
            HStack(spacing: Design.Abstand.s) {
                ForEach(teilnehmer.indices.filter { $0 != sicht }, id: \.self) { i in
                    VStack(spacing: 2) {
                        Text(verbatim: teilnehmer[i].name).font(.footnote).lineLimit(1).minimumScaleFactor(0.7)
                        Label("\(spiel.haende[i].count)", systemImage: "rectangle.split.2x1").font(.subheadline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: Design.Ecke.feld).fill(i == spiel.amZug ? Color.appFlaeche.opacity(0.25) : Color.kartenGrund))
                }
                Label("Vorrat \(spiel.vorrat.count)", systemImage: "square.stack").font(.footnote).padding(8)
            }.padding(.horizontal, Theme.seitenRand)
            Spacer(minLength: 0)
            kette
            Spacer(minLength: 0)
            eigene
        }
        .background(Color.seitenGrund)
        .fortsetzbar(spielID, $spiel)
        .weicheAnimation(bei: spiel)
        .spielHaptik(zug: spiel, erfolg: spiel.sieger != nil)
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .uebergabeSeite(teilnehmer: teilnehmer, amZug: spiel.amZug, aktiv: spiel.sieger == nil)
        .task(id: "\(spiel.amZug)-\(spiel.kette.count)-\(spiel.vorrat.count)-\(tick)") {
            guard amZugComputer, spiel.sieger == nil else { return }
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            guard !Task.isCancelled else { return }
            spiel.computerSchritt(fehler: fehler, mit: &zufall); tick += 1; pruefe()
        }
    }

    private var kette: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Design.Abstand.xs) {
                    Button { setze(.links) } label: { Image(systemName: "arrow.left.to.line").frame(width: 44, height: 70) }
                        .accessibilityLabel("Links anlegen")
                        .disabled(!(gewaehlt.map { g in spiel.passt(spiel.haende[sicht][g], an: .links) } ?? false) || !kannHandeln || spiel.kette.isEmpty)
                    ForEach(spiel.kette.indices, id: \.self) { i in
                        DominoStein(stein: spiel.kette[i], senkrecht: false).id(i)
                    }
                    if spiel.kette.isEmpty { Text("Lege den ersten Stein.").font(.footnote).foregroundStyle(.secondary).padding() }
                    Button { setze(.rechts) } label: { Image(systemName: "arrow.right.to.line").frame(width: 44, height: 70) }
                        .accessibilityLabel("Rechts anlegen")
                        .disabled(!(gewaehlt.map { g in spiel.kette.isEmpty || spiel.passt(spiel.haende[sicht][g], an: .rechts) } ?? false) || !kannHandeln)
                }.padding(.horizontal, Theme.seitenRand)
            }
            .onChange(of: spiel.kette.count) { _, n in withAnimation { proxy.scrollTo(n - 1, anchor: .trailing) } }
        }.frame(height: 80)
    }

    private var eigene: some View {
        VStack(spacing: Design.Abstand.s) {
            HStack(spacing: Design.Abstand.m) {
                if kannHandeln, spiel.mussZiehen { Button("Stein ziehen") { spiel.ziehe(); tick += 1 }.buttonStyle(HauptKnopfStil()) }
                if kannHandeln, spiel.mussPassen { Button("Passen") { spiel.passe(); tick += 1; pruefe() }.buttonStyle(ZweitKnopfStil()) }
                if kannHandeln, sicht == spiel.amZug, !spiel.mussZiehen, !spiel.mussPassen {
                    Button { tipp = spiel.haende[sicht].indices.first { i in let s = spiel.haende[sicht][i]; return spiel.kette.isEmpty || spiel.passt(s, an: .links) || spiel.passt(s, an: .rechts) } ; tippAnsage() } label: { Label("Tipp", systemImage: "lightbulb") }.nebenKnopf().dynamicTypeSize(...DynamicTypeSize.xxxLarge)   // F4
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Design.Abstand.s) {
                    ForEach(spiel.haende[sicht].indices, id: \.self) { i in
                        let s = spiel.haende[sicht][i]
                        let geht = sicht == spiel.amZug && (spiel.kette.isEmpty || spiel.passt(s, an: .links) || spiel.passt(s, an: .rechts))
                        DominoStein(stein: s, gewaehlt: gewaehlt == i, gedimmt: sicht == spiel.amZug && !geht)
                            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.yellow, lineWidth: 4).opacity(tipp == i ? 1 : 0))
                            .onTapGesture { tipp = nil; tippe(i, geht: geht) }
                            .accessibilityAddTraits(.isButton).accessibilityAddTraits(gewaehlt == i ? .isSelected : [])
                            .accessibilityValue(tipp == i ? Text("Tipp") : Text(verbatim: ""))
                    }
                }.padding(.horizontal, Theme.seitenRand).padding(.vertical, 6)
            }
            Text(kannHandeln ? String(localized: "Summe deiner Augen: \(spiel.summe(sicht))") : " ").font(.footnote).foregroundStyle(.secondary)
        }.padding(.bottom, 8)
    }

    /// F4/G1: Tipp auch hörbar.
    private func tippAnsage() {
        guard let i = tipp else { UIAccessibility.post(notification: .announcement, argument: String(localized: "Kein Stein passt – du musst nachziehen oder passen.")); return }
        let st = spiel.haende[sicht][i]
        UIAccessibility.post(notification: .announcement, argument: String(localized: "Tipp: Stein \(i + 1) von \(spiel.haende[sicht].count), \(st.a) zu \(st.b), passt an die Kette."))
    }

    private func tippe(_ i: Int, geht: Bool) {
        guard kannHandeln, geht else { return }
        let s = spiel.haende[sicht][i]
        if spiel.kette.isEmpty { spiel.lege(i, seite: .rechts); gewaehlt = nil; tick += 1; pruefe(); return }
        let l = spiel.passt(s, an: .links), r = spiel.passt(s, an: .rechts)
        if l != r { spiel.lege(i, seite: l ? .links : .rechts); gewaehlt = nil; tick += 1; pruefe() }
        else { gewaehlt = gewaehlt == i ? nil : i }
    }

    private func setze(_ seite: Seite) {
        guard let g = gewaehlt else { return }
        spiel.lege(g, seite: seite); gewaehlt = nil; tick += 1; pruefe()
    }

    private func pruefe() {
        guard let w = spiel.sieger, !gemeldet else { return }
        gemeldet = true
        let summen = teilnehmer.indices.map { spiel.summe($0) }
        let rang = teilnehmer.indices.sorted { a, b in a == w ? true : (b == w ? false : summen[a] < summen[b]) }
        Task {
            try? await Task.sleep(nanoseconds: 900_000_000)
            ende(SpielEnde(reihenfolge: rang.map { teilnehmer[$0].name }, punkte: rang.map { String(localized: "\(summen[$0]) Augen übrig") },
                           info: spiel.blockiert ? String(localized: "Das Spiel hat sich festgefahren") : nil))
        }
    }
}
#endif
