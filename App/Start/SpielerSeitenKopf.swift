// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

/// Kopf der Spielerseite je Design. Klar & Glas: nichts (die Seite beginnt wie bisher mit „Ich“).
/// Tinte: Verzeichnis-Titel „Spieler“ mit einer Zeile „5 Personen, 112 Partien zusammen.“
/// Salon: Farbblock in Senf mit der Schlagzeile „Spieler.“ und überlappenden Porträts an der unteren Kante.
struct SpielerSeitenKopf: View {
    @Environment(SpielerVerzeichnis.self) private var verzeichnis
    @Environment(StatistikDienst.self) private var statistik
    @Environment(\.designArt) private var art

    private var zeile: Text {
        // Fund 81: Einzahl („1 Person“, „1 Partie“). Die Neu-Schlüssel brauchen eine Übersetzung per Skript.
        let n = verzeichnis.menschen.count, p = statistik.ereignisse.count
        let personen = n == 1 ? String(localized: "1 Person") : String(localized: "\(n) Personen")
        let partien = p == 1 ? String(localized: "1 Partie") : String(localized: "\(p) Partien")
        return Text(verbatim: personen + ", " + partien + " " + String(localized: "zusammen."))
    }

    var body: some View {
        switch art {
        case .klar:
            EmptyView()
        case .tinte:
            StartTitel(titel: Text("Spieler"), untertitel: zeile)
                .padding(.bottom, 6)
        case .salon:
            let flaeche = Design.spielerSeite?.flaeche ?? Huelle.flaeche
            let schrift = Design.spielerSeite?.schrift ?? Color.schrift
            VStack(alignment: .leading, spacing: 0) {
                StartTitel(titel: Text(verbatim: String(localized: "Spieler") + "."), untertitel: zeile)
                    .environment(\.startTitelFarbe, schrift)
            }
            .padding(.horizontal, Theme.seitenRand).padding(.top, 14).padding(.bottom, 44)
            .frame(maxWidth: .infinity, minHeight: 210, alignment: .topLeading)
            .background(flaeche)
            .overlay(alignment: .bottomTrailing) {
                HStack(spacing: -12) {
                    ForEach(verzeichnis.zuletztGespielt.prefix(4)) { p in
                        SpielerBildKreis(p, groesse: 60)
                            .overlay { Circle().strokeBorder(Color.seitenGrund, lineWidth: 4) }
                            .background(Color.seitenGrund, in: Circle())
                    }
                }
                .padding(.trailing, Theme.seitenRand)
                .offset(y: 30)
                .accessibilityHidden(true)
            }
            .padding(.horizontal, -Theme.seitenRand).padding(.top, -Theme.seitenRand)   // der Block reicht bis an die Ränder des Blatts
            .padding(.bottom, 34)
            .zIndex(1)
        }
    }
}
