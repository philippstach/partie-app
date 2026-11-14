// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI

/// E8: Tisch-Modus für das iPad. Das iPad liegt flach auf dem Tisch, die Mitspielenden sitzen rundherum. Jede Person bekommt am
/// Rand ihres Platzes ein Namensschild, das zu ihr hin gedreht ist; wer gerade dran ist (meldet das Spiel über `LaufendePartie.zug`),
/// bekommt ein hervorgehobenes Schild. Das Spiel selbst bleibt unverändert in der Mitte.
public enum TischModus {
    public static let schluessel = "partie.tischModus"

    public enum Rand: Equatable, Sendable { case unten, links, oben, rechts }

    public struct Sitz: Equatable, Sendable {
        public let rand: Rand
        /// Drehung des Schilds in Grad (im Uhrzeigersinn), damit es von diesem Platz aus lesbar ist.
        public let grad: Double
    }

    /// Plätze für 2 bis 4 Personen, im Uhrzeigersinn um den Tisch (so wandert der Zug wie am echten Tisch). Sonst leer.
    public static func plaetze(anzahl: Int) -> [Sitz] {
        let unten = Sitz(rand: .unten, grad: 0), links = Sitz(rand: .links, grad: 90)
        let oben = Sitz(rand: .oben, grad: 180), rechts = Sitz(rand: .rechts, grad: -90)
        switch anzahl {
        case 2: return [unten, oben]
        case 3: return [unten, links, rechts]
        case 4: return [unten, links, oben, rechts]
        default: return []
        }
    }

    /// Lohnt der Tisch-Modus? iPad, 2 bis 4 Menschen am Gerät.
    public static func passt(menschen: Int, istIPad: Bool) -> Bool { istIPad && (2...4).contains(menschen) }
}

#if canImport(UIKit)
import UIKit
import KlarGlas

public extension TischModus {
    @MainActor static var istIPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
}

/// Legt Namensschilder um den Inhalt. Die Schilder nehmen am Rand nur ihre schmale Höhe ein.
public struct TischRahmen<Inhalt: View>: View {
    let namen: [String]
    let farbe: (Int) -> Color
    @ViewBuilder let inhalt: () -> Inhalt
    private let halter = LaufendePartie.halter

    public init(namen: [String], farbe: @escaping (Int) -> Color, @ViewBuilder inhalt: @escaping () -> Inhalt) {
        self.namen = namen; self.farbe = farbe; self.inhalt = inhalt
    }

    private var plaetze: [TischModus.Sitz] { TischModus.plaetze(anzahl: namen.count) }

    private func schild(_ i: Int) -> some View {
        let sitz = plaetze[i]
        let amZug = halter.zustand?.amZug == namen[i]
        return Schild(name: namen[i], farbe: farbe(i), amZug: amZug)
            .rotationEffect(.degrees(sitz.grad))
            // Gedrehte Schilder belegen die vertauschte Breite/Höhe: der Rahmen wird nach der Drehung gesetzt
            .fixedSize()
            .frame(maxWidth: sitz.rand == .links || sitz.rand == .rechts ? 56 : .infinity,
                   maxHeight: sitz.rand == .links || sitz.rand == .rechts ? .infinity : 56)
    }

    private func schild(an rand: TischModus.Rand) -> some View {
        Group { if let i = plaetze.firstIndex(where: { $0.rand == rand }) { schild(i) } }
    }

    public var body: some View {
        if plaetze.isEmpty {
            inhalt()
        } else {
            HStack(spacing: 0) {
                schild(an: .links)
                VStack(spacing: 0) {
                    schild(an: .oben)
                    inhalt().frame(maxWidth: .infinity, maxHeight: .infinity)
                    schild(an: .unten)
                }
                schild(an: .rechts)
            }
            .animation(.snappy, value: halter.zustand?.amZug)
        }
    }

    private struct Schild: View {
        let name: String
        let farbe: Color
        let amZug: Bool
        var body: some View {
            HStack(spacing: Design.Abstand.s) {
                Circle().fill(farbe).frame(width: 22, height: 22)
                    .overlay(Text(verbatim: String(name.prefix(1)).uppercased()).font(.caption.bold()).foregroundStyle(.white))
                Text(verbatim: name).font(.headline).lineLimit(1)
                if amZug { Image(systemName: "arrowtriangle.left.fill").font(.caption) }
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(amZug ? farbe.opacity(0.28) : Color.secondary.opacity(0.12), in: Capsule())
            .overlay(Capsule().stroke(amZug ? farbe : .clear, lineWidth: 2))
            .opacity(amZug ? 1 : 0.7)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(amZug ? Text("\(name), ist dran") : Text(verbatim: name))
        }
    }
}
#endif
