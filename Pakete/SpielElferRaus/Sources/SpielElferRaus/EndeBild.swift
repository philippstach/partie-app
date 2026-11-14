// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// design:spielinhalt-datei – Ergebnisseite Elfer raus (Blatt 22, Paket EB-1, Schritt 1). Nicht syntaxgeprüft.
#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern

/// Bild vom Ende: die vier Farbreihen wie am Tisch, verkleinert (ausgelegte Felder gefüllt, offene als dünner Rahmen).
/// Nimmt nur Werte (Reihen, Wertebereich, Variante), keine Bindungen und keine Gesten.
enum ElferEndeBild {
    static func bild(reihen: [ClosedRange<Int>?], werte: ClosedRange<Int>, variante v: ErVariante) -> EndeBild {
        EndeBild(Text("Die vier Reihen am Ende"), hoehe: 150) { groesse in
            let alle = Array(werte)
            let zeilenJeFarbe = alle.count > 10 ? 2 : 1
            let jeZeile = (alle.count + zeilenJeFarbe - 1) / zeilenJeFarbe
            let marke: CGFloat = 20, abstand: CGFloat = 3
            let slotB = (groesse.width - marke - 6 - CGFloat(jeZeile - 1) * abstand) / CGFloat(jeZeile)
            let reiheH = (groesse.height - 3 * 6) / 4
            let slotH = max(min((reiheH - CGFloat(zeilenJeFarbe - 1) * 3) / CGFloat(zeilenJeFarbe), slotB * 2.0, 40), 10)
            VStack(spacing: 6) {
                ForEach(0..<4, id: \.self) { f in
                    HStack(spacing: 6) {
                        Text(verbatim: ErNamen.zeichen(f, v)).font(.system(size: 13, weight: .bold)).foregroundStyle(farbe(f, v)).frame(width: marke)
                        VStack(spacing: 3) {
                            ForEach(0..<zeilenJeFarbe, id: \.self) { z in
                                HStack(spacing: abstand) {
                                    ForEach(Array(alle[(z * jeZeile)..<min((z + 1) * jeZeile, alle.count)]), id: \.self) { w in
                                        feld(ErKarte(f, w), da: reihen[f]?.contains(w) == true, v: v, breite: slotB, hoehe: slotH)
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxHeight: .infinity)
                }
            }
            .frame(width: groesse.width, height: groesse.height)
        }
    }

    private static func feld(_ k: ErKarte, da: Bool, v: ErVariante, breite: CGFloat, hoehe: CGFloat) -> some View {
        ZStack {
            if da {
                RoundedRectangle(cornerRadius: 3).fill(farbe(k.farbe, v).opacity(v == .echt ? 0.9 : 0.22))
                Text(verbatim: ErNamen.name(k, v)).font(.system(size: max(min(breite * 0.62, 14), 6), weight: .bold, design: Design.zahlDesign))
                    .minimumScaleFactor(0.5).lineLimit(1).foregroundStyle(schriftFarbe(k.farbe, v))
            } else {
                RoundedRectangle(cornerRadius: 3).strokeBorder(Tisch.elfenbein.opacity(0.35), lineWidth: 1)
            }
        }
        .frame(width: breite, height: hoehe)
    }

    // Farben wie am Tisch (ElferNeuSpiel.farbe / schriftFarbe)
    private static func farbe(_ f: Int, _ v: ErVariante) -> Color {
        switch v {
        case .echt:
            if KartenStil.ist(.klar) { return [Color(.systemRed), Color(.systemYellow), Color(.systemGreen), Color(.systemBlue)][f] }
            return [DesignWerte.fuer(KartenStil.aktuell.art).karten?.rot.color ?? FarbPaar(0xB3261E).color, FarbPaar(0xE0A91C).color, FarbPaar(0x2F7D4F).color, FarbPaar(0x2F5FA8).color][f]
        case .kartendomino: return f >= 2 ? Color(.systemRed) : Tisch.elfenbein
        }
    }
    private static func schriftFarbe(_ f: Int, _ v: ErVariante) -> Color { v == .echt && f == 1 ? .black : (v == .echt ? .white : farbe(f, v)) }
}
#endif
