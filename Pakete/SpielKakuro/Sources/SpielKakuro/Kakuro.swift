// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import SpielHilfen
import KakuroKern

@MainActor
public struct KakuroModul: SpielModul {
    public init() {}
    public let id = "kakuro"
    public let name = "Kakuro"
    public let gattung = Gattung.raetsel
    public let farbe = AkzentFarbeWert.blau
    public let symbol = "plus.forwardslash.minus"
    public let spielerzahl = 1...1
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "Zahlen-Kreuzworträtsel", farbe: farbe, spieler: 1...1,
                            regeln: "Trage in die weißen Felder Ziffern von 1 bis 9 ein. Die Zahl in einem dunklen Hinweisfeld ist die Summe aller Ziffern rechts davon (obere Zahl) bzw. darunter (untere Zahl) bis zum nächsten dunklen Feld. Innerhalb einer solchen Summe darf keine Ziffer doppelt vorkommen. Doppelte oder zu große Summen werden rot markiert.",
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            KakuroSpiel(name: teilnehmer[0].name, ende: ende, abbrechen: abbrechen)
        }.mitStartOptionen { _ in KakuroStartWahl() }   // T-038: Wahl auf der Spielseite (nur Tinte, sonst leer)
        .mitZiel("Fülle alle weißen Felder mit Ziffern von 1 bis 9, sodass jede Summe stimmt und keine Ziffer darin doppelt vorkommt.").mitZielSchrittNeu(.ziel("Kakuro ist ein Kreuzworträtsel mit Zahlen. Trage in die weißen Felder Ziffern von 1 bis 9 ein. Die Zahlen in den dunklen Feldern sagen dir, welche Summe jede Reihe ergeben muss. In einer Reihe darf keine Ziffer doppelt stehen. Sind alle Felder richtig gefüllt, hast du das Rätsel gelöst.")).mitAnleitung(RegelTexteNeu.anleitung(neu: Self.anleitungNeu, alt: Self.anleitung)))
    }
}

struct KakuroSpiel: View {
    let name: String
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    @State private var spiel: Kakuro
    @State private var undo = RueckgaengigVerlauf<Kakuro>()
    @State private var gewaehlt: Int?
    @State private var start = Date()
    /// Spielzeit aus früheren Sitzungen (nach dem Fortsetzen); die laufende Sitzung zählt ab `start` dazu.
    @State private var vorherSekunden = 0
    /// C-032: Hintergrundzeit zählt nicht mit (Uhr steht, solange die App nicht aktiv ist).
    @Environment(\.scenePhase) private var szene
    @Environment(\.designArt) private var art
    @Environment(\.geraeteSchema) private var geraet
    /// Farbschema des Geräts an dieser Stelle: oberhalb von `aufTisch()` (das unten angesetzt ist und erst für die Kinder dunkel setzt).
    @Environment(\.colorScheme) private var geraeteFarbschema
    @State private var pausiertSeit: Date?
    private var sekunden: Int { vorherSekunden + max(0, Int(Date().timeIntervalSince(start))) }
    /// D4: Die Größen sind die Stufen der Leiter.
    static let groessen = [5, 6, 7]
    @State private var n = 6
    @ScaledMetric(relativeTo: .body) private var zifferGroesse: CGFloat = 22
    @ScaledMetric(relativeTo: .caption) private var hinweisGroesse: CGFloat = 11
    @State private var tag = false
    @State private var tipps = 0
    @State private var falsche: Set<Int> = []
    @State private var pruefText: String?
    @State private var zufall = SystemRandomNumberGenerator()
    /// T-076: Rückfrage vor „Neue Partie“, „Tagesrätsel“ und Größenwechsel, sobald das Rätsel begonnen ist.
    @State private var neuFragen = false
    @State private var neuAktion: (() -> Void)?

    /// `vorgabe`: festes Rätsel statt eines zufälligen (nur für die Bildproben der Tests).
    init(name: String, ende: @escaping (SpielEnde) -> Void, abbrechen: @escaping () -> Void, vorgabe: Kakuro? = nil) {
        self.name = name; self.ende = ende; self.abbrechen = abbrechen
        var g = SystemRandomNumberGenerator()
        var start = Leiter.offen("kakuro", stufe: 1) ? 6 : 5   // D4: ohne Siege beginnt es klein
        // T-038 (nur Tinte): Wahl von der Spielseite (Größe, Tagesrätsel) abholen
        var tagesStart = false
        if vorgabe == nil, Design.ist(.tinte) {
            let gw = UserDefaults.standard.object(forKey: KakuroStartWahl.groesseSchluessel) as? Int ?? -1
            if Self.groessen.indices.contains(gw), Leiter.offen("kakuro", stufe: gw) { start = Self.groessen[gw] }
            tagesStart = UserDefaults.standard.string(forKey: KakuroStartWahl.schluessel) == "tag"
        }
        var k = vorgabe ?? Kakuro.zufaellig(n: start, mit: &g)
        if tagesStart { var t = Tagesraetsel.reinerGenerator(spiel: "kakuro", variante: "\(start)"); k = Kakuro.zufaellig(n: start, mit: &t) }
        _tag = State(initialValue: tagesStart)
        _n = State(initialValue: k.n)
        _spiel = State(initialValue: k)
        _gewaehlt = State(initialValue: k.ersteFreie)   // Ziffernleiste wirkt sofort
    }

    // Rollen des Spielmaterials je Design: klar wie bisher (Systemfarben), Tinte und Salon aus den Farbrollen (Hinweisfelder in Tinte bzw. Espresso).
    // F-AWS-M-016/N-022: Klar dunkel – Eingabefelder heben sich vom schwarzen Grund ab, Sperrfelder sind mittelgrau statt hellgrau (weiße Schrift bleibt gut lesbar).
    // Fund 11/20: In Tinte dunkel waren Eingabefelder (kartenGrund) fast schwarz und Hinweisfelder grau, also vertauscht gelesen. Jetzt dunkel:
    // Eingabefelder mittelgrau mit hellem Rand, Hinweisfelder fast schwarz mit weißer Schrift. Hell bleibt wie bisher.
    // Blatt 28 (Bauplan KA): Klar wie bisher; Salon wie in Build 25; Tinte: dunkel 0x484B53 / 0x9699A2 mit fast schwarzen Summenfeldern 0x111215, hell wie bisher.
    private static func dunkelHell(_ dunkel: UInt32, _ hell: Color) -> Color { Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(Color(hex: dunkel)) : UIColor(hell) }) }
    private static var zellGrund: Color {
        if Design.ist(.klar) { return Color(hell: 0xFFFFFF, dunkel: 0x2C2C2E) }
        if Design.ist(.salon) { return Color.kartenGrund }
        return dunkelHell(0x484B53, Color.kartenGrund)
    }
    private static var zellRand: Color {
        if Design.ist(.klar) { return Color(hell: 0xC7C7CC, dunkel: 0x8E8E93) }
        if Design.ist(.salon) { return Color.linie }
        return dunkelHell(0x9699A2, Color.linie)
    }
    private static var hinweisGrund: Color {
        if Design.ist(.klar) { return Color(hell: 0x6E6E73, dunkel: 0x636366) }
        if Design.ist(.salon) { return Color(hell: 0x3A3A3C, dunkel: 0x636366) }
        return Color(hell: 0x3A3A3C, dunkel: 0x111215)
    }
    private static var hinweisSchrift: Color { Color.white }
    private static var zellEcke: CGFloat { Design.ist(.klar) ? 4 : Design.Ecke.klein }

    private func ziffer(_ d: Int) -> some View {
        Button { eintragen(d) } label: { Text("\(d)").frame(maxWidth: .infinity, minHeight: 40) }
            .buttonStyle(ZweitKnopfStil()).accessibilityLabel("Ziffer \(d)")
    }

    var body: some View {
        let fehler = spiel.fehlerFelder()
        ScrollView {
        VStack(spacing: Theme.kartenAbstand) {
            SpielKopf(mitte: "Kakuro", linksAktion: abbrechen) {
                RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                    FragNachDenRegelnMenuePunkt()   // KI-3 (Blatt 12): nur mit Apple Intelligence sichtbar
                    Button("Rückgängig", systemImage: "arrow.uturn.backward") { undo.zurueck(&spiel); falsche = []; pruefText = nil }.disabled(!undo.kann)   // T-081: wie „Zug zurück“ auch die Prüfmarkierung zurücksetzen
                    Button("Neue Partie", systemImage: "arrow.counterclockwise") { fragen { tag = false; neu() } }   // T-076: Rückfrage wie in den anderen Spielen
                    Button("Tagesrätsel", systemImage: "calendar") { fragen { tag = true; neu() } }
                    Picker("Größe", selection: Binding(get: { spiel.n }, set: { g in fragen { n = g; neu() } })) {
                        ForEach(Array(Self.groessen.enumerated()), id: \.offset) { i, g in
                            (Text(verbatim: "\(g) × \(g)") + Text(Leiter.offen("kakuro", stufe: i) ? "" : " 🔒")).tag(g).disabled(!Leiter.offen("kakuro", stufe: i))   // D4
                        }
                    }
                    if let b = Bestleistung.lesen(Bestleistung.ergebnisSchluessel("kakuro", variante: "\(spiel.n)", tages: tag)) { Text("Bestzeit: \(b) s") }
                    Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
                }
            }
            raetselFeld(fehler).padding(.horizontal, Theme.seitenRand)
            HStack(spacing: 10) {
                Button { undo.zurueck(&spiel); falsche = []; pruefText = nil } label: { Label("Zug zurück", systemImage: "arrow.uturn.backward").lineLimit(1).minimumScaleFactor(0.7) }
                    .tischNebenKnopf().disabled(!undo.kann)
                Button { tippGeben() } label: { Label("Tipp", systemImage: "lightbulb").lineLimit(1).minimumScaleFactor(0.7) }
                    .tischNebenKnopf()
                Button { pruefen() } label: { Label("Prüfen", systemImage: "checkmark.circle").lineLimit(1).minimumScaleFactor(0.7) }
                    .tischNebenKnopf()
            }.dynamicTypeSize(...DynamicTypeSize.xxxLarge).padding(.horizontal, Theme.seitenRand)
            if let p = pruefText { Text(p).font(.footnote.weight(.semibold)).foregroundStyle(falsche.isEmpty ? Color.accentText : Color.meldungRot).padding(.horizontal, Theme.seitenRand) }
            VStack(spacing: 6) {
                HStack(spacing: 6) { ForEach(1...5, id: \.self) { d in ziffer(d) } }
                HStack(spacing: 6) {
                    ForEach(6...9, id: \.self) { d in ziffer(d) }
                    Button { eintragen(0) } label: { Image(systemName: "delete.left").frame(maxWidth: .infinity, minHeight: 40) }
                        .buttonStyle(ZweitKnopfStil()).accessibilityLabel("Löschen")
                }
            }.padding(.horizontal, Theme.seitenRand)
            if let g = gewaehlt {
                let k = spiel.kandidaten(g).sorted()
                let text = Text(k.isEmpty ? String(localized: "Hier passt keine Ziffer mehr – prüfe die anderen Felder.") : String(localized: "Möglich: \(k.map(String.init).joined(separator: " "))"))
                // Punkt 4 und 11: höchstens zwei Zeilen, mittig, nie breiter als der Bildschirm; auf dem Filz hell (Fehlerfarbe bleibt)
                if k.isEmpty {
                    text.font(.footnote).foregroundStyle(Color.meldungRot).multilineTextAlignment(.center).lineLimit(2).minimumScaleFactor(0.8)
                        .padding(.horizontal, Theme.seitenRand)
                } else {
                    text.font(.footnote).multilineTextAlignment(.center).padding(.horizontal, Theme.seitenRand).tischHinweis()
                }
            }
        }
        }
        .aufTisch()   // Design-Runde 3: in Tinte Filz bis in die Ecken, sonst Seitengrund wie bisher
        .confirmationDialog("Aktuelle Partie abbrechen?", isPresented: $neuFragen, titleVisibility: .visible) {
            Button("Abbrechen und neu starten", role: .destructive) { let a = neuAktion; neuAktion = nil; a?() }
            Button("Weiterspielen", role: .cancel) { neuAktion = nil }
        } message: { Text("Die laufende Partie wird verworfen und neu begonnen.") }
        .onAppear { if tag { Tagesraetsel.merkeStart(spiel: "kakuro") } }   // T-055: nicht im init schreiben
        .weicheAnimation(bei: spiel)
        .spielHaptik(zug: spiel, erfolg: spiel.geloest, fehler: false)
        // Gespeichert wird der ganze Stand (Zeit, Tipps, Tagesrätsel), nicht nur das Rätsel.
        .onChange(of: szene) { _, neu in
            if neu == .active { if let p = pausiertSeit { start = start.addingTimeInterval(Date().timeIntervalSince(p)); pausiertSeit = nil } }
            else if pausiertSeit == nil { pausiertSeit = Date() }
        }
        .fortsetzbar("kakuro", Binding(
            get: { KakuroStand(spiel: spiel, sekunden: sekunden, tipps: tipps, tag: tag) },
            set: { s in
                undo.leeren()   // der Wechsel auf den geladenen Stand ist kein Zug, den man zurücknehmen kann
                spiel = s.spiel; n = s.spiel.n; tag = s.tag; tipps = s.tipps
                vorherSekunden = s.sekunden; start = Date()
                gewaehlt = s.spiel.ersteFreie; falsche = []; pruefText = nil
            }), pruefen: { $0.istKonsistent })
        .rueckgaengigMerken(spiel, in: undo)
        #if DEBUG
        .testEndeMelden { pruefeEnde() }
        #endif
    }

    /// Das Gitter. Große Tinte-Runde, Punkt 9: in Tinte bei hellem Gerät als helles Blatt auf dem Filz, sonst in der Spielfeld-Karte wie bisher.
    @ViewBuilder private func raetselFeld(_ fehler: Set<Int>) -> some View {
        let gitter = Grid(horizontalSpacing: 2, verticalSpacing: 2) {
            ForEach(0..<spiel.n, id: \.self) { z in
                GridRow { ForEach(0..<spiel.n, id: \.self) { s in zelle(z * spiel.n + s, fehler) } }
            }
        }
        // T-041: `geraet` kommt von `aufTisch()` dieser Ansicht und ist hier selbst noch nicht gesetzt (nil); das Gerät sagt `colorScheme` von außen
        if art == .tinte && (geraet ?? geraeteFarbschema) == .light { gitter.raetselBlatt(Design.Ecke.klein, innen: 6) }
        else { SpielfeldKarte { gitter } }
    }

    /// T-040: Die Schrift folgt der Feldgröße (`anteil` der Feldbreite), mindestens aber wie bisher (`basis`, wächst mit der Schrift
    /// des Systems) und mindestens 11 pt. Gilt auf jedem Gerät.
    private func schriftGroesse(_ basis: CGFloat, feld: CGFloat, anteil: CGFloat) -> CGFloat {
        max(basis, feld * anteil, 11)
    }

    @ViewBuilder private func zelle(_ i: Int, _ fehler: Set<Int>) -> some View {
        if spiel.weiss[i] && spiel.vorgaben.contains(i) {
            // RT-008: Feste Vorgabe: nicht wählbar, VoiceOver sagt „vorgegeben“
            Text("\(spiel.eintrag[i])")
                .font(.system(size: min(zifferGroesse, 28), weight: .semibold, design: Design.zahlDesign).monospacedDigit())
                .foregroundStyle(Color.schrift)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .background(Self.zellGrund, in: .rect(cornerRadius: Self.zellEcke))
                .overlay(RoundedRectangle(cornerRadius: Self.zellEcke).strokeBorder(Self.zellRand, lineWidth: 1))
                .accessibilityLabel("Zeile \(i / spiel.n + 1), Spalte \(i % spiel.n + 1), \(spiel.eintrag[i]), \(String(localized: "vorgegeben"))")
        } else if spiel.weiss[i] {
            Button { gewaehlt = i } label: {
                Color.clear.frame(maxWidth: .infinity, maxHeight: .infinity)
                    .aspectRatio(1, contentMode: .fit)   // quadratisch statt dünner Balken, auch wenn das Feld noch leer ist
                    .overlay {
                        // T-040: die Schrift folgt der Feldgröße
                        GeometryReader { g in
                            Text(spiel.eintrag[i] == 0 ? "" : "\(spiel.eintrag[i])")
                                .font(.system(size: schriftGroesse(min(zifferGroesse, 28), feld: g.size.width, anteil: 0.33), weight: .semibold, design: Design.zahlDesign).monospacedDigit()) // design:spielinhalt
                                .foregroundStyle(fehler.contains(i) || falsche.contains(i) ? Color.meldungRot : Color.schrift)
                                .frame(width: g.size.width, height: g.size.height)
                        }
                    }
                    .background(gewaehlt == i ? Color.appFlaeche.opacity(0.3) : Self.zellGrund, in: .rect(cornerRadius: Self.zellEcke))
                    .overlay(RoundedRectangle(cornerRadius: Self.zellEcke).strokeBorder(gewaehlt == i ? Color.appFlaeche : Self.zellRand, lineWidth: gewaehlt == i ? 2 : 1))   // design:spielinhalt (Markierung auf dem Spielmaterial)
            }.buttonStyle(.plain)
            .accessibilityLabel("Zeile \(i / spiel.n + 1), Spalte \(i % spiel.n + 1), \(spiel.eintrag[i] == 0 ? String(localized: "leer") : "\(spiel.eintrag[i])")")
            .accessibilityHint(Text("Zum Auswählen doppeltippen, dann eine Ziffer eintragen."))
            .accessibilityAddTraits(gewaehlt == i ? .isSelected : [])
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: Self.zellEcke).fill(Self.hinweisGrund)
                // Blatt 28 / Fund 52: Diagonale nur, wenn das Feld eine Summe hat; sie endet vor den runden Ecken. Summen in den Dreiecken.
                if spiel.hinweisWaagrecht(i) != nil || spiel.hinweisSenkrecht(i) != nil {
                    GeometryReader { g in
                        let b = g.size.width, e = b * 0.044
                        Path { p in p.move(to: CGPoint(x: e, y: e)); p.addLine(to: CGPoint(x: b - e, y: b - e)) }
                            .stroke(Color.white.opacity(0.55), lineWidth: max(1, b * 0.015))
                    }.accessibilityHidden(true)
                    GeometryReader { g in
                        let b = g.size.width
                        let h = schriftGroesse(min(hinweisGroesse, 12.5), feld: b, anteil: 0.25)
                        ZStack {
                            if let r = spiel.hinweisWaagrecht(i) { Text("\(r)").font(.system(size: h, weight: .bold)).foregroundStyle(Self.hinweisSchrift).lineLimit(1).minimumScaleFactor(0.7).position(x: 0.69 * b, y: 0.29 * b) } // design:spielinhalt
                            if let u = spiel.hinweisSenkrecht(i) { Text("\(u)").font(.system(size: h, weight: .bold)).foregroundStyle(Self.hinweisSchrift).lineLimit(1).minimumScaleFactor(0.7).position(x: 0.30 * b, y: 0.71 * b) } // design:spielinhalt
                        }.frame(width: g.size.width, height: g.size.height)
                    }
                }
            }.frame(maxWidth: .infinity).aspectRatio(1, contentMode: .fit).frame(maxWidth: Theme.wideColumnWidth)
            .accessibilityLabel("Hinweis" + (spiel.hinweisWaagrecht(i).map { " rechts \($0)" } ?? "") + (spiel.hinweisSenkrecht(i).map { " unten \($0)" } ?? ""))
        }
    }

    private func tippGeben() {
        var g = SystemRandomNumberGenerator()
        guard let f = spiel.tipp(bevorzugt: gewaehlt, mit: &g) else { return }
        tipps += 1; falsche = []; pruefText = nil
        ansage(String(localized: "Tipp: Zeile \(f / spiel.n + 1), Spalte \(f % spiel.n + 1), Ziffer \(spiel.eintrag[f])"))
        pruefeEnde()
    }

    private func pruefen() {
        falsche = spiel.falscheEintraege()
        pruefText = falsche.isEmpty ? String(localized: "Bisher alles richtig.") : String(localized: "Falsche Felder: \(falsche.count)")
        if let t = pruefText { ansage(t) }
    }

    private func eintragen(_ d: Int) {
        guard let g = gewaehlt else { return }
        falsche = []; pruefText = nil
        spiel.setze(g, d)
        pruefeEnde()
    }

    private func pruefeEnde() {
        guard spiel.geloest else { return }
        let sek = max(1, sekunden)
        if let i = Self.groessen.firstIndex(of: spiel.n) { Leiter.sieg("kakuro", stufe: i, mitTipp: tipps > 0, tages: tag) }   // D4
        let zusatz = tipps == 0 ? Bestleistung.zusatz("kakuro", variante: "\(spiel.n)", tages: tag, wert: sek) : ""
        var fertig = SpielEnde(reihenfolge: [name], info: String(localized: "Gelöst in \(Zeitformat.text(sekunden: sek)).") + zusatz)
        // Blatt 22 (EB-3): Satz, zwei bis drei Werte, das gelöste Gitter als Bild
        fertig.werte = [EndeWert("Größe", "\(spiel.n) × \(spiel.n)")]   // Fund 15: Zeit steht schon im Satz „Gelöst in …“
        if tipps > 0 { fertig.werte.append(EndeWert("Tipps", "\(tipps)")) }
        let stand = spiel   // Wert festhalten: der Rahmen kennt den Spielstand danach nicht mehr
        fertig.bild = EndeBild(Text("Gelöstes Gitter"), hoehe: 320) { groesse in KakuroEndeBild(spiel: stand, groesse: groesse) }
        fertig.dauer = TimeInterval(sek)   // C-017: reine Spielzeit (ohne Hintergrund, über Fortsetzen hinweg) statt Wanduhr
        ende(fertig)
    }

    /// Führt `aktion` sofort aus, solange noch nichts eingetragen ist; sonst erst nach der Rückfrage.
    private func fragen(_ aktion: @escaping () -> Void) {
        if undo.kann || tipps > 0 { neuAktion = aktion; neuFragen = true } else { aktion() }
    }

    private func neu() {
        undo.leeren(); falsche = []; pruefText = nil
        if tag { var g = Tagesraetsel.generator(spiel: "kakuro", variante: "\(n)"); spiel = Kakuro.zufaellig(n: n, mit: &g) }
        else { spiel = Kakuro.zufaellig(n: n, mit: &zufall) }
        gewaehlt = spiel.ersteFreie; start = Date(); vorherSekunden = 0; tipps = 0
    }
}
#endif
