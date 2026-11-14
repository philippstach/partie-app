// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas

/// Teilbares Ergebnisbild („Werbekarte“): Spielname, Ergebnis, Rangliste und der Hinweis „Gespielt mit Partie“.
/// Entsteht aus dem Ergebnistext (`ErgebnisText`), damit alle Spiele ohne eigenen Code ein Bild teilen können.
struct ErgebnisKarte: View {
    let spiel: String
    let ergebnis: String
    let zeilen: [String]
    let fuss: String

    /// Zerlegt den Teilen-Text: erste Zeile „Spiel: Ergebnis“, letzte Zeile Fußzeile, dazwischen die Rangliste.
    init(text: String) {
        var z = text.split(separator: "\n", omittingEmptySubsequences: true).map(String.init)
        fuss = z.count > 1 ? z.removeLast() : String(localized: "Gespielt mit Partie")
        let kopf = z.first ?? ""
        if let r = kopf.range(of: ": ") {
            spiel = String(kopf[..<r.lowerBound]); ergebnis = String(kopf[r.upperBound...])
        } else { spiel = kopf; ergebnis = "" }
        zeilen = Array(z.dropFirst().prefix(6))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: Design.Abstand.s) {
                Image(systemName: "die.face.5.fill").font(.title3)
                Text("Partie").font(.headline.weight(.bold)).textCase(.uppercase).tracking(2)
            }
            .foregroundStyle(.white.opacity(0.85))
            Spacer(minLength: 0)
            Image(systemName: "trophy.fill").font(.largeTitle.weight(.bold)).imageScale(.large).foregroundStyle(.white)
            Text(spiel).font(.title3.weight(.semibold)).foregroundStyle(.white.opacity(0.9))
            if !ergebnis.isEmpty { Text(ergebnis).font(.largeTitle.weight(.bold)).foregroundStyle(.white).minimumScaleFactor(0.5) }
            if !zeilen.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(zeilen, id: \.self) { Text($0).font(.title3.weight(.medium)).foregroundStyle(.white) }
                }
                .padding(16).frame(maxWidth: .infinity, alignment: .leading)
                .background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            Spacer(minLength: 0)
            Text(fuss).font(.footnote.weight(.medium)).foregroundStyle(.white.opacity(0.8))
        }
        .padding(28)
        .frame(width: 360, height: 450, alignment: .leading)
        .background(LinearGradient(colors: [Color.accentColor, Color.accentColor.opacity(0.65)], startPoint: .topLeading, endPoint: .bottomTrailing))
    }
}

/// Wirft die Karte als Bild aus (ImageRenderer, 3-fach für scharfe Darstellung in Messengern).
enum ErgebnisBild {
    @MainActor static func erzeugen(text: String) -> UIImage? {
        let r = ImageRenderer(content: ErgebnisKarte(text: text).environment(\.colorScheme, .light))
        r.scale = 3
        return r.uiImage
    }
}
#endif
