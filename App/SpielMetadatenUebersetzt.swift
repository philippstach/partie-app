// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import SpieleKern

/// C-005: Die Stichworte in `SpielMetadaten` sind deutsch. Damit Suche und Spotlight auch auf Englisch, Spanisch und Französisch
/// finden („dice“, „cartas“, „puzzle“), steht hier zu jedem deutschen Stichwort die Übersetzung. Neue Stichworte dürfen fehlen;
/// sie werden dann nur auf Deutsch gefunden.
extension SpielMetadaten {
    private static let woerter: [String: [String]] = [
        "karten": ["cards", "cartas", "cartes"], "würfeln": ["dice", "roll", "dados", "dés"], "würfel": ["dice", "dados", "dés"],
        "brett": ["board", "tablero", "plateau"], "brettspiel": ["board game", "juego de mesa", "jeu de plateau"],
        "rätsel": ["puzzle", "riddle", "rompecabezas", "casse-tête", "énigme"], "logik": ["logic", "lógica", "logique"],
        "zwei spieler": ["two players", "dos jugadores", "deux joueurs"], "zahlen": ["numbers", "números", "nombres"],
        "reaktion": ["reaction", "reacción", "réaction"], "punkte": ["points", "puntos"], "kinder": ["kids", "children", "niños", "enfants"],
        "familie": ["family", "familia", "famille"], "taktik": ["tactics", "táctica", "tactique"], "strategie": ["strategy", "estrategia", "stratégie"],
        "bluffen": ["bluff", "farol", "bluffer"], "bluff": ["bluff", "farol"], "ablegen": ["discard", "descartar", "défausser"],
        "kneipe": ["pub", "bar", "taverna", "bistrot"], "wörter": ["words", "palabras", "mots"], "steine": ["stones", "piezas", "pions"],
        "spanisch": ["spanish", "español", "espagnol"], "farben": ["colors", "colours", "colores", "couleurs"], "farbe": ["color", "colour", "color", "couleur"],
        "allein": ["solo", "single player", "solitario", "seul"], "gitter": ["grid", "cuadrícula", "grille"], "buchstaben": ["letters", "letras", "lettres"],
        "raten": ["guess", "adivinar", "deviner"], "lügen": ["lying", "mentir", "mentir"], "anlegen": ["lay", "build", "colocar", "poser"],
        "paare": ["pairs", "parejas", "paires"], "schnell": ["fast", "quick", "rápido", "rapide"], "stiche": ["tricks", "bazas", "plis"],
        "pasch": ["doubles", "dobles", "doubles"], "deckel": ["lid", "cup", "tapa", "couvercle"], "figuren": ["pawns", "figures", "fichas", "pions"],
        "neu": ["new", "nuevo", "nouveau"], "knacken": ["crack", "break", "descifrar", "déchiffrer"], "leben": ["lives", "vidas", "vies"],
        "säen": ["sow", "sembrar", "semer"], "samen": ["seeds", "semillas", "graines"], "runden": ["rounds", "rondas", "tours"],
        "springen": ["jump", "saltar", "sauter"], "hüpfen": ["hop", "jump", "saltar", "sauter"], "party": ["party", "fiesta", "fête"],
        "könig": ["king", "rey", "roi"], "ball": ["ball", "pelota", "balle"], "weg": ["path", "way", "camino", "chemin"],
        "reihen": ["rows", "filas", "rangées"], "jagd": ["hunt", "chase", "caza", "chasse"], "fuchs": ["fox", "zorro", "renard"],
        "kreuz": ["cross", "cruz", "croix"], "augen": ["pips", "eyes", "puntos", "points"], "tiere": ["animals", "animales", "animaux"],
        "minen": ["mines", "minas"], "verlauf": ["gradient", "degradado", "dégradé"], "sortieren": ["sort", "ordenar", "trier"],
        "kreuzworträtsel": ["crossword", "crucigrama", "mots croisés"], "pfeilrätsel": ["arrow crossword", "crucigrama", "mots fléchés"],
        "tagesrätsel": ["daily puzzle", "puzzle diario", "défi du jour"], "klappen": ["flip", "voltear", "rabattre"], "schieben": ["slide", "deslizar", "glisser"],
        "schalten": ["switch", "toggle", "cambiar", "basculer"], "türme": ["towers", "torres", "tours"], "scheiben": ["discs", "disks", "discos", "disques"],
        "wischen": ["swipe", "deslizar", "balayer"], "wenden": ["flip", "turn", "voltear", "retourner"], "schlagzwang": ["forced capture", "captura obligatoria", "prise obligatoire"],
        "bank": ["dealer", "bank", "banca", "banque"], "ziehen": ["draw", "robar", "piocher"], "becher": ["cup", "vaso", "gobelet"], "flotte": ["fleet", "flota", "flotte"],
        "einfach": ["easy", "simple", "fácil", "facile"], "bilderrätsel": ["picture puzzle", "nonogram", "nonograma", "image cachée"], "zielzahl": ["target number", "número objetivo", "nombre cible"],
        "gebot": ["bid", "apuesta", "enchère"], "ecke": ["corner", "esquina", "coin"], "kategorien": ["categories", "categorías", "catégories"], "schreiben": ["write", "escribir", "écrire"],
        "matt": ["checkmate", "jaque mate", "échec et mat"], "inseln": ["islands", "islas", "îles"], "kreuzzahlrätsel": ["cross sums", "kakuro", "sommes croisées"],
        "summen": ["sums", "sumas", "sommes"], "folgen": ["sequences", "runs", "secuencias", "suites"], "sätze": ["sets", "combos", "juegos", "combinaisons"],
        "stapeln": ["stack", "apilar", "empiler"], "blöcke": ["blocks", "bloques", "blocs"], "plattformen": ["platforms", "plataformas", "plateformes"],
        "laufen": ["run", "correr", "courir"], "gedächtnis": ["memory", "memoria", "mémoire"], "füllen": ["fill", "llenar", "remplir"], "schiffe": ["ships", "barcos", "bateaux"],
        "fracht": ["cargo", "carga", "fret"], "packen": ["pack", "empaquetar", "emballer"], "ungleich": ["inequality", "desigualdad", "inégalité"], "acht": ["eight", "ocho", "huit"],
        "kästchen": ["boxes", "squares", "cajas", "cases"], "linien": ["lines", "líneas", "lignes"], "stecken": ["plug", "insert", "pegs", "clavijas", "fiches"],
        "muster": ["pattern", "patrón", "motif"], "esel": ["donkey", "burro", "âne"], "zelte": ["tents", "tiendas", "tentes"], "bäume": ["trees", "árboles", "arbres"],
        "code": ["code", "código", "code"], "verbinden": ["connect", "conectar", "relier"], "glück": ["luck", "suerte", "chance"], "gruppen": ["groups", "grupos", "groupes"],
        "kombination": ["combination", "combinación", "combinaison"], "klassiker": ["classic", "clásico", "classique"], "trumpf": ["trump", "triunfo", "atout"], "krieg": ["war", "guerra", "bataille"],
        "duell": ["duel", "duelo", "duel"], "vergleichen": ["compare", "comparar", "comparer"], "leitern": ["ladders", "escaleras", "échelles"], "schlangen": ["snakes", "serpientes", "serpents"],
        "streichhölzer": ["matchsticks", "matches", "cerillas", "allumettes"], "herzen": ["hearts", "corazones", "cœurs"], "pik dame": ["queen of spades", "dama de picas", "dame de pique"],
        "stapel": ["pile", "deck", "stack", "pila", "pile"], "reihenfolge": ["order", "sequence", "orden", "ordre"], "labyrinth": ["labyrinth", "maze", "laberinto", "labyrinthe"],
        "irrgarten": ["maze", "laberinto", "labyrinthe"], "nebel": ["fog", "niebla", "brouillard"], "spanien": ["spain", "españa", "espagne"], "südamerika": ["south america", "sudamérica", "amérique du sud"],
        "afrika": ["africa", "áfrica", "afrique"], "mexiko": ["mexico", "méxico", "mexique"], "kuba": ["cuba"], "risiko": ["risk", "riesgo", "risque"], "runde": ["round", "ronda", "tour"],
        "gewinnt": ["wins", "gana", "gagne"], "schock": ["shock", "schock"], "figur": ["figure", "piece", "ficha", "pion"], "spiel": ["game", "juego", "jeu"],
    ]

    private static let gattungWoerter: [Gattung: [String]] = [
        .raetsel: ["puzzle", "puzzles", "rompecabezas", "casse-tête", "logic"], .wort: ["word", "words", "palabras", "mots"],
        .karten: ["cards", "card game", "cartas", "cartes"], .brett: ["board", "board game", "tablero", "plateau"],
        .wuerfel: ["dice", "dados", "dés"], .arcade: ["arcade", "action", "reflex"],
    ]

    /// Englische, spanische und französische Entsprechungen der Stichworte (und der Spielart) eines Spiels.
    static func uebersetzt(_ id: String, gattung: Gattung) -> [String] {
        var aus: [String] = gattungWoerter[gattung] ?? []
        for w in info(id).stichworte { aus += woerter[w.lowercased()] ?? [] }
        return Array(Set(aus)).sorted()
    }
}
