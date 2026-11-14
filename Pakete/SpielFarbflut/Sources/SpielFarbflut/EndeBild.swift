// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// design:spielinhalt-datei – Ergebnisseite (Blatt 22, Schritt 2): das Feld vom Anfang
#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern

/// Das Feld, wie die Partie begann („Am Anfang“), n × n in den Farben vom Tisch, abgerundete Ecken. Nur lesen.
struct FarbflutEndeBild: View {
    let feld: [Int]
    let n: Int
    let groesse: CGSize

    var body: some View {
        let seite = max(60, floor(min(groesse.width, groesse.height)))
        let z = seite / CGFloat(n)
        Canvas { ctx, _ in
            for i in feld.indices {
                let r = CGRect(x: CGFloat(i % n) * z, y: CGFloat(i / n) * z, width: z, height: z)
                ctx.fill(Path(r), with: .color(flutFarben[min(max(feld[i], 0), flutFarben.count - 1)]))
            }
        }
        .frame(width: z * CGFloat(n), height: z * CGFloat(n))
        .clipShape(.rect(cornerRadius: 6))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
#endif
