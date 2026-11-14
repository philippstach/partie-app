// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Welches Spiel (Klondike, Spider, FreeCell, Pyramid, TriPeaks, Golf, Yukon)
enum GameKind: String, Codable, CaseIterable {
    case klondike, spider, freecell, pyramid, tripeaks, golf, yukon
}

/// Spiel + Option: Klondike 1/3 Karten · Spider 1/2/4 Farben · FreeCell 0. `key` benennt Spielstand und Statistik.
struct GameMode: Hashable, Codable {
    var kind: GameKind
    var option: Int

    static func klondike(_ draw: Int) -> GameMode { GameMode(kind: .klondike, option: draw == 3 ? 3 : 1) }
    /// FreeCell (kein Modus zur Wahl)
    static let freecell = GameMode(kind: .freecell, option: 0)
    /// Spider mit 1, 2 oder 4 Farben
    static func spider(_ suits: Int) -> GameMode { GameMode(kind: .spider, option: [1, 2, 4].contains(suits) ? suits : 2) }

    /// Pyramid (kein Modus zur Wahl)
    static let pyramid = GameMode(kind: .pyramid, option: 0)

    /// TriPeaks (kein Modus zur Wahl)
    static let tripeaks = GameMode(kind: .tripeaks, option: 0)

    /// Golf (kein Modus zur Wahl)
    static let golf = GameMode(kind: .golf, option: 0)

    /// `klondike1`, `klondike3`, `spider1`, `spider2`, `spider4`, `freecell`, `pyramid`
    /// Yukon (kein Modus zur Wahl)
    static let yukon = GameMode(kind: .yukon, option: 0)

    var key: String { [.freecell, .pyramid, .tripeaks, .golf, .yukon].contains(kind) ? kind.rawValue : "\(kind.rawValue)\(option)" }
}

/// Wie eine Karte aussieht: Wert 1…13 und Farbe
struct CardFace: Hashable {
    var rank: Int
    var suit: Suit
}

/// Zustand einer Partie, so wie ihn die gemeinsamen Teile (Speichern, Statistik, Tisch) brauchen.
protocol SolitaireState: Codable, Hashable {
    var isWon: Bool { get }
    var moves: Int { get }
    /// nil = keine Punkte (FreeCell)
    var displayScore: Int? { get }
    var stockCount: Int { get }
    /// Karten im Stapel (für das Wackeln beim Antippen ohne Wirkung)
    var stockCardIDs: [CardID] { get }
    /// Stapel leer, aber Ablage voll (für den Erstspieler-Hinweis)
    var needsRecycle: Bool { get }
    /// Wie viele Karten noch verdeckt liegen (ein Rückgang bedeutet: es wurde aufgedeckt)
    var hiddenCardCount: Int { get }
    /// Wie viele Zielstapel/Reihen komplett sind (steigt → Ton „Farbe komplett“)
    var completedFoundations: Int { get }
    /// Länge der laufenden Kette (nur TriPeaks, sonst 0)
    var chainLength: Int { get }
    /// Anzeige der Punkte in der Kopfzeile („215“, „−37 $“); nil = keine
    var scoreText: String? { get }
    var scoreNegative: Bool { get }
    /// Punkte für Rekorde („Höchste Punkte“); nil = zählt nicht
    var recordScore: Int? { get }
    /// Vegas fortlaufend: Dollar der Partie, die beim Ende aufs Konto gehen
    var accountDollars: Int? { get }
    /// Spalten, die ganz aufgedeckt sind (Klondike: keine verdeckte Karte mehr, aber Karten) – steigt → sanfter Haptik-Tick
    var revealedColumns: Int { get }
    func face(of card: CardID) -> CardFace
    /// Reihenfolge beim Austeilen (Versatz der Flug-Animation) und Spalte (Versatz beim Aufdecken)
    func dealOrder(of card: CardID) -> Int?
    func dealColumn(of card: CardID) -> Int?
    /// Versatz der Animation in Sekunden, damit Karten nacheinander landen (Stapel ziehen, Reihe abräumen); sonst 0
    func stagger(of card: CardID, style: MoveStyle) -> Double
}

/// Die Regeln einer Spielvariante: reine Funktionen auf dem Zustand.
protocol SolitaireRules {
    associatedtype State: SolitaireState
    static var kind: GameKind { get }
    /// Bewegungsart der automatischen Züge (Klondike: normal, Spider: fertige Reihe fliegt nacheinander ab)
    static var autoMoveStyle: MoveStyle { get }

    static func deal(seed: UInt64, mode: GameMode) -> State
    /// Alle Karten verdeckt auf dem Stapel (Startbild der Austeil-Animation)
    static func preDealState(_ s: State) -> State
    /// nil = Zug nicht erlaubt (der Zustand bleibt, wie er ist)
    static func apply(_ s: State, _ m: Move) -> State?
    static func movingCards(_ s: State, from: Pile, count: Int) -> [CardID]?
    static func tapTarget(_ s: State, from: Pile, count: Int) -> Move?
    /// Nach jedem Spielerzug (Klondike/FreeCell: sichere Ablagen, nur wenn eingeschaltet · Spider: fertige Reihen, immer)
    static func autoMoves(_ s: State, autoFoundation: Bool) -> [Move]
    static func canAutoFinish(_ s: State) -> Bool
    static func autoFinishMoves(_ s: State) -> [Move]
    static func hint(_ s: State) -> Move?
    static func isStuck(_ s: State) -> Bool
    /// Höchstens so viele Karten auf einmal nach `to` (FreeCell: Supermove-Grenze); nil = keine Grenze
    static func maxMovable(_ s: State, to: Pile) -> Int?
    /// Züge einer gespeicherten Lösung in der Zugschrift dieses Spiels (SPEZIFIKATION-EXTRAS §3); nil = nicht lesbar
    static func solutionMoves(from text: String) -> [Move]?
    /// Nur Antippen, kein Ziehen mit dem Finger (Pyramid)
    static var tapOnly: Bool { get }
    /// Antippen wählt eine Karte, ein zweiter Tipp auf den Partner entfernt das Paar (Pyramid)
    static var usesSelection: Bool { get }
    /// Orte, die zur freien Karte an `pile` passen (nur bei Auswahl-Spielen)
    static func partners(_ s: State, of pile: Pile) -> [Pile]
    /// Zug aus gewählter Karte und angetipptem Partner
    static func pairMove(_ s: State, _ a: Pile, _ b: Pile) -> Move?
    /// Aufs Ziel, wenn möglich (Doppeltipp: Klondike, FreeCell)
    static func foundationMove(_ s: State, from: Pile, count: Int) -> Move?
    /// Stellt eine frisch ausgeteilte Partie nach den Einstellungen ein (Klondike: Punkte-Art)
    static func prepare(_ s: State, prefs: some SolitaireRegelOptionen, kind: DealKind) -> State
    /// Hinweistext, wenn Stapel antippen gerade nicht geht (Vegas: „Keine Durchgänge mehr“)
    static func drawBlockedMessage(_ s: State) -> String?
    /// Zeitbonus beim Sieg (Klondike Standard)
    static func timeBonus(_ s: State, seconds: Int) -> Int
    /// Ort, der durch diesen Zug leer geräumt wurde (Golf: Spalte) – dort schimmert kurz Gold
    static func clearedPile(_ before: State, _ after: State, _ m: Move) -> Pile?
    /// Schwebender Text nach einem Zug (TriPeaks „+15“ beim Gipfelbonus) und der Ort, an dem er aufsteigt
    static func bonusPopup(_ before: State, _ after: State, _ m: Move) -> (text: String, pile: Pile)?
    /// Halbtöne, um die der Ton nach diesem Zug höher klingt (TriPeaks: ab Kette 5)
    static func soundPitch(_ after: State) -> Int
}

extension SolitaireState {
    var chainLength: Int { 0 }
    var scoreText: String? { displayScore.map(String.init) }
    var scoreNegative: Bool { false }
    var recordScore: Int? { displayScore }
    var accountDollars: Int? { nil }
    var revealedColumns: Int { 0 }
}

extension SolitaireRules {
    static func maxMovable(_ s: State, to: Pile) -> Int? { nil }
    static var tapOnly: Bool { false }
    static var usesSelection: Bool { false }
    static func partners(_ s: State, of pile: Pile) -> [Pile] { [] }
    static func pairMove(_ s: State, _ a: Pile, _ b: Pile) -> Move? { nil }
    static func foundationMove(_ s: State, from: Pile, count: Int) -> Move? { nil }
    static func prepare(_ s: State, prefs: some SolitaireRegelOptionen, kind: DealKind) -> State { s }
    static func drawBlockedMessage(_ s: State) -> String? { nil }
    static func timeBonus(_ s: State, seconds: Int) -> Int { 0 }
    static func clearedPile(_ before: State, _ after: State, _ m: Move) -> Pile? { nil }
    static func bonusPopup(_ before: State, _ after: State, _ m: Move) -> (text: String, pile: Pile)? { nil }
    static func soundPitch(_ after: State) -> Int { 0 }
    /// Klondike und Spider teilen sich die Zugschrift; Pyramid und TriPeaks liefern ihre eigene
    static func solutionMoves(from text: String) -> [Move]? { SolutionNotation.moves(text) }
    static func isLegal(_ s: State, _ m: Move) -> Bool { apply(s, m) != nil }
}


/// Einstellungen, die das Layout beeinflussen
struct TablePrefs {
    var leftHanded = false
    /// Kartengröße „Groß“: Index 1,25-fach, Fächer neu abgestimmt
    var largeCards = false
    /// Querformat: Spalte, deren dichter Block gerade aufgeklappt ist
    var unfolded: Int?
}

/// Leerer Platz (Spalte, Ziel, Zelle, Stapel, Ablage) – wird unter den Karten gezeichnet.
struct SlotSpec: Identifiable {
    var id: Int
    var frame: CGRect
    var symbol: String?
    /// Farbe des Ziels: das Symbol erscheint in der Farbe dieser Kartenfarbe (30 %)
    var suit: Suit?
    var dimmed = false
    /// Buchstabe statt Symbol (z. B. „K“ für die fertigen Reihen bei Spider)
    var label: String?
    /// Gefüllte Fläche (freie Zellen bei FreeCell)
    var filled = false
    /// Kleiner gezeichnet (Spider quer: Stapel und fertige Reihen in der Seitenleiste)
    var scale: CGFloat = 1
}

struct CardPlacement: Equatable {
    var frame: CGRect
    var faceUp: Bool
    var z: Double
    /// Noch nicht spielbar (Pyramid): leicht abgedunkelt
    var dimmed = false
    /// Größer gezeichnet (TriPeaks: Ablage 1,3-fach)
    var scale: CGFloat = 1
    /// Von einer anderen Karte teilweise verdeckt: Bildkarten zeigen dann nur den Index (kein Rahmen, der im Fächer blitzt)
    var covered = false
}

/// Wo eine Karte angefasst werden kann: Ort und Anzahl der Karten, die mitwandern.
struct CardSource {
    var pile: Pile
    var count: Int
}

/// Reine Funktion: Zustand + Fläche → Position jeder Karte. Alle Bewegungen entstehen, indem sich dieses Ergebnis ändert.
protocol SolitaireLayout {
    associatedtype State
    init(state: State, size: CGSize, prefs: TablePrefs)

    var size: CGSize { get }
    var cardSize: CGSize { get }
    /// Alle Karten des Spiels in fester Reihenfolge (Identität für die Animation)
    var cardIDs: [CardID] { get }
    var placements: [CardID: CardPlacement] { get }
    var sources: [CardID: CardSource] { get }
    var slots: [SlotSpec] { get }
    /// Stapel zum Antippen (nil, wenn die Variante keinen hat) und Mitte der Zahl darunter
    var stockTapFrame: CGRect? { get }
    var stockCountCenter: CGPoint? { get }
    /// Text unter dem Stapel (Klondike „24“, Spider „noch 3×“); nil = keiner
    var stockCaption: String? { get }
    /// Leere Spalten (blinken gold, wenn Austeilen nicht geht – nur Spider)
    var emptyColumnFrames: [CGRect] { get }
    /// Goldener Text über dem Tisch (TriPeaks „Kette 5“); nil = keiner
    var badge: (text: String, center: CGPoint, glow: Bool)? { get }
    /// Spalten mit dichtem Block tieferer offener Karten (Querformat: Antippen klappt auf)
    var collapsedBlocks: [CollapsedBlock] { get }
    /// Kleines Symbol auf dem Tisch (Golf: Schloss an der Ablage, wenn ein König oben liegt); nil = keines
    var cornerSymbol: (name: String, center: CGPoint, label: String)? { get }
    /// Alle Orte, auf die eine Karte gelegt werden kann
    var dropPiles: [Pile] { get }
    /// Wo jede Karte liegt (für VoiceOver: „Spalte 3“)
    var pileOf: [CardID: Pile] { get }
    func targetFrame(_ pile: Pile) -> CGRect
    /// Wo die erste verschobene Karte landen würde (für den Tipp)
    func landingOrigin(_ pile: Pile) -> CGPoint
    /// Ziel unter einem Punkt (Mitte der untersten gezogenen Karte)
    func dropTarget(at point: CGPoint) -> Pile?
    /// Karten des Siegesanimation in Startreihenfolge, mit Startpunkt
    func waterfallCards() -> [(face: CardFace, origin: CGPoint)]
}


extension SolitaireLayout {
    var emptyColumnFrames: [CGRect] { [] }
    var badge: (text: String, center: CGPoint, glow: Bool)? { nil }
    var cornerSymbol: (name: String, center: CGPoint, label: String)? { nil }
    var collapsedBlocks: [CollapsedBlock] { [] }
}
