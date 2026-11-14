// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if DEBUG && canImport(UIKit)
import SpieleKern

/// Nur Debug: Testzustand für `-testZustand`. Das erste Rätsel der Stufe „Leicht“ ohne Starthilfe; alle Buchstabenfelder bis auf das letzte
/// werden Feld für Feld mit den Lösungsbuchstaben getippt (normale Eingabe im Store).
/// kurzVorEnde: Ein Buchstabe fehlt. ende: derselbe Stand, die Ansicht tippt den letzten Buchstaben nach dem Laden selbst (Gewinn-Welle, Ende-Karte).
public enum WortpfeilTestzustand {
    @MainActor
    public static func ablegen(_ art: Testzustand.Art) {
        let store = GameStore(library: PackLibrary.bundled())
        guard let puzzle = store.library.puzzles(.leicht).first else { return }
        store.begin(Game(puzzle: puzzle, startHelp: false))
        for p in puzzle.letterCells.dropLast() {
            guard let c = puzzle.solution(p) else { continue }
            store.tap(row: p.r, col: p.c)
            store.type(String(c))
        }
        store.demoSetElapsed(95)
        store.save()
        Testzustand.melden(kennung: GameStore.kennung, spieler: 1)
    }
}
#endif
