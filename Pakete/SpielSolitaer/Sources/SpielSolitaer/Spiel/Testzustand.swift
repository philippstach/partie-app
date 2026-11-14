// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if DEBUG
import SpieleKern

/// Nur Debug: Testzustand für `-testZustand`. Den Spielstand legt `NeuWurzel` beim Aufbau selbst an (lösbare Partie mit gespeicherter
/// Lösung, fester Zufall, Klondike 1 Karte); hier nur die Marke und der Wunsch „gleich weiterspielen“ für den Rahmen.
/// kurzVorEnde: drei Züge der Lösung fehlen. ende: der letzte Zug wird beim Öffnen gespielt, Sieg und Ende-Karte erscheinen von selbst.
public enum SolitaerTestzustand {
    @MainActor
    public static func ablegen(_ art: Testzustand.Art) {
        NeuMarke.sichern()
        Testzustand.melden(kennung: NeuText.kennung, spieler: 1)
    }
}
#endif
