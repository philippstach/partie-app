// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import SpielHilfen
import HerzensjagdKern

@MainActor
public struct HerzensjagdModul: SpielModul {
    public init() {}
    public let id = "herzensjagd"
    public let name = "Herzensjagd"
    public let gattung = Gattung.karten
    public let farbe = AkzentFarbeWert.pink
    public let symbol = "heart.fill"
    public let spielerzahl = 4...4
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "Weiche den Herzen aus", farbe: farbe, spieler: 4...4, computerErlaubt: true,
                            regeln: "Vier Spieler, jeder bekommt 13 Karten. Gespielt werden 13 Stiche. Wer an der Reihe ist, muss die ausgespielte Farbe bedienen; wer sie nicht hat, wirft eine beliebige Karte ab. Den Stich gewinnt die höchste Karte der ausgespielten Farbe, und der Gewinner spielt als Nächster aus. Gesammelt werden Minuspunkte: jedes Herz zählt 1, die Pik-Dame 13. Die Runde beginnt mit der Kreuz-Zwei. Im ersten Stich gibt es möglichst keine Punktkarten. Herzen dürfen erst ausgespielt werden, wenn schon ein Herz oder die Pik-Dame gefallen ist. Holt ein Spieler alle 26 Punkte (Mondschuss), bekommen die anderen je 26 Punkte, er selbst keinen. Vor jeder Runde gibst du drei Karten weiter, reihum nach links, nach rechts, nach gegenüber, dann behält jeder seine Karten (im Blatt „Neues Spiel“ abschaltbar). Sobald jemand das gewählte Ziel erreicht (50, 75 oder 100 Punkte, Standard 50), endet das Spiel: Wer dann die wenigsten Punkte hat, gewinnt.",
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            HerzensjagdSpiel(teilnehmer: teilnehmer, ende: ende, abbrechen: abbrechen)
        }.mitStartOptionen { HerzensjagdOptionen(eintraege: $0) }   // 1.0 (M5): Weitergeben und Zielpunkte schon vor dem Start
        .mitZiel("Vermeide Herzen und die Pik-Dame, sie zählen Minuspunkte. Wer das gewählte Ziel erreicht (50, 75 oder 100 Punkte), beendet das Spiel, die wenigsten Punkte gewinnen.")
        .mitZielSchrittNeu(.ziel("Vermeide Herzen und die Pik-Dame, sie zählen Minuspunkte. Wer das gewählte Ziel erreicht (50, 75 oder 100 Punkte), beendet das Spiel, die wenigsten Punkte gewinnen. Herzensjagd ist ein Stichspiel für genau vier Personen, auch mit Computer."))   // B25: neue deutsche Anleitung (RegelTexteNeu), die alte bleibt für alle anderen Sprachen
        .mitAnleitung(RegelTexteNeu.anleitung(neu: [
            .figuren(symbol: "arrow.left.arrow.right", titel: "Karten weitergeben", text: "Vor jeder Runde gibst du drei Karten weiter: zuerst nach links, dann nach rechts, dann nach gegenüber, in der vierten Runde gar nicht. Gib gefährliche Karten ab, zum Beispiel die Pik-Dame oder hohe Herzen.", figuren: ["🂠", "🂠", "🂠", "◀️"], bewegt: 0),
            .figuren(symbol: "suit.club", titel: "Farbe bedienen", text: "Wer die Kreuz 2 hat, beginnt. Reihum legt jeder eine Karte. Du musst die ausgespielte Farbe bedienen. Hast du sie nicht, wirfst du eine beliebige Karte ab. Die höchste Karte der ausgespielten Farbe gewinnt den Stich, und wer ihn hat, spielt als Nächstes aus.", figuren: ["2♣", "7♣", "K♣", "A♣"], bewegt: nil),
            .figuren(symbol: "heart", titel: "Strafpunkte", text: "Jedes Herz in deinen Stichen zählt einen Minuspunkt, die Pik-Dame 13. Alle anderen Karten zählen nichts. Ein Tipp: Bist du eine Farbe los, kannst du dort Herzen und die Pik-Dame abwerfen.", figuren: ["5♥", "1", "D♠", "13"], bewegt: nil),
            .figuren(symbol: "lock.open", titel: "Herzen ausspielen", text: "Mit Herz darfst du einen Stich erst beginnen, wenn die Herzen offen sind: Ein Herz muss schon gefallen sein, oder die Pik-Dame wurde gespielt. Hast du nur noch Herzen, darfst du sie immer ausspielen.", figuren: ["🔒", "♥️", "🔓"], bewegt: nil),
            .figuren(symbol: "moon.stars", titel: "Mondschuss", text: "Holt jemand in einer Runde alle Herzen und die Pik-Dame, ist das ein Mondschuss. Dann bekommt er 0 Punkte, und die drei anderen bekommen je 26. Riskant: Fehlt am Ende ein einziges Herz, hast du dir selbst 25 Punkte eingebrockt.", figuren: ["🌙", "♥️", "♠️"], bewegt: nil),
            .figuren(symbol: "slider.horizontal.3", titel: "Einstellungen und Hilfen", text: "Vor dem Start wählst du, bei wie vielen Punkten das Spiel endet, und ob Karten weitergegeben werden. Die Stärke des Computers stellst du unter „Mehr“ ein. „Tipp“ zeigt dir eine gute Karte. Alles Weitere steht unter „Alle Regeln lesen“.", figuren: ["⚙️", "💡"], bewegt: nil),
        ], alt: [
            .figuren(symbol: "arrow.triangle.2.circlepath", titel: "Farbe bedienen", text: "Du musst die ausgespielte Farbe bedienen. Hast du sie nicht, wirfst du eine beliebige Karte ab.", figuren: ["🂡", "🂱", "🂻", "🃁"], bewegt: nil),
            .figuren(symbol: "heart.fill", titel: "Strafpunkte", text: "Jedes Herz zählt 1 Minuspunkt, die Pik-Dame 13. Die höchste Karte der Farbe gewinnt den Stich.", figuren: ["♥️", "♠️"], bewegt: nil),
            .figuren(symbol: "moon.stars", titel: "Mondschuss", text: "Holt ein Spieler alle 26 Punkte, bekommen die anderen je 26. Wer am wenigsten hat, gewinnt.", figuren: ["🌙", "💯"], bewegt: nil),
        ])))
    }
}

/// 1.0 (M5): Schlüssel der Wahl vor dem Start (Zielpunkte, Karten weitergeben).
enum HerzensjagdWahl {
    static let zielSchluessel = "partie.regeln.herzensjagd.ziel"
    static let weitergebenSchluessel = "partie.regeln.herzensjagd.weitergeben"
    static var ziel: Int { let z = UserDefaults.standard.integer(forKey: zielSchluessel); return [50, 75, 100].contains(z) ? z : 50 }
    static var weitergeben: Bool { UserDefaults.standard.object(forKey: weitergebenSchluessel) as? Bool ?? true }
}

/// 1.0 (M5): Karte im Blatt „Neues Spiel“: Karten weitergeben (Standard an) und Zielpunkte 50 / 75 / 100 (Standard 50).
struct HerzensjagdOptionen: View {
    let eintraege: [SpielerEintrag]
    @AppStorage(HerzensjagdWahl.weitergebenSchluessel) private var weitergeben = true
    @AppStorage(HerzensjagdWahl.zielSchluessel) private var ziel = 50
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: $weitergeben) {
                Label("Drei Karten weitergeben", systemImage: "arrow.left.arrow.right").font(.headline).foregroundStyle(Color.accentText)
            }
            Text("Vor jeder Runde: links, rechts, gegenüber, dann keine.").font(.footnote).foregroundStyle(.secondary)
            Label("Spielende bei", systemImage: "flag.checkered").font(.headline).foregroundStyle(Color.accentText)
            Picker("Spielende bei", selection: $ziel) {
                Text("50 Punkten").tag(50); Text("75 Punkten").tag(75); Text("100 Punkten").tag(100)
            }.pickerStyle(.segmented).labelsHidden()
        }
        .frame(maxWidth: .infinity, alignment: .leading).card()
    }
}

struct HKartenBild: View {
    let karte: HKarte
    var gedimmt = false
    var groesse: KartenGroesse = .klein   // Blatt 16b (iPad, Tinte): Hand .normal, Stichkarten .gross; iPhone bleibt .klein
    var body: some View {
        let rot = karte.farbe == 1 || karte.farbe == 3
        KartenFlaeche(groesse: groesse, gedimmt: gedimmt, beschriftung: Text(verbatim: Kartensprache.name(rang: karte.name, symbol: HKarte.farbSymbole[karte.farbe]))) {
            if KartenSatz.istGewaehlt {   // gewählter Kartensatz (Blatt 17/19): Kartenbild und Figuren vom Satz
                KartenIndex(rang: karte.name, zeichen: HKarte.farbSymbole[karte.farbe], farbe: KartenStil.aktuell.farbe(rot: rot),
                            breite: groesse.masse.width, hoehe: groesse.masse.height)
            } else {
            VStack(spacing: -2) {
                Text(verbatim: karte.name).font(.system(.title3, design: Design.zahlDesign).weight(.bold))
                Text(verbatim: HKarte.farbSymbole[karte.farbe]).font(.title2)
            }.foregroundStyle(KartenStil.aktuell.farbe(rot: rot))   // Designwechsel D.2
            }
        }
    }
}

struct HerzensjagdSpiel: View {
    let teilnehmer: [SpielTeilnehmer]
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    @State private var spiel: Herzensjagd
    @State private var tipp: AnyHashable?   // F4
    @State private var zufall = SystemRandomNumberGenerator()
    @State private var gemeldet = false
    @State private var schritte = 0
    @State private var letzterMensch: Int?   // C-030: Hand, die bei Computerzügen gezeigt bleibt
    @State private var stufe = ComputerStufe.gespeichert("herzensjagd")
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.dynamicTypeSize) private var schrift
    /// Blatt 16b (iPad, nur Tinte): größere Karten, Stichfläche wächst bis zur Hand. Nicht bei sehr großer Schrift; iPhone unverändert.
    private var breitTisch: Bool { sizeClass == .regular && Tisch.aktiv && !schrift.isAccessibilitySize }
    private var fehler: Double { switch stufe { case .leicht: 0.45; case .mittel: 0.12; case .schwer: 0 } }

    init(teilnehmer: [SpielTeilnehmer], ende: @escaping (SpielEnde) -> Void, abbrechen: @escaping () -> Void, vorgabe: Herzensjagd? = nil) {
        self.teilnehmer = teilnehmer; self.ende = ende; self.abbrechen = abbrechen
        var g = SystemRandomNumberGenerator()
        _spiel = State(initialValue: vorgabe ?? Herzensjagd(ziel: HerzensjagdWahl.ziel, weitergeben: HerzensjagdWahl.weitergeben, mit: &g))   // vorgabe: nur für die Bildproben der Tests
    }

    private var menschen: [Int] { teilnehmer.menschen }
    private var amZugComputer: Bool { teilnehmer[spiel.amZug].computer }
    private var sicht: Int { amZugComputer ? (letzterMensch ?? menschen.first ?? 0) : spiel.amZug }
    private var kannHandeln: Bool { !spiel.vorbei && !spiel.rundeFertig && !spiel.stichVoll && !amZugComputer && !spiel.weitergabeOffen }
    private var waehltWeitergabe: Bool { spiel.weitergabeOffen && !amZugComputer }   // 1.0 (M5)

    /// 1.0 (M5): Richtung der Weitergabe in Worten.
    private var richtungText: String {
        switch spiel.weitergabeRichtung { case 1: String(localized: "nach links"); case 3: String(localized: "nach rechts"); case 2: String(localized: "nach gegenüber"); default: "" }
    }

    var body: some View {
        ZStack {
            VStack(spacing: Theme.kartenAbstand) {
                SpielKopf(mitte: String(localized: "Runde \(spiel.runde)"), linksAktion: abbrechen) {
                    RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                        FragNachDenRegelnMenuePunkt()   // KI-3 (Blatt 12): nur mit Apple Intelligence sichtbar
                        if teilnehmer.contains(where: \.computer) { ComputerStufePicker(spiel: "herzensjagd", stufe: $stufe) }   // T-084: nur mit Computer
                        NeuePartieMenuePunkt()   // T-075: „Neue Partie“ wie in allen Spielen
                        Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
                    }
                }
                punkte
                if !breitTisch { Spacer(minLength: 0) }
                tisch
                if !breitTisch { Spacer(minLength: 0) }   // iPad (Tinte): keine Federn, die Stichfläche nimmt den Platz bis zur Hand
                eigene
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            if spiel.rundeFertig { rundenEnde }
        }
        .aufTisch()   // Design-Runde 3: in Tinte Filz bis in die Ecken, sonst Seitengrund wie bisher
        .uebergabeSeite(teilnehmer: teilnehmer, amZug: spiel.amZug, aktiv: !spiel.vorbei && !spiel.rundeFertig)
        #if DEBUG
        .testEndeMelden { if spiel.vorbei { beenden() } }   // -testZustand ende: das Ende wird nach dem Laden des Endstands selbst gemeldet
        #endif
        .fortsetzbar("herzensjagd", $spiel, pruefen: { $0.istStimmig(spieler: teilnehmer.count) })
        .weicheAnimation(bei: spiel)
        .spielHaptik(zug: spiel, erfolg: (spiel.vorbei))
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .onChange(of: spiel.amZug, initial: true) { _, z in if !teilnehmer[z].computer { letzterMensch = z } }
        .task(id: "\(spiel.stichNummer)-\(spiel.stich.count)-\(spiel.runde)-\(schritte)-\(spiel.bestaetigt)") {
            guard !spiel.vorbei, !spiel.rundeFertig else { return }
            if spiel.weitergabeOffen {   // 1.0 (M5): Computer wählt seine drei Karten
                guard amZugComputer else { return }
                try? await Task.sleep(nanoseconds: ComputerTempo.angepasst(nanosekunden: 600_000_000))
                guard !Task.isCancelled else { return }
                spiel.computerWaehltWeitergabe(); schritte += 1; return
            }
            if spiel.stichVoll {
                try? await Task.sleep(nanoseconds: ComputerTempo.angepasst(nanosekunden: 1_400_000_000))
                guard !Task.isCancelled else { return }
                spiel.stichAbschliessen(mit: &zufall); schritte += 1; nachZug(); return
            }
            guard amZugComputer else { return }
            try? await Task.sleep(nanoseconds: ComputerTempo.angepasst(nanosekunden: 800_000_000))
            guard !Task.isCancelled else { return }
            spiel.spiele(spiel.computerWahl(spiel.amZug, fehler: fehler, mit: &zufall)); schritte += 1
        }
    }

    /// Kachelgrund wie in der SpielerLeiste des Baukastens: Klar Karte (aktiv zarte App-Farbe), Tinte Zeile ohne Karte (aktiv Feldgrund), Salon ohne Fläche.
    private func kachelGrund(aktiv: Bool) -> Color {
        switch Design.art {
        case .klar: return aktiv ? Color.appFlaeche.opacity(0.25) : Color.kartenGrund
        case .tinte: return aktiv ? Color.schrift.opacity(0.14) : Color.clear   // Blatt 23: helle Kachel wie in der gemeinsamen Leiste, kein dunkler Kasten
        case .salon: return Color.clear
        }
    }

    /// Name der Kachel wie in der SpielerLeiste (2.21): eine Schriftfamilie und Größe für alle Namen; aktiv fett (mit Punkt im Salon), inaktiv normal in Schrift zweit (Tinte, Salon).
    @ViewBuilder private func kachelName(_ name: String, aktiv: Bool, klein: Bool, farbeIndex: Int = 0) -> some View {
        let salon = Design.ist(.salon)
        HStack(spacing: Design.Abstand.xs) {
            if salon && aktiv { Circle().fill(Color.appFlaeche).frame(width: 7, height: 7) }
            if Design.ist(.tinte) && aktiv { Circle().fill(Spieler.farbe(farbeIndex)).frame(width: 7, height: 7) }   // Blatt 23: kleiner Punkt in der Spielerfarbe
            Text(verbatim: name)
                .font(salon ? Design.Schrift.serif(15, gewicht: aktiv ? .bold : .regular, relativ: .caption, hoechstens: 1.2)
                            : (klein ? Font.caption : Font.footnote).weight(Design.ist(.tinte) && aktiv ? .semibold : .regular))
                .foregroundColor(Design.ist(.tinte) ? (aktiv ? nil : Color.schrift.opacity(0.82)) : (Design.art != .klar && !aktiv ? Color.schriftZweit : nil))
                .lineLimit(1).minimumScaleFactor(0.7)
        }
    }

    private var punkte: some View {
        HStack(spacing: Design.Abstand.s) {
            ForEach(0..<4, id: \.self) { i in
                VStack(spacing: 1) {
                    if Design.ist(.tinte) { SpielerAvatar(name: teilnehmer[i].name, farbe: Spieler.farbe(i), groesse: 30) }   // Blatt 23: Kreis mit Buchstabe wie in der gemeinsamen Leiste
                    kachelName(teilnehmer[i].name, aktiv: i == spiel.amZug && !spiel.stichVoll, klein: true, farbeIndex: i)
                    Text(verbatim: "\(spiel.gesamt[i])").font(Design.ist(.tinte) ? .system(.title3, design: Design.zahlDesign).weight(.semibold) : .title3.weight(.semibold))
                    Text(verbatim: "+\(spiel.rundenPunkte[i])").font(.caption2).tischHinweis(zeilen: 1)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: Design.ist(.tinte) ? 18 : Design.Ecke.feld).fill(kachelGrund(aktiv: i == spiel.amZug && !spiel.stichVoll)))   // wie SpielerLeiste im Baukasten: Klar zarte Farbe, Tinte Feldgrund, Salon keine Fläche
            }
        }.padding(.horizontal, Theme.seitenRand)
    }

    private var tisch: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18).fill(Color.appFlaeche.opacity(0.10))
            ForEach(spiel.stich.indices, id: \.self) { n in
                let e = spiel.stich[n]
                let r = (e.spieler - sicht + 4) % 4
                let f: CGFloat = breitTisch ? 76.0 / 44.0 : 1   // Versätze im Verhältnis der Kartengröße (.gross zu .klein)
                HKartenBild(karte: e.karte, groesse: breitTisch ? .gross : .klein)
                    .offset(x: [0, -52, 0, 52][r] * f, y: [38, 0, -38, 0][r] * f)
            }
            if spiel.weitergabeOffen && breitTisch { weitergabeMitte }
            else if spiel.weitergabeOffen { Text("Drei Karten \(richtungText) weitergeben").font(.footnote).tischHinweis(zeilen: 1) }
            else if spiel.stich.isEmpty { Text(spiel.stichNummer == 0 ? "Kreuz-Zwei beginnt" : "\(teilnehmer[spiel.amZug].name) spielt aus").font(.footnote).tischHinweis(zeilen: 1) }
        }
        .frame(minHeight: 150, maxHeight: breitTisch ? .infinity : 150)   // iPad: Fläche wächst bis zur Hand, iPhone fest 150 pt
        .frame(height: breitTisch ? nil : 150)
        .padding(.horizontal, Theme.seitenRand)
    }

    /// Bauplan T3-1 Punkt 1 / Blatt 27: Weitergeben in der Tischmitte (nur breiter Tintentisch): Satz, drei Plätze, Knopf, Zähler.
    private var weitergabeMitte: some View {
        let masse = KartenGroesse.normal.masse
        let gewaehlt = spiel.gewaehlt[sicht]
        return VStack(spacing: 14) {
            Text("Drei Karten \(richtungText) weitergeben").font(.title3.weight(.semibold)).tischHinweis(zeilen: 2)
            HStack(spacing: 14) {
                ForEach(0..<3, id: \.self) { n in
                    ZStack {
                        if gewaehlt.indices.contains(n) {
                            let k = gewaehlt[n]
                            HKartenBild(karte: k, groesse: .normal)
                                .onTapGesture { spiel.waehleWeitergabe(k) }   // Tipp auf die Karte am Platz legt sie zurück
                                .accessibilityAddTraits(.isButton)
                        } else {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(Tisch.elfenbein.opacity(0.5), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                                .overlay(Text(verbatim: "\(n + 1)").font(.title3.weight(.semibold)).foregroundStyle(Tisch.elfenbein.opacity(0.4)))
                        }
                    }
                    .frame(width: masse.width, height: masse.height)
                }
            }
            if waehltWeitergabe {
                Button { spiel.bestaetigeWeitergabe(); schritte += 1 } label: { Label("Weitergeben", systemImage: "arrow.left.arrow.right") }
                    .tischNebenKnopf().disabled(!spiel.weitergabeBereit).dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                Text("Wähle drei Karten \(richtungText) weitergeben (\(gewaehlt.count) von 3).").font(.footnote).tischHinweis(zeilen: 2)
            }
        }
    }

    /// Kartenbreite der Hand: iPad (Tinte) `.normal` 58 pt, sonst 44 pt. 13 Karten passen auf dem iPad in eine Reihe.
    private var handBreite: CGFloat { breitTisch ? KartenGroesse.normal.masse.width : 44 }
    private var handZeilenHoehe: CGFloat { breitTisch ? 100 : 80 }
    private var zeilenHoehe: CGFloat { breitTisch ? (spiel.haende[sicht].count > 13 ? 182 : handZeilenHoehe) : (spiel.haende[sicht].count > 10 ? 142 : 80) }

    private var eigene: some View {
        VStack(spacing: 6) {
            HStack(spacing: Design.Abstand.m) {
                Text(spiel.weitergabeOffen && breitTisch ? " " : hinweis).font(breitTisch ? .body : .footnote).frame(minHeight: 18).tischHinweis(sonst: Color.secondary)   // Tinte: heller Hinweis auf dem Filz, Klar und Salon wie bisher
                if waehltWeitergabe && !breitTisch {   // 1.0 (M5); auf dem breiten Tisch steht der Knopf in der Tischmitte
                    Button { spiel.bestaetigeWeitergabe(); schritte += 1 } label: { Label("Weitergeben", systemImage: "arrow.left.arrow.right") }
                        .tischNebenKnopf().disabled(!spiel.weitergabeBereit).dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                }
                if kannHandeln, sicht == spiel.amZug, let e = spiel.tippKarte(sicht) {
                    Button { tipp = AnyHashable(e); tippAnsage(e) } label: { Label("Tipp", systemImage: "lightbulb") }.tischNebenKnopf().dynamicTypeSize(...DynamicTypeSize.xxxLarge)   // F4
                }
            }
            let erlaubt = sicht == spiel.amZug && !spiel.weitergabeOffen ? spiel.erlaubt(sicht) : []
            GeometryReader { geo in
                let karten = spiel.haende[sicht]
                let breite: CGFloat = handBreite
                let platz = max(breite, geo.size.width - 2 * Theme.seitenRand)
                // Lesbar bleiben: höchstens so eng wie 30 pt Schritt, sonst zweite Reihe (F-B12: 13 Karten überlappten auf dem SE)
                let jeZeileMax = max(1, Int((platz - breite) / 30) + 1)
                // B18 (F-AWS-G-016, K-024): Karten gleichmäßig auf die Zeilen verteilen (13 = 7 + 6, nicht 12 + 1)
                let zeilenZahl = max(1, (karten.count + jeZeileMax - 1) / jeZeileMax)
                let jeZeile = max(1, (karten.count + zeilenZahl - 1) / zeilenZahl)
                let zeilen = stride(from: 0, to: karten.count, by: jeZeile).map { Array(karten[$0..<min($0 + jeZeile, karten.count)]) }
                VStack(spacing: zeilenZahl > 1 ? -18 : 0) {
                    ForEach(Array(zeilen.enumerated()), id: \.offset) { _, zeile in
                        let schritt = CGFloat(Faecher.schritt(anzahl: zeile.count, kartenbreite: Double(breite), platz: Double(platz)))
                        HStack(spacing: schritt - breite) {
                            ForEach(zeile, id: \.self) { k in
                                let ok = erlaubt.contains(k)
                                HKartenBild(karte: k, gedimmt: sicht == spiel.amZug && !ok && !spiel.stichVoll && !spiel.weitergabeOffen, groesse: breitTisch ? .normal : .klein)
                                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.yellow, lineWidth: 4).opacity(tipp == AnyHashable(k) ? 1 : 0))
                                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.appFlaeche, lineWidth: 4).opacity(spiel.weitergabeOffen && spiel.gewaehlt[sicht].contains(k) ? 1 : 0))   // 1.0 (M5)
                                    .offset(y: (ok && kannHandeln) || (spiel.weitergabeOffen && spiel.gewaehlt[sicht].contains(k)) ? -8 : 0)
                                    .onTapGesture {
                                        if waehltWeitergabe { spiel.waehleWeitergabe(k) }   // 1.0 (M5)
                                        else if kannHandeln, ok { tipp = nil; spiel.spiele(k); schritte += 1; nachZug() }
                                    }
                                    .accessibilityAddTraits(.isButton)   // G1
                                    .accessibilityHint(Text("Doppeltippen, um die Karte zu spielen"))
                                    .accessibilityValue(tipp == AnyHashable(k) ? Text("Tipp") : Text(verbatim: ""))
                            }
                        }
                        .frame(width: platz, height: handZeilenHoehe, alignment: .bottom)   // Hand mittig (vorher links, wenn der Fächer schmaler als `platz` ist)
                    }
                }
                .frame(width: geo.size.width, alignment: .bottom)
            }.frame(height: zeilenHoehe)
        }.padding(.bottom, 8)
    }

    private var hinweis: String {
        if spiel.stichVoll { return " " }
        if amZugComputer { return String(localized: "\(teilnehmer[spiel.amZug].name) überlegt …") }
        if waehltWeitergabe { return String(localized: "Wähle drei Karten \(richtungText) weitergeben (\(spiel.gewaehlt[spiel.amZug].count) von 3).") }   // 1.0 (M5)
        return kannHandeln ? String(localized: "Du bist dran – tippe eine Karte an.") : " "
    }

    private var rundenEnde: some View {
        VStack(spacing: 14) {
            Text(spiel.vorbei ? "Spielende" : "Runde \(spiel.runde) vorbei").font(.title2.bold())
            if let m = spiel.mondschuss { Text("Mondschuss von \(teilnehmer[m].name)!").foregroundStyle(Tisch.aktiv ? Tisch.elfenbein : Color.accentText) }
            ForEach(spiel.rangfolge, id: \.self) { i in
                HStack { Text(verbatim: teilnehmer[i].name); Spacer(); Text(verbatim: "\(spiel.gesamt[i])  (+\(spiel.rundenPunkte[i]))").monospacedDigit() }
            }
            Button(spiel.vorbei ? "Fertig" : "Nächste Runde") {
                if spiel.vorbei { beenden() } else {
                    spiel.naechsteRunde(mit: &zufall); schritte += 1
                }
            }.buttonStyle(HauptKnopfStil())
        }.padding(24).frame(maxWidth: 360)
        .background(RoundedRectangle(cornerRadius: Design.Ecke.karte).fill(Color.kartenGrund))
        .frame(maxWidth: .infinity, maxHeight: .infinity).background(Color.black.opacity(0.25))
    }

    /// C-030: Farbnamen für die Tipp-Ansage, in der Sprache des Geräts.
    private static func farbName(_ i: Int) -> String {
        [String(localized: "Kreuz"), String(localized: "Karo"), String(localized: "Pik"), String(localized: "Herz")][i]
    }

    /// F4/G1: Tipp auch hörbar.
    private func tippAnsage(_ k: HKarte) {
        let h = spiel.haende[sicht], i = h.firstIndex(of: k).map { $0 + 1 } ?? 0
        let w = k.wert > 10 ? [String(localized: "Bube"), String(localized: "Dame"), String(localized: "König"), String(localized: "Ass")][k.wert - 11] : "\(k.wert)"
        UIAccessibility.post(notification: .announcement, argument: String(localized: "Tipp: Karte \(i) von \(h.count), \(w) \(Self.farbName(k.farbe))."))
    }

    private func beenden() {
        guard !gemeldet else { return }
        gemeldet = true
        var e = SpielEnde.nachPunkten(namen: teilnehmer.map(\.name), punkte: spiel.gesamt, hoeherIstBesser: false)
        // Blatt 22 (EB2): Satz bei genau einer Siegerin oder einem Sieger, Werte (Durchmärsche nur, wenn der Stand sie kennt) und die Tabelle „Punkte je Runde“.
        let o = spiel.rangfolge
        if spiel.gesamt[o[0]] < spiel.gesamt[o[1]] { e.info = String(localized: "\(teilnehmer[o[0]].name) gewinnt mit \(spiel.gesamt[o[0]]) Punkten.") }
        var w = [EndeWert("Runden", "\(spiel.runde)")]
        if let d = spiel.durchmaersche { w.append(EndeWert("Durchmärsche", "\(d)")) }
        e.werte = w + [.dauer]
        e.bild = HerzensjagdEndeBild.bild(verlauf: spiel.rundenVerlauf, gesamt: spiel.gesamt, namen: teilnehmer.map(\.name))
        ende(e)
    }

    private func nachZug() {
    }
}
#endif
