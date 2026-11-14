// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import SpielHilfen
import PokerwurfKern

@MainActor
public struct PokerwurfModul: SpielModul {
    public init() {}
    public let id = "pokerwurf"
    public let name = "Pokerwurf"
    public let gattung = Gattung.wuerfel
    public let farbe = AkzentFarbeWert.gruen
    public let symbol = "dice"
    public let spielerzahl = 2...4
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "Fünf Würfel, drei Würfe, beste Hand", farbe: farbe, spieler: 2...4, computerErlaubt: true,
                            wuerfelWahl: true, regeln: "Fünf Runden lang würfelt jeder reihum mit fünf Würfeln bis zu dreimal. Nach dem ersten und zweiten Wurf tippst du die Würfel an, die du behalten willst. Die Hände sind, von schwach nach stark: Nichts, ein Paar, zwei Paare, Drilling, kleine Straße (1–5), große Straße (2–6), Full House, Vierling, Fünfling. Bei gleicher Hand zählen die höheren Würfel. Wer in einer Runde die beste Hand hat, bekommt einen Punkt, bei Gleichstand bekommen alle Besten einen. Nach fünf Runden gewinnt, wer die meisten Punkte hat.",
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            PokerwurfSpiel(teilnehmer: teilnehmer, ende: ende, abbrechen: abbrechen, quelle: WuerfelWahl.quelle(id, vorgabe: umgebung.wuerfelQuelle))
        }.mitStartOptionen { PokerwurfBeginnKarte(eintraege: $0) }   // T-097: Wer beginnt
        .mitZiel("Würfle in jeder der fünf Runden die beste Pokerhand. Wer am Ende die meisten Punkte hat, gewinnt.")
        .mitZielSchrittNeu(.ziel("Würfle in jeder der fünf Runden die beste Pokerhand. Wer am Ende die meisten Punkte hat, gewinnt. Pokerwurf ist Poker mit fünf Würfeln statt Karten. Es spielen 2 bis 4 Personen, auch gegen den Computer. Ihr würfelt der Reihe nach, offen und ohne Einsätze."))
        .mitAnleitung(RegelTexteNeu.anleitung(neu: [
            .figuren(symbol: "hand.tap", titel: "Dreimal würfeln", text: "Du hast bis zu drei Würfe. Beim ersten rollen alle fünf Würfel. Danach tippst du die Würfel an, die du behalten willst, und würfelst nur den Rest neu. Gehaltene Würfel bleiben für den nächsten Wurf liegen. Bist du zufrieden, tippst du auf „Behalten“. Das geht nach jedem Wurf. Nach dem dritten Wurf ist dein Zug auf jeden Fall vorbei.", figuren: ["🎲", "🎲", "🎲", "🎲", "🎲"], bewegt: nil),
            .figuren(symbol: "list.number", titel: "Die Hände", text: "Von schwach nach stark: Nichts, ein Paar, zwei Paare, Drilling, kleine Straße (1 bis 5), große Straße (2 bis 6), Full House, Vierling und Fünfling. Ein Full House sind drei gleiche und zwei gleiche Würfel. Die App zeigt dir nach jedem Wurf, welche Hand du gerade hast.", figuren: ["🎲", "🎲", "🎲"], bewegt: nil),
            .figuren(symbol: "equal.circle", titel: "Gleiche Hand", text: "Haben zwei die gleiche Hand, gewinnen die höheren Würfel. Ein Paar Sechsen schlägt also ein Paar Fünfen. Sind auch die gleich, zählen die übrigen Würfel, der höchste zuerst. Sind zwei Hände genau gleich gut, bekommen beide den Punkt.", figuren: ["4️⃣", "4️⃣", "⚖️", "3️⃣", "3️⃣"], bewegt: 2),
            .figuren(symbol: "trophy", titel: "Fünf Runden", text: "Haben alle gewürfelt, bekommt die beste Hand der Runde einen Punkt. Nach fünf Runden gewinnt, wer die meisten Punkte hat. Wer anfängt, wechselt jede Runde reihum. Wer als Letzter dran ist, sieht schon die Hände der anderen und weiß, was er schlagen muss.", figuren: ["🏆", "🎲"], bewegt: nil),
            .figuren(symbol: "dice", titel: "Echte Würfel und Hilfen", text: "Ihr könnt auch mit echten Würfeln spielen. Wähle dafür vor dem Start „Echt“ und tippe nach jedem Wurf die Augen ein. Mit „Zug zurück“ nimmst du deine Auswahl der gehaltenen Würfel zurück, aber nie einen Wurf. Die Stärke des Computers stellst du unter „Mehr“ ein. Alles Weitere steht unter „Alle Regeln lesen“.", figuren: ["🎲", "✍️", "↩️"], bewegt: nil),
        ], alt: [
            .figuren(symbol: "hand.tap", titel: "Würfel behalten", text: "Du würfelst fünf Würfel bis zu dreimal. Tippe die Würfel an, die du behalten willst.", figuren: ["🎲", "🎲", "🎲", "🎲", "🎲"], bewegt: nil),
            .figuren(symbol: "list.number", titel: "Pokerhände", text: "Von schwach nach stark: Nichts, Paar, zwei Paare, Drilling, kleine und große Straße, Full House, Vierling, Fünfling.", figuren: ["🎲", "🎲", "🎲"], bewegt: nil),
            .figuren(symbol: "trophy", titel: "Fünf Runden", text: "Wer in einer Runde die beste Hand hat, bekommt einen Punkt. Nach fünf Runden gewinnt, wer die meisten hat.", figuren: ["🏆", "🎲"], bewegt: nil),
        ])))
    }
}

struct PokerwurfSpiel: View {
    let teilnehmer: [SpielTeilnehmer]
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    let quelle: WuerfelQuelle
    @State private var spiel: Pokerwurf
    @State private var zufall = EchteWuerfelZufall()
    @State private var eingabe: Int?
    @State private var gemeldet = false
    @State private var tick = 0
    @State private var breite: CGFloat = 0
    @State private var stufe = ComputerStufe.gespeichert("pokerwurf")
    /// 1.0 (P4): Rückgängig. Stände vor jeder eigenen Halte-Auswahl und vor jeder Wertung („Behalten“); ein Wurf wird nie zurückgenommen
    /// (Würfeln und Züge des Computers leeren die Liste).
    @State private var verlauf: [Pokerwurf] = []
    /// 1.0 (P4): Würfelbilanz für „So fielen die Würfel“ am Ende.
    @State private var bilanz: WuerfelBilanz
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var regular: Bool { sizeClass == .regular }
    private var fehler: Double { switch stufe { case .leicht: 0.5; case .mittel: 0.15; case .schwer: 0 } }

    init(teilnehmer: [SpielTeilnehmer], ende: @escaping (SpielEnde) -> Void, abbrechen: @escaping () -> Void, quelle: WuerfelQuelle, vorgabe: Pokerwurf? = nil) {
        self.teilnehmer = teilnehmer; self.ende = ende; self.abbrechen = abbrechen; self.quelle = quelle
        _spiel = State(initialValue: vorgabe ?? Pokerwurf(spieler: teilnehmer.count, beginner: PokerwurfBeginn.naechster(anzahl: teilnehmer.count)))   // T-097: Wer beginnt
        _bilanz = State(initialValue: WuerfelBilanz(namen: teilnehmer.map(\.name)))   // 1.0 (P4)
    }

    /// Echte Würfel: erst die Augen der nicht gehaltenen Würfel eintippen, dann läuft die normale Wurf-Logik.
    private func wuerfelnMensch() {
        if quelle == .echt {
            let frei = spiel.wuerfe == 0 ? 5 : spiel.becher.gehalten.filter { !$0 }.count
            if frei == 0 { wirf(computer: false) } else { eingabe = frei }   // C-034 (2): nichts einzutippen, kein hängender Wert
        } else { wirf(computer: false) }
    }

    /// 1.0 (P4): Ein Wurf mit Bilanz: Gezählt werden nur die neu geworfenen Würfel (nicht die gehaltenen). Ein Wurf ist nicht rückgängig zu machen.
    private func wirf(computer: Bool) {
        let vorher = spiel
        spiel.wuerfeln(mit: &zufall)
        guard spiel.wuerfe != vorher.wuerfe else { return }
        // Einstellungen > Spielen > „Gehaltene Würfel bleiben liegen“ (Standard an); aus = nach jedem Wurf neu wählen
        if !(UserDefaults.standard.object(forKey: "wuerfelBleibenGehalten") as? Bool ?? true), spiel.wuerfe < 3 { spiel.alleFreigeben() }
        verlauf.removeAll()
        let frei = (0..<5).filter { vorher.wuerfe == 0 || !vorher.becher.gehalten[$0] }
        bilanz.zaehle(spieler: vorher.amZug, frei.map { spiel.becher.augen[$0] }, eingetippt: quelle == .echt && !computer)
    }

    /// 1.0 (P4): Halte-Auswahl eines Menschen, mit Merkstand fürs Rückgängig.
    private func halteMensch(_ i: Int) {
        let vorher = spiel
        spiel.halte(i)
        if spiel != vorher { verlauf.append(vorher) }
    }

    /// 1.0 (P4): „Behalten“ (Wertung der Hand) eines Menschen, mit Merkstand fürs Rückgängig.
    private func behaltenMensch() {
        let vorher = spiel
        spiel.fertig()
        if spiel != vorher { verlauf.append(vorher) }
        tick += 1
    }

    private var kannZurueck: Bool { !verlauf.isEmpty && !amZugComputer && !spiel.vorbei }

    private func zurueck() {
        guard kannZurueck, let alt = verlauf.popLast() else { return }
        spiel = alt; tick += 1
    }

    private var zurueckKnopf: some View {
        Button(action: zurueck) { Label("Zug zurück", systemImage: "arrow.uturn.backward") }
            .tischNebenKnopf().dynamicTypeSize(...DynamicTypeSize.xxxLarge).disabled(!kannZurueck)
    }

    private var amZugComputer: Bool { teilnehmer[spiel.amZug].computer }

    /// Kachelgrund wie in der SpielerLeiste des Baukastens: Klar Karte (aktiv zarte App-Farbe), Tinte Zeile ohne Karte (aktiv Feldgrund), Salon ohne Fläche.
    private func kachelGrund(aktiv: Bool) -> Color {
        switch Design.art {
        case .klar: return aktiv ? Color.appFlaeche.opacity(0.25) : Color.kartenGrund
        case .tinte: return aktiv ? Color.white.opacity(0.14) : Color.clear   // Design-Runde 3: auf dem Filz
        case .salon: return Color.clear
        }
    }

    /// Name der Kachel wie in der SpielerLeiste (2.21): eine Schriftfamilie und Größe für alle Namen; aktiv fett (mit Punkt im Salon), inaktiv normal in Schrift zweit (Tinte, Salon).
    @ViewBuilder private func kachelName(_ name: String, aktiv: Bool, klein: Bool) -> some View {
        let salon = Design.ist(.salon)
        HStack(spacing: Design.Abstand.xs) {
            if salon && aktiv { Circle().fill(Color.appFlaeche).frame(width: 7, height: 7) }
            Text(verbatim: name)
                .font(salon ? Design.Schrift.serif(15, gewicht: aktiv ? .bold : .regular, relativ: .caption, hoechstens: 1.2)
                            : (klein ? Font.caption : Font.footnote).weight(Design.ist(.tinte) && aktiv ? .semibold : .regular))
                .foregroundColor(Design.art != .klar && !aktiv ? Color.schriftZweit : nil)
                .lineLimit(1).minimumScaleFactor(0.7)
        }
    }

    var body: some View {
        VStack(spacing: Theme.kartenAbstand) {
            SpielKopf(mitte: String(localized: "Runde \(min(spiel.runde + 1, Pokerwurf.runden)) von \(Pokerwurf.runden)"), linksAktion: abbrechen) {
                RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                    FragNachDenRegelnMenuePunkt()   // KI-3 (Blatt 12): nur mit Apple Intelligence sichtbar
                    if teilnehmer.contains(where: \.computer) { ComputerStufePicker(spiel: "pokerwurf", stufe: $stufe) }
                    NeuePartieMenuePunkt()   // G-019
                    Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
                }
            }
            if Tisch.aktiv {
                // Große Tinte-Runde, Punkt 6: runde Leiste mit Bild und Spielerfarbe. Die Hände der Runde stehen darunter.
                SpielerLeiste(eintraege: teilnehmer.indices.map { i in
                    .init(id: "\(i)", name: teilnehmer[i].name, farbe: Spieler.farbe(i), wert: "\(spiel.punkte[i])")
                }, aktiv: spiel.rundeGewertet ? nil : "\(spiel.amZug)")
                .padding(.horizontal, Theme.seitenRand)
                if teilnehmer.indices.contains(where: { spiel.haende[$0] != nil }) {
                    Text(verbatim: teilnehmer.indices.compactMap { i in spiel.haende[i].map { "\(teilnehmer[i].name): " + String(localized: String.LocalizationValue($0.art.name)) } }.joined(separator: " · "))
                        .font(.caption2).tischHinweis().padding(.horizontal, Theme.seitenRand)
                }
            } else {
            HStack(spacing: Design.Abstand.s) {
                ForEach(teilnehmer.indices, id: \.self) { i in
                    VStack(spacing: 2) {
                        kachelName(teilnehmer[i].name, aktiv: i == spiel.amZug && !spiel.rundeGewertet, klein: false)
                        Text(verbatim: "\(spiel.punkte[i])").font(.title3.weight(.semibold))
                        Text(spiel.haende[i].map { LocalizedStringKey($0.art.name) } ?? "–").font(.caption2).foregroundStyle(Color.schriftZweit).lineLimit(1).minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: Design.Ecke.feld).fill(kachelGrund(aktiv: i == spiel.amZug && !spiel.rundeGewertet)))   // wie SpielerLeiste im Baukasten: Klar zarte Farbe, Tinte Feldgrund, Salon keine Fläche
                }
            }.padding(.horizontal, Theme.seitenRand)
            }
            Spacer(minLength: 0)
            if spiel.rundeGewertet {
                VStack(spacing: 10) {
                    Text(spiel.rundenSieger.count == 1 ? "\(teilnehmer[spiel.rundenSieger[0]].name) gewinnt die Runde" : "Unentschieden in dieser Runde").font(.headline)
                    Button(spiel.runde + 1 >= Pokerwurf.runden ? "Ergebnis" : "Nächste Runde") { weiterRunde() }.buttonStyle(HauptKnopfStil())
                    if !verlauf.isEmpty { zurueckKnopf }   // 1.0 (P4): Wertung zurücknehmen
                }.padding(.horizontal, Theme.seitenRand)
            } else {
                if Tisch.aktiv { rangTafel }   // Runde 5, Paket W (Blatt 7): Rangfolge über den Würfeln
                würfelReihe
                if !Tisch.aktiv {   // in Tinte steht der Wurf in der Tafel (VoiceOver: Ansage an der Tafel)
                    Text(spiel.wuerfe == 0 ? " " : LocalizedStringKey(spiel.aktuelleHand.art.name)).font(.headline).foregroundStyle(Color.accentText)
                }
                Text(hinweis).font(.footnote).frame(minHeight: 18).tischHinweis(sonst: Color.schriftZweit)
                zugKnoepfe.padding(.horizontal, Theme.seitenRand)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: regular && !Tisch.aktiv ? 640 : .infinity)   // Blatt 16: in Tinte ganze Breite, Kopfknöpfe am Rand; früher Tinte (Punkt 13): Würfel auf dem iPad größer; B18 F-AWS-P-011: auf dem iPad nicht über die volle Breite ziehen
        .frame(maxWidth: .infinity)
        .aufTisch()   // Design-Runde 3: in Tinte Filz bis in die Ecken, sonst Seitengrund wie bisher
        #if DEBUG
        .onAppear { if spiel.runde == 0, spiel.wuerfe == 0, spiel.haende.allSatisfy({ $0 == nil }) { PokerwurfBeginn.merke(spiel.beginner ?? 0) } }   // T-097: Reihum merkt, wer diese Partie begonnen hat
        .testEndeMelden { if spiel.runde + 1 >= Pokerwurf.runden, spiel.rundeGewertet { weiterRunde() } }   // -testZustand ende: das Ende wird nach dem Laden des Endstands selbst gemeldet
        #endif
        .fortsetzbar("pokerwurf", $spiel, pruefen: { [n = teilnehmer.count] in $0.spieler == n && $0.haende.count == n && $0.punkte.count == n && $0.amZug >= 0 && $0.amZug < n },
                     standGeladen: { geladen in   // 1.0 (P4): Würfelbilanz folgt dem Fortsetzen; frische Partie → alte Bilanz weg
                         if geladen, let b = WuerfelBilanz.laden(spiel: "pokerwurf", namen: teilnehmer.map(\.name)) { bilanz = b }
                         else if !geladen { WuerfelBilanz.loeschen(spiel: "pokerwurf") }
                     })
        .onChange(of: bilanz) { _, neu in neu.sichern(spiel: "pokerwurf") }   // 1.0 (P4)   // C-024: Stand mit anderer Spielerzahl verwerfen
        .weicheAnimation(bei: spiel)
        .spielHaptik(zug: spiel, erfolg: (spiel.vorbei))
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .echteWuerfelEingabe(anzahl: $eingabe) { augen in zufall.lade(augen: augen); wirf(computer: false) }
        .uebergabeSeite(teilnehmer: teilnehmer, amZug: spiel.amZug, aktiv: !spiel.vorbei && !spiel.rundeGewertet, geheim: false)
        .task(id: "\(spiel.amZug)-\(spiel.wuerfe)-\(spiel.runde)-\(tick)") {
            guard amZugComputer, !spiel.vorbei, !spiel.rundeGewertet else { return }
            try? await Task.sleep(nanoseconds: ComputerTempo.angepasst(nanosekunden: 1_000_000_000))
            guard !Task.isCancelled else { return }
            verlauf.removeAll()   // 1.0 (P4): Züge des Computers sind nicht rückgängig zu machen
            if spiel.wuerfe == 0 { wirf(computer: true); return }
            if spiel.wuerfe >= 3 { spiel.fertig(); tick += 1; return }
            if spiel.computerFertig(stufe: stufe.rawValue) { spiel.fertig(); tick += 1; return }
            let halten = Pokerwurf.computerHalten(spiel.becher.augen, fehler: fehler, mit: &zufall)
            if halten.allSatisfy({ $0 }) { spiel.fertig(); tick += 1; return }
            for i in 0..<5 where halten[i] != spiel.becher.gehalten[i] { spiel.halte(i) }
            wirf(computer: true)
        }
    }

    /// G-020: Nach dem dritten Wurf gibt es nur noch „Behalten“ als Hauptknopf (vorher stand dort ein totes „Würfeln (0 übrig)“, „Behalten“ rutschte bei großer Schrift aus dem Bild).
    /// Davor liegen beide Knöpfe nebeneinander, bei großer Schrift untereinander.
    @ViewBuilder private var zugKnoepfe: some View {
        if spiel.mussBehalten {
            Button("Behalten") { behaltenMensch() }.buttonStyle(HauptKnopfStil()).disabled(amZugComputer)
            zurueckKnopf   // 1.0 (P4)
        } else {
            let wuerfeln = Button("Würfeln (\(3 - spiel.wuerfe) übrig)") { wuerfelnMensch() }.buttonStyle(HauptKnopfStil()).beimSchuetteln(aktiv: quelle == .app) { wuerfelnMensch() }
                .disabled(amZugComputer || !spiel.kannWuerfeln)   // RT-011: alle Würfel gehalten
            let behalten = Button("Behalten") { behaltenMensch() }.tischNebenKnopf().disabled(amZugComputer || !spiel.zugBeendbar)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: Design.Abstand.m) { wuerfeln; behalten }
                VStack(spacing: Design.Abstand.s) { wuerfeln; behalten }
            }
            zurueckKnopf   // 1.0 (P4)
        }
    }

    private var hinweis: String {
        if amZugComputer { return String(localized: "\(teilnehmer[spiel.amZug].name) würfelt …") }
        if spiel.wuerfe == 0 { return String(localized: "\(teilnehmer[spiel.amZug].name): Würfle!") }
        return spiel.wuerfe < 3 ? String(localized: "Tippe Würfel an, die du behalten willst.") : String(localized: "Letzter Wurf – behalte die Hand.")
    }

    /// Runde 5, Paket W (Blatt 7): Tafel auf dem Filz mit den acht Würfen, der aktuelle als helle Kapsel. Bei „Nichts“ keiner markiert.
    private var rangTafel: some View {
        let links: [PokerHand.Art] = [.fuenfling, .vierling, .fullHouse, .grosseStrasse]
        let rechts: [PokerHand.Art] = [.kleineStrasse, .drilling, .zweiPaare, .paar]
        let aktuell: PokerHand.Art? = spiel.wuerfe == 0 ? nil : spiel.aktuelleHand.art
        // Fund 55: Nummern 1 (stärkste) bis 8, damit die Spaltenfolge (links 1–4, rechts 5–8) eindeutig zu lesen ist
        let reihe = links + rechts
        func zeile(_ art: PokerHand.Art) -> some View {
            let an = aktuell == art
            let nr = (reihe.firstIndex(of: art) ?? 0) + 1
            return (Text(verbatim: "\(nr)  ").monospacedDigit() + Text(LocalizedStringKey(art.name)))
                .font(.system(size: 15, weight: an ? .semibold : .regular)).lineLimit(1).minimumScaleFactor(0.7)
                .foregroundStyle(an ? Tisch.auge : Tisch.elfenbein.opacity(0.86))
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, minHeight: 34, alignment: .leading)
                .background(Capsule().fill(an ? Tisch.elfenbein : Color.clear))
        }
        return VStack(alignment: .leading, spacing: 4) {
            Text("Rangfolge · stark nach schwach").textCase(.uppercase).tracking(1.4)
                .font(.system(size: 11.5, weight: .semibold)).foregroundStyle(Tisch.elfenbein.opacity(0.7))
                .padding(.horizontal, 12).padding(.top, 8)
            HStack(alignment: .top, spacing: 8) {
                VStack(spacing: 0) { ForEach(links, id: \.self) { zeile($0) } }
                VStack(spacing: 0) { ForEach(rechts, id: \.self) { zeile($0) } }
            }.padding(.horizontal, 4).padding(.bottom, 6)
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Tisch.elfenbein.opacity(0.11)))
        .padding(.horizontal, Theme.seitenRand)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(spiel.wuerfe == 0 ? "Noch nicht gewürfelt" : LocalizedStringKey(spiel.aktuelleHand.art.name)))
    }

    private var würfelReihe: some View {
        // M-007: Würfel so groß wie die Breite erlaubt (wie Yacht, iPad bis 90, iPhone bis 72); vorher fest 54
        let abstand: CGFloat = regular ? 16 : (Tisch.aktiv ? 9 : 8)
        let kante: CGFloat = breite > 0 ? max(44, min(regular ? (Tisch.aktiv ? 150 : 90) : 72, ((breite - 2 * Theme.seitenRand) - 4 * abstand - 5 * 10) / 5)) : (regular ? 88 : 54)
        return HStack(spacing: abstand) {
            ForEach(0..<5, id: \.self) { i in
                let gehalten = spiel.becher.gehalten[i]
                WuerfelFlaeche(augen: spiel.wuerfe == 0 ? nil : spiel.becher.augen[i], gehalten: gehalten, groesse: kante)   // B18 K-014/M-007: Würfel wie bei Yacht (Design-Würfel), auf dem iPad größer
                    .accessibilityLabel(spiel.wuerfe == 0 ? Text("Noch nicht gewürfelt") : Text("Würfel: \(spiel.becher.augen[i])"))
                    .accessibilityValue(gehalten ? Text("gehalten") : Text(verbatim: ""))
                    .padding(2)
                    .overlay(RoundedRectangle(cornerRadius: Design.Ecke.klein).stroke(Color.appFlaeche, lineWidth: gehalten ? 3 : 0))
                    .offset(y: gehalten && Tisch.aktiv ? -kante * 0.22 : 0)   // Design-Runde 3: gehaltene Würfel rücken nach oben in die Ablage
                    .onTapGesture { if !amZugComputer { halteMensch(i) } }
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(.isButton)
                    .accessibilityHint(spiel.wuerfe == 0 || amZugComputer ? Text(verbatim: "") : Text("Tippen, um den Würfel zu halten oder freizugeben"))
                    .accessibilityAction { if !amZugComputer, spiel.wuerfe > 0 { halteMensch(i) } }
            }
        }
        .frame(maxWidth: .infinity)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { breite = $0 }
    }

    private func weiterRunde() {
        if spiel.runde + 1 >= Pokerwurf.runden {
            guard !gemeldet else { return }
            gemeldet = true
            var e = SpielEnde.nachPunkten(namen: teilnehmer.map(\.name), punkte: spiel.punkte)
            e.wuerfel = bilanz   // 1.0 (P4): „So fielen die Würfel“
            // Blatt 22 (EB2, Schritt 2): Satz mit Sieger, „Bester Wurf“, Dauer; das Würfelbild bleibt
            let spitze = spiel.punkte.max() ?? 0
            let sieger = spiel.punkte.indices.filter { spiel.punkte[$0] == spitze }
            if sieger.count == 1, teilnehmer.count > 1 {
                e.info = String(localized: "\(teilnehmer[sieger[0]].name) gewinnt \(spitze) von \(Pokerwurf.runden) Runden.")
            }
            var werte: [EndeWert] = []
            if let b = spiel.besteHaende, b.count == teilnehmer.count,
               let bester = b.indices.compactMap({ i in b[i].map { (i, $0) } }).max(by: { $0.1 < $1.1 }) {
                werte.append(EndeWert("Bester Wurf", "\(String(localized: String.LocalizationValue(bester.1.art.name))) (\(teilnehmer[bester.0].name))"))
            }
            e.werte = werte + [.dauer]
            ende(e)
        } else { spiel.naechsteRunde(); verlauf.removeAll() }
    }
}
#endif
