// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import SpielHilfen
import MuehleKern

@MainActor
public struct MuehleModul: SpielModul {
    public init() {}
    public let id = "muehle"
    public let name = "Mühle"
    public let gattung = Gattung.brett
    public let farbe = AkzentFarbeWert.tuerkis
    public let symbol = "circle.hexagongrid.fill"
    public let spielerzahl = 1...2
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "Drei in einer Reihe", farbe: farbe, spieler: 2...2, computerErlaubt: true,
                            regeln: "Jeder hat neun Steine (bei der Regelart „Kurz“ sechs). Erst setzt ihr abwechselnd auf die Punkte, danach zieht ihr einen Stein auf einen freien Nachbarpunkt. Drei Steine in einer Linie sind eine Mühle: dann nimmst du einen Stein des Gegners vom Brett (nicht aus einer Mühle, außer es gibt nur noch Mühlen). Wer nur noch drei Steine hat, darf springen (außer bei „Ohne Springen“). Wer weniger als drei Steine hat, sobald nichts mehr zu setzen ist, oder nicht mehr ziehen kann, verliert. Gibt es 60 Züge lang keine Mühle, ist die Partie remis. Die Regelart (Klassisch, Kurz, Ohne Springen, Auch aus Mühlen) wählst du vor dem ersten Zug im Mehr-Menü. Wer beginnt, wählst du vor dem Start; bei „Abwechselnd“ beginnt in der Revanche der andere.",
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            MuehleSpiel(teilnehmer: teilnehmer, ende: ende, abbrechen: abbrechen)
        }.mitStartOptionen { WerBeginntKarte(spiel: "muehle", eintraege: $0) }   // 1.0 (M7): Wer beginnt
        .mitZiel("Bilde Mühlen und nimm dem Gegner Steine weg, bis er nur noch zwei hat (nachdem alle gesetzt sind) oder nicht mehr ziehen kann.").mitZielSchrittNeu(.ziel("Bilde Mühlen und nimm dem Gegner Steine weg, bis er nur noch zwei hat oder sich nicht mehr bewegen kann. Mühle ist ein uraltes Brettspiel für zwei. Jede Seite hat 9 Steine. Es gibt kein Glück, nur gutes Vorausdenken. Du spielst zu zweit an einem Gerät oder gegen den Computer."))
        .mitAnleitung(RegelTexteNeu.anleitung(neu: Self.anleitungNeu, alt: Self.anleitung)))
    }

    static var anleitung: [AnleitungSchritt] { [
            .figuren(symbol: "circle.grid.3x3", titel: "Steine setzen", text: "Ihr setzt abwechselnd Steine auf die Punkte des Brettes.", figuren: ["⚪️","⚫️","⚪️"], bewegt: nil),
            .figuren(symbol: "line.3.horizontal", titel: "Mühle bilden", text: "Drei eigene Steine in einer Linie sind eine Mühle. Dann nimmst du einen Stein des Gegners weg.", figuren: ["⚪️","⚪️","⚪️"], bewegt: nil),
            .figuren(symbol: "arrow.left.and.right", titel: "Ziehen und springen", text: "Danach zieht ihr auf freie Nachbarpunkte. Mit nur noch drei Steinen darfst du springen. Die Regelart wählst du im Mehr-Menü.", figuren: ["⚪️","▫️"], bewegt: 0),
        ] }

    /// Neue deutsche Fassung (Regeltexte neu, Build 25) ohne Zielseite.
    static var anleitungNeu: [AnleitungSchritt] { [
        .figuren(symbol: "square.grid.3x3", titel: "Das Brett", text: "Das Brett besteht aus drei Quadraten, eins im anderen. Es hat 24 Punkte: die Ecken und die Seitenmitten. Die Seitenmitten sind durch Linien verbunden. Auf diesen Punkten stehen die Steine, immer nur einer pro Punkt. Steine bewegen sich nur entlang der Linien, nie schräg.", figuren: ["🔲","▫️","▫️"]),
        .figuren(symbol: "circle.grid.2x1", titel: "Steine setzen", text: "Zuerst setzt ihr abwechselnd je einen Stein auf einen freien Punkt. Tippe dafür einfach einen Punkt an. So geht es weiter, bis alle Steine auf dem Brett sind. Schon jetzt lohnt es sich aufzupassen: Wer drei Steine in eine Linie bekommt, hat eine Mühle. Unter dem Brett steht, wie viele Steine du noch setzen kannst.", figuren: ["⚪️","⚫️","⚪️"]),
        .figuren(symbol: "line.3.horizontal", titel: "Mühle bilden", text: "Drei eigene Steine in einer Linie sind eine Mühle. Dann nimmst du sofort einen Stein des Gegners vom Brett. Die Steine, die du nehmen darfst, bekommen einen roten Ring. Steine aus einer Mühle des Gegners sind geschützt, außer er hat nur noch Mühlen. Wer zwei Mühlen auf einmal schließt, nimmt trotzdem nur einen Stein.", figuren: ["⚪️","⚪️","⚪️"], bewegt: 2),
        .figuren(symbol: "arrow.right.circle", titel: "Ziehen", text: "Sind alle Steine gesetzt, zieht ihr. Tippe einen eigenen Stein an, dann einen freien Nachbarpunkt. Die möglichen Ziele zeigt die App mit einem Ring. Ein Trick: Zieh einen Stein aus deiner Mühle heraus und im nächsten Zug zurück. Dann hast du wieder eine Mühle und darfst wieder einen Stein nehmen.", figuren: ["⚪️","▫️"], bewegt: 0),
        .figuren(symbol: "flag.checkered", titel: "Springen und gewinnen", text: "Hast du nur noch drei Steine, darfst du springen: Dein Stein darf auf jeden freien Punkt. Wer nur noch zwei Steine hat oder sich nicht mehr bewegen kann, verliert. Werden 60 Züge lang keine Steine genommen, endet die Partie unentschieden.", figuren: ["⚪️","⚪️","⚪️","✨"], bewegt: 2),
        .figuren(symbol: "slider.horizontal.3", titel: "Regelarten und Hilfen", text: "Unter „Mehr“ → „Regeln“ wählst du vor dem ersten Zug eine Regelart: Klassisch, Kurz mit 6 Steinen, Ohne Springen oder Auch aus Mühlen schlagen. Dort stellst du auch die Stärke des Computers ein. „Tipp“ zeigt dir einen guten Zug, „Zug zurück“ nimmt deinen letzten Schritt zurück. Alles Weitere steht unter „Alle Regeln lesen“.", figuren: ["⚙️","💡","↩️"]),
    ] }
}

struct MuehleSpiel: View {
    let teilnehmer: [SpielTeilnehmer]
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void

    @Environment(\.horizontalSizeClass) private var sizeClass
    private var regular: Bool { sizeClass == .regular }   // B18: auf dem iPad Inhalt mittig, Brett größer
    @State private var art = MuehleArt.gespeichert
    @State private var spiel: Muehle
    @State private var gewaehlt: Int?
    @State private var denkt = false
    /// Laufende Berechnung des Computerzugs; wird beim Verlassen der Ansicht (Beenden, Zurück) abgebrochen,
    /// damit sie danach weder zieht noch das Ende meldet.
    @State private var rechnung: Task<Void, Never>?
    @State private var rechenLauf = 0
    @State private var verlassen = false
    @State private var verlauf: [Muehle] = []
    @State private var tipp: MuehleZug?
    @State private var tippRechnet = false
    @State private var stufe = ComputerStufe.gespeichert("muehle")
    @AppStorage(GegenueberEinstellung.schluessel) private var gegenueberAn = true

    /// `vorgabe`: feste Stellung statt eines leeren Bretts (nur für die Bildproben der Tests).
    init(teilnehmer: [SpielTeilnehmer], ende: @escaping (SpielEnde) -> Void, abbrechen: @escaping () -> Void, vorgabe: Muehle? = nil, waehle: Int? = nil) {
        self.teilnehmer = teilnehmer; self.ende = ende; self.abbrechen = abbrechen
        _spiel = State(initialValue: vorgabe ?? Muehle(regeln: MuehleArt.gespeichert.regeln, beginner: StartSpieler.naechster("muehle")))   // 1.0 (M7)
        _gewaehlt = State(initialValue: waehle)   // nur für die Bildproben: gewählter Stein, damit die Zielpunkte markiert sind
    }
    private var gegenueber: Bool { GegenueberEinstellung.gilt(fuer: teilnehmer, eingeschaltet: gegenueberAn) }
    private func band(_ s: Int) -> GegenueberBand {
        GegenueberBand(name: name(s), farbe: s == 1 ? .gray : .black, hinweis: hinweis, dran: spiel.dran == s && !spiel.vorbei)
    }
    private var staerke: MuehleStaerke { switch stufe { case .leicht: .leicht; case .mittel: .mittel; case .schwer: .schwer } }

    private func punkt(_ i: Int) -> (x: CGFloat, y: CGFloat) {
        let r = i / 8, k = i % 8, o = CGFloat(r), mitte: CGFloat = 3, m = 6 - o
        switch k {
        case 0: return (o, o); case 1: return (mitte, o); case 2: return (m, o); case 3: return (m, mitte)
        case 4: return (m, m); case 5: return (mitte, m); case 6: return (o, m); default: return (o, mitte)
        }
    }

    private func name(_ s: Int) -> String { teilnehmer[s - 1].name }
    private func istComputer(_ s: Int) -> Bool { teilnehmer[s - 1].computer }
    /// Markierung der möglichen Züge: Klar & Glas die Akzentfarbe wie bisher, Tinte und Salon die Farbe der Spielart (Rolle des Designs).
    private var zugFarbe: Color { Tisch.aktiv ? Color(hex: 0xFFD166) : Design.ist(.klar) ? Color.appFlaeche : (Design.spielFarben?.flaeche ?? Color.appFlaeche) }

    private func farbe(_ s: Int) -> Color { s == 1 ? Color(white: 0.88) : Color(white: 0.18) }

    private var hinweis: LocalizedStringKey {
        if denkt { return "\(name(spiel.dran)) denkt nach …" }
        if spiel.mussEntfernen { return "\(name(spiel.dran)): Mühle! Nimm einen Stein des Gegners." }
        if spiel.setzphase { return "\(name(spiel.dran)) setzt (\(spiel.vorrat[spiel.dran]) übrig)" }
        return gewaehlt == nil ? "\(name(spiel.dran)) zieht: wähle einen Stein" : "Wähle den Zielpunkt"
    }

    var body: some View {
        VStack(spacing: Theme.kartenAbstand) {
            SpielKopf(mitte: name(spiel.dran), linksAktion: abbrechen) {
                RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                    FragNachDenRegelnMenuePunkt()   // KI-3 (Blatt 12): nur mit Apple Intelligence sichtbar
                    if teilnehmer.contains(where: \.computer) {
                        ComputerStufePicker(spiel: "muehle", stufe: $stufe)
                    }
                    Picker("Regeln", selection: $art) {
                        ForEach(MuehleArt.allCases) { Text($0.titel).tag($0) }
                    }
                    .disabled(begonnen || denkt)   // nur vor dem ersten Zug, auch nach dem Fortsetzen
                    Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
                }
            }
            if regular { Spacer(minLength: 0) }
            if !gegenueber {
                SpielerLeiste(eintraege: [1, 2].map { s in
                    .init(id: "\(s)", name: name(s), farbe: s == 1 ? .gray : .black, wert: "\(spiel.gesamt(s))")
                }, aktiv: "\(spiel.dran)").padding(.horizontal, Theme.seitenRand)
            }
            SpielfeldKarte {
                GeometryReader { g in
                    let seite = min(g.size.width, g.size.height)
                    let schritt = (seite - 40) / 6
                    let p = { (i: Int) -> CGPoint in let c = punkt(i); return CGPoint(x: 20 + c.x * schritt, y: 20 + c.y * schritt) }
                    ZStack {
                        Canvas { ctx, _ in
                            var weg = Path()
                            for (i, ns) in Muehle.nachbarn.enumerated() { for j in ns where j > i { weg.move(to: p(i)); weg.addLine(to: p(j)) } }
                            ctx.stroke(weg, with: .color(Design.ist(.klar) ? Color.secondary.opacity(0.6) : Color.linieStark), lineWidth: Design.ist(.klar) ? 2 : 1.5)
                        }
                        ForEach(0..<24, id: \.self) { i in
                            let stein = spiel.brett[i]
                            let ziel = zielFrei(i)
                            Button { tippe(i) } label: {
                                ZStack {
                                    Circle().fill(stein == 0 ? (Design.ist(.klar) ? Color(.tertiarySystemFill) : Color.linieStark.opacity(0.35)) : farbe(stein))
                                        .overlay(Circle().strokeBorder(stein == 0 ? .clear : (Design.ist(.klar) ? Color.primary.opacity(0.55) : (stein == 2 ? Color(white: 0.85) : Color.linieStark)), lineWidth: Design.ist(.klar) ? 2 : 1.5))
                                    if ziel { Circle().strokeBorder(zugFarbe, lineWidth: 3) }   // design:spielinhalt (Markierung auf dem Spielmaterial)
                                    if gewaehlt == i { Circle().strokeBorder(zugFarbe, lineWidth: 4).padding(-4) }   // design:spielinhalt (Markierung auf dem Spielmaterial)
                                    if tippPunkte.contains(i) { Circle().strokeBorder(Color.yellow, lineWidth: 4).padding(-3) }
                                    if spiel.mussEntfernen, stein == spiel.gegner, spiel.zuege().contains(.entferne(i)) {
                                        Circle().strokeBorder(Color.red, lineWidth: 3)   // design:spielinhalt (Markierung auf dem Spielmaterial)
                                    }
                                }
                                .frame(width: stein == 0 ? 22 : 38, height: stein == 0 ? 22 : 38)
                                .frame(width: 44, height: 44).contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .position(p(i))
                            .accessibilityLabel(stein == 0 ? Text("Punkt \(i + 1), frei") : Text("Punkt \(i + 1), Stein von \(name(stein))"))
                            .accessibilityValue(ziel ? Text("mögliches Ziel") : (spiel.mussEntfernen && stein == spiel.gegner ? Text("kann entfernt werden") : Text(verbatim: "")))
                            .accessibilityAddTraits(gewaehlt == i ? .isSelected : [])
                        }
                    }
                    .frame(width: seite, height: seite)
                }
                .aspectRatio(1, contentMode: .fit).frame(maxWidth: regular ? 880 : Theme.wideColumnWidth)
            }
            .background { if Tisch.aktiv { RoundedRectangle(cornerRadius: 24).fill(Color.white.opacity(0.10)) } }   // Design-Runde 3: das Brett als helle Platte auf dem Filz
            .gegenueberModus(aktiv: gegenueber, oben: band(2), unten: band(1))
            .padding(.horizontal, gegenueber ? 0 : Theme.seitenRand)
            ZugKnoepfe(kannZurueck: !verlauf.isEmpty && !denkt, tippMoeglich: !istComputer(spiel.dran) && !spiel.vorbei, rechnet: tippRechnet, zurueck: zurueck, tipp: holeTipp)
            if !gegenueber { Text(hinweis).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal, Theme.seitenRand) }
            Spacer(minLength: 0)
        }
        .aufTisch()   // Design-Runde 3: in Tinte Filz bis in die Ecken, sonst Seitengrund wie bisher
        // Gespeichert wird die Stellung samt Zugverlauf. Die gespeicherte Regel bleibt: Die Auswahl im Menü folgt dem geladenen Stand.
        .fortsetzbar("muehle", Binding(
            get: { MuehleStand(spiel: spiel, verlauf: verlauf) },
            set: { s in
                spiel = s.spiel; verlauf = s.verlauf; gewaehlt = nil; tipp = nil
                if let a = MuehleArt.allCases.first(where: { $0.regeln == s.spiel.regeln }) { art = a }
            }), pruefen: { $0.istKonsistent }, standGeladen: { _ in if !begonnen { StartSpieler.merke(spiel.dran, spiel: "muehle") } })   // 1.0 (M7): Beginner merken, solange kein Zug gemacht ist (auch wenn die frische Partie schon gesichert wurde)
        // B21: Auch die frische Partie ohne Zug gleich sichern, sonst gibt es bis zum ersten Zug weder „Pausieren“ noch „Partie fortsetzen“.
        .onAppear { if !SpielStand.vorhanden("muehle"), !spiel.vorbei { SpielStand.sichern(MuehleStand(spiel: spiel, verlauf: verlauf), spiel: "muehle") } }
        .weicheAnimation(bei: spiel)
        .spielHaptik(zug: spiel, erfolg: (spiel.vorbei))
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .onChange(of: art) { _, neu in
            neu.sichern()
            if !begonnen, spiel.regeln != neu.regeln { spiel = Muehle(regeln: neu.regeln, beginner: spiel.dran); gewaehlt = nil; tipp = nil }
        }
        // Der Computer hängt am Stand, nicht am Erscheinen: Er zieht auch nach dem Laden eines Stands, in dem er am Zug ist.
        .computerZug(aktiv: !verlassen && !spiel.vorbei && istComputer(spiel.dran), id: spiel, verzoegerung: 0.45) { computerAmZug() }
        .onDisappear { verlassen = true; rechenLauf += 1; rechnung?.cancel(); denkt = false }
        .onAppear { if verlassen { verlassen = false; computerAmZug() } }   // nur verdeckt gewesen: der Computer rechnet neu
        #if DEBUG
        .testEndeMelden {   // -testZustand ende: der letzte, entscheidende Zug (Stein entfernen) wird nach dem Laden gespielt
            guard let z = spiel.zuege().first(where: { var k = spiel; k.spiele($0); return k.sieger != nil }) else { return }
            zieh(z)
        }
        #endif
    }

    private var tippPunkte: Set<Int> {
        switch tipp { case .setze(let p)?: [p]; case .ziehe(let a, let b)?: [a, b]; case .entferne(let p)?: [p]; case nil: [] }
    }

    /// Die Partie läuft schon (eigener Zug gemacht oder Steine auf dem Brett): Die Regel lässt sich nicht mehr wechseln.
    private var begonnen: Bool { MuehleStand(spiel: spiel, verlauf: verlauf).begonnen }

    private func zurueck() {
        tipp = nil; gewaehlt = nil
        while let l = verlauf.popLast() { spiel = l; if !istComputer(l.dran) { break } }
    }

    private func holeTipp() {
        tippRechnet = true
        let stand = spiel
        Task {
            let z = await Task.detached { MuehleComputer.wahl(stand, tiefe: stand.setzphase ? 3 : 4) }.value
            if spiel == stand { tipp = z; gewaehlt = nil }
            tippRechnet = false
        }
    }

    private func zielFrei(_ i: Int) -> Bool {
        guard !denkt, !istComputer(spiel.dran), !spiel.mussEntfernen else { return false }
        if spiel.setzphase { return spiel.brett[i] == 0 }
        guard let g = gewaehlt else { return false }
        return spiel.zuege().contains(.ziehe(g, i))
    }

    private func tippe(_ i: Int) {
        guard !denkt, !istComputer(spiel.dran), !spiel.vorbei else { return }
        if spiel.mussEntfernen { zieh(.entferne(i)); return }
        if spiel.setzphase { zieh(.setze(i)); return }
        if spiel.brett[i] == spiel.dran { gewaehlt = i; return }
        if let g = gewaehlt, spiel.zuege().contains(.ziehe(g, i)) { zieh(.ziehe(g, i)) }
    }

    private func zieh(_ z: MuehleZug) {
        let vorher = spiel
        guard !verlassen, spiel.spiele(z) else { return }
        if !istComputer(vorher.dran) { verlauf.append(vorher); SpielZug.gemacht("muehle") }
        gewaehlt = nil; tipp = nil
        if spiel.remis {
            ende(mitBild(SpielEnde(reihenfolge: [name(1), name(2)], punkte: ["\(spiel.gesamt(1))", "\(spiel.gesamt(2))"], plaetze: [1, 1], info: String(localized: "Remis – 60 Züge ohne Mühle"))))
            return
        }
        if let s = spiel.sieger { beenden(s) }
    }

    private func computerAmZug() {
        guard !verlassen, !spiel.vorbei, istComputer(spiel.dran) else { return }
        denkt = true
        let stand = spiel, st = staerke
        rechenLauf += 1
        let lauf = rechenLauf
        rechnung?.cancel()
        rechnung = Task {
            let zug = await Task.detached { MuehleComputer.wahl(stand, staerke: st) }.value
            guard lauf == rechenLauf else { return }   // eine neuere Berechnung läuft, oder die Ansicht wurde verlassen
            denkt = false
            // Nur ziehen (und gegebenenfalls das Ende melden), wenn die Partie noch dieselbe ist.
            guard !Task.isCancelled, !verlassen, spiel == stand else { return }
            if let zug { zieh(zug) }
        }
    }

    private func beenden(_ s: Int) {
        ende(mitBild(SpielEnde(reihenfolge: [name(s), name(3 - s)], punkte: ["\(spiel.gesamt(s))", "\(spiel.gesamt(3 - s))"],
                               info: String(localized: "\(name(s)) gewinnt"))))
    }

    /// Blatt 22 (EB-3): die Dauer und das Brett am Ende (die Zeichnung vom Tisch, als Wert festgehalten)
    private func mitBild(_ basis: SpielEnde) -> SpielEnde {
        var e = basis
        e.werte = [.dauer]
        // Schritt 2: „Mühlen geschlossen“; ein alter Stand zählt nicht (nil), dann fehlt die Zeile einfach
        if let m = spiel.geschlosseneMuehlen, m.count == 3 { e.werte.append(EndeWert("Mühlen geschlossen", "\(m[1] + m[2])")) }
        let brett = spiel.brett
        e.bild = EndeBild(Text("Brett am Ende"), hoehe: 320) { groesse in MuehleEndeBild(brett: brett, groesse: groesse) }
        return e
    }
}

/// Wählbare Regelart im „Mehr“-Menü (gilt vor dem ersten Zug, wird gemerkt).
enum MuehleArt: String, CaseIterable, Identifiable {
    case klassisch, kurz, ohneSpringen, streng
    var id: String { rawValue }
    var titel: LocalizedStringKey {
        switch self {
        case .klassisch: "Klassisch (9 Steine)"; case .kurz: "Kurz (6 Steine)"
        case .ohneSpringen: "Ohne Springen"; case .streng: "Auch aus Mühlen schlagen"
        }
    }
    var regeln: MuehleRegeln {
        switch self { case .klassisch: .klassisch; case .kurz: .kurz; case .ohneSpringen: .ohneSpringen; case .streng: .streng }
    }
    static var gespeichert: MuehleArt { MuehleArt(rawValue: UserDefaults.standard.string(forKey: "partie.regeln.muehle") ?? "") ?? .klassisch }
    func sichern() { UserDefaults.standard.set(rawValue, forKey: "partie.regeln.muehle") }
}
#endif
