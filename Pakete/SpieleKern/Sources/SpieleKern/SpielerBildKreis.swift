// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas

/// Rundes Bild einer Person aus dem Verzeichnis: Foto, sonst Avatar-Zeichen oder Initiale – mit Spielerfarbe als Rand.
/// Dieselbe Darstellung überall (Spielerseite, Auswahl, Statistik), damit Anna in jedem Spiel gleich aussieht.
public struct SpielerBildKreis: View {
    let spieler: Spieler
    var groesse: CGFloat

    public init(_ spieler: Spieler, groesse: CGFloat = 36) { self.spieler = spieler; self.groesse = groesse }

    public var body: some View {
        if spieler.bildNr != nil, let b = SpielerBilder.bild(spieler.id) {
            Image(uiImage: b).resizable().scaledToFill()
                .frame(width: groesse, height: groesse).clipShape(.circle)
                .overlay(Circle().strokeBorder(Spieler.farbe(spieler.farbeIndex), lineWidth: max(2, groesse / 16)))
                .accessibilityHidden(true)
        } else {
            SpielerAvatar(name: spieler.name, farbe: Spieler.farbe(spieler.farbeIndex), groesse: groesse,
                          symbol: spieler.zeichen)
        }
    }
}
/// Spieler-Abzeichen aus einem Zeichen (Emoji) in einem Kreis in der Spielerfarbe. Für Spiele, die ihre Spieler mit eigenem Zeichen
/// und eigener Farbe führen (Würfel- und Brettspiele); vorher hatte jedes dieser Spiele eine eigene Kopie `AvatarBadge`.
public struct AvatarAbzeichen: View {
    let avatar: String
    let farbe: Color
    var groesse: CGFloat

    public init(avatar: String, farbe: Color, groesse: CGFloat = 36) { self.avatar = avatar; self.farbe = farbe; self.groesse = groesse }

    public var body: some View {
        Text(avatar)
            .font(.system(size: groesse * 0.55))   // design:spielinhalt (skaliert mit dem Abzeichen)
            .frame(width: groesse, height: groesse)
            .background(farbe.opacity(0.2), in: .circle)
            .overlay(Circle().strokeBorder(farbe, lineWidth: 2))
            .accessibilityHidden(true)
    }
}
#endif
