// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import SpielHilfen
import SchiebepuzzleKern

@MainActor
public struct SchiebepuzzleModul: SpielModul {
    public init() {}
    public let id = "schiebepuzzle"
    public let name = "Schiebepuzzle"
    public let gattung = Gattung.raetsel
    public let farbe = AkzentFarbeWert.blau
    public let symbol = "square.grid.3x3.square"
    public let spielerzahl = 1...1
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "Kacheln in die richtige Reihenfolge schieben", farbe: farbe, spieler: 1...1,
                            regeln: "Schiebe die Kacheln in die Lücke, bis die Zahlen von 1 an der Reihe nach stehen und die Lücke unten rechts ist. Tippe eine Kachel in der Reihe der Lücke, um sie (und alle dazwischen) zu verschieben. Weniger Züge sind besser.",
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            SchiebepuzzleSpiel(name: teilnehmer[0].name, ende: ende, abbrechen: abbrechen)
        }.mitStartOptionen { _ in SchiebepuzzleStartWahl() }   // Blatt 20: Wahl auf der Spielseite (nur Tinte, sonst leer)
        .mitZiel("Ordne die Kacheln der Reihe nach von 1 an, mit der Lücke unten rechts, in möglichst wenigen Zügen.").mitZielSchrittNeu(.ziel("Ordne die Kacheln der Reihe nach von 1 an, mit der Lücke unten rechts. Du spielst allein und versuchst, mit möglichst wenigen Zügen auszukommen. Jedes Brett lässt sich lösen.")).mitAnleitung(RegelTexteNeu.anleitung(neu: Self.anleitungNeu, alt: Self.anleitung)))
    }
}

struct SchiebepuzzleSpiel: View {
    @Environment(\.accessibilityReduceMotion) private var bewegungReduziert
    @Environment(\.scenePhase) private var szenenPhase
    let name: String
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.designArt) private var art   // zeichnet beim Designwechsel neu
    private var tinte: Bool { art == .tinte }
    private var regular: Bool { sizeClass == .regular }   // B18: auf dem iPad Inhalt mittig, Brett größer
    @State private var n = 4
    @State private var puzzle: Schiebepuzzle
    @State private var undo = RueckgaengigVerlauf<Schiebepuzzle>()
    @State private var start = Date()
    /// Spielzeit aus früheren Sitzungen (nach dem Fortsetzen); die laufende Sitzung zählt ab `start` dazu.
    @State private var vorherSekunden = 0
    private var sekunden: Int { vorherSekunden + max(0, Int(Date().timeIntervalSince(start))) }
    @State private var zufall = SystemRandomNumberGenerator()
    @State private var tag = false
    @State private var tipp: Int?
    @State private var tipps = 0
    @State private var rechnet = false

    /// Das erste Brett wird schon hier gemischt und nicht erst beim Erscheinen: Sonst überschrieb das Mischen je nach
    /// Reihenfolge den gerade geladenen Stand. Ein gespeicherter Stand ersetzt dieses Brett beim Fortsetzen.
    init(name: String, ende: @escaping (SpielEnde) -> Void, abbrechen: @escaping () -> Void) {
        self.name = name; self.ende = ende; self.abbrechen = abbrechen
        var g = SystemRandomNumberGenerator()
        // Blatt 20 (nur Tinte): Wahl von der Spielseite (Größe, Tagesrätsel) abholen
        var kante = 4, tagesStart = false
        if Design.ist(.tinte) {
            let gw = UserDefaults.standard.integer(forKey: SchiebepuzzleStartWahl.groesseSchluessel)
            if SchiebepuzzleStartWahl.groessen.contains(gw) { kante = gw }
            tagesStart = UserDefaults.standard.string(forKey: SchiebepuzzleStartWahl.schluessel) == "tag"
        }
        var p = Schiebepuzzle(n: kante)
        if tagesStart { var t = Tagesraetsel.reinerGenerator(spiel: "schiebepuzzle", variante: "\(kante)"); p.mischen(mit: &t) } else { p.mischen(mit: &g) }
        _puzzle = State(initialValue: p)
        _n = State(initialValue: kante)
        _tag = State(initialValue: tagesStart)
    }

    var body: some View {
        VStack(spacing: Theme.kartenAbstand) {
            SpielKopf(mitte: puzzle.zuege == 1 ? String(localized: "1 Zug") : String(localized: "\(puzzle.zuege) Züge"), linksAktion: abbrechen) {
                RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                    FragNachDenRegelnMenuePunkt()   // KI-3 (Blatt 12): nur mit Apple Intelligence sichtbar
                    Button("Rückgängig", systemImage: "arrow.uturn.backward") { undo.zurueck(&puzzle) }.disabled(!undo.kann)
                    Button("Neu mischen", systemImage: "shuffle") { tag = false; neu() }
                    Button("Tagesrätsel", systemImage: "calendar") { tag = true; neu() }
                    if let b = Bestleistung.lesen(Bestleistung.ergebnisSchluessel("schiebepuzzle", variante: "\(puzzle.n)", tages: tag)) { Text("Beste Zugzahl: \(b)") }
                    Picker("Größe", selection: Binding(get: { puzzle.n }, set: { n = $0; neu() })) { Text("3 × 3").tag(3); Text("4 × 4").tag(4); Text("5 × 5").tag(5); Text("6 × 6").tag(6) }
                    Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
                }
            }
            Spacer(minLength: 0)   // Brett mittig statt oben
            brettFassung {
                GeometryReader { g in
                    let seite = min(g.size.width, g.size.height)
                    let n = puzzle.n
                    let kachel = (seite - CGFloat(n - 1) * 6) / CGFloat(n)
                    ZStack(alignment: .topLeading) {
                        ForEach(puzzle.felder.indices, id: \.self) { i in
                            let wert = puzzle.felder[i]
                            if wert != 0 {
                                Button { schiebe(i) } label: {
                                    Text("\(wert)")
                                        .font(.system(size: kachel * 0.42, weight: .bold, design: Design.zahlDesign).monospacedDigit())   // design:spielinhalt (skaliert mit Feld/Karte/Würfel)
                                        .frame(width: kachel, height: kachel)
                                        .foregroundStyle(tinte ? Tisch.auge : Color.white)   // Große Tinte-Runde, Punkt 8: helle Steine auf dem Filz
                                        .background(tinte ? Tisch.elfenbein.opacity(wert == i + 1 ? 1 : 0.88) : Color.appFlaeche.opacity(wert == i + 1 ? 1 : 0.8), in: .rect(cornerRadius: Theme.feldRadius))
                                        .overlay(RoundedRectangle(cornerRadius: Theme.feldRadius).stroke(Color.yellow, lineWidth: tipp == i ? 4 : 0))
                                }
                                .buttonStyle(.plain)
                                .position(x: CGFloat(i % n) * (kachel + 6) + kachel / 2, y: CGFloat(i / n) * (kachel + 6) + kachel / 2)
                                .accessibilityLabel("Kachel \(wert), Zeile \(i / n + 1), Spalte \(i % n + 1)\(wert == i + 1 ? String(localized: ", am richtigen Platz") : "")")
                                .accessibilityHint(Text("Schiebt die Kachel in Richtung der Lücke, wenn sie in derselben Reihe oder Spalte liegt."))
                                .accessibilityAddTraits(tipp == i ? .isSelected : [])
                                .accessibilityValue(tipp == i ? Text("Tipp: diese Kachel als Nächstes schieben") : Text(""))
                            }
                        }
                    }
                    .frame(width: seite, height: seite)
                    .animation(bewegungReduziert ? nil : .snappy(duration: 0.18), value: puzzle.felder)   // G3
                }
                .frame(maxWidth: regular ? 880 : Theme.wideColumnWidth).aspectRatio(1, contentMode: .fit)   // G-004/M-010: erst Breite begrenzen, dann quadratisch – das Brett füllt die Breite
            }
            .padding(.horizontal, Theme.seitenRand)
            Button { holeTipp() } label: { if rechnet { ProgressView() } else { Label("Tipp", systemImage: "lightbulb") } }.tischNebenKnopf().dynamicTypeSize(...DynamicTypeSize.xxxLarge).disabled(rechnet || puzzle.geloest)
                .accessibilityLabel(rechnet ? Text("Tipp wird berechnet") : Text("Tipp"))
            Spacer(minLength: 0)
        }
        .aufTisch()   // Große Tinte-Runde, Punkt 8: Tinte = Filz, sonst Seitengrund wie bisher
        .onAppear { if tag { Tagesraetsel.merkeStart(spiel: "schiebepuzzle") } }   // T-055: nicht im init schreiben
        .onChange(of: szenenPhase) { _, neu in
            // Hintergrundzeit zählt nicht mit (C-032): beim Verlassen falten, beim Zurückkehren neu ansetzen.
            if neu == .active { start = Date() } else { vorherSekunden = sekunden; start = Date() }
        }
        .spielHaptik(zug: puzzle, erfolg: puzzle.geloest, fehler: false)
        // Gespeichert wird der ganze Stand (Zeit, Tipps, Tagesrätsel), nicht nur das Brett.
        .fortsetzbar("schiebepuzzle", Binding(
            get: { SchiebepuzzleStand(puzzle: puzzle, sekunden: sekunden, tipps: tipps, tag: tag) },
            set: { s in
                undo.leeren()   // der Wechsel auf den geladenen Stand ist kein Zug, den man zurücknehmen kann
                puzzle = s.puzzle; n = s.puzzle.n; tag = s.tag; tipps = s.tipps
                vorherSekunden = s.sekunden; start = Date(); tipp = nil
            }), pruefen: { $0.istKonsistent && !$0.puzzle.geloest })
        .rueckgaengigMerken(puzzle, in: undo)
        #if DEBUG
        .testEndeMelden { if let h = puzzle.hinweis() { schiebe(h) } }   // -testZustand ende: der letzte Zug (der Tipp-Zug) wird nach dem Laden gespielt
        #endif
    }

    /// Brett: Tinte legt es als runde, leicht aufgehellte Fläche auf den Filz, sonst die Spielfeld-Karte wie bisher.
    @ViewBuilder private func brettFassung<Inhalt: View>(@ViewBuilder _ inhalt: () -> Inhalt) -> some View {
        if tinte { inhalt().padding(Theme.spielfeldRand).tischFlaeche(Theme.cardRadius) }
        else { SpielfeldKarte { inhalt() } }
    }

    private func neu() {
        undo.leeren()
        puzzle = Schiebepuzzle(n: n)
        if tag { var g = Tagesraetsel.generator(spiel: "schiebepuzzle", variante: "\(n)"); puzzle.mischen(mit: &g) } else { puzzle.mischen(mit: &zufall) }
        start = Date(); vorherSekunden = 0; tipp = nil; tipps = 0
    }

    private func holeTipp() {
        rechnet = true
        let kopie = puzzle
        Task {
            let h = await Task.detached(priority: .userInitiated) { kopie.hinweis() }.value
            if puzzle == kopie, let h {
                tipp = h; tipps += 1
                ansage(String(localized: "Tipp: Kachel \(puzzle.felder[h]) in Zeile \(h / puzzle.n + 1), Spalte \(h % puzzle.n + 1) schieben"))
            }
            rechnet = false
        }
    }

    private func schiebe(_ i: Int) {
        guard puzzle.schiebe(i) else { return }
        tipp = nil
        if !puzzle.geloest { ansage(String(localized: "Lücke jetzt in Zeile \(puzzle.luecke / puzzle.n + 1), Spalte \(puzzle.luecke % puzzle.n + 1)")) }
        if puzzle.geloest {
            var fertig = SpielEnde(reihenfolge: [name], info: (puzzle.zuege == 1 ? String(localized: "1 Zug in \(sekunden) Sekunden") : String(localized: "\(puzzle.zuege) Züge in \(sekunden) Sekunden"))   /* Fund 29: Einzahl */ + (tipps == 0 ? Bestleistung.zusatz("schiebepuzzle", variante: "\(puzzle.n)", tages: tag, wert: puzzle.zuege) : ""))
            fertig.dauer = TimeInterval(sekunden)   // C-017: reine Spielzeit statt Wanduhr
            // Blatt 22 (EB-3): zwei bis drei Werte und die Kacheln in der richtigen Reihenfolge als Bild
            fertig.werte = [EndeWert("Größe", "\(puzzle.n) × \(puzzle.n)"), EndeWert("Züge", "\(puzzle.zuege)"), EndeWert("Zeit", Zeitformat.text(sekunden: sekunden))]
            let kante = puzzle.n
            fertig.bild = EndeBild(Text("Steine in der richtigen Reihenfolge"), hoehe: 320) { groesse in SchiebepuzzleEndeBild(n: kante, groesse: groesse) }
            ende(fertig)
        }
    }
}
#endif
