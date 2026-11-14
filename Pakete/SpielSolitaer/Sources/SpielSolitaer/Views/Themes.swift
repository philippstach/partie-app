// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// design:spielinhalt-datei – Tischdecken und Kartenrücken (Spielmaterial, frei wählbare Tische)
import SwiftUI
import KlarGlas
import SpieleKern

/// Kartenrücken (DESIGN „Themen“): alles im Code gezeichnet, in hell und dunkel
enum CardBackStyle: String, CaseIterable, Identifiable {
    case gold, navy, bordeaux, retro
    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .gold: "Grün-Raute"
        case .navy: "Nachtblau"
        case .bordeaux: "Bordeaux"
        case .retro: "Retro-Karo"
        }
    }

    /// Grundfarbe hell / dunkel
    var base: Color {
        switch self {
        case .gold: Color.appFarbe
        case .navy: Theme.dynamic(0x1F3A5F, 0x15283F)
        case .bordeaux: Theme.dynamic(0x6E1F2A, 0x4E161E)
        case .retro: Theme.dynamic(0x2E6B4F, 0x1F4A37)
        }
    }
}

/// Tisch (DESIGN „Themen“)
enum TableStyle: String, CaseIterable, Identifiable {
    case linen, felt, navy, slate
    /// Eigenes Foto (weichgezeichnet und abgedunkelt)
    case photo
    /// Jahreszeiten-Tische (Frühling, Sommer, Herbst, Winter)
    case spring, summer, autumn, winter
    var id: String { rawValue }

    /// Die vier Standard-Tische (erste Zeile in Aussehen → Tisch)
    static let basic: [TableStyle] = [.linen, .felt, .navy, .slate]
    /// Die Jahreszeiten-Tische (zweite Zeile)
    static let seasons: [TableStyle] = [.spring, .summer, .autumn, .winter]
    var isSeason: Bool { Self.seasons.contains(self) }

    /// März–Mai Frühling, Juni–August Sommer, September–November Herbst, Dezember–Februar Winter (Ortszeit, kein Netz)
    static func season(month: Int) -> TableStyle {
        switch month {
        case 3...5: .spring
        case 6...8: .summer
        case 9...11: .autumn
        default: .winter
        }
    }

    static func season(for date: Date, calendar: Calendar = .solitaer) -> TableStyle {
        season(month: calendar.component(.month, from: date))
    }

    var title: LocalizedStringKey {
        switch self {
        case .linen: "Leinen"
        case .felt: "Filz"
        case .navy: "Nachtblau"
        case .slate: "Schiefer"
        case .photo: "Eigenes Foto"
        case .spring: "Frühling"
        case .summer: "Sommer"
        case .autumn: "Herbst"
        case .winter: "Winter"
        }
    }

    var color: Color {
        switch self {
        // Designwechsel D.4 / Design-Runde 3: der Standard-Tisch folgt dem Design (Tinte: grüner Filz, Salon: Farbfläche in der Spielart-Farbe); gewählte andere Tische bleiben
        case .linen: Design.ist(.klar) ? Theme.dynamic(0xE4F2EA, 0x0F1A14) : (Design.ist(.tinte) ? Color(hex: 0x1F4A38) : Color.appFlaeche)
        case .felt: Theme.dynamic(0x2E5B45, 0x173126)
        case .navy: Theme.dynamic(0x22344D, 0x121B28)
        case .slate: Theme.dynamic(0x5A5F66, 0x24272B)
        case .photo: Theme.dynamic(0x3A3A3A, 0x1E1E1E)       // solange kein Foto geladen ist
        case .spring: Theme.dynamic(0xD5E3CF, 0x1B261C)      // zartes Salbeigrün
        case .summer: Theme.dynamic(0xEBDDB5, 0x2A2214)      // warmer Sand
        case .autumn: Theme.dynamic(0xA8672F, 0x2A180C)      // Bernstein und Rost
        case .winter: Theme.dynamic(0x6F7C89, 0x1A222B)      // kühles Blaugrau
        }
    }

    /// Alle dunklen bzw. kräftigen Tische: Texte und Plätze in Weiß. Leinen, Frühling und Sommer sind hell (Texte folgen hell/dunkel).
    var lightText: Bool { self == .linen ? !Design.ist(.klar) : ![.spring, .summer].contains(self) }
    var tint: Color { lightText ? .white : .primary }
}

extension CardBackStyle {
    /// Rücken und Tisch zu ähnlich (Retro-Karo auf Filz und Nachtblau, Nachtblau auf Nachtblau): Rücken bekommt einen weißen Rand
    func needsContrastBorder(on table: TableStyle) -> Bool {
        switch table {
        case .photo: true
        case .felt, .navy: self == .retro || (self == .navy && table == .navy)
        case .spring: self == .retro                           // grün auf zartem Grün
        case .autumn: self == .gold || self == .bordeaux       // goldbraun/rot auf Bernstein-Rost
        case .winter: self == .navy                            // Blau auf Blaugrau
        case .linen, .slate, .summer: false
        }
    }
}

private struct CardBackStyleKey: EnvironmentKey { static let defaultValue = CardBackStyle.gold }
private struct LargeCardIndexKey: EnvironmentKey { static let defaultValue = false }
private struct TablePhotoKey: EnvironmentKey { static let defaultValue: UIImage? = nil }
private struct TableStyleKey: EnvironmentKey { static let defaultValue = TableStyle.linen }

extension EnvironmentValues {
    var cardBackStyle: CardBackStyle {
        get { self[CardBackStyleKey.self] }
        set { self[CardBackStyleKey.self] = newValue }
    }
    /// Kartengröße „Groß“: Index der normalen Karten 1,25-fach
    var largeCardIndex: Bool {
        get { self[LargeCardIndexKey.self] }
        set { self[LargeCardIndexKey.self] = newValue }
    }
    /// Das gewählte Tischfoto (nil, wenn keines geladen ist)
    var tablePhoto: UIImage? {
        get { self[TablePhotoKey.self] }
        set { self[TablePhotoKey.self] = newValue }
    }
    var tableStyle: TableStyle {
        get { self[TableStyleKey.self] }
        set { self[TableStyleKey.self] = newValue }
    }
}

/// Tischfläche; Filz mit feinem Rauschen (3 %)
struct TableBackground: View {
    let style: TableStyle
    @Environment(\.tablePhoto) private var photo

    var body: some View {
        ZStack {
            style.color
            // F-AWS-K-026: Salon-Tisch in der Spielart-Farbe um 22 % abgedunkelt, damit Titel, Chips und Leiste in Creme mindestens 4,5:1 erreichen
            if style == .linen && Design.ist(.salon) { Color.black.opacity(0.22) }
            if style == .photo, let photo {
                GeometryReader { geo in
                    Image(uiImage: photo).resizable().scaledToFill().frame(width: geo.size.width, height: geo.size.height).clipped()
                }
            }
            // Design-Runde 3 (Tinte): keine Rahmenlinie mehr rund um den Tisch; der Filz geht bis in die runden Ecken des Bildschirms.
            if style == .summer {
                // leichter Verlauf von oben
                LinearGradient(colors: [.white.opacity(0.22), .clear], startPoint: .top, endPoint: .bottom).allowsHitTesting(false)
            }
            if style.isSeason, style != .summer {
                Image(uiImage: Self.seasonTile(style))
                    .resizable(resizingMode: .tile)
                    .opacity(style == .autumn ? 0.04 / 0.5 : 0.05 / 0.5)       // Muster selbst 50 % deckend; sehr dezent
                    .allowsHitTesting(false)
            }
            if style == .felt {
                Image(uiImage: Self.noise)
                    .resizable(resizingMode: .tile)
                    .opacity(0.03 / 0.5)       // Punkte sind selbst 50 % deckend
                    .allowsHitTesting(false)
            }
        }
    }

    /// Dezentes Muster der Jahreszeit als 120 × 120 pt Kachel (feste Zufallsfolge): Blüten, Blätter, Schneepunkte
    private static var tiles: [TableStyle: UIImage] = [:]
    private static func seasonTile(_ style: TableStyle) -> UIImage {
        if let t = tiles[style] { return t }
        let size = CGSize(width: 120, height: 120)
        let image = UIGraphicsImageRenderer(size: size).image { ctx in
            var state: UInt64 = 0xC0_FFEE ^ (style == .spring ? 1 : style == .autumn ? 2 : 3)
            func next() -> CGFloat {
                state = state &* 6364136223846793005 &+ 1442695040888963407
                return CGFloat(state >> 40) / CGFloat(1 << 24)
            }
            let cg = ctx.cgContext
            UIColor.white.withAlphaComponent(0.5).setFill()
            switch style {
            case .spring:       // kleine Blüten: fünf Punkte um eine Mitte
                for _ in 0..<7 {
                    let c = CGPoint(x: next() * 110 + 5, y: next() * 110 + 5)
                    for k in 0..<5 {
                        let a = CGFloat(k) * 2 * .pi / 5
                        cg.fillEllipse(in: CGRect(x: c.x + cos(a) * 3 - 1.6, y: c.y + sin(a) * 3 - 1.6, width: 3.2, height: 3.2))
                    }
                }
            case .autumn:       // wenige Blattformen (Ellipsen, gedreht)
                UIColor.black.withAlphaComponent(0.5).setFill()
                for _ in 0..<4 {
                    cg.saveGState()
                    cg.translateBy(x: next() * 100 + 10, y: next() * 100 + 10)
                    cg.rotate(by: next() * .pi)
                    cg.fillEllipse(in: CGRect(x: -7, y: -3.5, width: 14, height: 7))
                    cg.restoreGState()
                }
            default:            // Winter: feine Schneepunkte
                for _ in 0..<22 {
                    let r = 0.8 + next() * 1.2
                    cg.fillEllipse(in: CGRect(x: next() * 118, y: next() * 118, width: r * 2, height: r * 2))
                }
            }
        }
        tiles[style] = image
        return image
    }

    /// 64 × 64 pt Rauschen, einmal im Code erzeugt (feste Zufallsfolge, damit es immer gleich aussieht)
    private static let noise: UIImage = {
        let size = CGSize(width: 64, height: 64)
        return UIGraphicsImageRenderer(size: size).image { ctx in
            var state: UInt64 = 0x9E37_79B9_7F4A_7C15
            func next() -> Double {
                state = state &* 6364136223846793005 &+ 1442695040888963407
                return Double(state >> 40) / Double(1 << 24)
            }
            for _ in 0..<700 {
                let white = next() < 0.5
                (white ? UIColor.white : UIColor.black).withAlphaComponent(0.5).setFill()
                ctx.fill(CGRect(x: (next() * 64).rounded(.down), y: (next() * 64).rounded(.down), width: 1, height: 1))
            }
        }
    }()
}

/// Das Muster eines Rückens (ohne Rand), für die Vorschau und für den Tisch
struct CardBackArt: View {
    let style: CardBackStyle
    let width: CGFloat

    var body: some View {
        let radius = Theme.cardRadius(width)
        let creme = Color.white.opacity(0.85)
        ZStack {
            // Designwechsel D.2: Der Standard-Rücken folgt in Tinte und Salon dem Rücken des Kartenstils; gewählte andere Rücken bleiben.
            if style == .gold && !KartenStil.ist(.klar) {
                // Salon: Der Standard-Tisch steht selbst in der Spielart-Farbe, deshalb Espresso mit Creme-Rahmen; Tinte: Rand wie die Vorderseiten
                KartenRuecken(breite: width, ecke: radius, fuellung: KartenStil.ist(.salon) ? KartenStil.aktuell.schwarz : nil)
                    .overlay(RoundedRectangle(cornerRadius: radius).strokeBorder(Theme.cardEdge, lineWidth: Theme.cardEdgeWidth))
            } else {
            RoundedRectangle(cornerRadius: radius).fill(style.base)
            switch style {
            case .gold:
                // Klar & Glas: flach in App-Farbe, weißer Innenrand 2 pt
                RoundedRectangle(cornerRadius: radius * 0.6).strokeBorder(.white.opacity(0.9), lineWidth: 2).padding(4)
            case .navy:
                Canvas { ctx, size in
                    var path = Path()
                    var y: CGFloat = 0
                    while y < size.height { path.move(to: CGPoint(x: 0, y: y)); path.addLine(to: CGPoint(x: size.width, y: y)); y += 3 }
                    ctx.stroke(path, with: .color(.white.opacity(0.18)), lineWidth: 0.5)
                }
                .clipShape(RoundedRectangle(cornerRadius: radius * 0.6))
                .padding(3)
                RoundedRectangle(cornerRadius: radius * 0.6).strokeBorder(.white.opacity(0.45), lineWidth: 1).padding(3)
            case .bordeaux:
                Canvas { ctx, size in
                    var y: CGFloat = 2
                    while y < size.height {
                        var x: CGFloat = 2
                        while x < size.width {
                            ctx.fill(Path(ellipseIn: CGRect(x: x - 0.5, y: y - 0.5, width: 1, height: 1)), with: .color(creme.opacity(0.30)))
                            x += 4
                        }
                        y += 4
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: radius * 0.6))
                .padding(3)
                // doppelter Rand: 2 pt außen, 1 pt innen
                RoundedRectangle(cornerRadius: radius * 0.8).strokeBorder(creme.opacity(0.55), lineWidth: 2).padding(2)
                RoundedRectangle(cornerRadius: radius * 0.5).strokeBorder(creme.opacity(0.55), lineWidth: 1).padding(5.5)
            case .retro:
                let light = Theme.dynamic(0x387A5B, 0x255640)     // Grundfarbe +8 % Helligkeit
                Canvas { ctx, size in
                    let cell: CGFloat = 6
                    for row in 0..<Int((size.height / cell).rounded(.up)) {
                        for col in 0..<Int((size.width / cell).rounded(.up)) where (row + col) % 2 == 0 {
                            ctx.fill(Path(CGRect(x: CGFloat(col) * cell, y: CGFloat(row) * cell, width: cell, height: cell)), with: .color(light))
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: radius * 0.6))
                .padding(4)
                RoundedRectangle(cornerRadius: radius * 0.8).strokeBorder(.white.opacity(0.85), lineWidth: 4)
            }
            RoundedRectangle(cornerRadius: radius).strokeBorder(Theme.cardEdge, lineWidth: Theme.cardEdgeWidth)
            }
        }
    }
}
