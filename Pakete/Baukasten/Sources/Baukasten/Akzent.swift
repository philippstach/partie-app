// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI

/// Eine wählbare App-Farbe. Die Werte sind vorab auf Kontrast geprüft (Tests: `AkzentTests`):
/// Weiß auf `flaeche` mindestens 3:1, `textHell` auf Weiß und `textDunkel` auf #1C1C1E mindestens 4,5:1.
/// Quelle der Werte ist die Tabelle A.1 in `DESIGN.md` (dieselben Hex wie `design_pruefung.py` SOLL und `accenttext_soll.json`).
public struct AkzentFarbe: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    let flaecheHex: UInt32
    let textHellHex: UInt32
    let textDunkelHex: UInt32

    public var flaeche: Color { Color(hex: flaecheHex) }
    public func text(_ schema: ColorScheme) -> Color { Color(hex: schema == .dark ? textDunkelHex : textHellHex) }
    public var weicheFlaeche: Color { flaeche.opacity(0.12) }

    static func f(_ id: String, _ name: String, _ a: UInt32, _ h: UInt32, _ d: UInt32) -> AkzentFarbe {
        AkzentFarbe(id: id, name: name, flaecheHex: a, textHellHex: h, textDunkelHex: d)
    }

    /// Die elf Farben der Spielefamilie (E8, 04.11.2026). Jede App bietet alle an; ihre eigene ist die Voreinstellung.
    public static let blau = f("blau", "Blau", 0x2F6FEB, 0x275BC1, 0x77A1F2)            // Sudoku
    public static let orange = f("orange", "Orange", 0xF26B1D, 0xA24813, 0xF5894A)      // 10k
    public static let gruen = f("gruen", "Grün", 0x14A06F, 0x0E704E, 0x4CB792)          // Solitär
    public static let rot = f("rot", "Rot", 0xE5484D, 0xAD363A, 0xED8285)               // Viererreihe
    public static let violett = f("violett", "Violett", 0x7A52D1, 0x6D49BB, 0xAC93E2)   // Galgenmännchen
    public static let pink = f("pink", "Pink", 0xC2398A, 0xA63176, 0xD985B7)            // Wortpfeil
    public static let tuerkis = f("tuerkis", "Türkis", 0x0C8599, 0x0A6A7A, 0x5DAEBB)    // Rauswurf
    public static let braun = f("braun", "Braun", 0x9A5B2E, 0x8B522A, 0xC0987C)         // Schocken (Leder)
    public static let indigo = f("indigo", "Indigo", 0x4B4ACF, 0x4B4ACF, 0x9897E3)      // Yacht
    public static let schiefer = f("schiefer", "Schiefer", 0x4F6377, 0x4E6276, 0x95A1AD) // Minensuche (E10)
    public static let limette = f("limette", "Limette", 0x5E8F00, 0x476C00, 0x8CAF49)   // Farbrätsel

    public static let alle: [AkzentFarbe] = [blau, orange, gruen, rot, violett, pink, tuerkis, braun, indigo, schiefer, limette]

    public static func mitID(_ id: String?) -> AkzentFarbe? { alle.first { $0.id == id } }
}

/// Merkt sich die gewählte Farbe pro App (UserDefaults). `standard` ist die Farbe der App (Mockup-Hex).
@Observable
@MainActor
public final class AkzentSpeicher {
    public static let schluessel = "baukasten.akzent"
    public let standard: AkzentFarbe
    private let speicher: WerteSpeicher

    public var gewaehlt: AkzentFarbe {
        didSet { speicher.set(gewaehlt == standard ? nil : gewaehlt.id, forKey: Self.schluessel) }
    }

    public init(standard: AkzentFarbe, speicher: WerteSpeicher = UserDefaults.standard) {
        self.standard = standard
        self.speicher = speicher
        gewaehlt = AkzentFarbe.mitID(speicher.object(forKey: Self.schluessel) as? String) ?? standard
    }
}

private struct AkzentKey: EnvironmentKey { static let defaultValue = AkzentFarbe.blau }

public extension EnvironmentValues {
    var akzent: AkzentFarbe {
        get { self[AkzentKey.self] }
        set { self[AkzentKey.self] = newValue }
    }
}

public extension View {
    /// Einmal ganz oben im App-Fenster: setzt Tint (Knöpfe, Schalter) und die Baukasten-Umgebung.
    func baukastenAkzent(_ farbe: AkzentFarbe) -> some View {
        environment(\.akzent, farbe).tint(farbe.flaeche)
    }

    /// App-Farbe als kleiner Text (Zahlen, Links): die abgedunkelte/aufgehellte Textvariante.
    func akzentText() -> some View { modifier(AkzentTextStil()) }
}

private struct AkzentTextStil: ViewModifier {
    @Environment(\.akzent) private var akzent
    @Environment(\.colorScheme) private var schema
    func body(content: Content) -> some View { content.foregroundStyle(akzent.text(schema)) }
}

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }
}

/// WCAG-Kontrast, für Tests und Prüfungen neuer Farben.
public enum Kontrast {
    public static func leuchtdichte(_ hex: UInt32) -> Double {
        func kanal(_ s: UInt32) -> Double {
            let v = Double((hex >> s) & 0xFF) / 255
            return v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * kanal(16) + 0.7152 * kanal(8) + 0.0722 * kanal(0)
    }

    public static func verhaeltnis(_ a: UInt32, _ b: UInt32) -> Double {
        let (hell, dunkel) = (max(leuchtdichte(a), leuchtdichte(b)), min(leuchtdichte(a), leuchtdichte(b)))
        return (hell + 0.05) / (dunkel + 0.05)
    }
}

extension AkzentFarbe {
    var pruefwerte: (flaeche: UInt32, hell: UInt32, dunkel: UInt32) { (flaecheHex, textHellHex, textDunkelHex) }
}

/// Zeile für „Aussehen“ direkt unter der Darstellung: Farbpunkte zum Antippen.
public struct AkzentAuswahl: View {
    @Bindable var speicher: AkzentSpeicher
    /// Farben (`AkzentFarbe.id`), die in dieser App nicht wählbar sind, z. B. weil sie Spielerfarben zu ähnlich sehen
    let ausgenommen: Set<String>
    public init(speicher: AkzentSpeicher, ausgenommen: Set<String> = []) {
        self.speicher = speicher; self.ausgenommen = ausgenommen
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("App-Farbe", bundle: .module)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 44), spacing: 8)], spacing: 8) {
                ForEach(AkzentFarbe.alle.filter { !ausgenommen.contains($0.id) }) { farbe in
                    Button { speicher.gewaehlt = farbe } label: {
                        Circle().fill(farbe.flaeche)
                            .frame(width: 32, height: 32)
                            .overlay { if farbe == speicher.gewaehlt { Image(systemName: "checkmark").font(.footnote.bold()).foregroundStyle(.white) } }
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(LocalizedStringKey(farbe.name), bundle: .module))
                    .accessibilityAddTraits(farbe == speicher.gewaehlt ? .isSelected : [])
                }
            }
            if speicher.gewaehlt != speicher.standard {
                Button { speicher.gewaehlt = speicher.standard } label: { Text("Zurücksetzen", bundle: .module) }
                    .font(.footnote)
            }
        }
    }
}
