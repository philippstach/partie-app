// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas

// Designwechsel D.1: Spielkarten je Design an einer Stelle. `KartenFlaeche`, `SkatKartenBild`,
// `SpanischeKarteBild`, `KartenPlatz` und die eigenen Kartenzeichner der Spiele (Solitär, Rommé, Mogeln, Mau-Mau,
// Elfer raus) lesen `KartenStil.aktuell`; Würfel zeichnet `WuerfelFlaeche`. Die Hex-Werte stehen in der Design-Ebene
// des Baukastens (`DesignWerte.karten`, `DesignWerte.wuerfel`). In „Klar & Glas“ bleibt alles wie bisher.

/// Runde 5, Abschnitt KS: Welcher Kartensatz gezeichnet wird. `.wieDesign` (Vorgabe) folgt dem Design wie bisher; die anderen Werte
/// erzwingen den ganzen Kartenstil eines Designs (Papier, Farben, Rand, Ecke, Schatten, Schrift, Bild). Gespeichert unter `"kartenSatz"`,
/// gewählt in Einstellungen › Design › Karten. Ein weiterer Satz (z. B. mit gezeichneten Figuren) kommt als neuer Fall dazu:
/// `bild(design:)` liefert dann die Art, auf der er aufbaut, und `KartenStil.fuer` ergänzt Figuren.
public enum KartenSatz: String, CaseIterable, Sendable {
    case wieDesign, tinte, klar, salon, figuren
    public static let schluessel = "kartenSatz"
    public static var aktuell: KartenSatz { UserDefaults.standard.string(forKey: schluessel).flatMap(KartenSatz.init(rawValue:)) ?? .wieDesign }
    /// Das Bild (Zeichenweise) dieses Satzes im Design `design`.
    public func bild(design: DesignArt) -> DesignArt {
        switch self { case .wieDesign: design; case .tinte, .figuren: .tinte; case .klar: .klar; case .salon: .salon }   // „Figuren“ baut auf Tinte auf
    }
    /// Name des Satzes (wie das Design heißt, nicht übersetzt); `.wieDesign` hat keinen eigenen Namen.
    public var name: String? {
        switch self { case .wieDesign: nil; case .tinte: "Tinte"; case .klar: "Klar & Glas"; case .salon: "Salon"; case .figuren: "Figuren" }
    }
    /// Hat jemand einen Kartensatz gewählt? Ohne Wahl zeichnen die Spiele mit eigenem Kartenbild wie bisher.
    public static var istGewaehlt: Bool { aktuell != .wieDesign }
    /// Sätze, die zur Wahl stehen (ohne `.wieDesign`).
    public static var wahl: [KartenSatz] { [.klar, .tinte, .salon, .figuren] }
}

/// Aussehen der Spielkarten im gewählten Design.
public struct KartenStil {
    public let art: DesignArt
    /// Papier der Vorderseite. In Tinte und Salon bleibt es auch im Dunkeln hell (wie echtes Papier).
    public let papier: Color
    /// Rot (Herz, Karo) und Schwarz (Kreuz, Pik) auf dem Papier.
    public let rot: Color
    public let schwarz: Color
    /// Rand der Karte (nil = kein Rand) und seine Stärke.
    public let rand: Color?
    public let randStaerke: CGFloat
    public let schatten: Bool
    /// Rand einer gewählten Karte und wie weit sie sich hebt.
    public let gewaehltRand: Color
    public let gewaehltStaerke: CGFloat
    public let hebung: CGFloat
    /// Linie eines leeren Kartenplatzes; `platzGestrichelt` zeichnet sie gestrichelt.
    public let platzLinie: Color
    public let platzGestrichelt: Bool
    public let serif: Bool
    /// Bildkarten (B, D, K) mit gezeichneter Figur (Satz „Figuren“, Blatt 19).
    public var figuren = false
    /// Kartenbild (seit KS Schritt 2 bestimmt der gewählte Satz den ganzen Stil, `bild` ist daher gleich `art`).
    public var bild: DesignArt { art }

    /// Eckenradius einer Karte der Breite `breite` (klar 8/10/12 je Größe, Tinte 4, Salon 3).
    public func ecke(breite: CGFloat) -> CGFloat {
        switch art {
        case .klar: return breite < 50 ? 8 : (breite > 100 ? 12 : 10)
        case .tinte: return 4
        case .salon: return 3
        }
    }

    /// Stil des gewählten Satzes: bei `.wieDesign` der des Designs wie bisher, sonst der Stil des gewählten Satzes.
    public static var aktuell: KartenStil { fuer(satz: KartenSatz.aktuell) }

    /// Zeigt der gewählte Satz zu diesem Rang („B“, „D“, „K“) eine gezeichnete Figur? Für Spiele, die ihre Karten selbst zeichnen.
    /// Karten unter 40 pt Breite zeigen keine Figur (sie wäre nicht mehr zu erkennen), sondern Rang und Zeichen wie in Tinte.
    public func zeigtFigur(_ rang: String, breite: CGFloat) -> Bool { figuren && KartenFigur.hat(rang) && breite >= 40 }

    /// Stil des Satzes `satz` (bei `.wieDesign` der des Designs).
    public static func fuer(satz: KartenSatz) -> KartenStil {
        var s = fuer(satz.bild(design: Design.werte.art))
        s.figuren = satz == .figuren
        return s
    }

    /// Ist der gewählte Kartensatz der der Art `a`? Für Spiele, die ihre Karten selbst zeichnen und dem Satz folgen (nicht dem Design).
    public static func ist(_ a: DesignArt) -> Bool { aktuell.art == a }

    /// Ganzer Kartenstil der Art `satzArt`; die Farben kommen aus den `DesignWerte.karten` dieser Art.
    public static func fuer(_ satzArt: DesignArt) -> KartenStil {
        let w = DesignWerte.fuer(satzArt)
        switch satzArt {
        case .klar:
            return KartenStil(art: .klar, papier: .kartenGrund, rot: .red, schwarz: .primary,
                              rand: Color.secondary.opacity(0.35), randStaerke: 1, schatten: true,
                              gewaehltRand: .appFlaeche, gewaehltStaerke: 3, hebung: 8,
                              platzLinie: Color.secondary.opacity(0.3), platzGestrichelt: true, serif: false)
        case .tinte:
            let k = w.karten
            return KartenStil(art: .tinte, papier: k?.papier.color ?? .white, rot: k?.rot.color ?? .red, schwarz: k?.schwarz.color ?? .black,
                              rand: k?.schwarz.color ?? .black, randStaerke: 1, schatten: false,
                              gewaehltRand: Design.spielFarben?.flaeche ?? .appFlaeche, gewaehltStaerke: 2.5, hebung: 8,
                              platzLinie: .linieStark, platzGestrichelt: true, serif: true)
        case .salon:
            let k = w.karten
            return KartenStil(art: .salon, papier: k?.papier.color ?? .white, rot: k?.rot.color ?? .red, schwarz: k?.schwarz.color ?? .black,
                              rand: Color.linie, randStaerke: 1, schatten: false,
                              // Espresso auf hellem Grund; auf dunklem Grund wäre er unsichtbar, dort die Spielart-Farbe
                              gewaehltRand: Color(uiColor: UIColor { t in
                                  t.userInterfaceStyle == .dark ? UIColor(Design.spielFarben?.flaeche ?? .orange) : UIColor(k?.schwarz.color ?? .black)
                              }), gewaehltStaerke: 3, hebung: 8,
                              platzLinie: .linie, platzGestrichelt: false, serif: true)
        }
    }

    /// Farbe einer Kartenfarbe (rot oder schwarz) auf dem Papier.
    public func farbe(rot istRot: Bool) -> Color { istRot ? rot : schwarz }
}

/// Rückseite einer Karte im gewählten Design, in der Form `form` (klar: Verlauf in der App-Farbe mit Karo; Tinte: Papier mit
/// feinem Linienraster und Tinte-Rand; Salon: volle Fläche in der Spielart-Farbe mit Creme-Rahmenlinie innen und kleinem Karo).
public struct KartenRuecken: View {
    @AppStorage(KartenSatz.schluessel) private var satzGewaehlt = ""   // KS: zeichnet beim Wechsel des Kartensatzes neu
    let breite: CGFloat
    let ecke: CGFloat?
    /// Salon: andere Füllung als die Spielart-Farbe, wenn der Tisch selbst in der Spielart-Farbe steht (sonst verschwände der Rücken).
    let fuellung: Color?

    let vorschau: KartenSatz?

    public init(breite: CGFloat, ecke: CGFloat? = nil, fuellung: Color? = nil, vorschau: KartenSatz? = nil) {
        self.breite = breite; self.ecke = ecke; self.fuellung = fuellung; self.vorschau = vorschau
    }

    public var body: some View {
        let stil = vorschau.map { KartenStil.fuer(satz: $0) } ?? KartenStil.aktuell
        let form = RoundedRectangle(cornerRadius: ecke ?? stil.ecke(breite: breite), style: .continuous)
        ZStack {
            switch stil.bild {
            case .klar:
                form.fill(LinearGradient(colors: [Color.appFlaeche, Color.appFlaeche.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                form.inset(by: 5).strokeBorder(.white.opacity(0.55), lineWidth: 1.5)
                Image(systemName: "suit.diamond.fill").font(.system(size: breite * 0.34)).foregroundStyle(.white.opacity(0.55))   // design:spielinhalt (Kartenbild skaliert mit der Kartengröße)
            case .tinte:
                // K-035/M-021: kräftigere Schraffur und Innenrand plus Mittelzeichen. Vorher wirkte der Rücken auf hellem Papier wie eine
                // leere weiße Karte und verschwand auf dunklem Grund fast.
                form.fill(stil.papier)
                Schraffur().stroke(stil.schwarz.opacity(0.4), lineWidth: 1.2).clipShape(form.inset(by: 3))
                form.inset(by: 3).strokeBorder(stil.schwarz.opacity(0.7), lineWidth: 1)
                Image(systemName: "suit.diamond.fill").font(.system(size: max(8, breite * 0.2))).foregroundStyle(stil.schwarz.opacity(0.7))   // design:spielinhalt (Kartenbild skaliert mit der Kartengröße)
                    .padding(max(3, breite * 0.07)).background(stil.papier, in: Circle())
            case .salon:
                let farben = Design.spielFarben
                form.fill(fuellung ?? farben?.flaeche ?? Color.appFlaeche)
                form.inset(by: 4).strokeBorder(stil.papier, lineWidth: 1)
                Image(systemName: "suit.diamond.fill").font(.system(size: max(8, breite * 0.2))).foregroundStyle(stil.papier)   // design:spielinhalt (Kartenbild skaliert mit der Kartengröße)
            }
        }
        .accessibilityHidden(true)
    }
}

/// Schraffur im Winkel von 45° (Rückseite der Tinte-Karten).
struct Schraffur: Shape {
    var abstand: CGFloat = 5
    func path(in r: CGRect) -> Path {
        var p = Path()
        var x = r.minX - r.height
        while x < r.maxX {
            p.move(to: CGPoint(x: x, y: r.maxY)); p.addLine(to: CGPoint(x: x + r.height, y: r.minY))
            x += abstand
        }
        return p
    }
}

/// Vorderseite einer Karte aus Rang und Farbzeichen im gewählten Design. `breite` bestimmt die Schriftgrößen.
/// klar: Rang mittig über dem Farbzeichen (wie bisher). Tinte: Rang und Farbzeichen oben links klein in Serifenschrift,
/// großes Farbzeichen mittig. Salon: Rang groß in Serifenschrift fett oben links, Farbzeichen darunter, unten rechts gespiegelt.
/// Bildkarten (B, D, K, A) sind in Tinte und Salon reine Typografie.
public struct KartenIndex: View {
    @AppStorage(KartenSatz.schluessel) private var satzGewaehlt = ""   // KS: zeichnet beim Wechsel des Kartensatzes neu
    let rang: String
    let zeichen: String
    let farbe: Color
    let breite: CGFloat
    let hoehe: CGFloat

    let vorschau: KartenSatz?

    public init(rang: String, zeichen: String, farbe: Color, breite: CGFloat, hoehe: CGFloat, vorschau: KartenSatz? = nil) {
        self.rang = rang; self.zeichen = zeichen; self.farbe = farbe; self.breite = breite; self.hoehe = hoehe; self.vorschau = vorschau
    }

    /// Rang und Zeichen oben links in Tinte (auch Ecke der Figurenkarten).
    private var tinteEcke: some View {
        VStack(spacing: -1) {
            Text(verbatim: rang).font(.system(size: breite * 0.27, weight: .medium, design: .serif)).minimumScaleFactor(0.6).lineLimit(1)   // design:spielinhalt (Kartenbild skaliert mit der Kartengröße)
            Text(verbatim: zeichen).font(.system(size: breite * 0.2))   // design:spielinhalt (Kartenbild skaliert mit der Kartengröße)
        }
        .padding(.leading, breite * 0.08).padding(.top, breite * 0.06)
    }

    /// Ob `farbe` nicht das Schwarz des Stils ist, also Rot (Herz, Karo): bestimmt das Kleid der Figur.
    static func istRot(_ farbe: Color, _ stil: KartenStil) -> Bool { farbe != stil.schwarz }

    public var body: some View {
        let stil = vorschau.map { KartenStil.fuer(satz: $0) } ?? KartenStil.aktuell
        Group {
            switch stil.bild {
            case .klar:
                let schrift = breite * 0.42
                VStack(spacing: -2) {
                    Text(verbatim: rang).font(.system(size: schrift, weight: .bold, design: Design.zahlDesign)).minimumScaleFactor(0.6)   // design:spielinhalt (Kartenbild skaliert mit der Kartengröße)
                    Text(verbatim: zeichen).font(.system(size: schrift * 0.95))   // design:spielinhalt (Kartenbild skaliert mit der Kartengröße)
                }
            case .tinte:
                if stil.zeigtFigur(rang, breite: breite) {
                    // Satz „Figuren“: gezeichnete Figur in der Mitte (gespiegelt), Rang und Zeichen oben links und gedreht unten rechts
                    ZStack {
                        KartenFigur(rang: rang, rot: Self.istRot(farbe, stil), stil: stil)
                        tinteEcke
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        tinteEcke.rotationEffect(.degrees(180))
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    }
                } else {
                ZStack(alignment: .topLeading) {
                    tinteEcke
                    Text(verbatim: zeichen).font(.system(size: breite * 0.5))   // design:spielinhalt (Kartenbild skaliert mit der Kartengröße)
                        .frame(maxWidth: .infinity, maxHeight: .infinity).offset(y: hoehe * 0.08)
                }
                }
            case .salon:
                ZStack {
                    VStack(alignment: .leading, spacing: -3) {
                        Text(verbatim: rang).font(.system(size: breite * 0.4, weight: .bold, design: .serif)).minimumScaleFactor(0.6).lineLimit(1)   // design:spielinhalt (Kartenbild skaliert mit der Kartengröße)
                        Text(verbatim: zeichen).font(.system(size: breite * 0.3))   // design:spielinhalt (Kartenbild skaliert mit der Kartengröße)
                    }
                    .padding(.leading, breite * 0.1).padding(.top, breite * 0.06)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    if hoehe > breite * 1.25 {   // unten rechts gespiegelt (nur wenn die Karte hoch genug ist)
                        VStack(alignment: .leading, spacing: -3) {
                            Text(verbatim: rang).font(.system(size: breite * 0.26, weight: .bold, design: .serif)).lineLimit(1)   // design:spielinhalt (Kartenbild skaliert mit der Kartengröße)
                            Text(verbatim: zeichen).font(.system(size: breite * 0.2))   // design:spielinhalt (Kartenbild skaliert mit der Kartengröße)
                        }
                        .rotationEffect(.degrees(180))
                        .padding(.trailing, breite * 0.1).padding(.bottom, breite * 0.06)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    }
                }
            }
        }
        .foregroundStyle(farbe)
        .frame(width: breite, height: hoehe)
    }
}

public extension View {
    /// Papier und Rand für eine selbst gezeichnete Karte (Rommé, Mogeln, …): in „Klar & Glas“ Fläche `klarFlaeche` mit grauem 1-pt-Rand,
    /// gewählt 3 pt in der App-Farbe (genau wie bisher); in Tinte und Salon Papier, Rand und Auswahlrand des `KartenStil`.
    /// `ecke` gilt für klar, in den anderen Designs bestimmt der Stil die Ecke (`breite` = Kartenbreite).
    func kartenPapier(ecke: CGFloat, breite: CGFloat, gewaehlt: Bool, klarFlaeche: Color = Color(.systemBackground)) -> some View {
        modifier(KartenPapierModifier(ecke: ecke, breite: breite, gewaehlt: gewaehlt, klarFlaeche: klarFlaeche))
    }
}

private struct KartenPapierModifier: ViewModifier {
    let ecke: CGFloat
    let breite: CGFloat
    let gewaehlt: Bool
    let klarFlaeche: Color
    @Environment(\.designArt) private var art   // zeichnet beim Designwechsel neu
    @AppStorage(KartenSatz.schluessel) private var satzGewaehlt = ""   // KS: zeichnet beim Wechsel des Kartensatzes neu

    func body(content: Content) -> some View {
        let stil = KartenStil.aktuell
        let r = stil.art == .klar ? ecke : stil.ecke(breite: breite)
        content
            .background(stil.art == .klar ? klarFlaeche : stil.papier, in: .rect(cornerRadius: r))
            .overlay {
                if stil.art == .klar {
                    RoundedRectangle(cornerRadius: r).strokeBorder(gewaehlt ? Color.appFlaeche : Color.secondary.opacity(0.4), lineWidth: gewaehlt ? 3 : 1)   // design:spielinhalt (Markierung auf dem Spielmaterial)
                } else if gewaehlt {
                    RoundedRectangle(cornerRadius: r).strokeBorder(stil.gewaehltRand, lineWidth: stil.gewaehltStaerke)
                } else if let rand = stil.rand {
                    RoundedRectangle(cornerRadius: r).strokeBorder(rand, lineWidth: stil.randStaerke)
                }
            }
    }
}
#endif
