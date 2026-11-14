// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import UIKit
import KlarGlas
import SpieleKern

/// Brettfläche mit 7 × 6 echten Ausschnitten (even-odd): Die Löcher sind Aussparungen, der Grund scheint durch.
struct GlasForm: Shape {
    let spalten: Int, zeilen: Int
    let kante: CGFloat
    let radius: CGFloat
    let lochAbstand: CGFloat

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addRoundedRect(in: rect, cornerSize: CGSize(width: radius, height: radius))
        for s in 0..<spalten {
            for r in 0..<zeilen {
                p.addEllipse(in: CGRect(x: rect.minX + CGFloat(s) * kante + lochAbstand, y: rect.minY + CGFloat(r) * kante + lochAbstand,
                                        width: kante - 2 * lochAbstand, height: kante - 2 * lochAbstand))
            }
        }
        return p
    }
}

/// Die Glasplatte der Viererreihe (Tinte und Salon): Füllung, Lichtstreifen, Schliffkante, Facette, Lochkanten, Schatten.
/// Alle Werte stehen in `Glas` (BrettWerte.swift). Ohne Material und ohne Unschärfe über die Fläche.
struct GlasPlatte: View {
    let werte: BrettWerte
    let spalten: Int, zeilen: Int
    let kante: CGFloat
    let glasFarbe: Color

    private var breite: CGFloat { kante * CGFloat(spalten) }
    private var hoehe: CGFloat { kante * CGFloat(zeilen) }
    private var abstand: CGFloat { werte.lochAbstand(kante) }
    private var form: GlasForm { GlasForm(spalten: spalten, zeilen: zeilen, kante: kante, radius: Glas.radius, lochAbstand: abstand) }
    private var eo: FillStyle { FillStyle(eoFill: true) }

    var body: some View {
        let f = Glas.fuellung(dunkel: werte.dunkel)
        let sch = Glas.schatten(dunkel: werte.dunkel)
        let auf = Glas.glasAufhellung(dunkel: werte.dunkel)
        let glasFarbe = auf > 0 ? BrettWerte.aufhellen(self.glasFarbe, auf) : self.glasFarbe
        let sd = Glas.streifenDeckkraft(dunkel: werte.dunkel)
        let st = Glas.streifenStuetzen
        ZStack {
            // Grund der leeren Löcher: Seitengrund plus Schwarz (scheint durch die Aussparungen)
            ForEach(0..<(spalten * zeilen), id: \.self) { i in
                Circle().fill(Tisch.aktiv ? Color.clear : Color.seitenGrund).overlay(Circle().fill(Color.black.opacity(Glas.lochSchwarz)))
                    .frame(width: kante - 2 * abstand, height: kante - 2 * abstand)
                    .position(x: CGFloat(i / zeilen) * kante + kante / 2, y: CGFloat(i % zeilen) * kante + kante / 2)
            }
            form.fill(LinearGradient(colors: [glasFarbe.opacity(f.von), glasFarbe.opacity(f.nach)], startPoint: .topLeading, endPoint: .bottomTrailing), style: eo)
                .shadow(color: (werte.dunkel ? Color.black : glasFarbe).opacity(sch.deckkraft), radius: sch.radius, y: sch.y)
            Rectangle().fill(LinearGradient(stops: [.init(color: .white.opacity(0), location: st[0]), .init(color: .white.opacity(sd), location: st[1]), .init(color: .white.opacity(0), location: st[2])], startPoint: .leading, endPoint: .trailing))
                .frame(width: breite * Glas.streifenBreite, height: hoehe * 2)
                .rotationEffect(.degrees(Glas.streifenWinkel))
                .position(x: breite * Glas.streifenLage, y: hoehe / 2)
                .frame(width: breite, height: hoehe)
                .mask(form.fill(style: eo))
            RoundedRectangle(cornerRadius: Glas.radius)
                .strokeBorder(LinearGradient(stops: [.init(color: .white.opacity(Glas.kanteOben), location: 0), .init(color: .white.opacity(Glas.kanteMitte), location: 0.5),
                                                     .init(color: .black.opacity(Glas.kanteUnten), location: 1)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: Glas.kanteBreite)
            RoundedRectangle(cornerRadius: Glas.radius - Glas.facetteAbstand)
                .strokeBorder(Color.white.opacity(Glas.facetteDeckkraft), lineWidth: Glas.facetteBreite)
                .padding(Glas.facetteAbstand)
            ForEach(0..<(spalten * zeilen), id: \.self) { i in
                Circle().strokeBorder(LinearGradient(colors: [.black.opacity(Glas.lochRandOben), .white.opacity(Glas.lochRandUnten)], startPoint: .top, endPoint: .bottom), lineWidth: Glas.lochRand)
                    .frame(width: kante - 2 * abstand, height: kante - 2 * abstand)
                    .position(x: CGFloat(i / zeilen) * kante + kante / 2, y: CGFloat(i % zeilen) * kante + kante / 2)
            }
        }
        .frame(width: breite, height: hoehe)
    }
}

/// Stein als Glaslinse: Verlauf mit Lichtpunkt, Glanzlicht links oben, feiner Rand.
struct GlasLinse: View {
    let farbe: Color
    let durchmesser: CGFloat

    var body: some View {
        let d = durchmesser
        Circle()
            .fill(RadialGradient(colors: [BrettWerte.aufhellen(farbe, Glas.linseHeller), farbe, BrettWerte.abdunkeln(farbe, Glas.linseDunkler)],
                                 center: Glas.linseMitte, startRadius: 0, endRadius: d * Glas.linseRadius))
            .overlay(alignment: .topLeading) {
                Ellipse().fill(Color.white.opacity(Glas.glanzDeckkraft))
                    .frame(width: d * Glas.glanzBreite, height: d * Glas.glanzHoehe)
                    .blur(radius: Glas.glanzWeich)
                    .padding(.leading, d * Glas.glanzLinks).padding(.top, d * Glas.glanzOben)
            }
            .overlay(Circle().strokeBorder(LinearGradient(colors: [.white.opacity(Glas.linsenRandOben), .clear], startPoint: .top, endPoint: .bottom), lineWidth: Glas.linsenRand))
            .frame(width: d, height: d)
    }
}
#endif
