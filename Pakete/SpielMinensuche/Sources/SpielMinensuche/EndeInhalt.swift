// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// design:spielinhalt-datei – Ergebnisseite der Minensuche (Tinte, Blatt 8, Paket R2)
import SwiftUI
import KlarGlas
import SpieleKern
import MinensucheKern

#if canImport(UIKit)
/// Inhalt der Ergebnisseite (über `mitEndeInhalt` im `SpielRahmen`): drei Wertzeilen und das Feld, wie es am Ende lag.
/// Blatt 22 (EB-3): Derselbe Inhalt steht jetzt auch in Klar und Salon (wie die Bildkarte des Kerns auf dem Filz, auch dort dunkles Schema);
/// ohne Stand (z. B. nach einem Neustart der App) bleibt das Spielbild wie bisher.
struct MinensucheEndeInhalt: View {
    let ende: SpielEnde
    @Environment(\.designArt) private var art   // zeichnet beim Designwechsel neu
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        if let st = SpielModell.letzterStand {
            VStack(spacing: 22) {
                werte(st)
                feld(st)
            }
            .frame(maxWidth: .infinity)
        } else {
            SpielBildMotiv(id: "minensuche", symbol: ende.einzel == .gewonnen ? "trophy.fill" : "flag.checkered")
        }
    }

    // MARK: Wertzeilen (Stufe, Zeit, Minen)

    private func werte(_ st: SpielModell.EndeStand) -> some View {
        VStack(spacing: 0) {
            Rectangle().fill(Color.schrift).frame(height: 1.5)   // starke Linie darüber
            zeile("Stufe", st.art == .tag ? Text("Tagesrätsel") : Text(verbatim: st.stufe.nameText))
            zeile("Zeit", Text(verbatim: SpielModell.zeit(st.dauer)))
            zeile("Minen", Text(verbatim: "\(st.spiel.mass.minen)"))
        }
    }

    private func zeile(_ titel: LocalizedStringKey, _ wert: Text) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Text(titel).font(Design.Schrift.serif(17, relativ: .body, hoechstens: 1.3)).foregroundStyle(Color.schrift)
                Spacer(minLength: 8)
                wert.font(.system(size: 17, weight: .semibold).monospacedDigit()).foregroundStyle(Color.schrift)
            }
            .frame(minHeight: 46)
            Rectangle().fill(Color.linie).frame(height: 0.5)   // feine Linie je Zeile
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: Spielfeld am Ende

    private func feld(_ st: SpielModell.EndeStand) -> some View {
        let s = st.spiel
        let luecke: CGFloat = 3
        let rand: CGFloat = 12
        let hoechst: CGFloat = sizeClass == .regular ? 420 : 320
        return GeometryReader { geo in
            let breite = geo.size.width - 2 * rand
            let hoehe = hoechst - 2 * rand
            let bz = (breite - luecke * CGFloat(s.mass.spalten - 1)) / CGFloat(s.mass.spalten)
            let bh = (hoehe - luecke * CGFloat(s.mass.zeilen - 1)) / CGFloat(s.mass.zeilen)
            let seite = max(8, floor(min(bz, bh, 56)))
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color.clear)
                    .overlay { TischGrund(SpielRahmenHaken.bild?("minensuche")?.farbe) }
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                brett(s, seite: seite, luecke: luecke)
                    .padding(rand)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .frame(height: hoechst)
        .environment(\.colorScheme, .dark)   // wie auf dem Filz am Tisch (Kern-Entscheidung EB-K: auch in Klar und Salon)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Spielfeld am Ende"))
    }

    private func brett(_ s: Spiel, seite: CGFloat, luecke: CGFloat) -> some View {
        VStack(spacing: luecke) {
            ForEach(0..<s.mass.zeilen, id: \.self) { z in
                HStack(spacing: luecke) {
                    ForEach(0..<s.mass.spalten, id: \.self) { sp in
                        ZelleView(spiel: s, position: Position(zeile: z, spalte: sp), seite: seite)
                    }
                }
            }
        }
        .environment(SpielModell.anzeigeModell)   // ZelleView braucht ein Modell für die Gesten; hier ohne Wirkung
        .allowsHitTesting(false)
    }
}
#endif
