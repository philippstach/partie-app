// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import SpielHilfen
import FarbwechselKern

@MainActor
public struct FarbwechselModul: SpielModul {
    public init() {}
    public let id = "farbwechsel"
    public let name = "Farbwechsel"
    public let gattung = Gattung.karten
    public let farbe = AkzentFarbeWert.violett
    public let symbol = "rectangle.stack.fill"
    public let spielerzahl = 2...4
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "Wer wird zuerst alle Karten los?", farbe: farbe, spieler: 2...4, computerErlaubt: true,
                            regeln: "Jeder bekommt sieben Karten. Wer dran ist, legt eine Karte auf den Ablagestapel: Sie muss dieselbe Farbe oder dieselbe Zahl (oder Aktion) haben wie die oberste Karte. Passt nichts, ziehst du eine Karte; passt sie, darfst du sie gleich legen, sonst ist der Nächste dran. Aktionen: Sprung – der Nächste setzt aus. Wende – die Richtung kehrt sich um (zu zweit wie Sprung). Zwei ziehen – der Nächste nimmt zwei Karten und setzt aus. Der Joker darf immer gelegt werden und wählt die Farbe; der Joker „drei ziehen“ zusätzlich: Der Nächste nimmt drei Karten und setzt aus. Wer als Erster keine Karten mehr hat, gewinnt. Mit mehreren Menschen an einem Gerät erscheint zwischen den Zügen eine Übergabe-Seite.",
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            FarbwechselSpiel(teilnehmer: teilnehmer, ende: ende, abbrechen: abbrechen)
        }.mitZiel("Werde deine Karten als Erster los. Wer keine Karten mehr hat, gewinnt.").mitAnleitung(Self.anleitung))
    }
}

private let kartenFarben: [Color] = [Color(red: 0.80, green: 0.14, blue: 0.22), Color(red: 0.14, green: 0.38, blue: 0.82), Color(red: 0.10, green: 0.60, blue: 0.40), Color(red: 0.90, green: 0.60, blue: 0.08)]

struct KartenBild: View {
    let karte: WKarte
    var gedimmt = false
    var body: some View {
        let farbe: AnyShapeStyle = karte.istJoker ? AnyShapeStyle(AngularGradient(colors: kartenFarben + [kartenFarben[0]], center: .center)) : AnyShapeStyle(kartenFarben[karte.farbe])
        KartenFlaeche(fuellung: farbe, gedimmt: gedimmt, beschriftung: beschreibung) {
            switch karte.art {
            case .zahl(let n): Text(verbatim: "\(n)").font(.system(.title, design: Design.zahlDesign).weight(.bold)).foregroundStyle(.white)
            case .sprung: Image(systemName: "forward.end.fill").font(.title2).foregroundStyle(.white)
            case .wende: Image(systemName: "arrow.left.arrow.right").font(.title2.weight(.bold)).foregroundStyle(.white)
            case .zwei: Text(verbatim: "+2").font(.system(.title, design: Design.zahlDesign).weight(.heavy)).foregroundStyle(.white)
            case .joker: Image(systemName: "sparkles").font(.title).foregroundStyle(.white).shadow(radius: 2)
            case .jokerDrei: Text(verbatim: "+3").font(.system(.title, design: Design.zahlDesign).weight(.heavy)).foregroundStyle(.white).shadow(radius: 2)
            }
        }
    }
    private var beschreibung: Text {
        let f = karte.farbe < 4 ? Text(verbatim: Farbwechsel.farbNamen[karte.farbe] + " ") : Text(verbatim: "")
        switch karte.art {
        case .zahl(let n): return f + Text(verbatim: "\(n)")
        case .sprung: return f + Text("Sprung")
        case .wende: return f + Text("Wende")
        case .zwei: return f + Text("Zwei ziehen")
        case .joker: return Text("Joker")
        case .jokerDrei: return Text("Joker, drei ziehen")
        }
    }
}

struct FarbwechselSpiel: View {
    let teilnehmer: [SpielTeilnehmer]
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    @State private var spiel: Farbwechsel
    @State private var tipp: Int?   // F4
    @State private var zufall = SystemRandomNumberGenerator()
    @State private var stufe = ComputerStufe.gespeichert("farbwechsel")
    private var fehler: Double { switch stufe { case .leicht: 0.4; case .mittel: 0.12; case .schwer: 0 } }
    @State private var jokerWahl: Int?
    @State private var gemeldet = false

    init(teilnehmer: [SpielTeilnehmer], ende: @escaping (SpielEnde) -> Void, abbrechen: @escaping () -> Void) {
        self.teilnehmer = teilnehmer; self.ende = ende; self.abbrechen = abbrechen
        var g = SystemRandomNumberGenerator()
        let gespeichert = SpielStand.laden(Farbwechsel.self, spiel: "farbwechsel")
        _spiel = State(initialValue: gespeichert.flatMap { $0.spieler == teilnehmer.count ? $0 : nil } ?? Farbwechsel(spieler: teilnehmer.count, mit: &g))
    }

    private var menschen: [Int] { teilnehmer.menschen }
    private var amZugComputer: Bool { teilnehmer[spiel.amZug].computer }
    /// Wessen Hand unten gezeigt wird.
    private var sicht: Int { amZugComputer ? (menschen.first ?? 0) : spiel.amZug }
    private var mehrereMenschen: Bool { menschen.count > 1 }

    var body: some View {
        ZStack {
            Color.seitenGrund.ignoresSafeArea()
            VStack(spacing: Theme.kartenAbstand) {
                SpielKopf(mitte: spiel.gewinner == nil ? String(localized: "\(teilnehmer[spiel.amZug].name) ist dran") : String(localized: "Spielende"), linksAktion: abbrechen) {
                    RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                        if teilnehmer.contains(where: \.computer) { ComputerStufePicker(spiel: "farbwechsel", stufe: $stufe) }
                        Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
                    }
                }
                gegner
                Spacer(minLength: 0)
                tisch
                Spacer(minLength: 0)
                if !spiel.meldung.isEmpty { Text(LocalizedStringKey(spiel.meldung)).font(.subheadline.weight(.semibold)).foregroundStyle(Color.accentText) }
                hand
            }
        }
        .spielstand("farbwechsel", spiel)
        .weicheAnimation(bei: spiel)
        .spielHaptik(zug: spiel, erfolg: spiel.gewinner != nil)
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .uebergabeSeite(teilnehmer: teilnehmer, amZug: spiel.amZug, aktiv: spiel.gewinner == nil)
        .task(id: "\(spiel.amZug)-\(spiel.ablage.count)-\(spiel.haende[spiel.amZug].count)-\(spiel.gezogen ?? -1)") {
            guard spiel.gewinner == nil, amZugComputer else { return }
            try? await Task.sleep(nanoseconds: 1_100_000_000)
            guard !Task.isCancelled else { return }
            spiel.computerZug(fehler: fehler, mit: &zufall)
            pruefe()
        }
        .confirmationDialog("Welche Farbe?", isPresented: Binding(get: { jokerWahl != nil }, set: { if !$0 { jokerWahl = nil } }), titleVisibility: .visible) {
            ForEach(0..<4, id: \.self) { f in
                Button(Farbwechsel.farbNamen[f]) { if let i = jokerWahl { lege(i, farbe: f) } }
            }
        }
    }

    private var gegner: some View {
        HStack(spacing: Design.Abstand.s) {
            ForEach(teilnehmer.indices.filter { $0 != sicht }, id: \.self) { i in
                VStack(spacing: 2) {
                    Text(verbatim: teilnehmer[i].name).font(.footnote).lineLimit(1).minimumScaleFactor(0.7)
                    Label("\(spiel.haende[i].count)", systemImage: "rectangle.stack").font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity).padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: Design.Ecke.feld).fill(i == spiel.amZug ? Color.appFlaeche.opacity(0.25) : Color.kartenGrund))
            }
        }.padding(.horizontal, Theme.seitenRand)
    }

    private var tisch: some View {
        HStack(spacing: 28) {
            Button {
                guard kannHandeln else { return }
                spiel.ziehe(mit: &zufall); pruefe()
            } label: {
                RoundedRectangle(cornerRadius: 10).fill(Color.appFlaeche.gradient)
                    .overlay(Text(verbatim: "\(spiel.zieh.count)").font(.headline).foregroundStyle(.white))
                    .frame(width: 58, height: 84)
            }.buttonStyle(.plain).accessibilityLabel(Text("Karte ziehen"))
            ZStack {
                KartenBild(karte: spiel.oben)
                Circle().fill(spiel.farbe < 4 ? kartenFarben[spiel.farbe] : .gray).frame(width: 22, height: 22)
                    .overlay(Circle().stroke(.white, lineWidth: 2)).offset(x: 34, y: -50)
            }
        }
    }

    private var kannHandeln: Bool { spiel.gewinner == nil && !amZugComputer }

    private var hand: some View {
        VStack(spacing: Design.Abstand.s) {
            HStack(spacing: Design.Abstand.m) {
                if spiel.gezogen != nil, kannHandeln {
                    Button("Passen") { spiel.passe(); pruefe() }.nebenKnopf().dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                }
                if kannHandeln, sicht == spiel.amZug, besterTipp() != nil {
                    Button { tipp = besterTipp(); tippAnsage() } label: { Label("Tipp", systemImage: "lightbulb") }.nebenKnopf().dynamicTypeSize(...DynamicTypeSize.xxxLarge)   // F4
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: -14) {
                    ForEach(spiel.haende[sicht].indices, id: \.self) { i in
                        let k = spiel.haende[sicht][i]
                        let ok = sicht == spiel.amZug && spiel.darfLegen(k) && (spiel.gezogen == nil || spiel.gezogen == i)
                        KartenBild(karte: k, gedimmt: sicht == spiel.amZug && !ok)
                            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.yellow, lineWidth: 4).opacity(tipp == i ? 1 : 0))
                            .offset(y: ok && kannHandeln ? -8 : 0)
                            .onTapGesture { tipp = nil; tippe(i, ok: ok) }
                            .accessibilityAddTraits(.isButton)   // G1
                            .accessibilityHint(Text("Doppeltippen, um die Karte zu spielen"))
                            .accessibilityValue(tipp == i ? Text("Tipp") : Text(verbatim: ""))
                    }
                }.padding(.horizontal, Theme.seitenRand).padding(.vertical, 12)
            }
        }.padding(.bottom, 8)
    }

    /// F4: erste legbare Karte, lieber keine Jokerkarte.
    /// F4/G1: Tipp auch hörbar.
    private func tippAnsage() {
        guard let i = tipp else { return }
        let h = spiel.haende[sicht], k = h[i]
        let art: String
        switch k.art {
        case .zahl(let n): art = "\(n)"
        case .sprung: art = String(localized: "Aussetzen")
        case .wende: art = String(localized: "Richtungswechsel")
        case .zwei: art = String(localized: "Zwei ziehen")
        case .joker: art = String(localized: "Joker")
        case .jokerDrei: art = String(localized: "Joker, drei ziehen")
        }
        let farbe = k.farbe < 4 ? [String(localized: "Rot"), String(localized: "Gelb"), String(localized: "Grün"), String(localized: "Blau")][k.farbe] : ""
        UIAccessibility.post(notification: .announcement, argument: String(localized: "Tipp: Karte \(i + 1) von \(h.count), \(farbe) \(art)."))
    }

    private func besterTipp() -> Int? {
        let h = spiel.haende[sicht]
        let ok = h.indices.filter { i in spiel.darfLegen(h[i]) && (spiel.gezogen == nil || spiel.gezogen == i) }
        return ok.first { !h[$0].istJoker } ?? ok.first
    }

    private func tippe(_ i: Int, ok: Bool) {
        guard kannHandeln, ok, sicht == spiel.amZug else { return }
        if spiel.haende[sicht][i].istJoker { jokerWahl = i } else { lege(i, farbe: nil) }
    }

    private func lege(_ i: Int, farbe: Int?) {
        spiel.lege(i, wunsch: farbe, mit: &zufall); jokerWahl = nil; pruefe()
    }

    /// Prüft Spielende und die Übergabe-Seite bei mehreren Menschen.
    private func pruefe() {
        if let w = spiel.gewinner, !gemeldet {
            gemeldet = true
            let rang = teilnehmer.indices.sorted { a, b in a == w ? true : (b == w ? false : spiel.haende[a].count < spiel.haende[b].count) }
            Task {
                try? await Task.sleep(nanoseconds: 700_000_000)
                ende(SpielEnde(reihenfolge: rang.map { teilnehmer[$0].name }, punkte: rang.map { String(localized: "\(spiel.haende[$0].count) Karten übrig") },
                               info: String(localized: "\(teilnehmer[w].name) hat alle Karten abgelegt")))
            }
            return
        }
    }
}
#endif
