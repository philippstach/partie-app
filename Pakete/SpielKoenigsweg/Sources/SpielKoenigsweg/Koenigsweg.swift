// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import KoenigswegKern

@MainActor
public struct KoenigswegModul: SpielModul {
    public init() {}
    public let id = "koenigsweg"
    public let name = "Königsweg"
    public let gattung = Gattung.wuerfel
    public let farbe = AkzentFarbeWert.braun
    public let symbol = "crown.fill"
    public let spielerzahl = 2...2
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "Das uralte Rennspiel aus Ur", farbe: farbe, spieler: 2...2, computerErlaubt: true, wuerfelWahl: true, wuerfelTexte: .muenzen,
                            regeln: "Jeder hat sieben Steine und bringt sie über den Weg von 14 Feldern bis hinaus. Du wirfst vier Münzen: Jede Seite mit Punkt zählt einen Schritt, also 0 bis 4. Mit der Zahl setzt du mit „Neuer Stein“ einen Stein aus dem Vorrat auf das Brett oder tippst einen Stein auf dem Brett an und ziehst ihn weiter. Ziehen ist Pflicht; bei einer Null oder wenn kein Zug möglich ist, ist der Gegner dran. Auf ein Feld, auf dem schon ein eigener Stein steht, darfst du nicht. Der mittlere Streifen ist gemeinsam: Springst du dort auf einen gegnerischen Stein, wird er geschlagen und muss zurück in den Vorrat. Rosettenfelder (Blume, Felder 4, 8 und 14) geben einen Extrazug; die Rosette in der Mitte (Feld 8) schützt den Stein dort vor dem Schlagen. Raus kommst du nur mit genauer Zahl. Wer als Erster alle sieben Steine hinausgebracht hat, gewinnt.",
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            KoenigswegSpiel(teilnehmer: teilnehmer, ende: ende, abbrechen: abbrechen, quelle: WuerfelWahl.quelle(id, vorgabe: umgebung.wuerfelQuelle))
        }.mitStartOptionen { KoenigswegOptionen(eintraege: $0) }
        .mitZiel("Bringe als Erster alle sieben Steine über den Weg hinaus. Schlage Gegner im mittleren Streifen.")
        .mitZielSchrittNeu(.ziel("Bringe als Erster alle sieben Steine über den Weg hinaus. Königsweg ist über 4.500 Jahre alt und stammt aus der Stadt Ur. Ihr spielt zu zweit oder du spielst gegen den Computer. Statt zu würfeln, werft ihr vier Münzen. Unterwegs könnt ihr euch gegenseitig schlagen."))
        .mitAnleitung(RegelTexteNeu.anleitung(neu: [
            .figuren(symbol: "point.topleft.down.to.point.bottomright.curvepath", titel: "Der Weg", text: "Jeder hat seinen eigenen Weg von 14 Feldern. Die ersten vier und die letzten zwei Felder gehören dir allein. Die acht Felder in der Mitte teilt ihr euch. Nur dort kann geschlagen werden. Am Ende des Wegs geht es hinaus ins Ziel.", figuren: ["▫️", "▫️", "🌸", "▫️"], bewegt: nil),
            .figuren(symbol: "circle.dotted", titel: "Vier Münzen", text: "Du wirfst vier Münzen. Jede Münze mit Punkt zählt einen Schritt, du ziehst also 0 bis 4 Felder. Die 2 kommt am häufigsten, 0 und 4 sind selten. Bei einer 0 setzt du aus. Mit echten Münzen am Tisch tippst du einfach ein, wie viele den Punkt zeigen.", figuren: ["🪙", "🪙", "🪙", "🪙"], bewegt: nil),
            .figuren(symbol: "arrow.right", titel: "Setzen oder ziehen", text: "Mit „Neuer Stein“ setzt du einen Stein aus dem Vorrat aufs Brett, oder du tippst einen Stein an und ziehst ihn weiter. Ziehen ist Pflicht. Auf ein Feld mit einem eigenen Stein darfst du nicht. Ins Ziel kommst du nur mit der genauen Zahl, von Feld 14 also nur mit einer 1.", figuren: ["♟", "▫️", "▫️"], bewegt: 0),
            .figuren(symbol: "sparkle", titel: "Schlagen und Rosetten", text: "Landest du in der Mitte auf einem Stein des Gegners, muss er zurück in den Vorrat. Auf den Blumenfeldern, den Rosetten, darfst du noch einmal werfen. Die Rosette in der Mitte ist außerdem sicher: Wer dort steht, kann nicht geschlagen werden. Wer zuerst alle sieben Steine draußen hat, gewinnt.", figuren: ["🌸", "♟"], bewegt: nil),
            .figuren(symbol: "lightbulb", titel: "Hilfen", text: "„Tipp“ zeigt dir mit einem gelben Ring einen guten Zug. „Zug zurück“ nimmt deinen letzten Zug zurück, solange noch nicht neu geworfen wurde. Die Stärke des Computers wählst du vor dem Spiel. Ob die App die Münzen wirft oder ihr echte nehmt, stellst du dort auch ein. Alles Weitere unter „Alle Regeln lesen“.", figuren: ["💡", "↩️", "🪙"], bewegt: nil),
        ], alt: [
            .figuren(symbol: "circle.dotted", titel: "Vier Münzen", text: "Du wirfst vier Münzen. Jede Seite mit Punkt zählt einen Schritt, also null bis vier.", figuren: ["🪙", "🪙", "🪙", "🪙"], bewegt: nil),
            .figuren(symbol: "arrow.right", titel: "Setzen oder ziehen", text: "Setze einen Stein aus dem Vorrat aufs Brett oder ziehe einen weiter. Auf ein Feld mit eigenem Stein darfst du nicht.", figuren: ["♟", "▫️", "▫️"], bewegt: 0),
            .figuren(symbol: "sparkle", titel: "Rosetten", text: "Im mittleren Streifen kannst du Gegner schlagen. Rosetten geben einen Extrazug, die mittlere schützt. Wer zuerst alle sieben Steine hinausbringt, gewinnt.", figuren: ["🌸", "♟"], bewegt: nil),
        ])))
    }
}

/// M-011: Die Stärke des Computers steht im Neues-Spiel-Blatt, es gibt keine zweite Seite „Schwierigkeit“ mehr.
struct KoenigswegOptionen: View {
    let eintraege: [SpielerEintrag]
    @State private var stufe = ComputerStufe.gespeichert("koenigsweg")
    var body: some View {
        VStack(spacing: 12) {
            WerBeginntKarte(spiel: "koenigsweg", eintraege: eintraege)   // T-097: Wer beginnt, abwechselnd oder fest
            if eintraege.contains { $0.art == "computer" } {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Stärke des Computers", systemImage: "cpu").font(.headline).foregroundStyle(Color.accentText)
                    ComputerStufePicker(spiel: "koenigsweg", stufe: $stufe).pickerStyle(.segmented).labelsHidden()
                }
                .frame(maxWidth: .infinity, alignment: .leading).card()
            }
        }
    }
}

struct KoenigswegSpiel: View {
    let teilnehmer: [SpielTeilnehmer]
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    var quelle: WuerfelQuelle = .app
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var regular: Bool { sizeClass == .regular }   // B18: auf dem iPad Inhalt mittig, Brett größer
    @State private var spiel = Koenigsweg(beginner: StartSpieler.naechster("koenigsweg"))   // T-097: Wer beginnt (gemeinsamer Baustein wie Mühle und Viererreihe)
    @State private var beginnerNr = StartSpieler.naechster("koenigsweg")
    @State private var zufall = SystemRandomNumberGenerator()
    @State private var stufe = ComputerStufe.gespeichert("koenigsweg")
    @State private var gemeldet = false
    @State private var tick = 0
    @State private var beginnt = SpielStand.vorhanden("koenigsweg")
    /// 1.0 (P4): Rückgängig: Stände vor jedem eigenen Zug. Der Wurf wird nie zurückgenommen (Wurf und Züge des Computers leeren die Liste).
    @State private var verlauf: [Koenigsweg] = []
    /// 1.0 (P4): Würfelbilanz „So fielen die Würfel“ (Münzwürfe 0…4, also fünf „Seiten“ ab 0).
    @State private var bilanz = WuerfelBilanz(namen: [], seiten: 5, kleinste: 0)
    private var ohneComputer: Bool { !teilnehmer.contains(where: \.computer) }
    /// Ohne Computer gibt es nichts zu wählen: keine zweite, fast leere Seite (Fund S2-014).
    private func neuesSpiel(beginner: Int) { beginnerNr = beginner; StartSpieler.merke(beginner, spiel: "koenigsweg"); spiel = Koenigsweg(beginner: beginner); gemeldet = false; beginnt = true; tick += 1; verlauf = []; bilanz = neueBilanz() }   // 1.0 (P4)
    private func neueBilanz() -> WuerfelBilanz { WuerfelBilanz(namen: teilnehmer.map(\.name), seiten: 5, kleinste: 0) }
    @State private var tipp: Koenigsweg.Zug?
    /// P-015/M-010/G-004: Größe der ganzen Spielseite, daraus die Ausrichtung des Bretts.
    @State private var seite: CGSize = .zero
    /// Platz, den Kopf, Namenszeilen, Meldung und Knöpfe ungefähr brauchen (geschätzt, nur für die Wahl der Ausrichtung).
    private static let restHoehe: CGFloat = 300
    /// P-015 (zweiter Anlauf): Das Brett ist 8 × 3 Felder. Waagerecht blieb es im Hochformat ein schmaler Streifen oben
    /// (iPhone ca. 140 pt hoch, iPad mini ca. 260 pt), darunter war die Seite leer. Senkrecht (3 × 8), wenn die Felder so größer werden.
    /// Im Gegenüber-Modus (Tisch) bleibt es waagerecht.
    private var hoch: Bool {
        guard !gegenueber, seite.width > 0 else { return false }
        let breite = min(seite.width - 2 * Theme.seitenRand, regular ? 880 : Theme.wideColumnWidth)
        let hoehe = seite.height - Self.restHoehe
        return min(breite / 3, hoehe / 8) > min(breite / 8, hoehe / 3)
    }
    /// Direkt im Brett beginnen statt in der Auswahl (nur für die Bildproben der Tests).
    var imBrett = false

    init(teilnehmer: [SpielTeilnehmer], ende: @escaping (SpielEnde) -> Void, abbrechen: @escaping () -> Void, quelle: WuerfelQuelle = .app, imBrett: Bool = false, vorgabe: Koenigsweg? = nil) {
        self.teilnehmer = teilnehmer; self.ende = ende; self.abbrechen = abbrechen; self.quelle = quelle; self.imBrett = imBrett
        _spiel = State(initialValue: vorgabe ?? Koenigsweg())   // vorgabe: nur für die Bildproben der Tests
        _bilanz = State(initialValue: WuerfelBilanz(namen: teilnehmer.map(\.name), seiten: 5, kleinste: 0))   // 1.0 (P4)
    }
    @AppStorage(GegenueberEinstellung.schluessel) private var gegenueberAn = true
    private var gegenueber: Bool { GegenueberEinstellung.gilt(fuer: teilnehmer, eingeschaltet: gegenueberAn) }
    /// Band eines Spielers im Gegenüber-Modus; der Wurf-Knopf sitzt im Band des Spielers am Zug, damit ihn jeder auf seiner Seite erreicht.
    private func band(_ s: Int) -> GegenueberBand {
        var werfen: AnyView? = (quelle == .app && spiel.wurf == nil && spiel.sieger == nil)
            ? AnyView(Button("Münzen werfen") { wirf(computer: false) }.buttonStyle(ZweitKnopfStil()).lineLimit(1).minimumScaleFactor(0.7)) : nil
        // Blatt 21 (W2-S, Tinte): Nach dem Wurf liegen die Münzen mit der Zahl im Band dessen, der dran ist
        if Tisch.aktiv, let w = spiel.wurf, spiel.sieger == nil, spiel.amZug == s {
            werfen = AnyView(HStack(spacing: 8) {
                MuenzenReihe(punkte: w, groesse: 30)
                Text(verbatim: "\(w)").font(.system(size: 26, weight: .bold, design: Design.zahlDesign)).foregroundStyle(Tisch.elfenbein)
            })
        }
        return GegenueberBand(name: teilnehmer[s].name, farbe: Self.farben[s], hinweis: LocalizedStringKey(meldungsText),
                              dran: spiel.amZug == s && spiel.sieger == nil, knopf: werfen)
    }

    private static let farben: [Color] = [Color(red: 0.2, green: 0.45, blue: 0.85), Color(red: 0.85, green: 0.45, blue: 0.2)]
    private func istComputer(_ s: Int) -> Bool { teilnehmer[s].computer }

    var body: some View {
        brett.aufTisch()   // Design-Runde 3: in Tinte Filz bis in die Ecken, sonst Seitengrund wie bisher
            .onAppear { if !beginnt { neuesSpiel(beginner: beginnerNr) } }
            .fortsetzbar("koenigsweg", $spiel, pruefen: { $0.istStimmig && teilnehmer.count == 2 },
                         standGeladen: { geladen in   // 1.0 (P4): Würfelbilanz folgt dem Fortsetzen; frische Partie → alte Bilanz weg
                             if geladen, let b = WuerfelBilanz.laden(spiel: "koenigsweg", namen: teilnehmer.map(\.name)), b.seiten == 5, b.kleinste == 0 { bilanz = b }
                             else if !geladen { WuerfelBilanz.loeschen(spiel: "koenigsweg") }
                             #if DEBUG
                             if geladen, Testzustand.art == .ende { pruefe() }   // nur Debug: Endstand laden meldet das Ende wie nach dem letzten Zug
                             #endif
                         })
            .onChange(of: bilanz) { _, neu in neu.sichern(spiel: "koenigsweg") }   // 1.0 (P4)
        .weicheAnimation(bei: spiel)
        .spielHaptik(zug: spiel, erfolg: (spiel.sieger != nil))
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
    }

    /// Spalte und Reihe des Feldes `f` (1…14) für Spieler `s`.
    private func ort(_ f: Int, _ s: Int) -> (Int, Int) {
        let eigeneReihe = s == 0 ? 2 : 0
        switch f {
        case 1...4: return (4 - f, eigeneReihe)
        case 5...12: return (f - 5, 1)
        case 13: return (7, eigeneReihe)
        default: return (6, eigeneReihe)
        }
    }

    // Große Tinte-Runde, Punkt 4: „Münzen werfen“ sprengt den Knopf nicht mehr. Der Text bricht nie um und schrumpft notfalls;
    // reicht die Breite trotzdem nicht (große Schrift), stehen die Knöpfe untereinander statt nebeneinander.
    private var wurfZahl: some View {
        Group {
            if let w = spiel.wurf, !(Tisch.aktiv && gegenueber) {   // Tinte zu zweit: Münzen und Zahl stehen im Band
                if Tisch.aktiv {   // Blatt 21 (W2-S): vier Münzen vor der Zahl
                    HStack(spacing: 12) {
                        MuenzenReihe(punkte: w, groesse: 30)
                        Text(verbatim: "\(w)").font(.system(.largeTitle, design: Design.zahlDesign).weight(.bold)).foregroundStyle(Tisch.elfenbein)
                    }
                } else {
                    Text(verbatim: "\(w)").font(.system(.largeTitle, design: Design.zahlDesign).weight(.bold)).foregroundStyle(Color.accentText)
                }
            }
        }
    }
    @ViewBuilder private var werfKnopf: some View {
        if (quelle == .app || istComputer(spiel.amZug)) && !gegenueber {
            Button("Münzen werfen") { wirf(computer: false) }.buttonStyle(HauptKnopfStil()).lineLimit(1).minimumScaleFactor(0.7)
                .disabled(spiel.wurf != nil || istComputer(spiel.amZug) || spiel.sieger != nil)
        }
    }
    @ViewBuilder private var tippKnopf: some View {
        if spiel.wurf != nil, !istComputer(spiel.amZug) {
            Button { var g = SystemRandomNumberGenerator(); tipp = spiel.computerZug(stufe: 3, mit: &g) } label: { Label("Tipp", systemImage: "lightbulb").lineLimit(1) }.tischNebenKnopf().dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        }
    }
    @ViewBuilder private var neuerSteinKnopf: some View {
        if spiel.wurf != nil, !istComputer(spiel.amZug), spiel.zuege().contains(where: { $0.von == 0 }) {
            Button("Neuer Stein") { if let z = spiel.zuege().first(where: { $0.von == 0 }) { zieheMensch(z) } }.tischNebenKnopf().dynamicTypeSize(...DynamicTypeSize.xxxLarge).tint(tipp?.von == 0 ? .yellow : nil)
                .overlay { if Tisch.aktiv && tipp?.von == 0 { Capsule().strokeBorder(Color.yellow, lineWidth: 2) } }   // Tinte: der Tipp-Hinweis kommt über den Rand, weil der runde Knopf `tint` nicht zeigt
                .lineLimit(1)
        }
    }
    /// Blatt 21 (W2-S, nur Tinte, Seite mindestens 760 pt hoch, nicht zu zweit): Münzen und Zahl in einer eigenen Zeile mit fester Höhe,
    /// darunter „Tipp“ und „Neuer Stein“, darunter „Münzen werfen“ über die ganze Breite (iPad höchstens 520 pt).
    private var grosseAktionen: some View {
        VStack(spacing: 12) {
            Group {
                if let w = spiel.wurf {
                    HStack(spacing: 12) {
                        MuenzenReihe(punkte: w, groesse: regular ? 56 : 44)
                        Text(verbatim: "\(w)").font(.system(.largeTitle, design: Design.zahlDesign).weight(.bold)).foregroundStyle(Tisch.elfenbein)
                    }
                } else { Color.clear }
            }.frame(minHeight: 44)
            HStack(spacing: 14) { tippKnopf; neuerSteinKnopf }
            werfKnopf.frame(maxWidth: regular ? 520 : .infinity)
        }
    }

    /// Meldungszeile: die Meldungen des Spiels haben Vorrang; in Tinte steht nach dem Wurf sonst „3 Felder ziehen“.
    private var meldungsText: String {
        if !spiel.meldung.isEmpty { return spiel.meldung }
        if Tisch.aktiv, let w = spiel.wurf, spiel.sieger == nil {
            return w == 1 ? String(localized: "1 Feld ziehen") : String(localized: "\(w) Felder ziehen")
        }
        return " "
    }

    private var aktionsReihe: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 14) { wurfZahl; werfKnopf; tippKnopf; neuerSteinKnopf }
            VStack(spacing: 10) {
                HStack(spacing: 14) { wurfZahl; werfKnopf }
                HStack(spacing: 14) { tippKnopf; neuerSteinKnopf }
            }
        }
    }

    private var brett: some View {
        VStack(spacing: Theme.kartenAbstand) {
            SpielKopf(mitte: spiel.sieger == nil ? String(localized: "\(teilnehmer[spiel.amZug].name) ist dran") : String(localized: "Spielende"), linksAktion: abbrechen) {
                RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                    FragNachDenRegelnMenuePunkt()   // KI-3 (Blatt 12): nur mit Apple Intelligence sichtbar
                    Button("Neue Partie", systemImage: "arrow.counterclockwise") { neuesSpiel(beginner: StartSpieler.naechster("koenigsweg")) }
                    Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
                }
            }
            Spacer(minLength: 0)
            if gegenueber {
                feld.gegenueberModus(aktiv: true, oben: band(1), unten: band(0))
            }
            ForEach(gegenueber ? [] : [1, 0], id: \.self) { s in
                HStack {
                    Circle().fill(Self.farben[s]).frame(width: 12, height: 12)
                    Text(verbatim: teilnehmer[s].name).font(.footnote.weight(s == spiel.amZug ? .bold : .regular))
                    Spacer()
                    Text("Vorrat \(spiel.vorrat(s))").font(.footnote)
                    Text("· draußen \(spiel.draussen(s))").font(.footnote).tischHinweis(zeilen: 1)
                }.padding(.horizontal, Theme.seitenRand)
                if s == 1 { feld; }
            }
            if !gegenueber { Text(LocalizedStringKey(meldungsText)).font(.subheadline.weight(.semibold)).foregroundStyle(Tisch.aktiv ? Tisch.elfenbein : Color.accentText) }
            if Tisch.aktiv && !gegenueber && seite.height >= 760 { grosseAktionen.padding(.horizontal, Theme.seitenRand) }   // Blatt 21 (W2-S): hohe Seite
            else { aktionsReihe.padding(.horizontal, Theme.seitenRand) }
            if kannZurueck {   // 1.0 (P4): letzten eigenen Zug zurück (nicht den Wurf)
                Button(action: zurueck) { Label("Zug zurück", systemImage: "arrow.uturn.backward") }.tischNebenKnopf().dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                    .padding(.horizontal, Theme.seitenRand)
            }
            if quelle == .echt, !istComputer(spiel.amZug), spiel.wurf == nil, spiel.sieger == nil {
                VStack(spacing: 6) {
                    Text("Wie viele Münzen zeigen den Punkt?").font(.footnote).tischHinweis(zeilen: 1)
                    HStack { ForEach(0...4, id: \.self) { n in Button { tipp = nil; wirf(computer: false, echt: n) } label: { Text(verbatim: "\(n)").frame(maxWidth: .infinity, minHeight: Theme.tapSize) }.buttonStyle(ZweitKnopfStil()) } }
                }.padding(.horizontal, Theme.seitenRand)
            }
            Spacer(minLength: 0)
        }
        .onGeometryChange(for: CGSize.self) { $0.size } action: { seite = $0 }
        .computerZug(aktiv: spiel.sieger == nil && istComputer(spiel.amZug), id: "\(tick)-\(spiel.amZug)-\(spiel.wurf ?? -1)") {
            verlauf.removeAll()   // 1.0 (P4): Züge des Computers sind nicht rückgängig zu machen
            if spiel.wurf == nil { wirf(computer: true); return }
            if let z = spiel.computerZug(stufe: stufe.rawValue, mit: &zufall) { spiel.ziehe(z) }
            tick += 1; pruefe()
        }
    }

    private var feld: some View {
        GeometryReader { g in
            let spalten: CGFloat = hoch ? 3 : 8, reihen: CGFloat = hoch ? 8 : 3
            let z = min(g.size.width / spalten, g.size.height / reihen)
            ZStack(alignment: .topLeading) {
                Canvas { ctx, _ in zeichne(&ctx, z) }
                    .frame(width: z * spalten, height: z * reihen)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .gesture(SpatialTapGesture().onEnded { v in
                let ox = (g.size.width - z * spalten) / 2
                let x = Int(floor((v.location.x - ox) / z)), y = Int(floor(v.location.y / z))
                if hoch { tippe(y, x) } else { tippe(x, y) }
            })
            .accessibilityElement(children: .ignore)   // G1
            .accessibilityLabel(Text("Königsweg-Brett"))
            .accessibilityValue(Text("\(teilnehmer[0].name) \(spiel.draussen(0)) von 7 draußen, \(teilnehmer[1].name) \(spiel.draussen(1)) von 7 draußen, \(teilnehmer[spiel.amZug].name) ist dran"))
            .accessibilityHint(Text("Erst würfeln, dann einen eigenen Stein antippen."))
            .accessibilityActions {   // C-031: jeder mögliche Zug als Aktion, damit es auch mit VoiceOver geht
                if spiel.sieger == nil, !istComputer(spiel.amZug), spiel.wurf != nil {
                    ForEach(spiel.zuege(), id: \.von) { z in
                        Button(z.von == 0 ? String(localized: "Neuen Stein einsetzen") : String(localized: "Stein von Feld \(z.von) nach Feld \(z.nach)")) { zieheMensch(z) }
                    }
                }
            }
        }.frame(maxWidth: regular ? 880 : Theme.wideColumnWidth).aspectRatio(hoch ? 3 / 8 : 8 / 3, contentMode: .fit).padding(.horizontal, Theme.seitenRand)
        .layoutPriority(1)   // P-015: Das Brett bekommt den freien Platz vor den Leerräumen
    }

    /// Linke obere Ecke von Spalte `c`, Reihe `r` (waagerechte Zählung) auf der Zeichenfläche; senkrecht sind Spalte und Reihe getauscht.
    private func ecke(_ c: Int, _ r: Int, _ z: CGFloat) -> CGPoint {
        hoch ? CGPoint(x: CGFloat(r) * z, y: CGFloat(c) * z) : CGPoint(x: CGFloat(c) * z, y: CGFloat(r) * z)
    }

    private func gueltigesFeld(_ c: Int, _ r: Int) -> Bool { r == 1 || !(c == 4 || c == 5) }
    private func rosette(_ c: Int, _ r: Int) -> Bool { (r != 1 && (c == 0 || c == 6)) || (r == 1 && c == 3) }

    private func zeichne(_ ctx: inout GraphicsContext, _ z: CGFloat) {
        let quellen = Set(spiel.zuege().map(\.von))
        for r in 0..<3 { for c in 0..<8 where gueltigesFeld(c, r) {
            let e = ecke(c, r, z)
            let rect = CGRect(x: e.x + 2, y: e.y + 2, width: z - 4, height: z - 4)
            ctx.fill(Path(roundedRect: rect, cornerRadius: Design.Ecke.klein), with: .color(r == 1 ? Color.appFlaeche.opacity(0.18) : Color.appFlaeche.opacity(0.10)))
            if rosette(c, r) { ctx.draw(Image(systemName: "sparkle"), at: CGPoint(x: rect.midX, y: rect.midY)) }
        } }
        for s in 0..<2 { for f in 1...14 where spiel.brett[s][f] > 0 {
            let (c, r) = ort(f, s)
            let e = ecke(c, r, z)
            let mitte = CGPoint(x: e.x + 0.5 * z, y: e.y + 0.5 * z)
            let rad = z * 0.3
            let kann = s == spiel.amZug && quellen.contains(f) && !istComputer(s)
            ctx.fill(Path(ellipseIn: CGRect(x: mitte.x - rad, y: mitte.y - rad, width: 2 * rad, height: 2 * rad)), with: .color(Self.farben[s]))
            if s == spiel.amZug, tipp?.von == f { ctx.stroke(Path(ellipseIn: CGRect(x: mitte.x - rad - 4, y: mitte.y - rad - 4, width: 2 * rad + 8, height: 2 * rad + 8)), with: .color(.yellow), lineWidth: 4) }
            ctx.stroke(Path(ellipseIn: CGRect(x: mitte.x - rad, y: mitte.y - rad, width: 2 * rad, height: 2 * rad)), with: .color(kann ? .primary : .white), lineWidth: kann ? 4 : 1.5)
        } }
    }

    private func tippe(_ c: Int, _ r: Int) {
        guard spiel.sieger == nil, !istComputer(spiel.amZug), spiel.wurf != nil else { return }
        for f in 1...14 where spiel.brett[spiel.amZug][f] > 0 {
            let o = ort(f, spiel.amZug)
            if o.0 == c && o.1 == r, let z = spiel.zuege().first(where: { $0.von == f }) { zieheMensch(z); return }
        }
    }

    private func zieheMensch(_ z: Koenigsweg.Zug) {
        tipp = nil
        let vorher = spiel
        if spiel.ziehe(z) { verlauf.append(vorher) }   // 1.0 (P4)
        if spiel.amZug != vorher.amZug { verlauf.removeAll() }   // T-083: Der Zug gehört dem, der ihn gemacht hat; wer danach dran ist, nimmt ihn nicht zurück (nur nach „Rosette – nochmal“ bleibt „Zug zurück“)
        tick += 1; pruefe()
    }

    /// 1.0 (P4): Ein Wurf mit Bilanz (`echt`: von Hand eingetragene Münzen). Ein Wurf ist nicht rückgängig zu machen und leert das Rückgängig.
    private func wirf(computer: Bool, echt: Int? = nil) {
        let s = spiel.amZug
        let geworfen: Bool
        if let n = echt { geworfen = spiel.setzeWurf(n) } else { geworfen = spiel.wuerfeln(mit: &zufall) }
        if geworfen {
            verlauf.removeAll()
            if let w = spiel.letzterWurf { bilanz.zaehle(spieler: s, [w], eingetippt: echt != nil) }
        }
        tick += 1; pruefe()
    }

    private var kannZurueck: Bool { !verlauf.isEmpty && !istComputer(spiel.amZug) && spiel.sieger == nil }

    private func zurueck() {
        guard kannZurueck, let alt = verlauf.popLast() else { return }
        spiel = alt; tipp = nil; tick += 1
    }

    private func pruefe() {
        guard let w = spiel.sieger, !gemeldet else { return }
        gemeldet = true
        Task {
            try? await Task.sleep(nanoseconds: 900_000_000)
            var e = SpielEnde(reihenfolge: [teilnehmer[w].name, teilnehmer[1 - w].name], punkte: ["7", "\(spiel.draussen(1 - w))"])
            e.wuerfel = bilanz   // 1.0 (P4): „So fielen die Würfel“
            // Blatt 22 (EB2, Schritt 2): Satz, Dauer, „Geschlagen“ (Summe; ein alter Stand hat keine Zählung: dann ohne); das Münzbild bleibt
            e.info = String(localized: "Alle sieben Steine draußen.")
            var werte: [EndeWert] = [.dauer]
            if let g = spiel.geschlagen { werte.append(EndeWert("Geschlagen", "\(g.reduce(0, +))")) }
            e.werte = werte
            ende(e)
        }
    }
}

/// Blatt 21 (W2-S, nur Tinte): vier Münzen, die ersten `punkte` mit Punkt. Der Kern kennt nur die Zahl, keine einzelnen Münzen.
private struct MuenzenReihe: View {
    let punkte: Int
    let groesse: CGFloat
    var body: some View {
        HStack(spacing: groesse * 0.18) {
            ForEach(0..<4, id: \.self) { i in
                Circle()
                    .fill(LinearGradient(colors: [Tisch.elfenbein, Tisch.elfenbeinTief], startPoint: .top, endPoint: .bottom))
                    .frame(width: groesse, height: groesse)
                    .shadow(color: Color.black.opacity(0.28), radius: 3, y: 3)
                    .overlay {
                        Circle().strokeBorder(Tisch.auge.opacity(0.2), lineWidth: max(1, groesse * 0.025)).padding(groesse * 0.12)
                    }
                    .overlay { if i < punkte { Circle().fill(Tisch.auge).frame(width: groesse * 0.28, height: groesse * 0.28) } }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(punkte) von 4 Münzen zeigen den Punkt"))
    }
}
#endif
