// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import SpielHilfen
import KreuzwurfKern

@MainActor
public struct KreuzwurfModul: SpielModul {
    public init() {}
    public let id = "kreuzwurf"
    public let name = "Kreuzwurf"
    public let gattung = Gattung.wuerfel
    public let farbe = AkzentFarbeWert.tuerkis
    public let symbol = "dice.fill"
    public let spielerzahl = 1...4
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "Würfeln, wählen, ankreuzen", farbe: farbe, spieler: 1...4, computerErlaubt: true, wuerfelWahl: true,
                            regeln: "Alle spielen auf demselben Farbfeld mit 7 × 7 Feldern, jeder auf seinem eigenen Bogen. In jeder Runde werden drei Farbwürfel und drei Zahlwürfel geworfen. Wer an der Reihe ist, nimmt einen Farbwürfel und einen Zahlwürfel und kreuzt bis zu so viele Felder dieser Farbe an, wie der Zahlwürfel zeigt. Die Felder müssen zusammenhängen. Das allererste Kreuz muss in der mittleren Spalte liegen, jedes weitere Kreuz muss an ein schon angekreuztes Feld grenzen. Der Stern auf dem Farbwürfel ist ein Joker für jede Farbe, auf dem Zahlwürfel für jede Zahl bis fünf. Genommene Würfel sind für die anderen weg. Punkte: ein Punkt je Kreuz, dazu Bonus für volle Spalten (erste 5, später 3) und für Farben, die du ganz angekreuzt hast (erste 6, später 3). Allein hast du pro Runde zwei Wahlen.",
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            KreuzwurfSpiel(teilnehmer: teilnehmer, ende: ende, abbrechen: abbrechen, quelle: WuerfelWahl.quelle(id, vorgabe: umgebung.wuerfelQuelle))
        }.mitZiel("Kreuze auf deinem Bogen passende Farbfelder an. Wer am Ende die meisten Punkte hat, gewinnt.").mitAnleitung([
            .figuren(symbol: "dice", titel: "Würfel wählen", text: "Pro Runde liegen drei Farb- und drei Zahlwürfel. Nimm einen Farbwürfel und einen Zahlwürfel.", figuren: ["🟥", "🟩", "3️⃣"], bewegt: nil),
            .figuren(symbol: "xmark.square", titel: "Felder ankreuzen", text: "Kreuze bis zu so viele zusammenhängende Felder dieser Farbe an, wie der Zahlwürfel zeigt. Das erste Kreuz liegt in der mittleren Spalte.", figuren: ["❌", "❌", "⬜️"], bewegt: nil),
            .figuren(symbol: "star", titel: "Joker und Punkte", text: "Der Stern ist ein Joker. Genommene Würfel sind für die anderen weg. Gewertet werden vollständige Farben und Spalten.", figuren: ["⭐️", "🟦"], bewegt: nil),
        ]))
    }
}

private let feldFarben: [Color] = [Color(red: 0.85, green: 0.30, blue: 0.30), Color(red: 0.25, green: 0.50, blue: 0.88), Color(red: 0.25, green: 0.65, blue: 0.40), Color(red: 0.93, green: 0.76, blue: 0.20), Color(red: 0.62, green: 0.38, blue: 0.80)]

struct KreuzwurfSpiel: View {
    let teilnehmer: [SpielTeilnehmer]
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    let quelle: WuerfelQuelle
    @State private var eingabeRunde = -1
    @State private var eF = [0, 0, 0]
    @State private var eZ = [1, 1, 1]
    @State private var spiel: Kreuzwurf
    @State private var zufall = SystemRandomNumberGenerator()
    @State private var stufe = ComputerStufe.gespeichert("kreuzwurf")
    private var fehler: Double { switch stufe { case .leicht: 0.5; case .mittel: 0.15; case .schwer: 0 } }
    @State private var wahlF: Int?
    @State private var wahlZ: Int?
    @State private var jokerFarbe: Int?
    @State private var auswahl: [Zelle] = []
    @State private var gemeldet = false

    init(teilnehmer: [SpielTeilnehmer], ende: @escaping (SpielEnde) -> Void, abbrechen: @escaping () -> Void, quelle: WuerfelQuelle = .app) {
        self.teilnehmer = teilnehmer; self.ende = ende; self.abbrechen = abbrechen; self.quelle = quelle
        var g = SystemRandomNumberGenerator()
        _spiel = State(initialValue: Kreuzwurf(spieler: teilnehmer.count, mit: &g))
    }

    private var menschen: [Int] { teilnehmer.menschen }
    private var spielerAmZug: Int { spiel.amZug }
    private var amZugComputer: Bool { teilnehmer[spielerAmZug].computer }
    private var sicht: Int { amZugComputer ? (menschen.first ?? 0) : spielerAmZug }
    private var kannHandeln: Bool { !spiel.vorbei && !amZugComputer }

    /// Gewählte Farbe (Joker aufgelöst) und größte Anzahl.
    private var farbe: Int? { wahlF.map { spiel.farbwuerfel[$0] == 5 ? jokerFarbe : spiel.farbwuerfel[$0] } ?? nil }
    private var maximal: Int? { wahlZ.map { spiel.zahlwuerfel[$0] == 0 ? 5 : spiel.zahlwuerfel[$0] } }
    private var auswahlGueltig: Bool {
        guard let f = farbe, let m = maximal else { return false }
        return spiel.gueltig(spieler: spielerAmZug, farbe: f, maximal: m, zellen: auswahl)
    }

    var body: some View {
        ZStack {
            VStack(spacing: Theme.kartenAbstand) {
                SpielKopf(mitte: spiel.vorbei ? String(localized: "Spielende") : String(localized: "Runde \(spiel.runde + 1) von \(spiel.runden)"), linksAktion: abbrechen) {
                    RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                        if teilnehmer.contains(where: \.computer) { ComputerStufePicker(spiel: "kreuzwurf", stufe: $stufe) }
                        Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
                    }
                }
                punkteLeiste
                brett
                wuerfel
                steuerung
                Spacer(minLength: 0)
            }
        }
        .aufTisch()   // Design-Runde 3: in Tinte Filz bis in die Ecken, sonst Seitengrund wie bisher
        .uebergabeSeite(teilnehmer: teilnehmer, amZug: spiel.amZug, aktiv: !spiel.vorbei, geheim: false)
        .fortsetzbar("kreuzwurf", $spiel)
        .weicheAnimation(bei: spiel)
        .spielHaptik(zug: spiel, erfolg: (spiel.vorbei))
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .sheet(isPresented: Binding(get: { wurfEingabeOffen }, set: { _ in })) { wurfEingabe }
        .task(id: "\(spiel.runde)-\(spiel.pick)-\(eingabeRunde)") {
            guard !spiel.vorbei, amZugComputer, !wurfEingabeOffen else { return }
            try? await Task.sleep(nanoseconds: 1_300_000_000)
            guard !Task.isCancelled else { return }
            if let w = spiel.computerWahl(fehler: fehler, mit: &zufall) { spiel.setze(farbwuerfel: w.fw, zahlwuerfel: w.zw, farbe: w.farbe, zellen: w.zellen, mit: &zufall) } else { spiel.passe(mit: &zufall) }
            nachZug()
        }
    }

    /// Echte Würfel: zu Beginn jeder Runde die sechs gewürfelten Seiten eintippen.
    private var wurfEingabeOffen: Bool { quelle == .echt && !spiel.vorbei && eingabeRunde != spiel.runde }

    private static let zahlSeiten = [1, 2, 3, 4, 5, 0]

    private var wurfEingabe: some View {
        VStack(spacing: Design.Abstand.l) {
            Text("Was hast du gewürfelt?").font(.headline)
            Text("Tippe einen Würfel, um die Seite zu wechseln.").font(.footnote).foregroundStyle(.secondary)
            HStack(spacing: 10) {
                ForEach(0..<3, id: \.self) { i in
                    let w = eF[i]
                    wuerfelFlaeche(farbe: w == 5 ? nil : feldFarben[w], text: w == 5 ? "★" : "", gewaehlt: false, genommen: false) { eF[i] = (eF[i] + 1) % 6 }
                }
                Spacer().frame(width: 10)
                ForEach(0..<3, id: \.self) { i in
                    let w = eZ[i]
                    wuerfelFlaeche(farbe: nil, text: w == 0 ? "★" : "\(w)", gewaehlt: false, genommen: false) {
                        let k = Self.zahlSeiten.firstIndex(of: eZ[i]) ?? 0
                        eZ[i] = Self.zahlSeiten[(k + 1) % 6]
                    }
                }
            }
            Button("Übernehmen") {
                if spiel.setzeWurf(farbwuerfel: eF, zahlwuerfel: eZ) { eingabeRunde = spiel.runde }
            }.buttonStyle(HauptKnopfStil())
        }
        .padding(24)
        .presentationDetents([.height(300)])
        .interactiveDismissDisabled()
    }

    private var punkteLeiste: some View {
        HStack(spacing: Design.Abstand.s) {
            ForEach(teilnehmer.indices, id: \.self) { i in
                VStack(spacing: 2) {
                    Text(verbatim: teilnehmer[i].name).font(.footnote).lineLimit(1).minimumScaleFactor(0.7)
                    Text(verbatim: "\(spiel.punkte(i))").font(.title3.weight(.semibold))
                }
                .frame(maxWidth: .infinity).padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: Design.Ecke.feld).fill(Tisch.aktiv ? Color.white.opacity(i == spielerAmZug && !spiel.vorbei ? 0.20 : 0.08) : (i == spielerAmZug && !spiel.vorbei ? Color.appFlaeche.opacity(0.25) : Color.kartenGrund)))   // Design-Runde 3: auf dem Filz
            }
        }.padding(.horizontal, Theme.seitenRand)
    }

    private var brett: some View {
        GeometryReader { g in
            let n = Kreuzwurf.groesse
            let z = min(g.size.width, g.size.height) / CGFloat(n)
            VStack(spacing: 0) {
                ForEach(0..<n, id: \.self) { y in
                    HStack(spacing: 0) {
                        ForEach(0..<n, id: \.self) { x in zelle(x, y, z) }
                    }
                }
            }.frame(width: z * CGFloat(n), height: z * CGFloat(n)).frame(maxWidth: .infinity)
        }
        .aspectRatio(1, contentMode: .fit).padding(.horizontal, Theme.seitenRand)
    }

    private func zelle(_ x: Int, _ y: Int, _ z: CGFloat) -> some View {
        let c = spiel.feld[y][x]
        let gemacht = spiel.markiert[sicht][y][x]
        let gewaehlt = auswahl.contains(Zelle(x, y)) && sicht == spielerAmZug
        let mitte = x == Kreuzwurf.groesse / 2
        return ZStack {
            Rectangle().fill(feldFarben[c].opacity(gemacht ? 0.35 : 0.9))
            Rectangle().stroke(mitte ? Color.primary.opacity(0.5) : .white.opacity(0.6), lineWidth: mitte ? 1.5 : 0.5)
            if gemacht { Image(systemName: "xmark").font(.system(size: z * 0.5, weight: .heavy)).foregroundStyle(.white) }   // design:spielinhalt (skaliert mit Feld/Karte/Würfel)
            if gewaehlt { RoundedRectangle(cornerRadius: 3).stroke(Color.primary, lineWidth: 3).padding(2) }
        }
        .frame(width: z, height: z)
        .contentShape(Rectangle())
        .onTapGesture { tippe(Zelle(x, y)) }
        .accessibilityLabel(gemacht ? Text("\(String(localized: String.LocalizationValue(Kreuzwurf.farbNamen[c]))), angekreuzt") : Text(LocalizedStringKey(Kreuzwurf.farbNamen[c])))
    }

    private var wuerfel: some View {
        VStack(spacing: Design.Abstand.s) {
            HStack(spacing: Design.Abstand.m) {
                ForEach(0..<3, id: \.self) { i in
                    let w = spiel.farbwuerfel[i]
                    wuerfelFlaeche(farbe: w == 5 ? nil : feldFarben[w], text: w == 5 ? "★" : "", gewaehlt: wahlF == i, genommen: spiel.farbGenommen[i]) {
                        guard kannHandeln, !spiel.farbGenommen[i] else { return }
                        wahlF = wahlF == i ? nil : i; jokerFarbe = nil; auswahl = []
                    }
                }
                Spacer().frame(width: 12)
                ForEach(0..<3, id: \.self) { i in
                    let w = spiel.zahlwuerfel[i]
                    wuerfelFlaeche(farbe: nil, text: w == 0 ? "★" : "\(w)", gewaehlt: wahlZ == i, genommen: spiel.zahlGenommen[i]) {
                        guard kannHandeln, !spiel.zahlGenommen[i] else { return }
                        wahlZ = wahlZ == i ? nil : i; auswahl = []
                    }
                }
            }
            if let f = wahlF, spiel.farbwuerfel[f] == 5, kannHandeln {
                HStack(spacing: Design.Abstand.s) {
                    ForEach(0..<5, id: \.self) { c in
                        Circle().fill(feldFarben[c]).frame(width: 30, height: 30)
                            .overlay(Circle().stroke(Color.primary, lineWidth: jokerFarbe == c ? 3 : 0))
                            .onTapGesture { jokerFarbe = c; auswahl = [] }
                            .accessibilityLabel(Text(LocalizedStringKey(Kreuzwurf.farbNamen[c]))).accessibilityAddTraits(jokerFarbe == c ? [.isButton, .isSelected] : .isButton)
                    }
                }
            }
        }
    }

    private func wuerfelFlaeche(farbe: Color?, text: String, gewaehlt: Bool, genommen: Bool, aktion: @escaping () -> Void) -> some View {
        RoundedRectangle(cornerRadius: 10).fill(farbe ?? (Tisch.aktiv ? Tisch.elfenbein : Color.kartenGrund))
            .overlay(Text(verbatim: text).font(.system(.title, design: Design.zahlDesign).weight(.bold)).foregroundStyle(farbe == nil ? (Tisch.aktiv ? Tisch.auge : Color.primary) : .white))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(gewaehlt ? Color.primary : Color.secondary.opacity(0.3), lineWidth: gewaehlt ? 3.5 : 1))
            .frame(width: 46, height: 46).opacity(genommen ? 0.25 : 1)
            .onTapGesture(perform: aktion)
            .accessibilityAddTraits(.isButton).accessibilityAddTraits(gewaehlt ? .isSelected : [])
    }

    private var steuerung: some View {
        VStack(spacing: Design.Abstand.s) {
            Text(hinweis).font(.footnote).foregroundStyle(.secondary).frame(minHeight: 18)
            HStack(spacing: Design.Abstand.m) {
                Button("Passen") { spiel.passe(mit: &zufall); nachZug() }.tischNebenKnopf().dynamicTypeSize(...DynamicTypeSize.xxxLarge).disabled(!kannHandeln)
                Button("Ankreuzen") { bestaetige() }.buttonStyle(HauptKnopfStil()).disabled(!kannHandeln || !auswahlGueltig)
            }
        }.padding(.horizontal, Theme.seitenRand)
    }

    private var hinweis: String {
        guard kannHandeln else { return amZugComputer ? String(localized: "\(teilnehmer[spielerAmZug].name) überlegt …") : " " }
        if wahlF == nil { return String(localized: "Wähle einen Farbwürfel.") }
        if spiel.farbwuerfel[wahlF!] == 5, jokerFarbe == nil { return String(localized: "Joker: Wähle eine Farbe.") }
        if wahlZ == nil { return String(localized: "Wähle einen Zahlwürfel.") }
        return grund ?? String(localized: "Alles klar – tippe auf „Ankreuzen“.")
    }

    /// Warum „Ankreuzen“ gerade nicht geht (nil, wenn es geht).
    private var grund: String? {
        guard let f = farbe, let m = maximal else { return nil }
        if auswahlGueltig { return nil }
        if spiel.startZellen(spieler: sicht, farbe: f).isEmpty {
            return String(localized: "In dieser Farbe geht nichts mehr – wähle andere Würfel oder passe.")
        }
        if auswahl.isEmpty { return String(localized: "Tippe bis zu \(m) zusammenhängende \(Kreuzwurf.farbNamen[f])-Felder an.") }
        if !Kreuzwurf.zusammenhaengend(auswahl) { return String(localized: "Die Felder müssen zusammenhängen.") }
        if !auswahl.contains(where: { spiel.anschluss(sicht, $0) }) {
            return spiel.markiert[sicht].joined().contains(true)
                ? String(localized: "Mindestens ein Feld muss an ein schon angekreuztes Feld grenzen.")
                : String(localized: "Das erste Kreuz muss in der mittleren Spalte liegen (dick umrandet).")
        }
        return nil
    }

    private func tippe(_ z: Zelle) {
        guard kannHandeln, farbe != nil, maximal != nil, sicht == spielerAmZug else { return }
        if let i = auswahl.firstIndex(of: z) { auswahl.remove(at: i) }
        else if auswahl.count < (maximal ?? 0), spiel.feld[z.y][z.x] == farbe, !spiel.markiert[sicht][z.y][z.x] { auswahl.append(z) }
    }

    private func bestaetige() {
        guard let fw = wahlF, let zw = wahlZ, let f = farbe, auswahlGueltig else { return }
        if spiel.setze(farbwuerfel: fw, zahlwuerfel: zw, farbe: f, zellen: auswahl, mit: &zufall) { nachZug() }
    }

    private func nachZug() {
        wahlF = nil; wahlZ = nil; jokerFarbe = nil; auswahl = []
        if spiel.vorbei, !gemeldet {
            gemeldet = true
            let e = SpielEnde.nachPunkten(namen: teilnehmer.map(\.name), punkte: teilnehmer.indices.map { spiel.punkte($0) })
            Task {
                try? await Task.sleep(nanoseconds: 800_000_000)
                ende(e)
            }
            return
        }
    }
}
#endif
