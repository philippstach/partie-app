// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import AblegeKarten
import MauMauKern

/// Karte der Hand mit Platz, damit gleiche Karten (zwei Blätter) unterscheidbar bleiben.
struct HandKarte: Hashable {
    let platz: Int
    let karte: NKarte
}

/// Gespeicherter Spielstand von „Mau-Mau“.
struct MauMauNeuStand: Codable, Equatable {
    var spiel: NMauMau
    var runden: NRunden?
}

/// Skatkarte in beliebiger Breite (das Bild des Baukastens kennt vier feste Größen und wird skaliert).
struct NKartenBild: View {
    let karte: NKarte?
    let breite: CGFloat
    var markiert = false
    var gedimmt = false
    var body: some View {
        let basis = KartenGroesse.riesig.masse
        let s = breite / basis.width
        SkatKartenBild(karte.flatMap { k in SkatKarte.Farbe(rawValue: k.farbe).map { SkatKarte($0, k.wert) } }, groesse: .riesig, gedimmt: gedimmt, markiert: markiert)
            .scaleEffect(s, anchor: .topLeading)
            .frame(width: basis.width * s, height: basis.height * s, alignment: .topLeading)
    }
}

func farbName(_ f: Int) -> String { [String(localized: "Kreuz"), String(localized: "Pik"), String(localized: "Herz"), String(localized: "Karo")][f] }

struct MauMauNeuSpiel: View {
    let teilnehmer: [SpielTeilnehmer]
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    @State private var regeln = RegelSpeicher.gespeichert
    @State private var stufe = ComputerStufe.gespeichert("maumau-neu", standard: .schwer)
    @State private var stand: MauMauNeuStand
    @State private var tipp: HandKarte?
    @State private var zufall = SystemRandomNumberGenerator()
    @State private var aufgedeckt = false
    @State private var wunschFuer: Int?
    @State private var mauGesagt = false
    @State private var denkt = false
    @State private var regelBlatt = false
    @State private var neuFragen = false
    @Environment(\.farbenUnterscheidbar) private var farbenUnterscheidbar

    init(teilnehmer: [SpielTeilnehmer], ende: @escaping (SpielEnde) -> Void, abbrechen: @escaping () -> Void) {
        self.teilnehmer = teilnehmer; self.ende = ende; self.abbrechen = abbrechen
        var g = SystemRandomNumberGenerator()
        let r = RegelSpeicher.gespeichert
        _stand = State(initialValue: MauMauNeuStand(spiel: NMauMau(spieler: teilnehmer.count, regeln: r, beginner: MauMauBeginn.naechster(anzahl: teilnehmer.count), mit: &g),
                                                    runden: r.mehrrunden ? NRunden(spieler: teilnehmer.count, ziel: r.zielPunkte) : nil))
    }

    private var spiel: NMauMau { stand.spiel }
    private var computerDran: Bool { teilnehmer[spiel.dran].computer }
    private var unberuehrt: Bool { spiel.verlauf.isEmpty && (stand.runden?.runde ?? 1) == 1 }

    // MARK: Aufbau

    var body: some View {
        AblegeTischAufbau(
            kopf: { kopf },
            leiste: { leiste },
            tisch: { m in tisch(m) },
            hand: { m in hand(m) },
            aktionen: { aktionen },
            seite: { m in seitenspalte(m) }
        )
        .aufTisch()   // Design-Runde 3: in Tinte Filz bis in die Ecken (Blätter danach bleiben im System-Aussehen), sonst Seitengrund wie bisher
        // S4: Der Computer wird erst angestoßen, wenn der Stand geladen ist (vorher lief `pruefe` im eigenen onAppear,
        // dessen Reihenfolge zum Laden nicht festliegt: Nach „Fortsetzen“ mit Computer am Zug blieb das Spiel stehen).
        #if DEBUG
        .testEndeMelden { if let s = spiel.sieger { rundeAbschliessen(s) } }   // -testZustand ende: das Ende wird nach dem Laden des Endstands selbst gemeldet
        #endif
        .fortsetzbar("maumau-neu", $stand, pruefen: { [n = teilnehmer.count] in $0.spiel.haende.count == n && $0.spiel.dran >= 0 && $0.spiel.dran < n && !$0.spiel.ablage.isEmpty && ($0.runden.map { $0.punkte.count == n } ?? true) }, standGeladen: { _ in pruefe() })
        .weicheAnimation(bei: spiel)
        .onAppear { if spiel.verlauf.isEmpty { MauMauBeginn.merke(spiel.dran) } }   // T-097: frische Partie oder Runde: Beginner merken
        .spielHaptik(zug: spiel, erfolg: spiel.sieger != nil)
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .confirmationDialog("Aktuelle Partie abbrechen?", isPresented: $neuFragen, titleVisibility: .visible) {
            Button("Abbrechen und neu starten", role: .destructive) { neuePartie() }
            Button("Weiterspielen", role: .cancel) {}
        } message: { Text("Die laufende Partie wird verworfen und neu begonnen.") }
        .sheet(isPresented: $regelBlatt) {
            RegelBlatt(regeln: $regeln, aenderbar: unberuehrt, spieler: teilnehmer.count).presentationDetents([.large])
        }
        .onChange(of: regeln) { _, neu in
            RegelSpeicher.sichern(neu)
            if unberuehrt, spiel.regeln != neu {
                var g = SystemRandomNumberGenerator()
                stand = MauMauNeuStand(spiel: NMauMau(spieler: teilnehmer.count, regeln: neu, beginner: spiel.dran, mit: &g),
                                       runden: neu.mehrrunden ? NRunden(spieler: teilnehmer.count, ziel: neu.zielPunkte) : nil)
                tipp = nil; aufgedeckt = false; mauGesagt = false; pruefe()
            }
        }
    }

    private func neuePartie() {
        var g = SystemRandomNumberGenerator()
        let beginner = MauMauBeginn.naechster(anzahl: teilnehmer.count)   // T-097: Wer beginnt
        stand = MauMauNeuStand(spiel: NMauMau(spieler: teilnehmer.count, regeln: regeln, beginner: beginner, mit: &g),
                               runden: regeln.mehrrunden ? NRunden(spieler: teilnehmer.count, ziel: regeln.zielPunkte) : nil)
        MauMauBeginn.merke(beginner)
        tipp = nil; aufgedeckt = false; mauGesagt = false; pruefe()
    }

    @Environment(\.regelnOeffnen) private var regelnOeffnen   // Fund 36/47: „Regeln“ im Mehr-Menü wie bei Yacht
    private var kopf: some View {
        SpielKopf(mitte: kopfText, mitteKurz: teilnehmer[spiel.dran].name, linksAktion: abbrechen) {
            RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                if teilnehmer.contains(where: \.computer) { ComputerStufePicker(spiel: "maumau-neu", stufe: $stufe) }
                Button("Hausregeln", systemImage: "slider.horizontal.3") { regelBlatt = true }
                if let regelnOeffnen { Button("Regeln", systemImage: "book") { regelnOeffnen() } }   // Fund 36
                FragNachDenRegelnMenuePunkt()   // KI-3 (Blatt 12): nur mit Apple Intelligence sichtbar
                Button("Neue Partie", systemImage: "arrow.counterclockwise") { if unberuehrt { neuePartie() } else { neuFragen = true } }   // G-012
                Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
            }
        }
    }

    private var kopfText: String {
        if let r = stand.runden { return String(localized: "Runde \(r.runde) · \(teilnehmer[spiel.dran].name)") }
        return spiel.sieger != nil ? String(localized: "Partie zu Ende") : String(localized: "\(teilnehmer[spiel.dran].name) ist dran")
    }

    private var leiste: some View {
        SpielerLeiste(eintraege: teilnehmer.indices.map { i in
            .init(id: "\(i)", name: teilnehmer[i].name, farbe: Spieler.farbe(i),
                  wert: stand.runden.map { "\(spiel.haende[i].count) · \($0.punkte[i])" } ?? "\(spiel.haende[i].count)")
        }, aktiv: "\(spiel.dran)")
        .padding(.horizontal, Theme.seitenRand)
    }

    // MARK: Tisch

    private func tisch(_ m: AblegeMasse) -> some View {
        VStack(spacing: 10) {
            Spacer(minLength: 0)
            if let s = spiel.sieger {
                rundenErgebnis(s)
            } else {
                HStack(spacing: m.tischKarte > 100 ? 28 : 18) {
                    StapelAnzeige("Stapel", anzahl: spiel.stapel.count) { NKartenBild(karte: nil, breite: m.tischKarte) }
                    StapelAnzeige("Ablage", anzahl: spiel.ablage.count) { NKartenBild(karte: spiel.oben, breite: m.tischKarte, markiert: true) }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(Text("Ablage, oben \(spiel.oben.name) \(farbName(spiel.oben.farbe)), \(spiel.ablage.count) Karten"))
                }
                zustandsChips
                Text(verbatim: letzteAktion).font(.footnote).multilineTextAlignment(.center).tischHinweis()
                    .lineLimit(m.kleinerBildschirm ? 1 : 2).padding(.horizontal, Theme.seitenRand)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
    }

    /// Zustands-Chip: was gerade gilt (Ziehen, Aussetzen, Wunschfarbe, Richtung).
    private var zustandsChips: some View {
        let name = teilnehmer[spiel.dran].name
        return HStack(spacing: Design.Abstand.s) {
            if spiel.zieh > 0 {
                StatusChip(symbol: "plus.circle.fill", text: Text("+\(spiel.zieh) für \(name)"), ton: .warnung, farbe: Tisch.aktiv ? Tisch.elfenbein : nil)
            } else if spiel.aussetzen {
                StatusChip(symbol: "forward.end.fill", text: Text("\(name) setzt aus"), ton: .warnung, farbe: Tisch.aktiv ? Tisch.elfenbein : nil)
            } else if let w = spiel.wunsch {
                StatusChip(symbol: "paintpalette.fill", text: Text("Wunsch: \(NKarte.farbSymbole[w]) \(farbName(w))"))
            } else {
                StatusChip(symbol: "equal.circle", text: Text("Farbe oder Wert"), ton: .neutral)
            }
            if spiel.richtung < 0 { StatusChip(symbol: "arrow.counterclockwise", text: Text("Richtung gedreht"), ton: .neutral) }
        }
    }

    private var letzteAktion: String {
        guard let a = spiel.verlauf.last else { return String(localized: "Die Partie beginnt.") }
        return beschreibe(a)
    }

    private func beschreibe(_ a: NAktion) -> String {
        func n(_ i: Int) -> String { teilnehmer[i].name }
        switch a {
        case .gelegt(let s, let k): return String(localized: "\(n(s)) legt \(k.name) \(farbName(k.farbe)).")
        case .gezogen(let s, let z): return String(localized: "\(n(s)) zieht \(z) Karten.")
        case .ausgesetzt(let s): return String(localized: "\(n(s)) setzt aus.")
        case .strafkarte(let s): return String(localized: "\(n(s)) hat „Mau“ vergessen und zieht eine Strafkarte.")
        case .wunsch(let s, let f): return String(localized: "\(n(s)) wünscht sich \(farbName(f)).")
        case .richtungGewechselt(let s): return String(localized: "\(n(s)) dreht die Richtung.")
        }
    }

    private func rundenErgebnis(_ s: Int) -> some View {
        VStack(spacing: 10) {
            Text("\(teilnehmer[s].name) gewinnt die Runde").font(.title3.weight(.bold)).multilineTextAlignment(.center)
            if let r = stand.runden {
                VStack(spacing: Design.Abstand.xs) {
                    ForEach(teilnehmer.indices, id: \.self) { i in
                        HStack {
                            Text(verbatim: teilnehmer[i].name)
                            Spacer()
                            Text("+\(spiel.restAugen(i)) → \(r.punkte[i] + spiel.restAugen(i))").monospacedDigit()
                        }.font(.subheadline)
                    }
                }.spielTischKarte().padding(.horizontal, Theme.seitenRand)
            }
        }
    }

    // MARK: Hand

    private func hand(_ m: AblegeMasse) -> some View {
        VStack(spacing: Design.Abstand.s) {
            if spiel.sieger != nil {
                Color.clear.frame(height: 0)
            } else if computerDran {
                Text("\(teilnehmer[spiel.dran].name) denkt nach …").tischHinweis().frame(height: m.handHoehe)
            } else if !aufgedeckt && teilnehmer.mehrereMenschen {
                SichtschutzKarte(name: teilnehmer[spiel.dran].name, farbe: Spieler.farbe(spiel.dran)) { aufgedeckt = true }
                    .padding(.horizontal, Theme.seitenRand).frame(minHeight: m.handHoehe)
            } else {
                if wunschFuer != nil {
                    FarbWahlLeiste(titel: "Farbe wünschen", eintraege: (0..<4).map { f in
                        FarbWahlEintrag(id: f, symbol: NKarte.farbSymbole[f], name: LocalizedStringKey(NKarte.farbNamen[f]), farbe: f < 2 ? .primary : Color(.systemRed))
                    }) { f in
                        if let i = wunschFuer { spiele(i, wunsch: f) }
                    }
                }
                let karten = spiel.haende[spiel.dran].enumerated().map { HandKarte(platz: $0.offset, karte: $0.element) }
                let spielbar = Set(spiel.spielbareIndizes.map { karten[$0] })
                KartenFaecher(karten: karten, spielbar: spielbar, tipp: tipp, kartenBreite: m.handKarte, kartenHoehe: m.handKarte * 1.42,
                              mindestSchritt: m.handKarte * 0.45, absenkung: 4,   // A-006: Ecke jeder Karte bleibt lesbar und antippbar
                              beschriftung: { k in Text("\(k.karte.name) \(farbName(k.karte.farbe)), Karte \(k.platz + 1) von \(karten.count)") },
                              aktion: { k in tipp = nil; tippe(k.platz) },
                              bild: { k, sp in NKartenBild(karte: k.karte, breite: m.handKarte, markiert: sp, gedimmt: !sp) })
            }
        }
    }

    // MARK: Knöpfe

    private var maeuKnopfNoetig: Bool {
        regeln.maueSagen && spiel.haende[spiel.dran].count == 2 && !spiel.spielbareIndizes.isEmpty
    }

    @ViewBuilder private var aktionen: some View {
        if let s = spiel.sieger {
            Button(stand.runden == nil ? "Ergebnis" : (rundenEnde ? "Ergebnis" : "Nächste Runde")) { rundeAbschliessen(s) }.buttonStyle(HauptKnopfStil())
        } else if computerDran || (!aufgedeckt && teilnehmer.mehrereMenschen) {
            Color.clear.frame(height: Theme.hauptKnopfHoehe)
        } else {
            HStack(spacing: Design.Abstand.m) {
                if spiel.spielbareIndizes.isEmpty || spiel.pflicht != .keine {
                    zustandsKnopf.buttonStyle(spiel.spielbareIndizes.isEmpty ? AnyButtonStyle(HauptKnopfStil()) : AnyButtonStyle(ZweitKnopfStil()))
                } else {
                    zustandsKnopf.buttonStyle(ZweitKnopfStil())
                }
                if maeuKnopfNoetig {
                    Button { mauGesagt.toggle() } label: { Label(mauGesagt ? "Mau!" : "Mau sagen", systemImage: mauGesagt ? "checkmark.circle.fill" : "megaphone") }
                        .buttonStyle(HauptKnopfStil())
                        .accessibilityValue(mauGesagt ? Text("gesagt") : Text("noch nicht gesagt"))
                }
                if !spiel.spielbareIndizes.isEmpty {
                    Button { zeigeTipp() } label: { Label("Tipp", systemImage: "lightbulb") }.buttonStyle(ZweitKnopfStil())
                }
            }
        }
    }

    private var zustandsKnopf: some View {
        Button { zieheOderWeiter() } label: { Text(zustandsTitel).lineLimit(1).minimumScaleFactor(0.6) }
        .accessibilityLabel(Text(zustandsTitel))
    }

    private func zieheOderWeiter() {
        var g = zufall; stand.spiel.ziehen(mit: &g); zufall = g
        SpielZug.gemacht("maumau-neu"); aufgedeckt = false; mauGesagt = false; tipp = nil; wunschFuer = nil; pruefe()
    }

    private var zustandsTitel: LocalizedStringKey {
        switch spiel.pflicht {
        case .ziehen(let n): return "\(n) Karten ziehen"
        case .aussetzen: return "Aussetzen"
        case .weiter: return "Weitergeben"
        case .keine: return "Karte ziehen"
        }
    }

    // MARK: iPad-Seitenspalte

    private func seitenspalte(_ m: AblegeMasse) -> some View {
        VStack(alignment: .leading, spacing: Design.Abstand.m) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Verlauf").font(.headline)
                ForEach(Array(spiel.verlauf.suffix(10).reversed().enumerated()), id: \.offset) { _, a in
                    Text(verbatim: beschreibe(a)).font(.footnote).tischHinweis(zeilen: 2)
                }
                if spiel.verlauf.isEmpty { Text("Noch nichts passiert.").font(.footnote).tischHinweis() }
            }.frame(maxWidth: .infinity, alignment: .leading).spielTischKarte()
            VStack(alignment: .leading, spacing: 6) {
                Text("Regeln dieser Partie").font(.headline)
                Text(verbatim: regelZeilen.joined(separator: "\n")).font(.footnote).tischHinweis(zeilen: 8)
            }.frame(maxWidth: .infinity, alignment: .leading).spielTischKarte()
        }
    }

    private var regelZeilen: [String] {
        var z: [String] = [String(localized: "\(regeln.startkarten) Karten auf der Hand")]
        if regeln.siebenZiehen { z.append(String(localized: "7 lässt ziehen")) }
        switch regeln.aussetzen { case .acht: z.append(String(localized: "8 setzt aus")); case .ass: z.append(String(localized: "Ass setzt aus")); case .keine: break }
        if regeln.neunRichtung { z.append(String(localized: "9 wechselt die Richtung")) }
        if regeln.bubeAufBube { z.append(String(localized: "Bube auf Bube erlaubt")) }
        if regeln.maueSagen { z.append(String(localized: "„Mau“ sagen")) }
        if regeln.sofortLegen { z.append(String(localized: "Gezogene Karte gleich legen")) }
        if regeln.mehrrunden { z.append(String(localized: "Mehrere Runden bis \(regeln.zielPunkte) Punkte")) }
        if teilnehmer.count >= 5 { z.append(String(localized: "Zwei Blätter")) }
        return z
    }

    // MARK: Zug

    private func zeigeTipp() {
        var g = zufall
        guard let z = NComputer.wahl(spiel, fehler: 0, mit: &g) else { return }
        let k = spiel.haende[spiel.dran][z.index]
        tipp = HandKarte(platz: z.index, karte: k)
        UIAccessibility.post(notification: .announcement, argument: String(localized: "Tipp: Karte \(z.index + 1) von \(spiel.haende[spiel.dran].count), \(k.name) \(farbName(k.farbe))."))
    }

    private func tippe(_ i: Int) {
        guard spiel.spielbar(i) else { return }
        if spiel.haende[spiel.dran][i].wert == 11 { wunschFuer = i } else { spiele(i, wunsch: nil) }
    }

    private func spiele(_ i: Int, wunsch: Int?) {
        wunschFuer = nil
        guard stand.spiel.spiele(i, wunsch: wunsch, mau: mauGesagt) else { return }
        SpielZug.gemacht("maumau-neu")
        aufgedeckt = false; mauGesagt = false; tipp = nil; pruefe()
    }

    private func pruefe() {
        guard spiel.sieger == nil, computerDran, !denkt else { return }
        denkt = true
        Task {
            await ComputerTempo.warte(.milliseconds(800))
            denkt = false
            guard stand.spiel.sieger == nil, teilnehmer[stand.spiel.dran].computer else { return }
            var g = zufall
            let fehler = stufe == .leicht ? 0.7 : (stufe == .mittel ? 0.25 : 0)
            if let z = NComputer.wahl(stand.spiel, fehler: fehler, mit: &g) { stand.spiel.spiele(z.index, wunsch: z.wunsch, mau: true) } else { stand.spiel.ziehen(mit: &g) }
            zufall = g
            pruefe()
        }
    }

    // MARK: Ende und Runden

    private var rundenEnde: Bool {
        guard let r = stand.runden, spiel.sieger != nil else { return false }
        var kopie = r; kopie.verbuche(spiel); return kopie.beendet
    }

    private func rundeAbschliessen(_ s: Int) {
        guard var r = stand.runden else { einzelnesEnde(s); return }
        r.verbuche(spiel)
        if r.beendet {
            let o = r.reihenfolge
            var e = SpielEnde(reihenfolge: o.map { teilnehmer[$0].name }, punkte: o.map { "\(r.punkte[$0])" },
                              info: r.punkte[o[0]] < r.punkte[o[1]] ? String(localized: "\(teilnehmer[o[0]].name) gewinnt mit den wenigsten Punkten") : nil)   // T-082: bei Gleichstand kein Sieger-Satz
            // Blatt 22 (EB-1): Dauer, gelegte Karten und Runden als Werte, dazu die letzte Karte und die Resthände als Bild.
            e.werte = [.dauer, EndeWert("Gelegte Karten", "\(spiel.ablage.count)"), EndeWert("Runden", "\(max(r.runde - 1, 1))")]
            e.bild = MauMauEndeBild.bild(spiel: spiel, sieger: s, namen: teilnehmer.map(\.name))
            ende(e)
        } else {
            var g = SystemRandomNumberGenerator()
            let beginner = MauMauBeginn.rundeReihum(anzahl: teilnehmer.count)   // T-097: jede neue Runde beginnt die nächste Person
            stand = MauMauNeuStand(spiel: NMauMau(spieler: teilnehmer.count, regeln: regeln, beginner: beginner, mit: &g), runden: r)
            MauMauBeginn.merke(beginner)
            tipp = nil; aufgedeckt = false; mauGesagt = false; pruefe()
        }
    }

    private func einzelnesEnde(_ s: Int) {
        let rest = teilnehmer.indices.filter { $0 != s }.sorted { spiel.haende[$0].count < spiel.haende[$1].count }
        let o = [s] + rest
        // Blatt 22 (EB2): Satz mit der Karte, mit der ausgemacht wurde („Mit Pik Dame ausgemacht.“), ohne Artikel, damit jede Sprache mit einem Text auskommt.
        let letzte = "\(farbName(spiel.oben.farbe)) \(Kartensprache.rang(spiel.oben.name))"
        var e = SpielEnde(reihenfolge: o.map { teilnehmer[$0].name }, punkte: o.map { "\(spiel.haende[$0].count)" }, info: String(localized: "Mit \(letzte) ausgemacht."))
        // Blatt 22 (EB-1): Dauer und gelegte Karten als Werte, dazu die letzte Karte und die Resthände als Bild.
        e.werte = [.dauer, EndeWert("Gelegte Karten", "\(spiel.ablage.count)")]
        e.bild = MauMauEndeBild.bild(spiel: spiel, sieger: s, namen: teilnehmer.map(\.name))
        ende(e)
    }
}

/// Knopfstil-Wrapper, damit ein Knopf je nach Lage Haupt- oder Zweitknopf sein kann.
struct AnyButtonStyle: ButtonStyle {
    private let bauen: (Configuration) -> AnyView
    init<S: ButtonStyle>(_ stil: S) { bauen = { AnyView(stil.makeBody(configuration: $0)) } }
    func makeBody(configuration: Configuration) -> some View { bauen(configuration) }
}
#endif
