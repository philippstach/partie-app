// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import SpieleKern

/// Regel-Chat von Zehntausend: seit KI-3 der gemeinsame Baustein „Frag nach den Regeln“ (Blatt 12) aus SpieleKern, mit den
/// Rechen-Werkzeugen von 10k (`ZehnkRegelWissen`). Aussehen und Zustände (leer, „Apple Intelligence ist aus“, „Einen Moment noch“)
/// sind in allen Spielen gleich. Der Chat braucht iOS 26; sonst ist er nicht erreichbar (Status `.hidden`, nichts sichtbar).
struct RegelChatSheet: View {
    let rules: GameRules
    /// Aktueller Zug als Kontext (im Spiel)
    var zug: String? = nil

    var body: some View {
        RegelChatBlatt(wissen: ZehnkRegelWissen(rules: rules, imSpiel: zug != nil), zug: zug)
    }
}
