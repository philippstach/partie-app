// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

// B3 Gegenüber-Modus: Zwei Menschen sitzen sich am selben Gerät gegenüber (iPhone flach auf dem Tisch, iPad im Tischmodus).
// Das Brett bleibt in der Mitte; oben steht das Band des gegenübersitzenden Spielers, um 180° gedreht, unten das eigene.

public enum GegenueberEinstellung {
    public static let schluessel = "partie.gegenueber"
    /// Standard: an. Wirkt nur, wenn genau zwei Menschen ohne Computer am Gerät spielen.
    public static func aktiv(defaults: UserDefaults = .standard) -> Bool { defaults.object(forKey: schluessel) as? Bool ?? true }
    /// Gilt der Modus? Genau zwei Teilnehmer, davon kein Computer.
    public static func gilt(teilnehmer: Int, computer: Int, eingeschaltet: Bool) -> Bool {
        eingeschaltet && teilnehmer == 2 && computer == 0
    }
}

#if canImport(UIKit)
import SwiftUI
import KlarGlas

public extension GegenueberEinstellung {
    static func gilt(fuer teilnehmer: [SpielTeilnehmer], eingeschaltet: Bool) -> Bool {
        gilt(teilnehmer: teilnehmer.count, computer: teilnehmer.filter(\.computer).count, eingeschaltet: eingeschaltet)
    }
}

/// Schalter für die Einstellungen (in eine `Form`/`Section` setzen).
public struct GegenueberSchalter: View {
    @AppStorage(GegenueberEinstellung.schluessel) private var aktiv = true
    public init() {}
    public var body: some View {
        Toggle(isOn: $aktiv) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Zu zweit gegenüber sitzen")
                Text("Bei Brettspielen für zwei Personen am selben Gerät steht ein Band mit Namen und Hinweis auch auf dem Kopf für die Person gegenüber.").font(.footnote).foregroundStyle(.secondary)
            }
        }
    }
}

/// Ein Band mit Name, Farbe und Hinweis eines Spielers.
public struct GegenueberBand: View {
    let name: String
    let farbe: Color
    let hinweis: LocalizedStringKey
    let dran: Bool
    /// Knopf dieses Spielers (z. B. „Münzen werfen“), wird nur gezeigt, wenn er dran ist.
    let knopf: AnyView?
    @Environment(\.designArt) private var art   // W2-K: zeichnet beim Designwechsel neu
    public init(name: String, farbe: Color, hinweis: LocalizedStringKey, dran: Bool, knopf: AnyView? = nil) { self.name = name; self.farbe = farbe; self.hinweis = hinweis; self.dran = dran; self.knopf = knopf }

    /// Blatt 21 (W2-K): In Tinte liegt das Band hell auf dem Filz, unabhängig von der Spielerfarbe (Mühle gibt Grau und Schwarz herein).
    private var tinte: Bool { art == .tinte }

    public var body: some View {
        HStack(spacing: 10) {
            SpielerAvatar(name: name, farbe: farbe, groesse: 32)
            VStack(alignment: .leading, spacing: 1) {
                if tinte {
                    Text(verbatim: name).font(.subheadline.weight(dran ? .semibold : .regular)).lineLimit(1)
                        .foregroundStyle(dran ? Tisch.elfenbein : Tisch.hinweisLeise)
                    if dran { Text(hinweis).font(.footnote).foregroundStyle(Tisch.hinweis).lineLimit(2) }
                } else {
                    Text(verbatim: name).font(.subheadline.weight(dran ? .semibold : .regular)).lineLimit(1)
                    if dran { Text(hinweis).font(.footnote).foregroundStyle(.secondary).lineLimit(2) }
                }
            }
            Spacer(minLength: 4)
            if dran, let knopf { knopf }
            if dran { Image(systemName: "circle.fill").font(.caption2).foregroundStyle(farbe).accessibilityHidden(true) }
        }
        .padding(.horizontal, 12).padding(.vertical, 8).frame(minHeight: 48)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(grund))
    }

    /// Grund des Bands: Tinte hell (Elfenbein 16 % dran, sonst 9 %); Klar und Salon wie bisher.
    private var grund: Color {
        if tinte { return Tisch.elfenbein.opacity(dran ? 0.16 : 0.09) }
        return dran ? farbe.opacity(0.14) : Color.kartenGrund
    }
}

public extension View {
    /// Legt bei aktivem Gegenüber-Modus ein Band für den oberen Spieler (um 180° gedreht, für VoiceOver verborgen) über und das Band
    /// des unteren Spielers unter die Spielansicht. Ist der Modus aus, bleibt die Ansicht unverändert.
    func gegenueberModus(aktiv: Bool, oben: GegenueberBand, unten: GegenueberBand) -> some View {
        modifier(GegenueberModus(aktiv: aktiv, oben: oben, unten: unten))
    }
}

struct GegenueberModus: ViewModifier {
    let aktiv: Bool
    let oben: GegenueberBand
    let unten: GegenueberBand
    func body(content: Content) -> some View {
        if aktiv {
            VStack(spacing: Design.Abstand.s) {
                oben.rotationEffect(.degrees(180)).accessibilityHidden(true)
                content
                unten
            }
            .padding(.horizontal, Theme.seitenRand)
        } else {
            content
        }
    }
}
#endif
