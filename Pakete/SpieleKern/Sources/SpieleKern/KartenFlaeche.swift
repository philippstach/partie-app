// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas

/// Kartengröße (Breite × Höhe in pt) für `KartenFlaeche`.
public enum KartenGroesse: Sendable {
    case klein, normal, gross, riesig
    public var masse: CGSize {
        switch self {
        case .klein: CGSize(width: 44, height: 64)
        case .normal: CGSize(width: 58, height: 84)
        case .gross: CGSize(width: 76, height: 110)
        case .riesig: CGSize(width: 110, height: 156)
        }
    }
}

/// Gemeinsame Kartenfläche für alle Kartenspiele (ersetzt die Eigenbauten KartenBild, HKartenBild, StufenKarte, DuellKarte, PechKarte).
/// Zeichnet Hintergrund, Rand, Zustand (gewählt, gedimmt) und Zugänglichkeit; den Inhalt liefert das Spiel.
public struct KartenFlaeche<Inhalt: View>: View {
    @Environment(\.accessibilityReduceMotion) private var bewegungReduziert
    @Environment(\.designArt) private var art   // Designwechsel D.1: zeichnet beim Wechsel neu
    @AppStorage(KartenSatz.schluessel) private var satzGewaehlt = ""   // KS: zeichnet beim Wechsel des Kartensatzes neu
    @Environment(\.tischFarbe) private var filz   // Tinte: Spielart-Farbe des Filzes für den Schleier
    public enum Seite: Sendable { case vorn, ruecken }

    let groesse: KartenGroesse
    let seite: Seite
    let flaeche: AnyShapeStyle?
    let gewaehlt: Bool
    let gedimmt: Bool
    let beschriftung: Text
    let inhalt: Inhalt
    private var markiert = false

    /// Farbiger Rand ohne Anheben (z. B. Atout).
    public func markiert(_ an: Bool = true) -> Self { var k = self; k.markiert = an; return k }

    /// - flaeche: Kartenfarbe, nil = neutrale Kartenfläche (Hell/Dunkel automatisch)
    /// - beschriftung: Text für VoiceOver (bei `.ruecken` „Verdeckte Karte“)
    public init(groesse: KartenGroesse = .normal, seite: Seite = .vorn, flaeche: Color? = nil, gewaehlt: Bool = false, gedimmt: Bool = false,
                beschriftung: Text = Text(verbatim: ""), @ViewBuilder inhalt: () -> Inhalt) {
        self.groesse = groesse; self.seite = seite; self.flaeche = flaeche.map { AnyShapeStyle($0) }; self.gewaehlt = gewaehlt; self.gedimmt = gedimmt
        self.beschriftung = beschriftung; self.inhalt = inhalt()
    }

    /// Wie oben, aber mit beliebiger Füllung (z. B. Farbverlauf für Joker).
    public init(groesse: KartenGroesse = .normal, seite: Seite = .vorn, fuellung: AnyShapeStyle, gewaehlt: Bool = false, gedimmt: Bool = false,
                beschriftung: Text = Text(verbatim: ""), @ViewBuilder inhalt: () -> Inhalt) {
        self.groesse = groesse; self.seite = seite; self.flaeche = fuellung; self.gewaehlt = gewaehlt; self.gedimmt = gedimmt
        self.beschriftung = beschriftung; self.inhalt = inhalt()
    }

    private var stil: KartenStil { KartenStil.aktuell }
    private var form: RoundedRectangle { RoundedRectangle(cornerRadius: stil.ecke(breite: groesse.masse.width), style: .continuous) }

    /// Rand: gewählt/markiert in der Auswahlfarbe des Designs, sonst der Rand des Kartenstils (Salon: feine Linie, klar: 1 pt grau).
    @ViewBuilder private var rahmen: some View {
        if gewaehlt || markiert { form.strokeBorder(stil.gewaehltRand, lineWidth: stil.gewaehltStaerke) }
        else if let rand = stil.rand { form.strokeBorder(rand, lineWidth: stil.randStaerke) }
    }

    public var body: some View {
        ZStack {
            switch seite {
            case .vorn:
                form.fill(flaeche ?? AnyShapeStyle(stil.papier))
                inhalt
            case .ruecken:
                KartenRuecken(breite: groesse.masse.width, ecke: stil.ecke(breite: groesse.masse.width))
            }
        }
        .frame(width: groesse.masse.width, height: groesse.masse.height)
        .overlay { rahmen }
        .shadow(color: stil.schatten ? .black.opacity(gewaehlt ? 0.25 : 0.12) : .clear, radius: gewaehlt ? 5 : 2, y: gewaehlt ? 3 : 1)
        .offset(y: gewaehlt ? -stil.hebung : 0)
        // Klar: Deckkraft 0,6 (K-024: mit 0,4 waren nicht spielbare Handkarten zu blass, die Werte kaum lesbar). Tinte/Salon: Karte bleibt deckend (sonst scheinen die Nachbarkarten im Fächer durch und es wird ein grauer Schleier);
        // abgedunkelt wird die einzelne Karte mit dem Seitengrund (45 %), die Werte bleiben lesbar (Karte wirkt wie Deckkraft 0,55).
        // Tinte (Runde 5, Blatt 10): Schleier in der Filzfarbe, rund 20 %, damit die Karte hell bleibt statt grau/schwarz zu werden. Die passende Karte
        // steht höher (Fächer: `absenkung` 14 pt).
        .overlay {
            if gedimmt && stil.art == .tinte { form.fill((filz ?? Tisch.violett).opacity(0.2)).allowsHitTesting(false) }
            else if gedimmt && stil.art != .klar { form.fill(Color.seitenGrund.opacity(0.45)).allowsHitTesting(false) }
        }
        .opacity(gedimmt && stil.art == .klar ? 0.6 : 1)
        .animation(bewegungReduziert ? nil : .snappy(duration: 0.18), value: gewaehlt)   // G3
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(seite == .ruecken ? Text("Verdeckte Karte") : beschriftung)
        .accessibilityAddTraits(gewaehlt ? .isSelected : [])
    }
}

/// Karte des Standard-Skatblatts (`SkatKarte`, 52 Karten); `nil` zeigt die Rückseite.
public struct SkatKartenBild: View {
    let karte: SkatKarte?
    let groesse: KartenGroesse
    let gewaehlt: Bool
    let gedimmt: Bool
    let markiert: Bool

    public init(_ karte: SkatKarte?, groesse: KartenGroesse = .normal, gewaehlt: Bool = false, gedimmt: Bool = false, markiert: Bool = false) {
        self.karte = karte; self.groesse = groesse; self.gewaehlt = gewaehlt; self.gedimmt = gedimmt; self.markiert = markiert
    }

    public var body: some View {
        KartenFlaeche(groesse: groesse, seite: karte == nil ? .ruecken : .vorn, gewaehlt: gewaehlt, gedimmt: gedimmt,
                      beschriftung: Text(verbatim: karte?.sprechname ?? "")) {
            if let k = karte {
                let stil = KartenStil.aktuell
                KartenIndex(rang: k.rang, zeichen: k.farbe.symbol, farbe: stil.farbe(rot: k.farbe.rot),
                            breite: groesse.masse.width, hoehe: groesse.masse.height)
            }
        }
        .markiert(markiert)
    }
}

/// Karte des spanischen Blatts (Escoba, Truco, Brisca, Chinchón): Rang und Farbsymbol (Münzen, Becher, Schwerter-Blitz, Blatt).
public struct SpanischeKarteBild: View {
    static let symbole = ["circle.circle.fill", "cup.and.saucer.fill", "bolt.fill", "leaf.fill"]
    static let farben: [Color] = [.orange, .red, .blue, .green]
    let rang: Int
    let farbe: Int
    let groesse: KartenGroesse
    let gewaehlt: Bool
    let gedimmt: Bool
    let markiert: Bool

    public init(rang: Int, farbe: Int, groesse: KartenGroesse = .normal, gewaehlt: Bool = false, gedimmt: Bool = false, markiert: Bool = false) {
        self.markiert = markiert; self.rang = rang; self.farbe = farbe; self.groesse = groesse; self.gewaehlt = gewaehlt; self.gedimmt = gedimmt
    }

    public var body: some View {
        let klein = groesse == .klein
        KartenFlaeche(groesse: groesse, gewaehlt: gewaehlt, gedimmt: gedimmt,
                      beschriftung: Text(verbatim: "\(Kartensprache.spanischeFarbe(farbe)) \(rang)")) {
            VStack(spacing: klein ? 2 : 4) {
                Text(verbatim: "\(rang)").font(klein ? .headline.weight(.bold) : .title3.weight(.bold))
                Image(systemName: Self.symbole[farbe % 4]).font(klein ? .subheadline : .title3)
            }
            .foregroundStyle(Self.farben[farbe % 4])
        }
        .markiert(markiert)
    }
}

/// Leerer Kartenplatz (gestrichelter Umriss).
public struct KartenPlatz: View {
    let groesse: KartenGroesse
    public init(groesse: KartenGroesse = .normal) { self.groesse = groesse }
    public var body: some View {
        let stil = KartenStil.aktuell
        RoundedRectangle(cornerRadius: stil.art == .klar ? (groesse == .klein ? 8 : 10) : stil.ecke(breite: groesse.masse.width), style: .continuous)
            .stroke(stil.platzLinie, style: StrokeStyle(lineWidth: 1, dash: stil.platzGestrichelt ? [4] : []))
            .frame(width: groesse.masse.width, height: groesse.masse.height)
    }
}
#endif

public extension SkatKarte {
    /// Aus den Kartenspielen der Sammlung mit 32er-Blatt (Farbe 0 Kreuz, 1 Pik, 2 Herz, 3 Karo; Wert 7 … 14).
    init?(farbIndex: Int, wert: Int) {
        guard let f = Farbe(rawValue: farbIndex), (2...14).contains(wert) else { return nil }
        self.init(f, wert)
    }
}
