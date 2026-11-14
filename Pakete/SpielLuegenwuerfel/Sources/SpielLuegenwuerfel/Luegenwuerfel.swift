// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import LuegenwuerfelKern

@MainActor
public struct LuegenwuerfelModul: SpielModul {
    public let id: String
    public let name: String
    public let regeln: LuegenRegeln
    public init() { id = "luegenwuerfel"; name = "Lügenwürfel"; regeln = .standard }
    /// Perudo: Lügenwürfel mit Einser-Jokern, Palifico und Calza.
    public static let perudo = LuegenwuerfelModul(id: "perudo", name: "Perudo", regeln: .perudo)
    public init(id: String, name: String, regeln: LuegenRegeln) { self.id = id; self.name = name; self.regeln = regeln }
    public let gattung = Gattung.wuerfel
    public let farbe = AkzentFarbeWert.indigo
    public let symbol = "die.face.6.fill"
    public let spielerzahl = 2...6
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        let r = regeln
        return AnyView(SpielRahmen(id: id, name: name, untertitel: regeln.einserJoker ? "Bluffen mit Jokern" : "Bieten, bluffen, aufdecken", farbe: farbe, spieler: 2...6, computerErlaubt: true, wuerfelWahl: true,
                            regeln: r.einserJoker ? "Jeder hat fünf verdeckte Würfel und sieht nur seine eigenen. Reihum gibst du ein Gebot ab: wie viele Würfel aller Spieler zusammen eine bestimmte Augenzahl zeigen. Jedes Gebot muss höher sein als das vorige (mehr Würfel oder gleich viele mit höherer Augenzahl). Statt zu bieten kannst du das letzte Gebot anzweifeln: Es wird aufgedeckt und gezählt. Stimmt das Gebot, verliert der Zweifler einen Würfel, sonst der Bieter. Wer keine Würfel mehr hat, scheidet aus; wer übrig bleibt, gewinnt. Perudo-Regeln: Einser sind Joker und zählen bei jeder anderen Augenzahl mit. Das erste Gebot darf nicht auf Einser lauten. Wechselst du zu Einsern, genügt die halbe Anzahl (aufgerundet); wechselst du von Einsern zurück, brauchst du das Doppelte plus eins. Hat jemand nur noch einen Würfel, spielt er einmal „Palifico“: Alle müssen bei der Augenzahl seines ersten Gebots bleiben und nur die Anzahl erhöhen, Einser sind dann keine Joker. „Calza“ (genau richtig): Behauptest du, das Gebot stimme genau, gewinnst du bei Recht einen Würfel (höchstens fünf), sonst verlierst du einen." : "Jeder hat fünf verdeckte Würfel und sieht nur seine eigenen. Reihum gibst du ein Gebot ab: wie viele Würfel aller Spieler zusammen eine bestimmte Augenzahl zeigen. Jedes Gebot muss höher sein als das vorige (mehr Würfel oder gleich viele mit höherer Augenzahl). Statt zu bieten kannst du das letzte Gebot anzweifeln: Es wird aufgedeckt und gezählt. Stimmt das Gebot, verliert der Zweifler einen Würfel, sonst der Bieter. Wer keine Würfel mehr hat, scheidet aus; wer übrig bleibt, gewinnt.",
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            LuegenwuerfelSpiel(teilnehmer: teilnehmer, regeln: r, ende: ende, abbrechen: abbrechen, quelle: WuerfelWahl.quelle(id, vorgabe: umgebung.wuerfelQuelle), spielID: id)
        }.mitZiel("Bluffe und rate besser als die anderen. Wer als Letzter noch Würfel hat, gewinnt.").mitAnleitung([
            .figuren(symbol: "eye.slash", titel: "Verdeckte Würfel", text: "Jeder würfelt verdeckt unter einem Becher und sieht nur die eigenen Würfel.", figuren: ["🥤", "🎲", "🎲"], bewegt: nil),
            .figuren(symbol: "megaphone", titel: "Gebot abgeben", text: "Biete, wie viele Würfel mit einer Augenzahl am ganzen Tisch liegen. Jedes Gebot muss das letzte übertreffen.", figuren: ["3️⃣", "×", "5️⃣"], bewegt: nil),
            .figuren(symbol: "exclamationmark.bubble", titel: "Anzweifeln", text: "Zweifle das Gebot an: Wer sich irrt, verliert einen Würfel. Wer als Letzter Würfel hat, gewinnt.", figuren: ["🤥", "❗️"], bewegt: nil),
        ]))
    }
}

struct LuegenwuerfelSpiel: View {
    let teilnehmer: [SpielTeilnehmer]
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    let quelle: WuerfelQuelle
    let spielID: String
    @State private var eingegeben: Set<Int> = []
    @State private var eingabe: Int?
    @State private var spiel: Luegenwuerfel
    @State private var zufall = SystemRandomNumberGenerator()
    @State private var sichtbar = false
    @State private var denkt = false
    @State private var stufe = ComputerStufe.gespeichert("luegenwuerfel")
    @State private var anzahl = 1
    @State private var augen = 2
    @State private var aufloesung: String?

    init(teilnehmer: [SpielTeilnehmer], regeln: LuegenRegeln, ende: @escaping (SpielEnde) -> Void, abbrechen: @escaping () -> Void, quelle: WuerfelQuelle = .app, spielID: String = "luegenwuerfel") {
        self.teilnehmer = teilnehmer; self.ende = ende; self.abbrechen = abbrechen; self.quelle = quelle; self.spielID = spielID
        _spiel = State(initialValue: Luegenwuerfel(spieler: teilnehmer.count, regeln: regeln))
    }

    private var computerDran: Bool { teilnehmer[spiel.dran].computer }

    var body: some View {
        VStack(spacing: Theme.kartenAbstand) {
            SpielKopf(mitte: teilnehmer[spiel.dran].name, linksAktion: abbrechen) {
                RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                    ComputerStufePicker(spiel: "luegenwuerfel", stufe: $stufe)
                    Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
                }
            }
            SpielerLeiste(eintraege: teilnehmer.indices.map { .init(id: "\($0)", name: teilnehmer[$0].name, farbe: Spieler.farbe($0), wert: "\(spiel.anzahlen[$0])🎲") }, aktiv: "\(spiel.dran)")
                .padding(.horizontal, Theme.seitenRand)
            ScrollView {
                VStack(spacing: Theme.kartenAbstand) {
                    if let a = aufloesung { Text(a).font(.subheadline.weight(.semibold)).multilineTextAlignment(.center).frame(maxWidth: .infinity).card() }
                    if spiel.palificoRunde { Text("Palifico: Augenzahl bleibt, Einser sind keine Joker").font(.footnote.weight(.semibold)).foregroundStyle(.secondary).frame(maxWidth: .infinity).card() }
                    if let g = spiel.gebot, let b = spiel.bieter {
                        VStack(spacing: Design.Abstand.xs) { SectionLabel("Aktuelles Gebot"); Text("\(teilnehmer[b].name): \(g.anzahl) × \(g.augen)").font(.title2.weight(.bold)) }.frame(maxWidth: .infinity).card()
                    }
                    inhalt
                }.padding(.horizontal, Theme.seitenRand)
            }
        }
        .background(Color.seitenGrund)
        .fortsetzbar(spielID, $spiel)
        .weicheAnimation(bei: [spiel.gesamt, spiel.dran, spiel.gebot?.anzahl ?? 0, spiel.gebot?.augen ?? 0])
        .spielHaptik(zug: [spiel.gesamt, spiel.dran, spiel.gebot?.anzahl ?? 0, spiel.gebot?.augen ?? 0], erfolg: spiel.sieger != nil)
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .onAppear { if SpielStand.vorhanden(spielID) { pruefe() } else { neueRunde(nil) } }
        .echteWuerfelEingabe(anzahl: $eingabe, titel: "Was liegt unter deinem Becher?") { augen in
            if spiel.setzeWuerfel(augen, fuer: spiel.dran) { eingegeben.insert(spiel.dran) }
        }
    }

    @ViewBuilder private var inhalt: some View {
        if let s = spiel.sieger {
            Button("Ergebnis") { fertig(s) }.buttonStyle(HauptKnopfStil())
        } else if computerDran {
            Text("\(teilnehmer[spiel.dran].name) denkt nach …").foregroundStyle(.secondary).frame(maxWidth: .infinity).card()
        } else if !sichtbar && teilnehmer.mehrereMenschen {
            VStack(spacing: Design.Abstand.s) {
                Text("\(teilnehmer[spiel.dran].name) ist dran").font(.headline)
                Text("Gerät übergeben, dann antippen.").font(.footnote).foregroundStyle(.secondary)
                Button("Meine Würfel ansehen") { sichtbar = true; aufloesung = nil }.buttonStyle(HauptKnopfStil())
            }.frame(maxWidth: .infinity).card()
        } else if quelle == .echt, !eingegeben.contains(spiel.dran) {
            VStack(spacing: Design.Abstand.s) {
                Text("Würfle unter dem Becher und tippe deine Würfel ein.").font(.subheadline).multilineTextAlignment(.center)
                Button("Würfel eintippen") { eingabe = spiel.anzahlen[spiel.dran] }.buttonStyle(HauptKnopfStil())
            }.frame(maxWidth: .infinity).card()
        } else {
            VStack(spacing: 10) {
                HStack(spacing: Design.Abstand.s) { ForEach(Array(spiel.wuerfel[spiel.dran].enumerated()), id: \.offset) { _, w in WuerfelBild(w).font(.largeTitle).foregroundStyle(Color.appFlaeche) } }
                if spiel.gebot != nil { Text(tippText).font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center) }
                Stepper("Anzahl: \(anzahl)", value: $anzahl, in: 1...max(1, spiel.gesamt))
                Stepper("Augen: \(augen)", value: $augen, in: 1...6)
                HStack(spacing: Design.Abstand.s) {
                    if spiel.gebot != nil { Button("Anzweifeln") { zweifeln() }.buttonStyle(ZweitKnopfStil()) }
                    if spiel.gebot != nil, spiel.regeln.calza { Button("Calza") { calza() }.buttonStyle(ZweitKnopfStil()) }
                    Button("Bieten") { if spiel.biete(Gebot(anzahl, augen)) { sichtbar = false; vorbereiten(); pruefe() } }
                        .buttonStyle(HauptKnopfStil()).disabled(!gueltig)
                }
            }.frame(maxWidth: .infinity).card()
        }
    }

    private var gueltig: Bool { spiel.erlaubt(Gebot(anzahl, augen), nach: spiel.gebot) }

    private func vorbereiten() {
        guard spiel.gebot != nil else { return }
        // Kleinstes erlaubtes Folgegebot vorbelegen (gilt für Standard- und Perudo-Regeln)
        for n in 1...max(1, spiel.gesamt) { for a in 1...6 where spiel.erlaubt(Gebot(n, a), nach: spiel.gebot) { anzahl = n; augen = a; return } }
    }

    private func neueRunde(_ beginnt: Int?) {
        spiel.neueRunde(beginnt: beginnt, mit: &zufall); anzahl = 1; augen = 2; sichtbar = false; eingegeben = []; pruefe()
    }

    /// Hinweis für den Menschen am Zug: Wie wahrscheinlich stimmt das letzte Gebot aus deiner Sicht?
    private var tippText: LocalizedStringKey {
        let prozent = Int((LuegenwuerfelComputer.wahrheitsChance(spiel, spieler: spiel.dran) * 100).rounded())
        if prozent == 0 { return "Tipp: Das Gebot kann nicht stimmen – anzweifeln lohnt sich." }
        if prozent < 35 { return "Tipp: Das Gebot stimmt nur zu etwa \(prozent) % – anzweifeln lohnt sich." }
        return "Tipp: Das Gebot stimmt zu etwa \(prozent) %."
    }

    private func zweifeln() {
        guard let g = spiel.gebot, let r = spiel.zweifeln() else { return }
        aufloesung = "\(g.anzahl) × \(g.augen) geboten, gezählt: \(r.gezaehlt). \(teilnehmer[r.verlierer].name) verliert einen Würfel."
        sichtbar = false
        if spiel.sieger == nil { neueRunde(r.verlierer) }
    }

    private func calza() {
        guard let g = spiel.gebot, let r = spiel.calzaRufen() else { return }
        let n = teilnehmer[r.spieler].name
        aufloesung = r.richtig ? "\(g.anzahl) × \(g.augen) geboten, gezählt: \(r.gezaehlt). Genau richtig! \(n) gewinnt einen Würfel."
                               : "\(g.anzahl) × \(g.augen) geboten, gezählt: \(r.gezaehlt). Calza falsch, \(n) verliert einen Würfel."
        sichtbar = false
        if spiel.sieger == nil { neueRunde(r.spieler) }
    }

    private func pruefe() {
        guard spiel.sieger == nil, computerDran, !denkt else { return }
        denkt = true
        Task {
            try? await Task.sleep(for: .milliseconds(900))
            denkt = false
            guard computerDran, spiel.sieger == nil else { return }
            let i = spiel.dran
            if spiel.gebot != nil, LuegenwuerfelComputer.ruftCalza(spiel, spieler: i) { calza() }
            else if let g = spiel.gebot, LuegenwuerfelComputer.zweifelt(spiel, spieler: i, stufe: stufe.rawValue) || g.anzahl >= spiel.gesamt { zweifeln() }
            else { spiel.biete(LuegenwuerfelComputer.gebot(spiel, spieler: i)); vorbereiten(); pruefe() }
        }
    }

    private func fertig(_ s: Int) {
        let o = [s] + teilnehmer.indices.filter { $0 != s }
        ende(SpielEnde(reihenfolge: o.map { teilnehmer[$0].name }, punkte: o.map { "\(spiel.anzahlen[$0])" }, info: String(localized: "\(teilnehmer[s].name) bleibt übrig")))
    }
}
#endif
