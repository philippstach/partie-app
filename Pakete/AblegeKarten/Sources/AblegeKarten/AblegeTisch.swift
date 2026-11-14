// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import CoreGraphics
#if canImport(UIKit)
import SwiftUI
import KlarGlas
#endif

/// Maße und Aufbau-Art eines Ablege-Kartenspiels je Bildschirmgröße (reine Rechnung, mit `swift test` prüfbar).
/// iPhone: SE 375 → Hand 84, Tisch 80; 390 → 100/120; ab 420 (Pro Max) → 112/150. iPad: Tisch 150, Hand 108 (hoch) bzw. 112 (quer, mit Seitenspalte).
public struct AblegeMasse: Equatable, Sendable {
    public enum Aufbau: Sendable { case telefon, padHoch, padQuer }
    public var aufbau: Aufbau
    public var handKarte: CGFloat
    public var tischKarte: CGFloat
    public var seitenspalte: CGFloat
    public var kleinerBildschirm: Bool

    public var handHoehe: CGFloat { handKarte * 1.45 }
    public var tischHoehe: CGFloat { tischKarte * 1.42 }

    public static func berechne(breite: CGFloat, hoehe: CGFloat) -> AblegeMasse {
        if breite >= 700 {
            return hoehe < breite
                ? AblegeMasse(aufbau: .padQuer, handKarte: 112, tischKarte: 150, seitenspalte: 340, kleinerBildschirm: false)
                : AblegeMasse(aufbau: .padHoch, handKarte: 108, tischKarte: 150, seitenspalte: 0, kleinerBildschirm: false)
        }
        if breite < 385 { return AblegeMasse(aufbau: .telefon, handKarte: 84, tischKarte: 80, seitenspalte: 0, kleinerBildschirm: true) }
        if breite < 420 { return AblegeMasse(aufbau: .telefon, handKarte: 100, tischKarte: 120, seitenspalte: 0, kleinerBildschirm: false) }
        return AblegeMasse(aufbau: .telefon, handKarte: 112, tischKarte: 150, seitenspalte: 0, kleinerBildschirm: false)
    }
}

#if canImport(UIKit)
/// Eintrag der Farbwahl: Symbol und Name, damit die Farbe nicht nur an der Tönung hängt.
public struct FarbWahlEintrag: Identifiable {
    public let id: Int
    public let symbol: String
    public let name: LocalizedStringKey
    public let farbe: Color
    public init(id: Int, symbol: String, name: LocalizedStringKey, farbe: Color) { self.id = id; self.symbol = symbol; self.name = name; self.farbe = farbe }
}

/// Vier große Farbknöpfe über der Hand („Farbe wünschen“), statt eines Systemdialogs. Jeder Knopf zeigt Symbol und Namen.
public struct FarbWahlLeiste: View {
    let titel: LocalizedStringKey
    let eintraege: [FarbWahlEintrag]
    let wahl: (Int) -> Void
    @Environment(\.dynamicTypeSize) private var schrift

    public init(titel: LocalizedStringKey, eintraege: [FarbWahlEintrag], wahl: @escaping (Int) -> Void) {
        self.titel = titel; self.eintraege = eintraege; self.wahl = wahl
    }

    public var body: some View {
        VStack(spacing: Design.Abstand.s) {
            Text(titel).font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
            let raster = schrift.isAccessibilitySize ? [GridItem(.flexible())] : Array(repeating: GridItem(.flexible(), spacing: Design.Abstand.s), count: eintraege.count)
            LazyVGrid(columns: raster, spacing: Design.Abstand.s) {
                ForEach(eintraege) { e in
                    Button { wahl(e.id) } label: {
                        VStack(spacing: 2) {
                            Text(verbatim: e.symbol).font(.title).foregroundStyle(e.farbe)   // design:spielinhalt (Kartenfarbsymbol)
                            Text(e.name).font(.caption.weight(.semibold)).foregroundStyle(.primary).lineLimit(1).minimumScaleFactor(0.7)
                        }
                        .frame(maxWidth: .infinity, minHeight: 60)
                        .background(Color.feldGrund, in: RoundedRectangle(cornerRadius: Theme.feldRadius, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: Theme.feldRadius, style: .continuous).strokeBorder(e.farbe.opacity(0.6), lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(e.name))
                }
            }
        }
        .padding(.horizontal, Theme.seitenRand)
        .accessibilityElement(children: .contain)
    }
}

/// Aufbau eines Ablege-Kartenspiels: Kopf, Spielerleiste, Tisch (füllt den Rest), Aktionen, Hand. Auf dem iPad quer steht rechts eine Seitenspalte.
/// Die Inhalte liefert das Spiel und bekommt dazu die Maße.
public struct AblegeTischAufbau<Kopf: View, Leiste: View, Tisch: View, Hand: View, Aktionen: View, Seite: View>: View {
    let kopf: Kopf, leiste: Leiste
    let tisch: (AblegeMasse) -> Tisch
    let hand: (AblegeMasse) -> Hand
    let aktionen: Aktionen
    let seite: (AblegeMasse) -> Seite

    public init(@ViewBuilder kopf: () -> Kopf, @ViewBuilder leiste: () -> Leiste,
                @ViewBuilder tisch: @escaping (AblegeMasse) -> Tisch, @ViewBuilder hand: @escaping (AblegeMasse) -> Hand,
                @ViewBuilder aktionen: () -> Aktionen, @ViewBuilder seite: @escaping (AblegeMasse) -> Seite) {
        self.kopf = kopf(); self.leiste = leiste(); self.tisch = tisch; self.hand = hand; self.aktionen = aktionen(); self.seite = seite
    }

    public var body: some View {
        GeometryReader { g in
            let m = AblegeMasse.berechne(breite: g.size.width, hoehe: g.size.height)
            VStack(spacing: Theme.kartenAbstand) {
                kopf
                if m.aufbau == .padQuer {
                    HStack(alignment: .top, spacing: Theme.kartenAbstand) {
                        VStack(spacing: Theme.kartenAbstand) {
                            tisch(m).frame(maxHeight: .infinity)
                            hand(m)
                            aktionen.padding(.horizontal, Theme.seitenRand)
                        }
                        VStack(spacing: Theme.kartenAbstand) {
                            leiste
                            seite(m).frame(maxHeight: .infinity, alignment: .top)
                        }
                        .frame(width: m.seitenspalte)
                        .padding(.trailing, Theme.seitenRand)
                    }
                } else {
                    leiste
                    tisch(m).frame(maxHeight: .infinity)
                    hand(m)
                    aktionen.padding(.horizontal, Theme.seitenRand)
                }
            }
            .padding(.bottom, 8)
        }
    }
}
#endif
