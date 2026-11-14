// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// design:spielinhalt-datei – Ergebnisseite (Blatt 22, EB-3): das Brett am Ende mit den vier markierten Steinen
#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern

/// Das Brett am Ende, nur lesen: dieselben Bauteile wie am Tisch (Glasplatte und Linsen in Salon, sonst flaches Brett mit Steinen),
/// die Gewinnreihe mit weißem Ring. Nimmt nur Werte entgegen (Stellung als Brett, Gewinnzellen), keine Bindungen, keine Gesten.
struct VierEndeBild: View {
    /// `brett[spalte][zeile]`: 0 = leer, 1 = Rot, 2 = Blau
    let brett: [[Int]]
    let reihen: Set<Zelle>
    let groesse: CGSize
    @Environment(\.designArt) private var art
    @Environment(\.colorScheme) private var farbschema
    @Environment(\.accessibilityReduceTransparency) private var transparenzReduziert
    @Environment(\.farbenUnterscheidbar) private var farbenUnterscheidbar

    init(partie: Partie, groesse: CGSize) {
        brett = partie.brett
        reihen = Set(partie.gewinnZellen)
        self.groesse = groesse
    }

    private var werte: BrettWerte { BrettWerte(art: art, dunkel: farbschema == .dark, transparenzReduziert: transparenzReduziert) }
    private func steinFarbe(_ spieler: Int) -> Color { spieler == 1 ? Color(.systemRed) : Color(.systemBlue) }

    var body: some View {
        let w = werte
        let kante = max(12, floor(min(groesse.width / CGFloat(Partie.spalten), (groesse.height - w.sockel) / CGFloat(Partie.zeilen))))
        let breite = kante * CGFloat(Partie.spalten)
        let hoehe = kante * CGFloat(Partie.zeilen)
        ZStack(alignment: .topLeading) {
            if w.glas {
                GlasPlatte(werte: w, spalten: Partie.spalten, zeilen: Partie.zeilen, kante: kante, glasFarbe: Color.appFlaeche)
            } else {
                RoundedRectangle(cornerRadius: w.radius).fill(w.flaeche).frame(width: breite, height: hoehe + w.sockel)
                if art == .tinte { RoundedRectangle(cornerRadius: w.radius).strokeBorder(Color.linieStark, lineWidth: BrettWerte.tintenLinie).frame(width: breite, height: hoehe) }
                if w.sockel > 0 { Rectangle().fill(w.brettDunkel).frame(width: breite, height: w.sockel).offset(y: hoehe) }
            }
            ForEach(0..<Partie.spalten, id: \.self) { s in
                ForEach(0..<Partie.zeilen, id: \.self) { z in
                    let besitzer = brett[s][z]
                    ZStack {
                        if !w.glas {
                            Circle().fill(w.loch).padding(w.lochAbstand(kante))
                                .overlay { if w.gestanzt { Circle().strokeBorder(w.lochLinie, lineWidth: w.lochLinieBreite).padding(w.lochAbstand(kante)) } }
                        }
                        if besitzer != 0 {
                            stein(besitzer, kante: kante, w: w)
                                .overlay { if reihen.contains(Zelle(spalte: s, zeile: z)) { Circle().strokeBorder(.white, lineWidth: 3).padding(w.steinAbstand(kante)) } }
                        }
                    }
                    .frame(width: kante, height: kante)
                    .offset(x: CGFloat(s) * kante, y: CGFloat(Partie.zeilen - 1 - z) * kante)
                }
            }
        }
        .frame(width: breite, height: hoehe + (w.glas ? 0 : w.sockel), alignment: .topLeading)
        .clipShape(.rect(cornerRadius: w.glas ? Glas.radius : w.radius))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func stein(_ spieler: Int, kante: CGFloat, w: BrettWerte) -> some View {
        if w.glas {
            GlasLinse(farbe: steinFarbe(spieler), durchmesser: kante * w.steinAnteil)
                .overlay { if farbenUnterscheidbar && spieler == 2 { Circle().strokeBorder(.white.opacity(0.85), lineWidth: kante * 0.07).padding(kante * 0.24) } }
                .frame(width: kante, height: kante)
        } else {
            Circle().fill(steinFarbe(spieler)).padding(w.steinAbstand(kante))
                .overlay { if w.gestanzt { Circle().strokeBorder(BrettWerte.abdunkeln(steinFarbe(spieler), BrettWerte.steinDunkler), lineWidth: BrettWerte.steinRing).padding(w.steinAbstand(kante) + kante * 0.07) } }
                .overlay { if art == .klar && w.dunkel { Circle().strokeBorder(.white.opacity(0.55), lineWidth: 1.5).padding(w.steinAbstand(kante)) } }
                .overlay { if farbenUnterscheidbar && spieler == 2 { Circle().strokeBorder(.white.opacity(0.85), lineWidth: kante * 0.07).padding(kante * 0.24) } }
                .frame(width: kante, height: kante)
        }
    }
}
#endif
