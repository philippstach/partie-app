// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
#if canImport(UIKit)
import SwiftUI
import KlarGlas

// Große Tinte-Runde, Punkt 5: „Gerät weitergeben“ sieht in allen Spielen gleich aus, als ganze Filzseite wie in Herzensjagd.
// Die `SichtschutzKarte` meldet ihren Wunsch nach oben, `aufTisch()` legt die Seite über die ganze Spielansicht. Die Spiele ändern nichts.

/// Was eine `SichtschutzKarte` vom Spieltisch braucht: den Namen und die Bestätigung.
struct SichtschutzWunsch {
    let name: String
    let farbe: Color?
    let aufdecken: () -> Void
}

struct SichtschutzWunschKey: PreferenceKey {
    static var defaultValue: SichtschutzWunsch? { nil }
    static func reduce(value: inout SichtschutzWunsch?, nextValue: () -> SichtschutzWunsch?) { value = nextValue() ?? value }
}

/// Ganze Filzseite „Gerät weitergeben“ (Tinte): Bild der Person, „… ist dran.“, unten der eine Knopf. Gleicher Aufbau wie die
/// `UebergabeSeite` in SpielHilfen (Herzensjagd). Liegt über der Spielansicht und deckt sie ganz ab.
struct SichtschutzSeite: View {
    let name: String
    var farbe: Color? = nil
    let aufdecken: () -> Void

    var body: some View {
        VStack(spacing: Design.Abstand.m) {
            Spacer(minLength: 0)
            SpielerAvatar(name: name, farbe: farbe, groesse: 96).accessibilityHidden(true)
            Text("Gerät weitergeben").designLabel().padding(.top, Design.Abstand.m)
            Text("\(name) ist dran.").font(Design.Schrift.serif(34, gewicht: .medium, relativ: .title, hoechstens: 1.2))
                .foregroundStyle(Color.schrift).multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            Text("Nur \(name) darf jetzt hinsehen.").font(Design.Schrift.serif(18, gewicht: .light, relativ: .body, kursiv: true))
                .foregroundStyle(Tisch.hinweis).multilineTextAlignment(.center)
            Spacer(minLength: 0)
            Spacer(minLength: 0)
            Button("Ich bin \(name)") { aufdecken() }.buttonStyle(HauptKnopfStil())
        }
        .padding(Theme.seitenRand)
        .iPadSpalte()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(TischGrund().ignoresSafeArea())   // voll deckend: nichts vom Tisch schimmert durch
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)   // VoiceOver bleibt auf der Seite, der Tisch darunter ist nicht erreichbar
    }
}

// B2 Sichtschutz
/// Zwischenbildschirm „Gerät an <Name> geben“ für Spiele mit verdeckten Karten oder Würfeln. Ersetzt die Hand-Anzeige,
/// solange der Name noch nicht bestätigt hat. Gleicher Aufbau und gleiche Texte in allen Spielen.
public struct SichtschutzKarte: View {
    let name: String
    let farbe: Color?
    let aufdecken: () -> Void
    /// `farbe`: Farbe der Person (`Spieler.farbe(i)`), damit das Bild auf der Seite „Gerät weitergeben“ wie die Spielerleiste gefärbt ist.
    public init(name: String, farbe: Color? = nil, aufdecken: @escaping () -> Void) { self.name = name; self.farbe = farbe; self.aufdecken = aufdecken }
    @Environment(\.designArt) private var art

    public var body: some View {
        switch art {
        case .klar: klar
        case .tinte:
            // Papierseite mit der Zeile „Gerät an Ben“
            VStack(alignment: .leading, spacing: Design.Abstand.m) {
                Text("Gerät an \(name) geben").font(Design.Schrift.serif(26, gewicht: .medium, relativ: .title2)).foregroundStyle(Color.schrift)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading).linieUnten(stark: true, staerke: 1.5)
                Text("Nur \(name) darf jetzt hinsehen.").font(Design.Schrift.neben).foregroundStyle(Color.schriftZweit)
                Button("Ich bin \(name)") { aufdecken() }.buttonStyle(HauptKnopfStil())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .contain)
            // Punkt 5: Liegt das Spiel auf dem Filz (`aufTisch()`), zeigt der Tisch stattdessen die ganze Filzseite; diese Zeile bleibt darunter.
            .preference(key: SichtschutzWunschKey.self, value: SichtschutzWunsch(name: name, farbe: farbe, aufdecken: aufdecken))
        case .salon:
            // Farbfeld in der Spielart-Farbe mit dem Namen als Schlagzeile („Ben.“)
            let farben = Design.spielFarben
            let schrift = farben?.aufFlaeche ?? Design.werte.aufHuelleFlaeche.color
            VStack(alignment: .leading, spacing: Design.Abstand.s) {
                Text("Gerät an \(name) geben").designLabel(schrift).opacity(0.9)
                Text(verbatim: "\(name).").font(Design.Schrift.serif(64, gewicht: .bold, relativ: .largeTitle, hoechstens: 1.2)).tracking(-1.9)
                    .lineLimit(2).minimumScaleFactor(0.4).accessibilityHidden(true)
                Text("Nur \(name) darf jetzt hinsehen.").font(Design.Schrift.serif(18, gewicht: .light, relativ: .body, kursiv: true))
                Button("Ich bin \(name)") { aufdecken() }.buttonStyle(HauptKnopfStil())
                    .environment(\.knopfFarben, (flaeche: schrift, schrift: farben?.flaecheFuerKleineSchrift ?? Color.hinweisFlaecheHuelle))
                    .padding(.top, Design.Abstand.s)
            }
            .foregroundStyle(schrift)
            .padding(Theme.seitenRand)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(farben?.flaecheFuerKleineSchrift ?? Color.hinweisFlaecheHuelle)
            .accessibilityElement(children: .contain)
        }
    }

    private var klar: some View {
        VStack(spacing: Design.Abstand.s) {
            Image(systemName: "hand.raised.fill").font(.title2).foregroundStyle(.secondary).accessibilityHidden(true)
            Text("Gerät an \(name) geben").font(.headline).multilineTextAlignment(.center)
            Text("Nur \(name) darf jetzt hinsehen.").font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
            Button("Ich bin \(name)") { aufdecken() }.buttonStyle(HauptKnopfStil())
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
    }
}
#endif
