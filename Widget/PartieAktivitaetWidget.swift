// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import ActivityKit
import WidgetKit
import SwiftUI
import KlarGlas

// E5: Darstellung der Live Activity. Aussehen schlicht in der Spielfarbe, Zeit läuft über `Text(timerInterval:)` ohne Updates.

struct PartieAktivitaetWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PartieAktivitaet.self) { kontext in
            SperrbildschirmAnsicht(attribute: kontext.attributes, zustand: kontext.state)
                .activityBackgroundTint(SperrStil(kontext.attributes).grund)
                .activitySystemActionForegroundColor(SperrStil(kontext.attributes).schrift)
                .widgetURL(kontext.attributes.link)
        } dynamicIsland: { kontext in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "gamecontroller.fill").font(.title2).foregroundStyle(Color(hex: kontext.attributes.farbeHex))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: kontext.attributes.beginn...Date.distantFuture, countsDown: false)
                        .monospacedDigit().multilineTextAlignment(.trailing).frame(maxWidth: 70)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(verbatim: kontext.attributes.spielName).font(.headline).lineLimit(1)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        zugText(kontext.state, spieler: kontext.attributes.spieler).font(.title3.weight(.semibold))
                        if let stand = kontext.state.stand { Text(verbatim: stand).font(.caption).foregroundStyle(.secondary) }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } compactLeading: {
                Image(systemName: "gamecontroller.fill").foregroundStyle(Color(hex: kontext.attributes.farbeHex))
            } compactTrailing: {
                if let n = kontext.state.amZug { Text(verbatim: String(n.prefix(1)).uppercased()).font(.caption.bold()) }
                else { Text(timerInterval: kontext.attributes.beginn...Date.distantFuture, countsDown: false).monospacedDigit().frame(maxWidth: 44) }
            } minimal: {
                Image(systemName: "gamecontroller.fill").foregroundStyle(Color(hex: kontext.attributes.farbeHex))
            }
            .widgetURL(kontext.attributes.link)
            .keylineTint(Color(hex: kontext.attributes.farbeHex))
        }
    }
}

/// „Anna ist dran“ oder, wenn das Spiel es nicht meldet, die Namen aller Mitspielenden.
@ViewBuilder private func zugText(_ z: PartieAktivitaet.ContentState, spieler: [String]) -> some View {
    if let n = z.amZug { Text("\(n) ist dran") }
    else { Text(verbatim: spieler.joined(separator: " · ")) }
}

/// Farben der Sperrbildschirm-Ansicht je Design (Designwechsel E): klar wie bisher (Spielfarbe, weiße Schrift), Tinte Papier und Tinte,
/// Salon Farbfläche der Spielart mit Creme-Schrift. Die Dynamic Island bleibt schlicht.
private struct SperrStil {
    let stil: WidgetStil
    let attribute: PartieAktivitaet
    init(_ a: PartieAktivitaet) { attribute = a; stil = WidgetStil(roh: PartieGeteilt.design()) }
    var grund: Color { stil.art == .klar ? Color(hex: attribute.farbeHex) : stil.grund(id: attribute.spielID) }
    var schrift: Color { stil.art == .klar ? .white : stil.schrift(id: attribute.spielID) }
    var serif: Bool { stil.art != .klar }
}

private struct SperrbildschirmAnsicht: View {
    let attribute: PartieAktivitaet
    let zustand: PartieAktivitaet.ContentState

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "gamecontroller.fill").font(.title).frame(width: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: attribute.spielName).font(.subheadline).opacity(0.85)
                zugText(zustand, spieler: attribute.spieler).font(.title3.weight(.bold)).lineLimit(1).minimumScaleFactor(0.7)
                if let stand = zustand.stand { Text(verbatim: stand).font(.caption).opacity(0.9).lineLimit(1) }
            }
            Spacer(minLength: 8)
            Text(timerInterval: attribute.beginn...Date.distantFuture, countsDown: false)
                .font(.title3.monospacedDigit()).multilineTextAlignment(.trailing).frame(maxWidth: 76)
        }
        .foregroundStyle(SperrStil(attribute).schrift)
        .fontDesign(SperrStil(attribute).serif ? .serif : nil)
        .padding(16)
    }
}
