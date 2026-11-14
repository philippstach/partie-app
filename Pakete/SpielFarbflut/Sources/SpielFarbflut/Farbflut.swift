// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import SpielHilfen
import FarbflutKern

@MainActor
public struct FarbflutModul: SpielModul {
    public init() {}
    public let id = "farbflut"
    public let name = "Farbfüller"
    public let gattung = Gattung.raetsel
    public let farbe = AkzentFarbeWert.tuerkis
    public let symbol = "drop.fill"
    public let spielerzahl = 1...1
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "Färbe das ganze Feld ein", farbe: farbe, spieler: 1...1,
                            regeln: "Das Feld besteht aus bunten Quadraten. Die Flut beginnt oben links. Tippe unten eine Farbe an: Die ganze Fläche, die jetzt zur Flut gehört, nimmt diese Farbe an und schluckt dabei alle angrenzenden Felder in dieser Farbe. Färbe so das ganze Feld in einer einzigen Farbe, bevor deine Züge aufgebraucht sind. Du hast nur eine begrenzte Zahl von Zügen; jedes Feld ist garantiert lösbar. Je mehr Züge übrig bleiben, desto mehr Punkte. „Zurück“ nimmt einen Zug zurück.",
                            einzelText: "Ein Spieler: Schaffst du es in wenigen Zügen?",
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            FarbflutSpiel(name: teilnehmer[0].name, ende: ende, abbrechen: abbrechen)
        }.mitZiel("Färbe das ganze Feld in einer einzigen Farbe, bevor deine Züge aufgebraucht sind.").mitZielSchrittNeu(.ziel("Färbe das ganze Feld in einer einzigen Farbe, bevor deine Züge aufgebraucht sind. Du spielst allein. Es zählt nicht die Zeit, sondern wie viele Züge du brauchst.")).mitAnleitung(RegelTexteNeu.anleitung(neu: Self.anleitungNeu, alt: Self.anleitung))
            .mitStartOptionen { _ in FarbflutOptionen() }
            .mitStartInhalt { aktionen in TagesKarte(spiel: "farbflut", spielName: name, aktionen: aktionen) })   // 1.0 (P5): Tageskarte mit Serie
    }
}

let flutFarben: [Color] = [Familienfarbe.rot.color, Familienfarbe.blau.color, Familienfarbe.gruen.color, Familienfarbe.orange.color, Familienfarbe.violett.color, Familienfarbe.tuerkis.color]   // Farben der Spielefamilie aus KlarGlas, Formzeichen unterscheiden sie zusätzlich
private let flutFormen = ["circle.fill", "square.fill", "triangle.fill", "diamond.fill", "star.fill", "hexagon.fill"]

struct FarbflutSpiel: View {
    let name: String
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    enum Stufe: Int, CaseIterable { case leicht, normal, schwer }
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var regular: Bool { sizeClass == .regular }   // B18: auf dem iPad Inhalt mittig, Brett größer
    @State private var stufe = Stufe(rawValue: FarbflutStufenWahl.gespeichert(FarbflutOptionen.stufeSchluessel)) ?? .normal
    @State private var spiel: Farbflut?
    @State private var gemeldet = false
    @State private var neuFragen = false   // T-076
    @State private var tagesraetsel = UserDefaults.standard.bool(forKey: FarbflutOptionen.tagesSchluessel)
    @State private var tippFarbe: Int?
    @State private var tipps = 0
    /// Festes Brett statt der Auswahl (nur für die Bildproben der Tests).
    var vorgabe: Farbflut? = nil

    /// C-039: Gespeichert werden Brett, Stufe, Tagesrätsel-Schalter und Tipp-Zähler (nicht nur das Brett).
    struct Stand: Codable { var spiel: Farbflut; var stufe: Int; var tages: Bool; var tipps: Int }
    private var standBinding: Binding<Stand?> {
        Binding(get: { spiel.map { Stand(spiel: $0, stufe: stufe.rawValue, tages: tagesraetsel, tipps: tipps) } },
                set: { if let n = $0 { spiel = n.spiel; stufe = Stufe(rawValue: n.stufe) ?? .normal; tagesraetsel = n.tages; tipps = n.tipps } else { spiel = nil } })
    }

    var body: some View { Group { if let s = spiel ?? vorgabe { brett(s) } else { Color.clear.onAppear { starten() } } }.aufTisch().weicheAnimation(bei: spiel).spielHaptik(zug: spiel, erfolg: (spiel?.geloest ?? false), fehler: ((spiel?.vorbei ?? false) && !(spiel?.geloest ?? false))).fortsetzbar("farbflut", standBinding, pruefen: { $0.spiel.istKonsistent && Stufe(rawValue: $0.stufe) != nil })
        .confirmationDialog("Aktuelle Partie abbrechen?", isPresented: $neuFragen, titleVisibility: .visible) {   // T-076: Rückfrage wie in den anderen Spielen
            Button("Abbrechen und neu starten", role: .destructive) { spiel = nil }
            Button("Weiterspielen", role: .cancel) {}
        } message: { Text("Die laufende Partie wird verworfen und neu begonnen.") }
        #if DEBUG
        .testEndeMelden { if let s = spiel, s.vorbei { beenden(s) } }   // -testZustand ende: „Ergebnis“ wird nach dem Laden des gelösten Brettes selbst gewählt
        #endif
    }

    /// B18: Stufe und Tagesrätsel kommen aus dem Neues-Spiel-Blatt; hier gibt es keine zweite Startseite mehr.
    private func starten() {
        stufe = Stufe(rawValue: FarbflutStufenWahl.gespeichert(FarbflutOptionen.stufeSchluessel)) ?? .normal
        // 1.0 (P5): „Spielen“ auf der Tageskarte der Startseite merkt das Tagesrätsel einmalig vor; der Schalter im Blatt bleibt, wie er ist
        // Große Tinte-Runde, Punkt 14f: In Tinte gibt es den Schalter nicht mehr, nur die Tageszeile; ein alter Schalterwert zählt dort nicht
        tagesraetsel = Tagesraetsel.wunschAbholen(spiel: "farbflut") || (!Design.ist(.tinte) && UserDefaults.standard.bool(forKey: FarbflutOptionen.tagesSchluessel))
        if tagesraetsel { Tagesraetsel.merkeStart(spiel: "farbflut"); var g = ZufallsQuelle(seed: Tagesraetsel.seed(spiel: "farbflut")); spiel = Farbflut(groesse: 12, farben: 6, luft: 5, mit: &g) }
        else {
            var g = SystemRandomNumberGenerator()
            switch stufe {
            case .leicht: spiel = Farbflut(groesse: 8, farben: 4, luft: 6, mit: &g)
            case .normal: spiel = Farbflut(groesse: 12, farben: 6, luft: 5, mit: &g)
            case .schwer: spiel = Farbflut(groesse: 14, farben: 6, luft: 2, mit: &g)
            }
        }
        gemeldet = false; tippFarbe = nil; tipps = 0
    }

    private func brett(_ s: Farbflut) -> some View {
        VStack(spacing: Theme.kartenAbstand) {
            SpielKopf(mitte: s.geloest ? String(localized: "Geschafft!") : String(localized: "\(s.verbleibend) Züge übrig"), linksAktion: abbrechen) {
                RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                    FragNachDenRegelnMenuePunkt()   // KI-3 (Blatt 12): nur mit Apple Intelligence sichtbar
                    Button("Neu beginnen", systemImage: "arrow.counterclockwise") { if s.zuege > 0 && !s.vorbei { neuFragen = true } else { spiel = nil } }   // T-076: Rückfrage wie in den anderen Spielen
                    Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
                }
            }
            if regular { Spacer(minLength: 0) }
            SpielfeldKarte {
                GeometryReader { g in
                    let z = min(g.size.width, g.size.height) / CGFloat(s.n)
                    let flut = s.flut
                    Canvas { ctx, _ in
                        for i in s.feld.indices {
                            let x = i % s.n, y = i / s.n
                            let r = CGRect(x: CGFloat(x) * z, y: CGFloat(y) * z, width: z, height: z)
                            ctx.fill(Path(r), with: .color(flutFarben[s.feld[i]]))
                            if flut.contains(i) && !s.geloest { ctx.stroke(Path(r.insetBy(dx: z * 0.3, dy: z * 0.3)), with: .color(.white.opacity(0.7)), lineWidth: max(1, z * 0.08)) }
                        }
                    }.frame(width: z * CGFloat(s.n), height: z * CGFloat(s.n)).frame(maxWidth: .infinity)
                    .accessibilityElement(children: .ignore)   // G1
                    .accessibilityLabel(Text("Farbfeld, \(s.n) mal \(s.n)"))
                    .accessibilityValue(Text("Zug \(s.zuege), Flut deckt \(flut.count) von \(s.feld.count) Feldern"))
                }.aspectRatio(1, contentMode: .fit).frame(maxWidth: regular ? 880 : Theme.wideColumnWidth)
            }.padding(.horizontal, Theme.seitenRand)
            if s.vorbei {
                VStack(spacing: Design.Abstand.s) {
                    Text(s.geloest ? "Geschafft mit \(s.zuege) Zügen!" : "Leider keine Züge mehr.").font(.headline)
                    Button("Ergebnis") { beenden(s) }.buttonStyle(HauptKnopfStil())   // nach dem Ende gibt es kein Zurücknehmen mehr
                }.padding(.horizontal, Theme.seitenRand)
            } else {
                HStack(spacing: 10) {
                    ForEach(0..<s.farben, id: \.self) { f in
                        Button { spiel?.zug(f); tippFarbe = nil } label: {
                            ZStack { Circle().fill(flutFarben[f]); Image(systemName: flutFormen[f]).font(.system(size: 14, weight: .bold)).foregroundStyle(.white.opacity(0.85)) } // design:spielinhalt
                                .frame(width: 46, height: 46).opacity(f == s.aktuelleFarbe ? 0.3 : 1)
                                .overlay(Circle().stroke(Color.primary, lineWidth: tippFarbe == f ? 4 : 0))
                        }.buttonStyle(.plain).disabled(f == s.aktuelleFarbe)
                            .accessibilityLabel(Text("Farbe \(f + 1) von \(s.farben)"))
                            .accessibilityValue(f == s.aktuelleFarbe ? Text("aktuelle Farbe") : (tippFarbe == f ? Text("Tipp") : Text(verbatim: "")))
                            .accessibilityHint(Text("Färbt die Flut in diese Farbe um."))
                    }
                }
                HStack(spacing: Design.Abstand.m) {
                    Button { spiel?.zurueck(); tippFarbe = nil } label: { Label("Zurück", systemImage: "arrow.uturn.backward") }.tischNebenKnopf().dynamicTypeSize(...DynamicTypeSize.xxxLarge).disabled(!s.kannZurueck)
                    Button { tippFarbe = s.besteFarbeGierig(); tipps += 1 } label: { Label("Tipp", systemImage: "lightbulb") }.tischNebenKnopf().dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                }
            }
            Spacer(minLength: 0)
        }
    }

    private var tagesSchluessel: String { "farbflut.tag.\(Tagesraetsel.tag())" }
    private var stufenSchluessel: String { "farbflut.\(stufe.rawValue)" }

    private func beenden(_ s: Farbflut) {
        guard !gemeldet else { return }
        gemeldet = true
        let punkte = s.geloest ? 100 + s.verbleibend * 10 : 0
        var rekord = false
        if s.geloest { Leiter.sieg("farbflut", stufe: stufe.rawValue, mitTipp: tipps > 0, tages: tagesraetsel) }   // D4
        // 1.0 (P5): Gelöstes Tagesrätsel zählt für die Serie (mit oder ohne Tipp), unter dem Starttag
        if s.geloest && tagesraetsel { TagesSerie.melden(spiel: "farbflut", tag: Tagesraetsel.startTag(spiel: "farbflut"), ergebnis: String(localized: "In \(s.zuege) von \(s.limit) Zügen geschafft")) }
        if s.geloest && tipps == 0 { rekord = Bestleistung.melden(tagesraetsel ? "farbflut.tag.\(Tagesraetsel.startTag(spiel: "farbflut"))" : stufenSchluessel, wert: s.zuege) }
        // S1: Ohne verbleibende Züge ist die Partie verloren (Überschrift „Verloren“, kein Sieg in der Statistik).
        // T-077: Kennzahl für die Statistik je Stufe (0 = Leicht), das Tagesrätsel zählt eigens (wie Sudoku)
        let kennzahlen: [String: Double] = tagesraetsel ? ["tages": 1] : ["stufe": Double(stufe.rawValue)]
        guard s.geloest else { var v = SpielEnde.verloren(name, punkte: "0", info: String(localized: "Keine Züge mehr")); v.kennzahlen = kennzahlen; ende(v); return }
        var e = SpielEnde(reihenfolge: [name], punkte: ["\(punkte)"], info: String(localized: "In \(s.zuege) von \(s.limit) Zügen geschafft") + (rekord ? " · " + String(localized: "Neue Bestleistung!") : ""))
        e.kennzahlen = kennzahlen
        // Blatt 22 (EB-3), Größe, Züge („17 von 22“) und Punkte
        if let start = s.anfang, start.count == s.n * s.n {   // Schritt 2: das Feld vom Anfang als Bild
            let kante = s.n
            e.bild = EndeBild(Text("Das Feld am Anfang"), hoehe: 320) { groesse in FarbflutEndeBild(feld: start, n: kante, groesse: groesse) }
        }
        e.werte = [EndeWert("Größe", "\(s.n) × \(s.n)"), EndeWert("Züge", String(localized: "\(s.zuege) von \(s.limit)")), EndeWert("Punkte", "\(punkte)")]
        ende(e)
    }
}
/// Karte im Neues-Spiel-Blatt: Schwierigkeit und Tagesrätsel (vorher eigene zweite Seite).
struct FarbflutOptionen: View {
    static let stufeSchluessel = "farbflut.neu.stufe"
    static let tagesSchluessel = "farbflut.neu.tages"
    @AppStorage(FarbflutOptionen.stufeSchluessel) private var stufe = FarbflutStufenWahl.standard
    @AppStorage(FarbflutOptionen.tagesSchluessel) private var tages = false
    @Environment(\.designArt) private var art   // zeichnet beim Designwechsel neu

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Schwierigkeit").font(.headline)
            LeiterWahl(spiel: "farbflut", namen: ["Leicht", "Normal", "Schwer"], stufe: $stufe)
            if art != .tinte { Toggle("Tagesrätsel (für alle gleich)", isOn: $tages) }   // Tinte: Die Zeile „Tagesrätsel heute“ oben genügt (Punkt 14f)
            if tages && art != .tinte, let b = Bestleistung.lesen("farbflut.tag.\(Tagesraetsel.tag())") { Label("Heute geschafft in \(b) Zügen", systemImage: "checkmark.seal.fill").font(.footnote).foregroundStyle(.green) }
            else if let b = Bestleistung.lesen("farbflut.\(stufe)") { Label("Bestleistung: \(b) Züge", systemImage: "trophy").font(.footnote).foregroundStyle(.secondary) }
            Text(stufe == 0 ? "8 × 8, 4 Farben, viele Reservezüge" : (stufe == 1 ? "12 × 12, 6 Farben, wenige Reservezüge" : "14 × 14, 6 Farben, nur 2 Reservezüge")).font(.footnote).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading).card()
    }
}
#endif
