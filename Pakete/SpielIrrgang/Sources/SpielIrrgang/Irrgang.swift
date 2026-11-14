// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import SpielHilfen
import IrrgangKern

@MainActor
public struct IrrgangModul: SpielModul {
    public init() {}
    public let id = "irrgang"
    public let name = "Labyrinth"
    public let gattung = Gattung.raetsel
    public let farbe = AkzentFarbeWert.schiefer
    public let symbol = "square.grid.3x3.topleft.filled"
    public let spielerzahl = 1...1
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "Finde den Ausgang", farbe: farbe, spieler: 1...1,
                            regeln: "Du stehst in der Ecke links oben, der Ausgang ist in der Ecke rechts unten. Wische in eine Richtung: Dein Läufer geht geradeaus und hält erst vor einer Wand, an einer Abzweigung, an einem Funken oder am Ausgang an (er biegt nie von allein ab). Funken liegen in Sackgassen und bringen 50 Punkte extra. Je kürzer dein Weg, desto mehr Bonus. Mit jeder Stufe wird das Labyrinth größer, und ab Stufe 4 siehst du nur einen Ausschnitt rund um deinen Läufer; er ist anfangs groß und wird erst auf höheren Stufen merklich kleiner. „Zug zurück“ nimmt den letzten Wisch zurück, die gelaufenen Schritte zählen für den Bonus aber weiter. Beende den Lauf, wann du willst; deine Punkte zählen.",
                            einzelText: "Ein Spieler: Wie weit kommst du?", zeigtRekord: true,   // Punktelauf: Startseite zeigt Bestwert und Durchschnitt statt Siege und Serie
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            IrrgangSpiel(name: teilnehmer[0].name, ende: ende, abbrechen: abbrechen)
        }.mitZiel("Finde den Weg von links oben zum Ausgang rechts unten, möglichst kurz und mit Funken, und sammle so Punkte.").mitZielSchrittNeu(.ziel("Finde den Weg von links oben zum Ausgang rechts unten, möglichst kurz und mit Funken, und sammle so Punkte. Danach kommt ein größeres Labyrinth. Du spielst allein, ohne Zeitdruck, so lange du willst.")).mitAnleitung(RegelTexteNeu.anleitung(neu: Self.anleitungNeu, alt: Self.anleitung))
            .mitStartInhalt { aktionen in TagesKarte(spiel: "irrgang", spielName: name, titel: "Tageslauf heute", aktionen: aktionen) })   // 1.0 (P5): Tageskarte mit Serie
    }
}

/// Gespeicherter Lauf: Labyrinth samt Zugverlauf und die Serienpunkte.
struct IrrgangStand: Codable {
    var labyrinth: Irrgang
    var punkte: Int
    var stufenGewinn: Int
    var geschafft: Bool
    var tag: Bool
}

struct IrrgangSpiel: View {
    let name: String
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var regular: Bool { sizeClass == .regular }   // B18: auf dem iPad Inhalt mittig, Brett größer
    @State private var labyrinth: Irrgang
    @State private var punkte = 0
    @State private var geschafft = false
    @State private var stufenGewinn = 0
    @State private var tag = false
    @State private var hinweis: Richtung?
    /// T-076: Rückfrage vor „Neue Partie“ und „Tageslauf“, sobald der Lauf begonnen ist (Punkte oder Schritte).
    @State private var neuFragen = false
    @State private var neuAktion: (() -> Void)?

    /// `vorgabe`: festes Labyrinth statt eines zufälligen (nur für die Bildproben der Tests).
    init(name: String, ende: @escaping (SpielEnde) -> Void, abbrechen: @escaping () -> Void, vorgabe: Irrgang? = nil) {
        self.name = name; self.ende = ende; self.abbrechen = abbrechen
        var g = SystemRandomNumberGenerator()
        _labyrinth = State(initialValue: vorgabe ?? Irrgang(stufe: 1, mit: &g))
    }

    private func beenden() {
        let st = geschafft ? labyrinth.stufe : labyrinth.stufe - 1
        // 1.0 (P5): Ein Tageslauf mit mindestens einer geschafften Stufe zählt für die Serie (unter dem Starttag)
        if tag && st >= 1 { TagesSerie.melden(spiel: "irrgang", tag: Tagesraetsel.startTag(spiel: "irrgang"), ergebnis: String(localized: "\(punkte) Punkte") + " · " + String(localized: "Stufe \(st) geschafft")) }
        // S1: „Lauf beenden“ ist kein Sieg. Der Lauf ist ein Punktespiel: Punkte und Bestwert zählen, „Geschafft!“ und Sieg-Buchung entfallen.
        let zusatz = Bestleistung.zusatz("irrgang", tages: tag, wert: punkte, hoeherIstBesser: true)   // zuerst: trägt einen neuen Bestwert ein
        var e = SpielEnde(reihenfolge: [name], punkte: ["\(punkte)"], info: String(localized: "Stufe \(max(st, 0)) geschafft.") + zusatz, einzel: .punkte)
        // Blatt 22 (EB-3): Satz, drei Werte und das letzte Labyrinth als Bild
        e.werte = [EndeWert("Stufe", "\(max(st, 0))"), EndeWert("Punkte", "\(punkte)")]
        if let b = Bestleistung.lesen(Bestleistung.schluessel("irrgang", tages: tag)) { e.werte.append(EndeWert("Bestwert", "\(b)")) }
        let letztes = labyrinth   // Wert festhalten: der Rahmen kennt den Spielstand danach nicht mehr
        e.bild = EndeBild(Text("Das letzte Labyrinth"), hoehe: 320) { groesse in IrrgangEndeBild(labyrinth: letztes, groesse: groesse) }
        ende(e)
    }

    private static func pfeil(_ r: Richtung) -> String {
        switch r { case .nord: String(localized: "nach oben ↑"); case .sued: String(localized: "nach unten ↓"); case .west: String(localized: "nach links ←"); case .ost: String(localized: "nach rechts →") }
    }

    private func weiter() { labyrinth = stufe(labyrinth.stufe + 1); geschafft = false }

    /// Neue Stufe; im Tageslauf ist sie für alle am selben Tag gleich.
    private func stufe(_ nummer: Int) -> Irrgang {
        if tag { var g = Tagesraetsel.generator(spiel: "irrgang", variante: "\(nummer)"); return Irrgang(stufe: nummer, mit: &g) }
        var g = SystemRandomNumberGenerator(); return Irrgang(stufe: nummer, mit: &g)
    }

    private func fragen(_ aktion: @escaping () -> Void) {
        if punkte > 0 || labyrinth.schritte > 0 || labyrinth.stufe > 1 { neuAktion = aktion; neuFragen = true } else { aktion() }
    }

    private func neuerLauf(tages: Bool) { tag = tages; punkte = 0; geschafft = false; labyrinth = stufe(1) }

    @Environment(\.accessibilityReduceMotion) private var bewegungReduziert

    private func wische(_ t: CGSize) {
        guard !geschafft else { return }
        let r: Richtung = abs(t.width) > abs(t.height) ? (t.width > 0 ? .ost : .west) : (t.height > 0 ? .sued : .nord)
        let weg = labyrinth.gleite(r); hinweis = nil
        if !labyrinth.imZiel { ansage(weg > 0 ? String(localized: "Jetzt in Zeile \(labyrinth.y + 1), Spalte \(labyrinth.x + 1)") : String(localized: "Wand")) }
        if labyrinth.imZiel {
            ansage(String(localized: "Ausgang gefunden"))
            stufenGewinn = labyrinth.stufenPunkte(); punkte += stufenGewinn; geschafft = true
        }
    }

    var body: some View {
        VStack(spacing: Theme.kartenAbstand) {
            SpielKopf(mitte: "\(punkte)", linksAktion: abbrechen) {
                RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                    FragNachDenRegelnMenuePunkt()   // KI-3 (Blatt 12): nur mit Apple Intelligence sichtbar
                    Button("Neue Partie", systemImage: "arrow.counterclockwise") { fragen { neuerLauf(tages: false) } }   // T-076: Rückfrage wie in den anderen Spielen
                    Button("Tageslauf", systemImage: "calendar") { fragen { neuerLauf(tages: true) } }
                    if let b = Bestleistung.lesen(Bestleistung.schluessel("irrgang", tages: tag)) { Text("Beste Punktzahl: \(b)") }
                    Button("Lauf beenden", systemImage: "flag.checkered", action: beenden)
                    Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
                }
            }
            if regular { Spacer(minLength: 0) }
            HStack {
                Text("Stufe \(labyrinth.stufe)").font(.footnote.weight(.semibold))
                Spacer()
                Label("\(labyrinth.schritte)", systemImage: "figure.walk").font(.footnote.monospacedDigit()).accessibilityLabel("\(labyrinth.schritte) Schritte")
                Spacer()
                Label("\(labyrinth.gesammelt)/\(labyrinth.gesammelt + labyrinth.funken.count)", systemImage: "sparkle").font(.footnote).foregroundStyle(.orange)
            }.padding(.horizontal, Theme.seitenRand)
            SpielfeldKarte {
                GeometryReader { g in
                    let z = min(g.size.width / CGFloat(labyrinth.breite), g.size.height / CGFloat(labyrinth.hoehe))
                    Canvas { ctx, size in Self.zeichne(labyrinth, voll: false, &ctx, z: z, ox: (size.width - z * CGFloat(labyrinth.breite)) / 2, oy: 0) }
                        .contentShape(Rectangle())
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(Text("Labyrinth, Stufe \(labyrinth.stufe)"))
                        .accessibilityValue(Text("Du bist in Zeile \(labyrinth.y + 1), Spalte \(labyrinth.x + 1). Der Ausgang ist in Zeile \(labyrinth.ziel.y + 1), Spalte \(labyrinth.ziel.x + 1)."))
                        .accessibilityAction(named: Text("Nach oben laufen")) { wische(CGSize(width: 0, height: -100)) }
                        .accessibilityAction(named: Text("Nach unten laufen")) { wische(CGSize(width: 0, height: 100)) }
                        .accessibilityAction(named: Text("Nach links laufen")) { wische(CGSize(width: -100, height: 0)) }
                        .accessibilityAction(named: Text("Nach rechts laufen")) { wische(CGSize(width: 100, height: 0)) }
                }
                .aspectRatio(CGFloat(labyrinth.breite) / CGFloat(labyrinth.hoehe), contentMode: .fit)
            }.padding(.horizontal, Theme.seitenRand)
            if geschafft {
                VStack(spacing: Design.Abstand.s) {
                    Text("Ausgang gefunden! +\(stufenGewinn)").font(.headline)
                    Button("Weiter zu Stufe \(labyrinth.stufe + 1)", action: weiter).buttonStyle(HauptKnopfStil())
                }.padding(.horizontal, Theme.seitenRand)
            } else {
                if let h = hinweis {
                    Label("Tipp: \(Self.pfeil(h))", systemImage: "lightbulb.fill").font(.headline).foregroundStyle(.orange)
                } else {
                    Text("Wische in eine Richtung, um loszulaufen.").font(.footnote).tischHinweis()
                }
                ZugKnoepfe(kannZurueck: labyrinth.kannZurueck, zurueck: { labyrinth.zurueck(); hinweis = nil },
                           tipp: { hinweis = labyrinth.hinweisRichtung(); punkte = max(0, punkte - 25); if let h = hinweis { ansage(String(localized: "Tipp: \(Self.pfeil(h))")) } })
                Text("Ein Tipp kostet 25 Punkte.").font(.footnote).tischHinweis()
            }
            Spacer(minLength: 0)
        }
        .aufTisch()   // Design-Runde 3: in Tinte Filz bis in die Ecken, sonst Seitengrund wie bisher
        .confirmationDialog("Aktuelle Partie abbrechen?", isPresented: $neuFragen, titleVisibility: .visible) {
            Button("Abbrechen und neu starten", role: .destructive) { let a = neuAktion; neuAktion = nil; a?() }
            Button("Weiterspielen", role: .cancel) { neuAktion = nil }
        } message: { Text("Die laufende Partie wird verworfen und neu begonnen.") }
        .onAppear { if Tagesraetsel.wunschAbholen(spiel: "irrgang") { neuerLauf(tages: true) } }   // 1.0 (P5): „Spielen“ auf der Tageskarte der Startseite
        .contentShape(Rectangle())
        .simultaneousGesture(DragGesture(minimumDistance: 18).onEnded { wische($0.translation) })   // Wisch zählt auf der ganzen Fläche (Fund S1-031)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .transaction { if bewegungReduziert { $0.animation = nil } }
        .spielHaptik(zug: labyrinth.x * 1000 + labyrinth.y, erfolg: geschafft)
        .fortsetzbar("irrgang", Binding(
    get: { IrrgangStand(labyrinth: labyrinth, punkte: punkte, stufenGewinn: stufenGewinn, geschafft: geschafft, tag: tag) },
    set: { labyrinth = $0.labyrinth; punkte = $0.punkte; stufenGewinn = $0.stufenGewinn; geschafft = $0.geschafft; tag = $0.tag }),
            pruefen: { $0.labyrinth.istKonsistent })
        #if DEBUG
        .testEndeMelden { beenden() }   // -testZustand ende: „Lauf beenden“ wird nach dem Laden des geschafften Standes selbst gewählt
        #endif
    }

    /// Die Zeichnung des Labyrinths; `voll` zeigt es ganz (Ergebnisseite, Blatt 22), sonst mit dem Ausschnitt der Stufe wie am Tisch.
    static func zeichne(_ m: Irrgang, voll: Bool = false, _ ctx: inout GraphicsContext, z: CGFloat, ox: CGFloat, oy: CGFloat) {
        let sicht = voll ? nil : Irrgang.sichtweite(stufe: m.stufe)
        let akzent = Color.appFlaeche
        let wandFarbe = Design.ist(.klar) ? Color.primary : Color.schrift   // Tinte und Salon: Tinte bzw. Espresso
        func sichtbar(_ x: Int, _ y: Int) -> Int {     // 2 = hell, 1 = gemerkt, 0 = dunkel
            guard let s = sicht else { return 2 }
            if max(abs(x - m.x), abs(y - m.y)) <= s { return 2 }
            return m.besucht.contains(y * m.breite + x) ? 1 : 0
        }
        for y in 0..<m.hoehe {
            for x in 0..<m.breite {
                let v = sichtbar(x, y)
                guard v > 0 else { continue }
                let r = CGRect(x: ox + CGFloat(x) * z, y: oy + CGFloat(y) * z, width: z, height: z)
                let a = v == 2 ? 1.0 : 0.4
                if x == m.ziel.x && y == m.ziel.y { ctx.fill(Path(r.insetBy(dx: 1, dy: 1)), with: .color(.green.opacity(0.35 * a))) }
                if m.funken.contains(y * m.breite + x) {
                    let s = z * 0.28
                    ctx.fill(Path(ellipseIn: CGRect(x: r.midX - s / 2, y: r.midY - s / 2, width: s, height: s)), with: .color(.yellow.opacity(a)))
                }
                var wand = Path()
                if !m.offen[y][x][Richtung.nord.rawValue] { wand.move(to: CGPoint(x: r.minX, y: r.minY)); wand.addLine(to: CGPoint(x: r.maxX, y: r.minY)) }
                if !m.offen[y][x][Richtung.west.rawValue] { wand.move(to: CGPoint(x: r.minX, y: r.minY)); wand.addLine(to: CGPoint(x: r.minX, y: r.maxY)) }
                if !m.offen[y][x][Richtung.sued.rawValue] { wand.move(to: CGPoint(x: r.minX, y: r.maxY)); wand.addLine(to: CGPoint(x: r.maxX, y: r.maxY)) }
                if !m.offen[y][x][Richtung.ost.rawValue] { wand.move(to: CGPoint(x: r.maxX, y: r.minY)); wand.addLine(to: CGPoint(x: r.maxX, y: r.maxY)) }
                ctx.stroke(wand, with: .color(wandFarbe.opacity(0.8 * a)), style: StrokeStyle(lineWidth: max(2, z * 0.08), lineCap: .round))
            }
        }
        let c = CGPoint(x: ox + (CGFloat(m.x) + 0.5) * z, y: oy + (CGFloat(m.y) + 0.5) * z)
        let rr = z * 0.3
        ctx.fill(Path(ellipseIn: CGRect(x: c.x - rr, y: c.y - rr, width: rr * 2, height: rr * 2)), with: .color(akzent))
        ctx.stroke(Path(ellipseIn: CGRect(x: c.x - rr, y: c.y - rr, width: rr * 2, height: rr * 2)), with: .color(.white), lineWidth: 1.5)
    }
}
#endif
