// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import MaexchenKern

@MainActor
public struct MaexchenModul: SpielModul {
    public init() {}
    public let id = "maexchen"
    public let name = "Mäxchen"
    public let gattung = Gattung.wuerfel
    public let farbe = AkzentFarbeWert.indigo
    public let symbol = "questionmark.dice.fill"
    public let spielerzahl = 2...8
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "Bluffen mit verdecktem Wurf", farbe: farbe, spieler: 2...8, computerErlaubt: true,
                            wuerfelWahl: true, regeln: "Du würfelst mit zwei Würfeln verdeckt und siehst nur selbst, was gefallen ist. Dann sagst du einen Wert an – ehrlich oder geblufft –, der höher sein muss als die letzte Ansage. Der Nächste glaubt dir (und würfelt selbst, mit höherer Ansage) oder zweifelt an. Beim Zweifel wird aufgedeckt: War die Ansage nicht gelogen, verliert der Zweifler ein Leben, sonst der Lügner. Stimmte die Ansage „Mäxchen“, verliert der Zweifler sogar zwei Leben. Rangfolge: 31 bis 65 (größere Zahl zuerst), dann Pasche 11 bis 66, am höchsten Mäxchen (2 und 1). Auf Mäxchen muss man aufdecken. Jeder startet mit 1, 3 oder 5 Leben (vor dem ersten Wurf im Menü „Mehr“ wählbar, vorgegeben sind 3), wer übrig bleibt, gewinnt.",
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            MaexchenSpiel(teilnehmer: teilnehmer, ende: ende, abbrechen: abbrechen, quelle: WuerfelWahl.quelle(id, vorgabe: umgebung.wuerfelQuelle))
        }.mitStartOptionen { MaexchenBeginnKarte(eintraege: $0) }   // T-097: Wer beginnt
        .mitZiel("Bluffe geschickt und verliere keine Leben. Wer als Letzter noch Leben hat, gewinnt.")
        .mitZielSchrittNeu(.ziel("Bluffe geschickt und verliere keine Leben. Mäxchen ist ein Würfelspiel für 2 bis 8 Leute. Du würfelst verdeckt und sagst an, was du hast, ehrlich oder gelogen. Der Nächste glaubt dir oder deckt auf. Wer sich irrt, verliert ein Leben. Wer als Letzter noch Leben hat, gewinnt."))
        .mitAnleitung(RegelTexteNeu.anleitung(neu: [
            .figuren(symbol: "eye.slash", titel: "Verdeckt würfeln", text: "Du würfelst zwei Würfel verdeckt, nur du siehst, was gefallen ist. Spielen mehrere an einem Gerät, erscheint vorher eine Karte mit deinem Namen. Erst wenn du das Gerät hast, tippst du darauf. Mit echten Würfeln würfelst du unter dem Becher und tippst dein Ergebnis ein.", figuren: ["🥤", "🎲", "🎲"], bewegt: nil),
            .figuren(symbol: "list.number", titel: "Was zählt", text: "Die größere Zahl steht vorn: 3 und 1 ist 31, die schwächste Ansage. Danach kommen 32, 41 und so weiter bis 65. Jeder Pasch, also zwei gleiche, schlägt jede Zahl. Am höchsten ist Mäxchen: eine 2 und eine 1.", figuren: ["⚂⚀", "→", "⚄⚄", "→", "⚁⚀"], bewegt: nil),
            .figuren(symbol: "megaphone", titel: "Ansagen", text: "Sage einen Wert an, ehrlich oder geblufft. Er muss höher sein als die letzte Ansage. Wähle ihn im Rad und tippe „Ansagen und weitergeben“. Hast du zu wenig gewürfelt, musst du lügen. Lüg lieber knapp: Je höher die Ansage, desto eher deckt der Nächste auf.", figuren: ["🎲", "🗣️"], bewegt: nil),
            .figuren(symbol: "heart", titel: "Glauben oder aufdecken", text: "Glaubst du die Ansage, würfelst du selbst und musst noch höher ansagen. Zweifelst du, wird aufgedeckt. War der Wurf mindestens so hoch wie angesagt, verlierst du ein Leben, sonst der Ansager. Auf Mäxchen musst du aufdecken. War es echt, kostet es dich zwei Leben.", figuren: ["❤️", "❤️", "❤️"], bewegt: nil),
            .figuren(symbol: "slider.horizontal.3", titel: "Leben und Hilfen", text: "Unter „Mehr“ wählst du vor dem ersten Wurf 1, 3 oder 5 Leben und die Stärke des Computers. Beim Entscheiden zeigt dir eine Zeile, wie wahrscheinlich ein so hoher Wurf ist. Wer ein Leben verliert, beginnt die nächste Runde. Alles Weitere steht unter „Alle Regeln lesen“.", figuren: ["❤️", "💡", "🤖"], bewegt: nil),
        ], alt: [
            .figuren(symbol: "eye.slash", titel: "Verdeckt würfeln", text: "Du würfelst zwei Würfel verdeckt und siehst nur selbst, was gefallen ist.", figuren: ["🥤", "🎲", "🎲"], bewegt: nil),
            .figuren(symbol: "megaphone", titel: "Ansagen", text: "Sage einen Wert an, ehrlich oder geblufft. Er muss höher sein als die letzte Ansage. Mäxchen (2 und 1) ist am höchsten.", figuren: ["🎲", "🗣️"], bewegt: nil),
            .figuren(symbol: "heart", titel: "Glauben oder zweifeln", text: "Der Nächste glaubt dir oder zweifelt an. Wer sich irrt, verliert ein Leben, bei einem echten Mäxchen der Zweifler zwei. Wer zuletzt noch Leben hat, gewinnt.", figuren: ["❤️", "❤️", "❤️"], bewegt: nil),
        ])))
    }
}

struct MaexchenSpiel: View {
    let teilnehmer: [SpielTeilnehmer]
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    let quelle: WuerfelQuelle
    @AppStorage("partie.regeln.maexchen.leben") private var leben = 3
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var regular: Bool { sizeClass == .regular }
    @State private var spiel: Maexchen
    @State private var zufall = SystemRandomNumberGenerator()
    @State private var sichtbar = false
    @State private var eingabe: Int?   // 1.0 (P4): Eingabe-Blatt für echte Würfel statt Plus und Minus (ersetzt echtA/echtB, S1-015)
    @State private var gewaehlteAnsage: Int?
    @State private var meldung: String?
    @State private var stufe = ComputerStufe.gespeichert("maexchen")
    @State private var neuFragen = false

    /// Noch kein Wurf und keine Ansage: Wechsel der Lebenszahl gibt neu aus.
    private var unberuehrt: Bool { spiel.ansage == nil && spiel.wurf == nil && spiel.log.isEmpty && spiel.leben.allSatisfy { $0 == spiel.leben[0] } }

    init(teilnehmer: [SpielTeilnehmer], ende: @escaping (SpielEnde) -> Void, abbrechen: @escaping () -> Void, quelle: WuerfelQuelle, vorgabe: Maexchen? = nil) {
        self.teilnehmer = teilnehmer; self.ende = ende; self.abbrechen = abbrechen; self.quelle = quelle
        _spiel = State(initialValue: vorgabe ?? Maexchen(spieler: teilnehmer.count, leben: max(1, UserDefaults.standard.integer(forKey: "partie.regeln.maexchen.leben") == 0 ? 3 : UserDefaults.standard.integer(forKey: "partie.regeln.maexchen.leben")), beginner: MaexchenBeginn.naechster(anzahl: teilnehmer.count)))   // T-097: Wer beginnt
    }

    /// Hinweis für den Menschen am Zug: Wie wahrscheinlich war die Ansage bei einem ehrlichen Wurf, und lohnt sich das Anzweifeln?
    private var tippText: LocalizedStringKey {
        guard let a = spiel.ansage else { return "" }
        if a == 200 { return "Tipp: Auf Mäxchen musst du aufdecken." }
        let prozent = Int((MaexchenComputer.wahrscheinlichkeit(mindestens: a) * 100).rounded())
        if prozent < 30 { return "Tipp: So hoch würfelt man nur zu etwa \(prozent) % – anzweifeln lohnt sich." }
        return "Tipp: So hoch oder höher würfelt man zu etwa \(prozent) %."
    }
    private var istComputer: Bool { teilnehmer[spiel.dran].computer }
    private func neuePartie() { let b = MaexchenBeginn.naechster(anzahl: teilnehmer.count); MaexchenBeginn.merke(b); spiel = Maexchen(spieler: teilnehmer.count, leben: leben, beginner: b); meldung = nil; sichtbar = false; gewaehlteAnsage = nil ; eingabe = nil }
    private func herz(_ i: Int) -> String { spiel.leben[i] > 0 ? String(repeating: "♥", count: spiel.leben[i]) : "–" }

    var body: some View {
        VStack(spacing: Theme.kartenAbstand) {
            SpielKopf(mitte: teilnehmer[spiel.dran].name, linksAktion: abbrechen) {
                RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                    FragNachDenRegelnMenuePunkt()   // KI-3 (Blatt 12): nur mit Apple Intelligence sichtbar
                    if teilnehmer.contains(where: { $0.computer }) { ComputerStufePicker(spiel: "maexchen", stufe: $stufe) }
                    Picker("Leben", selection: $leben) {
                        Text("Ein Leben (K. o.)").tag(1); Text("3 Leben").tag(3); Text("5 Leben").tag(5)
                    }
                    .disabled(!unberuehrt)   // nur vor dem ersten Wurf
                    Button("Neue Partie", systemImage: "arrow.counterclockwise") { if unberuehrt { neuePartie() } else { neuFragen = true } }   // G-012
                    Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
                }
            }
            SpielerLeiste(eintraege: teilnehmer.indices.map { .init(id: "\($0)", name: teilnehmer[$0].name, farbe: Spieler.farbe($0), wert: herz($0)) }, aktiv: "\(spiel.dran)")
                .padding(.horizontal, Theme.seitenRand)
            GeometryReader { geo in
            ScrollView {
                VStack(spacing: Theme.kartenAbstand) {
                    if let m = meldung { Text(m).font(.subheadline.weight(.semibold)).multilineTextAlignment(.center).frame(maxWidth: .infinity).spielTischKarte() }
                    if let a = spiel.ansage, let von = spiel.ansager {
                        VStack(spacing: Design.Abstand.xs) {
                            TischUeberschrift("Letzte Ansage")
                            Text("\(teilnehmer[von].name): \(MaexchenWert.text(a))").font(.title2.weight(.bold))
                        }.frame(maxWidth: .infinity).spielTischKarte()
                    }
                    inhalt
                }
                .padding(.horizontal, Theme.seitenRand)
                .frame(minHeight: geo.size.height, alignment: .center)   // G-014/M-019: auf iPhone und iPad mittig statt oben mit leerer Fläche
            }
            }
        }
        .frame(maxWidth: regular && !Tisch.aktiv ? 640 : .infinity)   // Blatt 16 / T2: in Tinte ganze Breite; B18 G-014: sonst iPad nicht über die volle Breite
        .frame(maxWidth: .infinity)
        .aufTisch()   // Design-Runde 3: in Tinte Filz bis in die Ecken, sonst Seitengrund wie bisher
        .confirmationDialog("Aktuelle Partie abbrechen?", isPresented: $neuFragen, titleVisibility: .visible) {
            Button("Abbrechen und neu starten", role: .destructive) { neuePartie() }
            Button("Weiterspielen", role: .cancel) {}
        } message: { Text("Die laufende Partie wird verworfen und neu begonnen.") }
        #if DEBUG
        .testEndeMelden { if let s = spiel.sieger { fertig(s) } }   // -testZustand ende: das Ende wird nach dem Laden des Endstands selbst gemeldet
        #endif
        .fortsetzbar("maexchen", $spiel, pruefen: { $0.leben.count == teilnehmer.count && $0.istKonsistent })
        .onAppear { if unberuehrt { MaexchenBeginn.merke(spiel.dran) } }   // T-097: wer diese Partie beginnt, gilt für die nächste (Reihum)
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .echteWuerfelEingabe(anzahl: $eingabe, titel: "Was hast du verdeckt gewürfelt?") { augen in if augen.count == 2 { spiel.setzeWurf(augen[0], augen[1]) } }   // 1.0 (P4)
        .weicheAnimation(bei: [spiel.dran, spiel.leben.reduce(0, +), spiel.ansage ?? 0, spiel.log.count])
        .spielHaptik(zug: [spiel.dran, spiel.leben.reduce(0, +), spiel.ansage ?? 0, spiel.log.count], erfolg: spiel.sieger != nil)
        .onChange(of: spiel.phase) { _, neu in if neu == .ansagen { meldung = nil } }   // C-034 (1): alte Aufdeck-Meldung verschwindet mit dem nächsten Wurf
        .onChange(of: leben) { _, neu in
            if unberuehrt { spiel = Maexchen(spieler: teilnehmer.count, leben: neu, beginner: spiel.dran) }
        }
        // Der Computer hängt am Stand, nicht am Erscheinen: Er zieht auch nach dem Laden eines Stands, in dem er am Zug ist.
        .computerZug(aktiv: spiel.sieger == nil && istComputer, id: "\(spiel.dran)-\(spiel.phase)-\(spiel.ansage ?? 0)-\(spiel.leben.reduce(0, +))-\(spiel.log.count)") {
            guard spiel.sieger == nil, istComputer else { return }
            switch spiel.phase {
            case .wuerfeln: spiel.wuerfeln(mit: &zufall)
            case .ansagen: spiel.ansagen(MaexchenComputer.ansage(spiel, stufe: stufe.rawValue, mit: &zufall))
            case .entscheiden:
                if MaexchenComputer.zweifelt(spiel, stufe: stufe.rawValue, mit: &zufall) { zweifeln() } else { spiel.glauben() }
            }
        }
    }

    @ViewBuilder private var inhalt: some View {
        if let s = spiel.sieger {
            Button("Ergebnis") { fertig(s) }.buttonStyle(HauptKnopfStil())
        } else if istComputer {
            Text("\(teilnehmer[spiel.dran].name) denkt nach …").frame(maxWidth: .infinity).tischHinweis(zeilen: 1).spielTischKarte()
        } else if !sichtbar && teilnehmer.mehrereMenschen {
            SichtschutzKarte(name: teilnehmer[spiel.dran].name, farbe: Spieler.farbe(spiel.dran)) { sichtbar = true; meldung = nil }.spielTischKarte()
        } else {
            switch spiel.phase {
            case .entscheiden:
                VStack(spacing: 10) {
                    if let von = spiel.ansager, let a = spiel.ansage {
                        Text("\(teilnehmer[von].name) sagt \(MaexchenWert.text(a)). Glaubst du das?").font(.headline).multilineTextAlignment(.center)
                    }
                    Text(tippText).font(.footnote).multilineTextAlignment(.center).tischHinweis(zeilen: 3)
                    HStack(spacing: Design.Abstand.s) {
                        if spiel.ansage != 200 { Button("Glauben") { spiel.glauben(); sichtbar = false } .buttonStyle(ZweitKnopfStil()) }
                        Button("Anzweifeln") { zweifeln() }.buttonStyle(HauptKnopfStil())
                    }
                }.frame(maxWidth: .infinity).spielTischKarte()
            case .wuerfeln where Tisch.aktiv && quelle != .echt:
                // Runde 5, Paket W (Blatt 7): zwei verdeckte Würfel mittig auf dem Filz, der Knopf darunter ohne Kasten
                VStack(spacing: 34) {
                    HStack(spacing: regular ? 24 : 16) { WuerfelFlaeche(augen: nil, groesse: regular ? 132 : 89); WuerfelFlaeche(augen: nil, groesse: regular ? 132 : 89) }   // iPad (T2): wie Chicago 132 pt
                        .accessibilityHidden(true)
                    Button("Verdeckt würfeln") { spiel.wuerfeln(mit: &zufall) }.buttonStyle(HauptKnopfStil()).beimSchuetteln { spiel.wuerfeln(mit: &zufall) }
                }.frame(maxWidth: .infinity)
            case .wuerfeln:
                VStack(spacing: 10) {
                    if quelle == .echt {
                        Text("Würfle verdeckt und tippe die Augen ein.").font(.subheadline)
                        Button("Würfel eintragen") { eingabe = 2 }.buttonStyle(HauptKnopfStil())   // 1.0 (P4)
                    } else {
                        Button("Verdeckt würfeln") { spiel.wuerfeln(mit: &zufall) }.buttonStyle(HauptKnopfStil()).beimSchuetteln { spiel.wuerfeln(mit: &zufall) }
                    }
                }.frame(maxWidth: .infinity).spielTischKarte()
            case .ansagen:
                VStack(spacing: 10) {
                    if let w = spiel.wurf { HStack(spacing: 12) { WuerfelBild(w.0); WuerfelBild(w.1) }.font(.system(size: regular ? 110 : 80)).foregroundStyle(Tisch.aktiv ? Tisch.elfenbein : Color.appFlaeche)   // design:spielinhalt (feste Großdarstellung von Spielmaterial, kein Fließtext)
                        Text("Du hast \(MaexchenWert.text(MaexchenWert.rang(w.0, w.1))). Sage an (auch gelogen):").font(.subheadline) }
                    Picker("Ansage", selection: Binding(get: { gewaehlteAnsage ?? spiel.moeglicheAnsagen.first ?? 0 }, set: { gewaehlteAnsage = $0 })) {
                        ForEach(spiel.moeglicheAnsagen, id: \.self) { Text(MaexchenWert.text($0)).tag($0) }
                    }.pickerStyle(.wheel).frame(height: 110)
                    Button("Ansagen und weitergeben") {
                        if spiel.ansagen(gewaehlteAnsage ?? spiel.moeglicheAnsagen.first ?? 0) { gewaehlteAnsage = nil; sichtbar = false }
                    }.buttonStyle(HauptKnopfStil())
                }.frame(maxWidth: .infinity).spielTischKarte()
            }
        }
    }

    private func zweifeln() {
        guard let von = spiel.ansager, let an = spiel.ansage else { return }
        spiel.zweifeln()
        if let w = spiel.aufgedeckt, let v = spiel.verlierer {
            // T-078: Stimmte die Ansage „Mäxchen“, verliert der Zweifler zwei Leben (Kern: schaden = 2); der Ansager verliert immer eines
            if an == 200 && v != von {
                meldung = String(localized: "Aufgedeckt: \(MaexchenWert.text(MaexchenWert.rang(w.0, w.1))) – \(teilnehmer[v].name) verliert zwei Leben. (Ansage von \(teilnehmer[von].name): \(MaexchenWert.text(an)))")
            } else {
                meldung = String(localized: "Aufgedeckt: \(MaexchenWert.text(MaexchenWert.rang(w.0, w.1))) – \(teilnehmer[v].name) verliert ein Leben. (Ansage von \(teilnehmer[von].name): \(MaexchenWert.text(an)))")
            }
        }
        sichtbar = false
    }

    private func fertig(_ s: Int) {
        let (o, plaetze) = Maexchen.schlussstand(sieger: s, spieler: teilnehmer.count)   // alle Verlierer teilen sich Platz 2
        var e = SpielEnde(reihenfolge: o.map { teilnehmer[$0].name }, punkte: o.map { herz($0) }, plaetze: plaetze, info: String(localized: "\(teilnehmer[s].name) bleibt übrig"))
        // Blatt 22 (EB2, Schritt 2): Runden, Mäxchen geworfen, Dauer; Würfelbild aus der Zählung (alter Stand: ohne)
        var werte = [EndeWert("Runden", "\(spiel.log.count)")]
        if let m = spiel.maexchenWuerfe { werte.append(EndeWert("Mäxchen geworfen", "\(m)")) }
        e.werte = werte + [.dauer]
        if let a = spiel.augen, a.count == teilnehmer.count, a.allSatisfy({ $0.count == 6 }) {
            var b = WuerfelBilanz(namen: teilnehmer.map(\.name))
            b.augen = a
            if let t = spiel.eingetippt, t.count == teilnehmer.count { b.eingetippt = t }
            if !b.leer { e.wuerfel = b }
        }
        ende(e)
    }
}
#endif
