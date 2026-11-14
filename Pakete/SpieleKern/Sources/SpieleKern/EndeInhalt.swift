// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// design:spielinhalt-datei – Ergebnisseite mit eigenem Inhalt je Spiel (Blatt 22, freigegeben 13.11.; Bauplan EB-K, AUS-010)
// NICHT SYNTAXGEPRÜFT (Cloud-Chat EB-K, kein swiftc). Vorlage: Pakete/SpielMinensuche/Sources/SpielMinensuche/EndeInhalt.swift
#if canImport(UIKit)
import SwiftUI
import KlarGlas

// MARK: - Schnittstelle für die Spiele (Namen bindend, Bauplan EB-K)

/// Eine Wertzeile der Ergebnisseite: links der Name, rechts der Wert.
/// Beispiel: `e.werte = [EndeWert("Runden", "\(spiel.runde)"), .dauer]`.
public struct EndeWert {
    /// Name der Zeile (Übersetzungsschlüssel, z. B. „Runden“).
    let titel: LocalizedStringKey
    /// Fertiger Wert; `nil` heißt „Dauer“, die setzt der Rahmen ein.
    let wert: String?

    public init(_ titel: LocalizedStringKey, _ wert: String) { self.titel = titel; self.wert = wert }

    private init(dauerZeile titel: LocalizedStringKey) { self.titel = titel; self.wert = nil }

    /// „Dauer“: Die Zeit setzt der Rahmen selbst ein (`SpielEnde.dauer`, sonst die Uhr des Rahmens, einmal beim Ende festgehalten).
    public static var dauer: EndeWert { EndeWert(dauerZeile: "Dauer") }

    /// Ob diese Zeile die Dauer des Rahmens zeigt.
    var istDauer: Bool { wert == nil }

    /// Der angezeigte Wert. Die Dauer im Format von `Zeitformat` (z. B. 6:12); ohne bekannte Dauer ein Strich.
    func text(dauer: TimeInterval?) -> String {
        if let wert { return wert }
        guard let dauer else { return "–" }
        return Zeitformat.text(max(0, dauer))
    }
}

/// Das Bild vom Ende. `hoehe` = gewünschte Höhe der ganzen Karte auf dem iPhone in pt; der Kern begrenzt sie.
/// `inhalt` bekommt die nutzbare Innenfläche (Breite und Höhe in pt) und zeichnet darin, mittig, ohne Gesten.
/// Das Bild wird gebaut, wenn das Spiel das Ende meldet, und hält den Stand als Wert fest (keine Bindungen, kein `@State`).
public struct EndeBild {
    let beschreibung: Text
    let hoehe: CGFloat
    let inhalt: (CGSize) -> AnyView

    public init<V: View>(_ beschreibung: Text, hoehe: CGFloat, @ViewBuilder _ inhalt: @escaping (CGSize) -> V) {
        self.beschreibung = beschreibung
        self.hoehe = hoehe
        self.inhalt = { AnyView(inhalt($0)) }
    }
}

/// Kleine Überschrift im Bild, z. B. „LETZTE KARTE“. Hell auf dem Filz (Elfenbein), in Großbuchstaben mit etwas Sperrung.
public struct EndeBildTitel: View {
    let titel: LocalizedStringKey
    public init(_ titel: LocalizedStringKey) { self.titel = titel }
    public var body: some View {
        Text(titel)
            .font(.system(size: 11, weight: .semibold))
            .tracking(1.2)
            .textCase(.uppercase)
            .foregroundStyle(Tisch.elfenbein.opacity(0.78))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Regeln der Anordnung (ohne Ansicht, darum testbar)

/// Maße und Regeln der Ergebnisseite, an einer Stelle (Bauplan EB-K Punkte 4 bis 6).
enum EndeAnordnung {
    /// Höchstens so viele Wertzeilen stehen auf der Seite; meldet ein Spiel mehr, gelten die ersten.
    static let hoechstensWerte = 3
    /// Innenrand der Bildkarte.
    static let rand: CGFloat = 14
    /// Eckenradius der Bildkarte.
    static let ecke: CGFloat = 22
    /// Kleinste Kartenhöhe, damit die Innenfläche nie leer oder negativ wird.
    static let mindestHoehe: CGFloat = 80

    /// Zeigt der Rahmen den neuen Standardinhalt (statt `SpielBildMotiv`)? Nur wenn das Spiel Werte, ein Bild oder gezählte Würfel meldet.
    static func zeigtStandard(werte: [EndeWert], bild: EndeBild?, wuerfel: WuerfelBilanz?) -> Bool {
        !werte.isEmpty || bild != nil || (wuerfel.map { !$0.leer } ?? false)
    }

    static func zeigtStandard(_ e: SpielEnde) -> Bool { zeigtStandard(werte: e.werte, bild: e.bild, wuerfel: e.wuerfel) }

    /// Die Wertzeilen, die tatsächlich stehen (höchstens drei).
    static func sichtbar(_ werte: [EndeWert]) -> [EndeWert] { Array(werte.prefix(hoechstensWerte)) }

    /// Höhe der ganzen Bildkarte: gewünschte Höhe, auf dem iPhone höchstens 320 pt (mit drei oder mehr Einträgen in der Rangliste
    /// höchstens 220 pt), auf dem iPad die gewünschte Höhe mal 1,3, höchstens 420 pt. Nie unter `mindestHoehe`.
    static func bildHoehe(gewuenscht: CGFloat, ipad: Bool, rangEintraege: Int) -> CGFloat {
        let wunsch = gewuenscht.isFinite ? max(0, gewuenscht) : 0
        let h: CGFloat
        if ipad {
            h = min(wunsch * 1.3, 420)
        } else {
            h = min(wunsch, rangEintraege >= 3 ? 220 : 320)
        }
        return max(mindestHoehe, h)
    }

    /// Innenfläche, die das Spiel zum Zeichnen bekommt.
    static func innen(_ aussen: CGSize) -> CGSize {
        CGSize(width: max(0, aussen.width - 2 * rand), height: max(0, aussen.height - 2 * rand))
    }

    /// Höchste Balkenhöhe im Würfelbild: 44 pt, ab drei Personen 28 pt.
    static func balkenHoechst(personen: Int) -> CGFloat { personen >= 3 ? 28 : 44 }

    /// Balkenhöhe für einen Zähler (mindestens 2 pt, damit eine Null sichtbar bleibt).
    static func balken(_ anzahl: Int, maximum: Int, hoechst: CGFloat) -> CGFloat {
        guard maximum > 0 else { return 2 }
        return max(2, hoechst * CGFloat(max(0, anzahl)) / CGFloat(maximum))
    }

    /// Münzen (Königsweg, Augen 0…4) oder andere Würfel ohne 1…6: dann steht die Ziffer statt des kleinen Würfels.
    static func zeigtZiffer(_ b: WuerfelBilanz) -> Bool { b.kleinste != 1 || b.seiten > 6 }

    /// Überschrift des Würfelbilds: Königsweg zählt Münzen (kleinste Augenzahl 0).
    static func wuerfelTitel(_ b: WuerfelBilanz) -> LocalizedStringKey { b.kleinste == 0 ? "So fielen die Münzen" : "So fielen die Würfel" }
}

// MARK: - Standardinhalt der Ergebnisseite

/// Inhalt der Ergebnisseite unter der Rangliste, wenn ein Spiel `werte`, `bild` oder `wuerfel` meldet (Bauplan EB-K Punkt 4):
/// Wertzeilen (höchstens drei), darunter das Bild vom Ende auf dem Filz des Spiels oder „So fielen die Würfel“.
/// Minensuche und Kreuzworträtsel melden ihren eigenen Inhalt über `mitEndeInhalt` und kommen hier nicht an.
struct EndeStandardInhalt: View {
    let werte: [EndeWert]
    let dauer: TimeInterval?
    let bild: EndeBild?
    let wuerfel: WuerfelBilanz?
    /// Einträge der Rangliste über dem Inhalt (0 = keine Rangliste, eine Person).
    let rangEintraege: Int
    let spielID: String
    @Environment(\.designArt) private var art   // zeichnet beim Designwechsel neu
    @Environment(\.horizontalSizeClass) private var sizeClass

    init(ende e: SpielEnde, rangEintraege: Int, spielID: String) {
        werte = e.werte; dauer = e.dauer; bild = e.bild; wuerfel = e.wuerfel
        self.rangEintraege = rangEintraege; self.spielID = spielID
    }

    private var filz: Color? { SpielRahmenHaken.bild?(spielID)?.farbe }
    /// T-1: Salon zeichnet die Ergebnisseite auf einem Farbfeld des Spiels (dunkelrot bei Mau-Mau, Herzensjagd); die Wertzeilen standen mit
    /// `Color.schrift` (im hellen Modus fast schwarz) darauf. Salon nimmt die Schrift, die zum Farbfeld gehört (wie die Übergabeseite in `SpielHilfen`).
    private var zeilenSchrift: Color {
        art == .salon ? (Design.spielFarben?.aufFlaeche ?? Design.werte.aufHuelleFlaeche.color) : Color.schrift
    }

    var body: some View {
        VStack(spacing: 22) {
            if !werte.isEmpty { wertZeilen }
            if let bild {
                bildKarte(bild)
            } else if let w = wuerfel, !w.leer {
                if art == .tinte {
                    WuerfelEndeBild(bilanz: w, filz: filz)
                } else {
                    WuerfelBilanzKarte(w)   // Klar und Salon: die Karte von heute (Bauplan EB-K Punkt 8)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Wertzeilen

    private var wertZeilen: some View {
        VStack(spacing: 0) {
            // Ohne Rangliste (eine Person) eine starke Linie darüber; mit Rangliste hat die ihre eigene, dann nur eine feine.
            if rangEintraege > 1 {
                Rectangle().fill(Color.linie).frame(height: 0.5)
            } else {
                Rectangle().fill(zeilenSchrift).frame(height: 1.5)
            }
            ForEach(Array(EndeAnordnung.sichtbar(werte).enumerated()), id: \.offset) { _, w in
                zeile(w)
            }
        }
    }

    private func zeile(_ w: EndeWert) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Text(w.titel).font(Design.Schrift.serif(17, relativ: .body, hoechstens: 1.3)).foregroundStyle(zeilenSchrift)
                Spacer(minLength: 8)
                Text(verbatim: w.text(dauer: dauer))
                    .font(.system(size: 17, weight: .semibold).monospacedDigit()).foregroundStyle(zeilenSchrift)
                    .lineLimit(1).minimumScaleFactor(0.7)
            }
            .frame(minHeight: 46)
            Rectangle().fill(art == .salon ? zeilenSchrift.opacity(0.3) : Color.linie).frame(height: 0.5)   // feine Linie je Zeile
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: Bild vom Ende

    private func bildKarte(_ b: EndeBild) -> some View {
        let hoehe = EndeAnordnung.bildHoehe(gewuenscht: b.hoehe, ipad: sizeClass == .regular, rangEintraege: rangEintraege)
        let form = RoundedRectangle(cornerRadius: EndeAnordnung.ecke, style: .continuous)
        return GeometryReader { geo in
            let innen = EndeAnordnung.innen(geo.size)
            b.inhalt(innen)
                .frame(width: innen.width, height: innen.height)   // mittig in der Innenfläche
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .frame(height: hoehe)
        .frame(maxWidth: .infinity)
        // Auch in Klar und Salon auf dem Filz: Die Spiele zeichnen ihr Bild mit Tisch-Bausteinen und heller Schrift (siehe Meldung EB-K).
        .background { TischGrund(filz) }
        .clipShape(form)
        .environment(\.colorScheme, .dark)   // wie auf dem Filz am Tisch
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(b.beschreibung)
    }
}

// MARK: - „So fielen die Würfel“ auf dem Filz (Tinte)

/// Würfelbild der Ergebnisseite in Tinte (Entwurf `entwurf-e22-zehntausend.jpg`): je Person Name, Würfe und Schnitt, darunter
/// je Augenzahl ein Balken, der kleine Würfel (Königsweg: die Ziffer) und die Anzahl. Ersetzt in Tinte die `WuerfelBilanzKarte`.
struct WuerfelEndeBild: View {
    let bilanz: WuerfelBilanz
    let filz: Color?
    @State private var offen = false

    private var personen: Int { bilanz.namen.count }
    private var gezeigt: [Int] { Array(bilanz.namen.indices.prefix(offen ? personen : 4)) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            EndeBildTitel(EndeAnordnung.wuerfelTitel(bilanz))
            ForEach(Array(gezeigt.enumerated()), id: \.element) { pos, i in
                if pos > 0 { Rectangle().fill(Tisch.elfenbein.opacity(0.2)).frame(height: 0.5) }
                zeile(i)
            }
            if personen > 4 {
                Button(offen ? "Weniger" : "Alle Spieler") { withAnimation { offen.toggle() } }
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Tisch.elfenbein)
                    .frame(minHeight: 44)
            }
            Text("Jeder Wurf ist zufällig, der Computer würfelt mit denselben Würfeln.")
                .font(.system(size: 11.5)).foregroundStyle(Tisch.elfenbein.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(EndeAnordnung.rand)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { TischGrund(filz) }
        .clipShape(RoundedRectangle(cornerRadius: EndeAnordnung.ecke, style: .continuous))
        .environment(\.colorScheme, .dark)
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }

    private func zeile(_ i: Int) -> some View {
        let werte = bilanz.augen[i]
        let maximum = werte.max() ?? 0
        let hoechst = EndeAnordnung.balkenHoechst(personen: personen)
        let schnitt = bilanz.schnitt(i).map { String(format: "%.1f", $0).replacingOccurrences(of: ".", with: Locale.current.decimalSeparator ?? ",") } ?? "–"
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                SpielerAvatar(name: bilanz.namen[i], farbe: Spieler.farbe(i), groesse: 18)
                Text(verbatim: bilanz.namen[i]).font(.system(size: 13.5, weight: .semibold)).foregroundStyle(Tisch.elfenbein).lineLimit(1)
                Spacer(minLength: 8)
                Text("\(bilanz.wuerfe(i)) Würfe · Schnitt \(schnitt)")
                    .font(.system(size: 12).monospacedDigit()).foregroundStyle(Tisch.elfenbein.opacity(0.78)).lineLimit(1)
            }
            HStack(alignment: .bottom, spacing: 0) {
                ForEach(0..<bilanz.seiten, id: \.self) { k in
                    VStack(spacing: 4) {
                        UnevenRoundedRectangle(topLeadingRadius: 4, topTrailingRadius: 4, style: .continuous)
                            .fill(Tisch.elfenbein.opacity(maximum > 0 && werte[k] == maximum ? 0.92 : 0.5))
                            .frame(width: 20, height: EndeAnordnung.balken(werte[k], maximum: maximum, hoechst: hoechst))
                            .frame(height: hoechst, alignment: .bottom)
                        if EndeAnordnung.zeigtZiffer(bilanz) {
                            Text(verbatim: "\(k + bilanz.kleinste)")
                                .font(.system(size: 14, weight: .bold).monospacedDigit()).foregroundStyle(Tisch.elfenbein)
                                .frame(width: 20, height: 20)
                        } else {
                            WuerfelFlaeche(augen: k + bilanz.kleinste, groesse: 20)
                        }
                        Text(verbatim: "\(werte[k])")
                            .font(.system(size: 11.5, weight: .semibold).monospacedDigit()).foregroundStyle(Tisch.elfenbein.opacity(0.78))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: bilanz.namen[i]))
        .accessibilityValue(Text(verbatim: (0..<bilanz.seiten).map { "\($0 + bilanz.kleinste): \(werte[$0])" }.joined(separator: ", ")))
    }
}
#endif
