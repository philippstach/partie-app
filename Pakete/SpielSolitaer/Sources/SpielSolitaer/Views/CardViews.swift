// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// design:spielinhalt-datei (Karten, Tischthemen, Farben und Konfetti sind Spielinhalt, DESIGN.md 3.6)
import SwiftUI
import KlarGlas
import SpieleKern

/// Vorderseite „großer Index“: Wert und Symbol oben links, damit der obere Streifen allein reicht.
struct CardFaceView: View {
    let face: CardFace
    let width: CGFloat
    var fourColor = false
    /// Teilweise verdeckt: bei Bildkarten nur der Index
    var covered = false
    @Environment(\.largeCardIndex) private var largeIndex

    private var radius: CGFloat { Theme.cardRadius(width) }
    private var ink: Color { Theme.ink(for: face.suit, fourColor: fourColor) }
    /// Schmale Karten (Spider, < 42 pt): kompakter Index, mittelgroßes Symbol, keine Bildbuchstaben
    private var compact: Bool { width < 42 }

    var body: some View {
        if compact { compactBody } else { normalBody }
    }

    private var compactBody: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: radius).fill(Theme.cardFace)
            RoundedRectangle(cornerRadius: radius).strokeBorder(Theme.cardEdge, lineWidth: Theme.cardEdgeWidth)
            // Wert und Symbol in einer Zeile: passt in den schmalen oberen Streifen der aufgefächerten Spalte
            HStack(spacing: width * 0.01) {
                Text(face.rankText)
                    .font(.system(size: width * 0.46, weight: .bold, design: Design.zahlDesign))   // design:spielinhalt (skaliert mit Feld/Karte/Würfel)
                    .tracking(face.rank == 10 && KartenStil.ist(.klar) ? -1 : 0)   // Serife (Tinte, Salon) braucht die Lücke
                Image(systemName: face.suit.symbolName)
                    .font(.system(size: width * 0.30))   // design:spielinhalt (skaliert mit Feld/Karte/Würfel)
            }
            .foregroundStyle(ink)
            .lineLimit(1).minimumScaleFactor(0.7)
            .fixedSize()
            .padding(.leading, width * 0.07)
            .padding(.top, width * 0.02)
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                Image(systemName: face.suit.symbolName)
                    .font(.system(size: width * 0.5))   // design:spielinhalt (skaliert mit Feld/Karte/Würfel)
                    .foregroundStyle(ink)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, width * 0.10)
        }
        .frame(width: width, height: width * Theme.cardAspect)
    }

    private var normalBody: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: radius).fill(Theme.cardFace)
            RoundedRectangle(cornerRadius: radius).strokeBorder(Theme.cardEdge, lineWidth: Theme.cardEdgeWidth)

            // Kartengröße „Groß“: Index 1,25-fach
            let k: CGFloat = largeIndex ? 1.25 : 1
            HStack(spacing: width * 0.02) {
                Text(face.rankText)
                    .font(.system(size: width * 0.36 * k, weight: .bold, design: Design.zahlDesign))   // design:spielinhalt (skaliert mit Feld/Karte/Würfel)
                    .tracking(face.rank == 10 && KartenStil.ist(.klar) ? -width * 0.04 * k : 0)
                Image(systemName: face.suit.symbolName)
                    .font(.system(size: width * 0.26 * k))   // design:spielinhalt (skaliert mit Feld/Karte/Würfel)
            }
            .foregroundStyle(ink)
            .lineLimit(1).minimumScaleFactor(0.7)
            .fixedSize()
            .padding(.leading, width * 0.07)
            .padding(.top, largeIndex ? width * 0.01 : width * 0.04)

            if face.rank >= 11 {
                if !covered && KartenStil.aktuell.figuren && width >= 40 { EmptyView() } else if !covered && KartenStil.ist(.klar) { courtCard } else if !covered { courtTypografie }   // Tinte, Salon: Bildkarten nur Typografie
            } else {
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    ZStack {
                        // Pik-Ass: feiner Goldring um das große Symbol
                        if face.rank == 1, face.suit == .spades, !covered, KartenStil.ist(.klar) {
                            Circle().strokeBorder(Theme.cardGold, lineWidth: 1).frame(width: width * 0.78, height: width * 0.78)
                        }
                        Image(systemName: face.suit.symbolName)
                            .font(.system(size: width * 0.55))   // design:spielinhalt (skaliert mit Feld/Karte/Würfel)
                    }
                }
                .foregroundStyle(ink)
                .frame(maxWidth: .infinity)
                .padding(.bottom, width * 0.07)
            }
        }
        .frame(width: width, height: width * Theme.cardAspect)
        .overlay { if KartenStil.aktuell.figuren && face.rank >= 11 && !covered && width >= 40 { figurenKarte } }   // Satz „Figuren“ (Blatt 19)
    }

    /// Satz „Figuren“: Bube, Dame und König gezeichnet; Rang und Zeichen oben links und gedreht unten rechts. Deckt die ganze Karte.
    private var figurenKarte: some View {
        let stil = KartenStil.aktuell
        let hoehe = width * Theme.cardAspect
        let ecke = VStack(spacing: -1) {
            Text(face.rankText).font(.system(size: width * 0.27, weight: .medium, design: .serif)).minimumScaleFactor(0.6).lineLimit(1)   // design:spielinhalt (skaliert mit Feld/Karte/Würfel)
            Image(systemName: face.suit.symbolName).font(.system(size: width * 0.2))   // design:spielinhalt (skaliert mit Feld/Karte/Würfel)
        }
        .foregroundStyle(ink)
        .padding(.leading, width * 0.08).padding(.top, width * 0.06)
        return ZStack {
            RoundedRectangle(cornerRadius: radius).fill(Theme.cardFace)
            KartenFigur(rang: face.rank == 11 ? "B" : (face.rank == 12 ? "D" : "K"), rot: face.suit.isRed, stil: stil)
            ecke.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            ecke.rotationEffect(.degrees(180)).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
        .frame(width: width, height: hoehe)
        .clipShape(RoundedRectangle(cornerRadius: radius))
        .overlay(RoundedRectangle(cornerRadius: radius).strokeBorder(Theme.cardEdge, lineWidth: Theme.cardEdgeWidth))
    }

    /// Bildkarte in Tinte und Salon: nur Typografie (Monogramm und Farbzeichen), kein Rahmen, keine Krone.
    private var courtTypografie: some View {
        VStack(spacing: 0) {
            Text(face.rankText)
                .font(.system(size: width * 0.5, weight: .bold, design: Design.zahlDesign))   // design:spielinhalt (skaliert mit Feld/Karte/Würfel)
                .minimumScaleFactor(0.6)
            Image(systemName: face.suit.symbolName).font(.system(size: width * 0.17))   // design:spielinhalt (skaliert mit Feld/Karte/Würfel)
        }
        .foregroundStyle(ink)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .padding(.bottom, width * 0.12)
    }

    /// Bildkarte B/D/K: Innenrahmen in Gold (1 pt) mit 6 % Farbton, großes Monogramm, kleines Farbsymbol, beim König eine Krone
    private var courtCard: some View {
        let frameTop = width * 0.46, side = width * 0.12, bottom = width * 0.08
        return ZStack {
            RoundedRectangle(cornerRadius: radius * 0.6).fill(ink.opacity(0.06))
            RoundedRectangle(cornerRadius: radius * 0.6).strokeBorder(Theme.cardGold, lineWidth: 1)
            VStack(spacing: 0) {
                if face.rank == 13 {
                    Image(systemName: "crown.fill").font(.system(size: width * 0.15)).foregroundStyle(Theme.cardGold)   // design:spielinhalt (skaliert mit Feld/Karte/Würfel)
                }
                Text(face.rankText)
                    .font(.system(size: width * 0.5, weight: .heavy, design: Design.zahlDesign))   // design:spielinhalt (skaliert mit Feld/Karte/Würfel)
                    .minimumScaleFactor(0.6)
                Image(systemName: face.suit.symbolName).font(.system(size: width * 0.17))   // design:spielinhalt (skaliert mit Feld/Karte/Würfel)
            }
            .foregroundStyle(ink)
        }
        .padding(.leading, side).padding(.trailing, side).padding(.top, frameTop).padding(.bottom, bottom)
    }
}

/// Rücken im gewählten Aussehen (Einstellungen → Aussehen), im Code gezeichnet. `style`/`table`: für Vorschauen,
/// sonst gelten die Werte aus der Umgebung. Sind Rücken und Tisch zu ähnlich, bekommt der Rücken einen weißen 1,5-pt-Rand.
struct CardBackView: View {
    let width: CGFloat
    var style: CardBackStyle?
    var table: TableStyle?
    @Environment(\.cardBackStyle) private var envStyle
    @Environment(\.tableStyle) private var envTable

    var body: some View {
        let style = style ?? envStyle
        let table = table ?? envTable
        CardBackArt(style: style, width: width)
            .overlay {
                if style.needsContrastBorder(on: table) {
                    RoundedRectangle(cornerRadius: Theme.cardRadius(width)).strokeBorder(.white.opacity(0.6), lineWidth: 1.5)
                }
            }
            .frame(width: width, height: width * Theme.cardAspect)
    }
}

/// Karte mit Drehung um die Y-Achse beim Aufdecken. `angle` 0 = offen, 180 = verdeckt.
struct FlippingCardView: View, Animatable {
    let face: CardFace
    let width: CGFloat
    var fourColor: Bool
    var angle: Double
    var covered = false

    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    var body: some View {
        ZStack {
            if angle < 90 {
                CardFaceView(face: face, width: width, fourColor: fourColor, covered: covered)
            } else {
                CardBackView(width: width)
                    .rotation3DEffect(.degrees(180), axis: (0, 1, 0))
            }
        }
        .rotation3DEffect(.degrees(angle), axis: (0, 1, 0), perspective: 0.4)
    }
}

/// Leerer Platz: Rahmen in `primary` 12 %, optional Symbol bei 30 %
struct SlotView: View {
    let size: CGSize
    var symbol: String?
    var label: String?
    var filled = false
    var tint: Color = .primary
    /// Farbe des Symbols (Kartenfarbe des Ziels); nil = Tischfarbe
    var symbolColor: Color?

    var body: some View {
        RoundedRectangle(cornerRadius: Theme.cardRadius(size.width))
            .fill(filled ? tint.opacity(0.04) : .clear)
            .overlay {
                // Mockup: leerer Platz gestrichelt in zarter App-Farbe (helle Tische); auf dunklen Tischen weiß, ruhig
                if tint == .white {
                    RoundedRectangle(cornerRadius: Theme.cardRadius(size.width)).strokeBorder(tint.opacity(0.28), lineWidth: 1)
                } else {
                    RoundedRectangle(cornerRadius: Theme.cardRadius(size.width))
                        .strokeBorder(Color.appFarbe.opacity(0.45), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                }
            }
            .overlay {
                if let symbol {
                    Image(systemName: symbol)
                        .font(.system(size: size.width * 0.45))   // design:spielinhalt (skaliert mit Feld/Karte/Würfel)
                        .foregroundStyle((symbolColor ?? tint).opacity(0.3))
                } else if let label {
                    Text(label)
                        .font(.system(size: size.width * 0.5, weight: .bold, design: Design.zahlDesign))   // design:spielinhalt (skaliert mit Feld/Karte/Würfel)
                        .foregroundStyle(tint.opacity(0.3))
                }
            }
            .frame(width: size.width, height: size.height)
    }
}
