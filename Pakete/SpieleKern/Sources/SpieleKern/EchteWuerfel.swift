// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Zufallsquelle für echte Würfel: gibt zuerst die eingetippten Augen aus, danach (oder ohne Eingabe) echten Zufall.
/// So nutzen alle Spielkerne ihre bestehende Würfel-Funktion (`wuerfeln(mit: &g)`) unverändert, auch mit Becher und Halten.
/// Jede Augenzahl `v` (1…6) wird als ein 64-Bit-Wert geliefert, den `Int.random(in: 1...6, using:)` genau auf `v` abbildet.
public struct EchteWuerfelZufall: RandomNumberGenerator {
    private var eingabe: [UInt64] = []
    private var system = SystemRandomNumberGenerator()
    public init() {}

    /// Wert, der bei `Int.random(in: 1...6)` die Augenzahl `augen` ergibt (Mitte des Teilbereichs, weit weg von der Ablehnungsgrenze).
    static func wert(fuer augen: Int) -> UInt64 {
        let k = UInt64(max(1, min(6, augen)) - 1)
        let teil: UInt64 = 0x2AAA_AAAA_AAAA_AAAB   // ⌈2⁶⁴ / 6⌉
        return k &* teil &+ (teil / 2)
    }

    /// Augen für die nächsten Würfe vormerken.
    public mutating func lade(augen: [Int]) { eingabe = augen.map(Self.wert(fuer:)) }
    public var offen: Int { eingabe.count }

    public mutating func next() -> UInt64 {
        eingabe.isEmpty ? system.next() : eingabe.removeFirst()
    }
}

#if canImport(UIKit)
import SwiftUI
import KlarGlas

/// Haken, den die App beim Start setzt (der Kern kennt `WuerfelScan`/Kamera nicht).
/// Jeder Haken baut eine Ansicht, die `anzahl` erwartete Würfel liest und die Augen über `fertig` meldet; `abbrechen` schließt sie ohne Ergebnis.
/// Ist ein Haken nil, erscheint der zugehörige Knopf im Eingabe-Blatt nicht.
public enum WuerfelEingabeHaken {
    public typealias Bauer = @MainActor (_ anzahl: Int, _ fertig: @escaping ([Int]) -> Void, _ abbrechen: @escaping () -> Void) -> AnyView
    /// „Mit Kamera lesen“
    nonisolated(unsafe) public static var kamera: Bauer?
    /// „Vom Scanner“ (zweites Gerät)
    nonisolated(unsafe) public static var scanner: Bauer?
    /// Gibt es unter den Würfelflächen eine Zeile mit Knöpfen (Kamera, Scanner, Ansage) und Hinweis? Dann braucht das Blatt mehr Höhe.
    @MainActor public static var hatZusatzZeile: Bool { kamera != nil || scanner != nil || WuerfelAnsageHaken.angeboten }
}

/// Augen-Eingabe für echte Würfel als Blatt: `anzahl` Plätze, sechs Würfelflächen zum Antippen, Korrektur durch Tippen auf einen Platz.
/// Darüber die Reihe „Kamera · Scanner · Ansagen“ (nur was da ist). Sind alle Plätze gefüllt, erscheint „Übernehmen“. Aufruf über `.echteWuerfelEingabe(...)`.
/// Tinte (Blatt 15): weißes Blatt wie bei Yacht, Würfel wie am Tisch. Klar und Salon behalten die Strichzeichen.
public struct WuerfelEingabeBlatt: View {
    let titel: LocalizedStringKey
    let anzahl: Int
    let fertig: ([Int]) -> Void
    let abbrechen: () -> Void
    @State private var plaetze: [Int?]
    @State private var kameraOffen = false
    @State private var scannerOffen = false
    @State private var ansage = AnsageSteuerung()
    /// Kamera oder Scanner haben in diesem Blatt Augen geliefert.
    @State private var hilfeGenutzt = false
    @Environment(\.designArt) private var art

    public init(titel: LocalizedStringKey = "Was hast du gewürfelt?", anzahl: Int, fertig: @escaping ([Int]) -> Void, abbrechen: @escaping () -> Void) {
        self.titel = titel; self.anzahl = anzahl; self.fertig = fertig; self.abbrechen = abbrechen
        _plaetze = State(initialValue: Array(repeating: nil, count: max(1, anzahl)))
    }

    private var voll: Bool { plaetze.allSatisfy { $0 != nil } }
    private var tinte: Bool { art == .tinte }

    public var body: some View {
        VStack(spacing: 18) {
            HStack {
                Text(titel).font(tinte ? Design.Schrift.serif(18, gewicht: .semibold, relativ: .headline) : .headline)
                Spacer()
                RundKnopf(symbol: "xmark", beschriftung: "Schließen", klein: true, aktion: abbrechen)
            }
            HStack(spacing: tinte ? 10 : Design.Abstand.s) {
                ForEach(plaetze.indices, id: \.self) { i in
                    Button { plaetze[i] = nil } label: {
                        if tinte {
                            WuerfelFlaeche(augen: plaetze[i], groesse: 54)   // Blatt 15 (ki9); der gewählte Würfelsatz wirkt in WuerfelFlaeche
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: Theme.feldRadius).strokeBorder(Color.secondary.opacity(0.5), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                                if let w = plaetze[i] {
                                    if WuerfelSatz.istGewaehlt { WuerfelFlaeche(augen: w, groesse: 40) }   // KS: gewählter Würfelsatz
                                    else { Image(systemName: "die.face.\(w).fill").font(.title).foregroundStyle(Color.appFlaeche) }
                                }
                            }
                            .frame(height: 54).frame(maxWidth: 60)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("Würfel \(i + 1) von \(plaetze.count)")).accessibilityValue(Text(verbatim: plaetze[i].map(String.init) ?? "–"))
                }
            }
            if ansage.hoert {
                Label("Ich höre zu. Sag die Augen, zum Beispiel: drei, fünf, eins.", systemImage: "waveform")
                    .font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    .symbolEffect(.variableColor.iterative, isActive: true)
            } else if let hinweis = ansage.hinweis {
                Text(hinweis).font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
            if !knoepfe.isEmpty { EingabeArtReihe(knoepfe) }
            tasten
            Button("Übernehmen") { abschliessen() }
                .buttonStyle(HauptKnopfStil()).disabled(!voll)
        }
        .padding(Theme.seitenRand)
        .sensoryFeedback(.selection, trigger: plaetze.compactMap { $0 })
        .onDisappear { ansage.abbrechen() }
        .task { await gemerkteArtOeffnen() }
        .fullScreenCover(isPresented: $kameraOffen) { haken(WuerfelEingabeHaken.kamera) }
        .fullScreenCover(isPresented: $scannerOffen) { haken(WuerfelEingabeHaken.scanner) }
    }

    /// Die sechs Würfel zum Antippen: in Tinte dieselben Würfel wie am Tisch in einer Reihe, sonst die Strichzeichen im Raster.
    @ViewBuilder private var tasten: some View {
        if tinte {
            GeometryReader { geo in
                let kante = max(36, min(64, (geo.size.width - 5 * 8) / 6))
                HStack(spacing: 8) {
                    ForEach(1...6, id: \.self) { w in
                        Button { tippe(w) } label: { WuerfelFlaeche(augen: w, groesse: kante).frame(minHeight: Theme.tapSize) }
                            .buttonStyle(.plain)
                            .accessibilityLabel(Text(verbatim: String(w)))
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .frame(height: 64)
        } else {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                ForEach(1...6, id: \.self) { w in
                    Button { tippe(w) } label: {
                        Group {
                            if WuerfelSatz.istGewaehlt { WuerfelFlaeche(augen: w, groesse: 46) }   // KS: gewählter Würfelsatz
                            else { Image(systemName: "die.face.\(w)").font(.largeTitle) }
                        }
                        .frame(maxWidth: .infinity, minHeight: 62)
                            .designFlaeche(Theme.feldRadius)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.primary)
                    .accessibilityLabel(Text(verbatim: String(w)))
                }
            }
        }
    }

    /// Knöpfe der Reihe: nur die, die es auf diesem Gerät gibt.
    private var knoepfe: [EingabeKnopfDaten] {
        var k: [EingabeKnopfDaten] = []
        if WuerfelEingabeHaken.kamera != nil {
            k.append(EingabeKnopfDaten(id: "kamera", symbol: "camera", wort: "Kamera", vorlesetext: "Mit Kamera lesen") { waehle(.kamera) })
        }
        if WuerfelEingabeHaken.scanner != nil {
            k.append(EingabeKnopfDaten(id: "scanner", symbol: "iphone.radiowaves.left.and.right", wort: "Scanner", vorlesetext: "Vom Scanner") { waehle(.scanner) })
        }
        if ansage.angeboten {
            if ansage.hoert {
                k.append(EingabeKnopfDaten(id: "ansage", symbol: "stop.fill", wort: "Fertig", vorlesetext: "Fertig", hervorgehoben: true) { ansage.stoppen() })
            } else {
                // Die Ansage füllt nur leere Plätze (Philipp 13.11.); was schon steht, bleibt.
                k.append(EingabeKnopfDaten(id: "ansage", symbol: "mic", wort: "Ansagen", vorlesetext: "Ansagen",
                                           hinweis: "Sag die Augen deiner Würfel der Reihe nach, zum Beispiel: drei, fünf, eins.", gesperrt: voll) { waehle(.ansage) })
            }
        }
        return k
    }

    /// Öffnet die Eingabeart und merkt sie sich für den nächsten Wurf.
    private func waehle(_ art: WuerfelEingabeArt) {
        WuerfelEingabeArt.merke(art)
        starte(art)
    }

    private func starte(_ art: WuerfelEingabeArt) {
        switch art {
        case .kamera: if WuerfelEingabeHaken.kamera != nil { kameraOffen = true }
        case .scanner: if WuerfelEingabeHaken.scanner != nil { scannerOffen = true }
        case .ansage: if ansage.angeboten { ansage.starten(plaetze: $plaetze) }
        }
    }

    /// Beim Öffnen gleich mit der zuletzt benutzten Eingabeart beginnen (kurz warten, bis das Blatt steht).
    private func gemerkteArtOeffnen() async {
        guard let art = WuerfelEingabeArt.gemerkt() else { return }
        try? await Task.sleep(for: .milliseconds(350))
        guard !Task.isCancelled, plaetze.allSatisfy({ $0 == nil }) else { return }
        starte(art)
    }

    /// Baut die Haken-Ansicht; bei Ergebnis werden die Augen auf die Plätze gelegt (auf `anzahl` gekürzt) und das Blatt übernimmt sofort, wenn alle Plätze voll sind.
    @ViewBuilder private func haken(_ bauer: WuerfelEingabeHaken.Bauer?) -> some View {
        if let bauer {
            bauer(anzahl, { augen in
                kameraOffen = false; scannerOffen = false
                let gueltig = augen.filter { (1...6).contains($0) }.prefix(plaetze.count)
                guard !gueltig.isEmpty else { return }
                hilfeGenutzt = true
                for (i, w) in gueltig.enumerated() { plaetze[i] = w }
                if voll { abschliessen() }
            }, { kameraOffen = false; scannerOffen = false })
        }
    }

    private func tippe(_ w: Int) {
        guard let k = plaetze.firstIndex(where: { $0 == nil }) else { return }
        plaetze[k] = w
        if voll { abschliessen() }   // alle Plätze voll: sofort übernehmen, kein zweiter Tipp
    }

    /// Wurf übernehmen. Wurde er ganz von Hand getippt (weder Kamera, Scanner noch Ansage), vergisst die App die gemerkte Eingabeart.
    private func abschliessen() {
        if !hilfeGenutzt && !ansage.hatEingetragen { WuerfelEingabeArt.merke(nil) }
        fertig(plaetze.compactMap { $0 })
    }
}

/// Blatt 15: In Tinte ist das Eingabeblatt ein weißes Blatt wie bei Yacht (Seitengrund statt Glas). Klar und Salon bleiben, wie sie waren.
private struct WuerfelBlattGrund: ViewModifier {
    @Environment(\.designArt) private var art

    @ViewBuilder func body(content: Content) -> some View {
        if art == .tinte { content.presentationBackground(Color.seitenGrund) } else { content }
    }
}

public extension View {
    /// Zeigt die Augen-Eingabe, solange `anzahl` gesetzt ist (nil = geschlossen). Nach Eingabe wird `anzahl` auf nil gesetzt und `fertig` gerufen.
    func echteWuerfelEingabe(anzahl: Binding<Int?>, titel: LocalizedStringKey = "Was hast du gewürfelt?", fertig: @escaping ([Int]) -> Void) -> some View {
        sheet(isPresented: Binding(get: { anzahl.wrappedValue != nil }, set: { if !$0 { anzahl.wrappedValue = nil } })) {
            WuerfelEingabeBlatt(titel: titel, anzahl: anzahl.wrappedValue ?? 1,
                                fertig: { augen in anzahl.wrappedValue = nil; fertig(augen) },
                                abbrechen: { anzahl.wrappedValue = nil })
                .blattSchema()
                .modifier(WuerfelBlattGrund())
                .presentationDetents([.height(WuerfelEingabeHaken.hatZusatzZeile ? 480 : 400)])
        }
    }
}
#endif
