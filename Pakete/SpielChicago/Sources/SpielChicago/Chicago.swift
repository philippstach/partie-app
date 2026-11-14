// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import ChicagoKern

@MainActor
public struct ChicagoModul: SpielModul {
    public init() {}
    public let id = "chicago"
    public let name = "Chicago"
    public let gattung = Gattung.wuerfel
    public let farbe = AkzentFarbeWert.indigo
    public let symbol = "die.face.2.fill"
    public let spielerzahl = 1...6
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "Elf Runden, elf Zielzahlen", farbe: farbe, spieler: 1...6, computerErlaubt: true,   // 1.0 (P4)
                            wuerfelWahl: true, regeln: "Gespielt werden elf Runden mit den Zielzahlen 2 bis 12. Du wirfst zwei Würfel, bis zu dreimal pro Runde. Ergibt die Augensumme die Zielzahl, bekommst du so viele Punkte wie die Zielzahl (bei einem Pasch doppelt) und dein Zug endet. Wer nach elf Runden die meisten Punkte hat, gewinnt; bei gleicher Punktzahl teilen sich die Spieler den Platz. Allein zählst du nur deine Punkte.",
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            ChicagoSpiel(teilnehmer: teilnehmer, ende: ende, abbrechen: abbrechen, quelle: WuerfelWahl.quelle(id, vorgabe: umgebung.wuerfelQuelle))
        }.mitZiel("Triff in elf Runden mit deinen Würfen die Zielzahlen 2 bis 12. Wer am Ende die meisten Punkte hat, gewinnt.")
        .mitZielSchrittNeu(.ziel("Triff in elf Runden mit deinen Würfen die Zielzahlen 2 bis 12. Wer am Ende die meisten Punkte hat, gewinnt. Ein schnelles Würfelspiel für 1 bis 6 Personen, auch gegen den Computer."))
        .mitAnleitung(RegelTexteNeu.anleitung(neu: [
            .figuren(symbol: "target", titel: "Zielzahl", text: "Jede Runde hat ihre Zielzahl: zuerst die 2, dann die 3, zuletzt die 12. Du würfelst mit zwei Würfeln, bis zu dreimal pro Runde. Ergibt die Summe die Zielzahl, hast du getroffen. Die App zeigt dir, wie groß deine Chance beim nächsten Wurf ist.", figuren: ["🎲", "🎲", "7"], bewegt: nil),
            .figuren(symbol: "plus.circle", titel: "Treffer", text: "Ein Treffer bringt so viele Punkte wie die Zielzahl, und dein Zug ist vorbei. Mit einem Pasch, also zwei gleichen Würfeln, gibt es doppelt so viele. Triffst du in drei Würfen nicht, bekommst du in dieser Runde nichts.", figuren: ["🎯", "➕"], bewegt: nil),
            .figuren(symbol: "flag.checkered", titel: "Beste Punkte", text: "Wer nach elf Runden die meisten Punkte hat, gewinnt. Allein spielst du auf deinen Bestwert. Ihr könnt auch mit echten Würfeln spielen und die Augen eintippen. Wähle dafür vor dem Start „Echt“.", figuren: ["🏆", "🎲"], bewegt: nil),
        ], alt: [
            .figuren(symbol: "target", titel: "Zielzahl", text: "Elf Runden mit den Zielzahlen 2 bis 12. Du wirfst zwei Würfel, bis zu dreimal pro Runde.", figuren: ["🎲", "🎲", "7"], bewegt: nil),
            .figuren(symbol: "plus.circle", titel: "Treffer", text: "Ergibt die Summe die Zielzahl, bekommst du so viele Punkte wie die Zielzahl, bei einem Pasch doppelt. Dann endet dein Zug.", figuren: ["🎯", "➕"], bewegt: nil),
            .figuren(symbol: "flag.checkered", titel: "Beste Punkte", text: "Wer nach elf Runden die meisten Punkte hat, gewinnt. Allein zählst du nur deine Punkte.", figuren: ["🏆", "🎲"], bewegt: nil),
        ])))
    }
}

struct ChicagoSpiel: View {
    let teilnehmer: [SpielTeilnehmer]
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    let quelle: WuerfelQuelle
    @State private var spiel: Chicago
    @State private var zufall = SystemRandomNumberGenerator()
    @State private var eingabe: Int?   // 1.0 (P4): Eingabe-Blatt für echte Würfel statt Plus und Minus
    @State private var neuFragen = false
    private var unberuehrt: Bool { spiel.runde == 0 && spiel.versuche == 0 && spiel.wurf == nil }
    private func neuePartie() { spiel = Chicago(spieler: teilnehmer.count); eingabe = nil }
    private var istComputer: Bool { spiel.dran < teilnehmer.count && teilnehmer[spiel.dran].computer }   // 1.0 (P4)
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var regular: Bool { sizeClass == .regular }
    /// Blatt 16 (iPad, nur Tinte): ganze Breite statt schmaler Spalte, Würfel und Schrift wachsen.
    private var breitTisch: Bool { regular && Tisch.aktiv }
    @Environment(\.dynamicTypeSize) private var schriftGroesse

    /// Blatt 21 (W2-S, nur Tinte): Tafel mit den Zielzahlen 2 bis 12. Gespielt = blass, aktuell = helle Kapsel, kommend = hell.
    /// Wer welche Zahl getroffen hat, weiß das Spiel heute nicht (kommt mit Schritt 2 der Ergebnisseite).
    private var zielTafel: some View {
        let ueberschrift = Text("Runde \(min(spiel.runde + 1, 11)) von 11 · Zielzahl \(spiel.ziel)")
        return VStack(alignment: .leading, spacing: 4) {
            ueberschrift.textCase(.uppercase).tracking(1.4)
                .font(.system(size: 11.5, weight: .semibold)).foregroundStyle(Tisch.elfenbein.opacity(0.7))
                .padding(.horizontal, 12).padding(.top, 8)
            HStack(spacing: 0) {
                ForEach(2...12, id: \.self) { zahl in
                    let aktuell = !spiel.beendet && zahl == spiel.ziel
                    let gespielt = zahl < spiel.ziel
                    Text("\(zahl)")
                        .font(.system(size: breitTisch ? 20 : 16, weight: aktuell ? .bold : .regular).monospacedDigit())
                        .foregroundStyle(aktuell ? Tisch.auge : Tisch.elfenbein.opacity(gespielt ? 0.42 : 0.9))
                        .frame(minWidth: aktuell ? 32 : 0, maxWidth: .infinity, minHeight: breitTisch ? 44 : 34)
                        .background(Capsule().fill(aktuell ? Tisch.elfenbein : Color.clear))
                }
            }.padding(.horizontal, 4).padding(.bottom, 6)
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Tisch.elfenbein.opacity(0.11)))
        .padding(.horizontal, Theme.seitenRand)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(ueberschrift)
    }

    /// Blatt 21 (W2-S, nur Tinte): zwei große Würfel direkt auf dem Filz (iPhone 104, iPad 150, bei größter Schrift auf dem iPhone 84), ohne Kasten.
    private var tischMitte: some View {
        let kante: CGFloat = breitTisch ? 150 : (schriftGroesse.isAccessibilitySize ? 84 : 104)
        return VStack(spacing: 14) {
            HStack(spacing: 24) {
                WuerfelFlaeche(augen: spiel.wurf?.0, groesse: kante)
                WuerfelFlaeche(augen: spiel.wurf?.1, groesse: kante)
            }
            .overlay(alignment: .topTrailing) { if spiel.treffer == true { Image(systemName: "checkmark.circle.fill").font(.title).foregroundStyle(Color.meldungGruen).offset(x: 14, y: -14) } }   // design:spielinhalt
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(spiel.wurf.map { Text("Würfel: \($0.0) und \($0.1)") } ?? Text("Noch nicht gewürfelt"))
            if let w = spiel.wurf { Text("Summe \(w.0 + w.1)").font(breitTisch ? .title2.weight(.semibold) : .title3.weight(.semibold)).foregroundStyle(Tisch.elfenbein) }
            Text(spiel.treffer == true ? "Treffer!" : (spiel.treffer == false ? "Leider verfehlt." : (spiel.versuche == 0 ? "Versuch 1 von \(Chicago.wuerfe)" : "Nächster Versuch: \(spiel.versuche + 1) von \(Chicago.wuerfe)"))).font(.subheadline).tischHinweis()
            if spiel.darfWerfen && !istComputer {
                let prozent = Int((spiel.chanceNaechsterWurf * 100).rounded())
                Text("Chance auf die \(spiel.ziel) im nächsten Wurf: \(prozent) %").font(.footnote).tischHinweis(sonst: Color.schriftZweit)
                    .accessibilityLabel(Text("Chance auf die Zielzahl \(spiel.ziel) im nächsten Wurf: \(prozent) Prozent"))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Theme.seitenRand)
    }

    init(teilnehmer: [SpielTeilnehmer], ende: @escaping (SpielEnde) -> Void, abbrechen: @escaping () -> Void, quelle: WuerfelQuelle) {
        self.teilnehmer = teilnehmer; self.ende = ende; self.abbrechen = abbrechen; self.quelle = quelle
        _spiel = State(initialValue: Chicago(spieler: teilnehmer.count))
    }

    @Environment(\.regelnOeffnen) private var regelnOeffnen   // Fund 36/47: „Regeln“ im Mehr-Menü wie bei Yacht
    var body: some View {
        VStack(spacing: Theme.kartenAbstand) {
            SpielKopf(mitte: "Chicago", linksAktion: abbrechen) {
                RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                    FragNachDenRegelnMenuePunkt()   // KI-3 (Blatt 12): nur mit Apple Intelligence sichtbar
                    if let regelnOeffnen { Button("Regeln", systemImage: "book") { regelnOeffnen() } }   // Fund 36
                    Button("Neue Partie", systemImage: "arrow.counterclockwise") { if unberuehrt { neuePartie() } else { neuFragen = true } }   // G-012
                    Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
                }
            }
            SpielerLeiste(eintraege: teilnehmer.indices.map { .init(id: "\($0)", name: teilnehmer[$0].name, farbe: Spieler.farbe($0), wert: "\(spiel.punkte[$0])") }, aktiv: "\(spiel.dran)")
                .padding(.horizontal, Theme.seitenRand)
            if Tisch.aktiv {   // Blatt 21 (W2-S): Zieltafel oben, große Würfel direkt auf dem Filz, kein Kasten
                zielTafel
                Spacer(minLength: 0)
                tischMitte
            } else {
                Spacer(minLength: 0)
                VStack(spacing: 10) {
                    Text("Runde \(min(spiel.runde + 1, 11)) von 11 · Zielzahl \(spiel.ziel)").font(.subheadline).tischHinweis()
                    if Tisch.aktiv {   // Design-Runde 3 (Tinte): Elfenbein-Würfel auf dem Filz
                        HStack(spacing: 18) {
                            WuerfelFlaeche(augen: spiel.wurf?.0, groesse: breitTisch ? 132 : (regular ? 110 : 84))
                            WuerfelFlaeche(augen: spiel.wurf?.1, groesse: breitTisch ? 132 : (regular ? 110 : 84))
                        }
                        .overlay(alignment: .topTrailing) { if spiel.treffer == true { Image(systemName: "checkmark.circle.fill").font(.title).foregroundStyle(Color.meldungGruen).offset(x: 14, y: -14) } }   // design:spielinhalt
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(spiel.wurf.map { Text("Würfel: \($0.0) und \($0.1)") } ?? Text("Noch nicht gewürfelt"))
                    } else {
                    HStack(spacing: 14) {
                        if let w = spiel.wurf { WuerfelBild(w.0); WuerfelBild(w.1) }
                        else { Image(systemName: "dice"); Image(systemName: "dice") }
                    }.font(.system(size: regular ? 130 : 90)).foregroundStyle(spiel.treffer == true ? Color.green : Color.appFlaeche)   // design:spielinhalt (feste Großdarstellung von Spielmaterial, kein Fließtext)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(spiel.wurf.map { Text("Würfel: \($0.0) und \($0.1)") } ?? Text("Noch nicht gewürfelt"))
                    }
                    if let w = spiel.wurf { Text("Summe \(w.0 + w.1)").font(breitTisch ? .title2.weight(.semibold) : .title3.weight(.semibold)) }
                    Text(spiel.treffer == true ? "Treffer!" : (spiel.treffer == false ? "Leider verfehlt." : (spiel.versuche == 0 ? "Versuch 1 von \(Chicago.wuerfe)" : "Nächster Versuch: \(spiel.versuche + 1) von \(Chicago.wuerfe)"))).font(.subheadline).tischHinweis()
                }.frame(maxWidth: .infinity).padding(.vertical, breitTisch ? 36 : 20).spielTischKarte().padding(.horizontal, Theme.seitenRand)
                if spiel.darfWerfen && !istComputer {   // 1.0 (P4): Chance auf die Zielzahl im nächsten Wurf
                    let prozent = Int((spiel.chanceNaechsterWurf * 100).rounded())
                    Text("Chance auf die \(spiel.ziel) im nächsten Wurf: \(prozent) %").font(.footnote).tischHinweis(sonst: Color.schriftZweit)
                        .accessibilityLabel(Text("Chance auf die Zielzahl \(spiel.ziel) im nächsten Wurf: \(prozent) Prozent"))
                }
            }
            Spacer(minLength: 0)
            Group {
                if spiel.beendet { Button("Ergebnis") { fertig() }.buttonStyle(HauptKnopfStil()) }
                else if istComputer {
                    Text("\(teilnehmer[spiel.dran].name) würfelt …").font(.subheadline).frame(maxWidth: .infinity, minHeight: Theme.tapSize).tischHinweis()   // 1.0 (P4)
                }
                else if spiel.darfWerfen {
                    Button(quelle == .echt ? "Eintragen" : "Würfeln") { if quelle == .echt { eingabe = 2 } else { spiel.wuerfeln(mit: &zufall) } }.buttonStyle(HauptKnopfStil()).beimSchuetteln(aktiv: quelle == .app) { spiel.wuerfeln(mit: &zufall) }
                } else { Button("Weiter") { spiel.weiter() }.buttonStyle(HauptKnopfStil()) }
            }.padding(.horizontal, Theme.seitenRand).padding(.bottom, 8)
        }
        .frame(maxWidth: regular && !Tisch.aktiv ? 640 : .infinity)   // Blatt 16: in Tinte ganze Breite; B18 F-AWS-P-002/P-011: iPad nicht über die volle Breite, Inhalt mittig
        .frame(maxWidth: .infinity)
        .aufTisch()   // Design-Runde 3: in Tinte Filz bis in die Ecken, sonst Seitengrund wie bisher
        .confirmationDialog("Aktuelle Partie abbrechen?", isPresented: $neuFragen, titleVisibility: .visible) {
            Button("Abbrechen und neu starten", role: .destructive) { neuePartie() }
            Button("Weiterspielen", role: .cancel) {}
        } message: { Text("Die laufende Partie wird verworfen und neu begonnen.") }
        #if DEBUG
        .testEndeMelden { if spiel.beendet { fertig() } }   // -testZustand ende: das Ende wird nach dem Laden des Endstands selbst gemeldet
        #endif
        .fortsetzbar("chicago", $spiel, pruefen: { $0.punkte.count == teilnehmer.count && $0.istStimmig })
        .weicheAnimation(bei: [spiel.runde, spiel.dran, spiel.versuche, spiel.punkte.reduce(0, +)])
        .spielHaptik(zug: [spiel.runde, spiel.dran, spiel.versuche, spiel.punkte.reduce(0, +)], erfolg: spiel.beendet)
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .echteWuerfelEingabe(anzahl: $eingabe) { augen in if augen.count == 2 { spiel.setzeWurf(augen[0], augen[1]) } }   // 1.0 (P4)
        // 1.0 (P4): Der Computer würfelt immer selbst (auch bei „Echte Würfel“) und geht danach weiter; das Tempo folgt der Einstellung.
        .computerZug(aktiv: !spiel.beendet && istComputer, id: "\(spiel.runde)-\(spiel.dran)-\(spiel.versuche)-\(spiel.treffer.map { $0 ? 1 : 0 } ?? -1)") {
            guard !spiel.beendet, istComputer else { return }
            if spiel.darfWerfen { spiel.wuerfeln(mit: &zufall) } else { spiel.weiter() }
        }
    }

    private func fertig() {
        let o = teilnehmer.indices.sorted { spiel.punkte[$0] > spiel.punkte[$1] }
        let platz = o.map { i in spiel.punkte.filter { $0 > spiel.punkte[i] }.count + 1 }
        var e = SpielEnde(reihenfolge: o.map { teilnehmer[$0].name }, punkte: o.map { "\(spiel.punkte[$0])" }, plaetze: platz,
                          info: teilnehmer.count == 1 ? String(localized: "\(spiel.punkte[0]) Punkte") : nil,
                          einzel: .punkte)   // S1: allein ist Chicago ein Punktespiel ohne Sieg (wirkt nur bei einem Namen)
        // Blatt 22 (EB2, Schritt 2): Satz mit Sieger, „Treffer“ je Person in der Reihenfolge der Rangliste, Dauer; Bild „Zielzahlen und Treffer“
        if teilnehmer.count > 1, let ersterPlatz = o.first, o.dropFirst().allSatisfy({ spiel.punkte[$0] < spiel.punkte[ersterPlatz] }) {
            e.info = String(localized: "\(teilnehmer[ersterPlatz].name) gewinnt mit \(spiel.punkte[ersterPlatz]) Punkten.")
        }
        var werte: [EndeWert] = []
        if let t = spiel.trefferJePerson, t.count == teilnehmer.count {
            werte.append(EndeWert("Treffer", o.map { "\(t[$0])" }.joined(separator: " · ")))
        }
        e.werte = werte + [.dauer]
        if let r = spiel.rundenPunkte, r.count == teilnehmer.count {
            e.bild = ChicagoEndeBild.bild(namen: o.map { teilnehmer[$0].name }, farben: o.map { Spieler.farbe($0) }, zuege: o.map { r[$0] })
        }
        ende(e)
    }
}
#endif
