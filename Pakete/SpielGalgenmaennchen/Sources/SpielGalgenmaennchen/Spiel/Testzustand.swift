// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if DEBUG && canImport(UIKit)
import SpieleKern

/// Nur Debug: Testzustand für `-testZustand`. Allein-Spiel mit dem festen Wort „Elefant“ (Deutsch); geraten werden E, X, L, Q, F, A, N
/// (X und Q sind Fehlgriffe, zwei von acht Ballons sind geplatzt), nur das T fehlt noch.
/// kurzVorEnde: Stand so. ende: derselbe Stand, die Ansicht rät das T nach dem Laden selbst (Wort gelöst, Ende-Karte).
public enum GalgenmaennchenTestzustand {
    @MainActor
    public static func ablegen(_ art: Testzustand.Art) {
        var s = NeuStand.eigenes(solution: "ELEFANT", text: "Elefant", hinweis: nil, sprache: .de)
        if var g = s.game {
            for c in "EXLQFAN" { g.guess(String(c)) }
            s.game = g
        }
        Testzustand.ablegen(s, kennung: NeuAblage.id, spieler: 1)
    }
}
#endif
