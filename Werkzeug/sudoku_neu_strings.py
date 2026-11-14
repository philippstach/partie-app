#!/usr/bin/env python3
"""Sudoku (neu): trägt die neuen Texte (de/en/es/fr) in App/Ressourcen/Localizable.xcstrings ein.
Fehlende Schlüssel werden angelegt, vorhandene bleiben unberührt. Aufruf: python3 Werkzeug/sudoku_neu_strings.py"""
import json, os

PFAD = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "App", "Ressourcen", "Localizable.xcstrings")

T = {
 "Sudoku (neu)": ("Sudoku (new)", "Sudoku (nuevo)", "Sudoku (nouveau)"),
 "Zahlenrätsel in drei Spielarten": ("Number puzzle in three variants", "Puzzle de números en tres variantes", "Casse-tête de chiffres en trois variantes"),
 "Fülle das Gitter so, dass jede Zahl in jeder Zeile, jeder Spalte und jedem Kästchen genau einmal steht. Beim klassischen Sudoku (9 × 9) sind es die Zahlen 1 bis 9 in 3 × 3-Kästchen, beim Kinder-Sudoku (6 × 6) die Zahlen 1 bis 6 in Kästchen aus 3 × 2 Feldern. Beim X-Sudoku enthalten zusätzlich die beiden Diagonalen jede Zahl von 1 bis 9 genau einmal. Tippe ein Feld an und dann die Zahl. Mit dem Stift merkst du dir Möglichkeiten, der Tipp erklärt den nächsten Schritt. Nach drei falschen Zahlen kannst du zum letzten fehlerfreien Stand zurück. Beim neuen Rätsel findest du das Tagesrätsel, den Lernweg und die Eingabe eigener Rätsel.":
   ("Fill the grid so that every number appears exactly once in each row, each column and each box. In classic Sudoku (9 × 9) these are the numbers 1 to 9 in 3 × 3 boxes; in Kids Sudoku (6 × 6) the numbers 1 to 6 in boxes of 3 × 2 cells. In X-Sudoku the two diagonals must also contain every number from 1 to 9 exactly once. Tap a cell and then the number. Use the pencil to note possibilities; the hint explains the next step. After three wrong numbers you can go back to the last error-free state. Under New puzzle you will find the daily puzzle, the learning path and the entry of your own puzzles.",
    "Rellena la cuadrícula de modo que cada número aparezca exactamente una vez en cada fila, cada columna y cada caja. En el sudoku clásico (9 × 9) son los números del 1 al 9 en cajas de 3 × 3; en el sudoku infantil (6 × 6), los números del 1 al 6 en cajas de 3 × 2 casillas. En el sudoku X, las dos diagonales también contienen cada número del 1 al 9 exactamente una vez. Toca una casilla y después el número. Con el lápiz anotas posibilidades; la pista explica el siguiente paso. Tras tres números incorrectos puedes volver al último estado sin errores. En Nuevo puzzle encontrarás el puzzle diario, el camino de aprendizaje y la entrada de puzzles propios.",
    "Remplis la grille de sorte que chaque chiffre apparaisse exactement une fois dans chaque ligne, chaque colonne et chaque bloc. Au sudoku classique (9 × 9), ce sont les chiffres de 1 à 9 dans des blocs de 3 × 3 ; au sudoku enfant (6 × 6), les chiffres de 1 à 6 dans des blocs de 3 × 2 cases. Au sudoku X, les deux diagonales contiennent aussi chaque chiffre de 1 à 9 exactement une fois. Touche une case, puis le chiffre. Le crayon sert à noter les possibilités ; l'indice explique l'étape suivante. Après trois erreurs, tu peux revenir au dernier état sans erreur. Sous Nouvelle grille, tu trouves la grille du jour, le parcours d'apprentissage et la saisie de tes propres grilles."),
 "Fülle das ganze Gitter, sodass jede Zahl in jeder Zeile, Spalte und jedem Kästchen einmal steht.": ("Fill the whole grid so that every number appears once in each row, column and box.", "Rellena toda la cuadrícula de modo que cada número aparezca una vez en cada fila, columna y caja.", "Remplis toute la grille de sorte que chaque chiffre apparaisse une fois dans chaque ligne, colonne et bloc."),
 "Klassisch 9×9": ("Classic 9×9", "Clásico 9×9", "Classique 9×9"),
 "Kinder 6×6": ("Kids 6×6", "Infantil 6×6", "Enfants 6×6"),
 "X-Sudoku": ("X-Sudoku", "Sudoku X", "Sudoku X"),
 "Kinder-Sudoku": ("Kids Sudoku", "Sudoku infantil", "Sudoku enfant"),
 "Eigenes Rätsel": ("Your own puzzle", "Puzzle propio", "Grille personnelle"),
 "Spielart": ("Variant", "Variante", "Variante"),
 "Das bekannte Sudoku: Zahlen 1 bis 9 in einem 9 × 9-Gitter.": ("The well-known Sudoku: numbers 1 to 9 in a 9 × 9 grid.", "El sudoku de siempre: números del 1 al 9 en una cuadrícula de 9 × 9.", "Le sudoku bien connu : chiffres de 1 à 9 dans une grille de 9 × 9."),
 "Kleineres Gitter mit 6 × 6 Feldern und den Zahlen 1 bis 6 – ideal für Kinder und zum Einstieg.": ("A smaller grid with 6 × 6 cells and the numbers 1 to 6 – ideal for kids and for getting started.", "Una cuadrícula más pequeña de 6 × 6 casillas con los números del 1 al 6: ideal para niños y para empezar.", "Une grille plus petite de 6 × 6 cases avec les chiffres de 1 à 6 – idéale pour les enfants et pour débuter."),
 "Wie das klassische Sudoku, aber auch die beiden Diagonalen enthalten jede Zahl einmal.": ("Like classic Sudoku, but the two diagonals also contain every number once.", "Como el sudoku clásico, pero las dos diagonales también contienen cada número una vez.", "Comme le sudoku classique, mais les deux diagonales contiennent aussi chaque chiffre une fois."),
 "Auch die beiden Diagonalen enthalten jede Zahl von 1 bis 9 genau einmal.": ("The two diagonals also contain every number from 1 to 9 exactly once.", "Las dos diagonales también contienen cada número del 1 al 9 exactamente una vez.", "Les deux diagonales contiennent aussi chaque chiffre de 1 à 9 exactement une fois."),
 "Die Zahlen 1 bis 6 stehen in jeder Zeile, Spalte und jedem Kästchen aus 3 × 2 Feldern genau einmal.": ("The numbers 1 to 6 appear exactly once in each row, column and box of 3 × 2 cells.", "Los números del 1 al 6 aparecen exactamente una vez en cada fila, columna y caja de 3 × 2 casillas.", "Les chiffres de 1 à 6 apparaissent exactement une fois dans chaque ligne, colonne et bloc de 3 × 2 cases."),
 "Tippe ein Feld an und dann unten die Zahl. Der Stift merkt dir Möglichkeiten.": ("Tap a cell and then the number below. The pencil keeps track of possibilities.", "Toca una casilla y después el número de abajo. El lápiz guarda las posibilidades.", "Touche une case, puis le chiffre en bas. Le crayon garde les possibilités en mémoire."),
 "Heutiges Rätsel, %@. Löse es, um deine Serie zu halten.": ("Today's puzzle, %@. Solve it to keep your streak.", "Puzzle de hoy, %@. Resuélvelo para mantener tu racha.", "Grille du jour, %@. Résous-la pour garder ta série."),
 "Dein eingegebenes Rätsel. Es hat genau eine Lösung.": ("The puzzle you entered. It has exactly one solution.", "El puzzle que introdujiste. Tiene exactamente una solución.", "La grille que tu as saisie. Elle a exactement une solution."),
 "Fehler %lld von %lld": ("Mistakes %lld of %lld", "Errores %lld de %lld", "Erreurs %lld sur %lld"),
 "Fortschritt %lld Prozent": ("Progress %lld percent", "Progreso %lld por ciento", "Progression %lld pour cent"),
 "Vorgabe %lld": ("Given %lld", "Dato %lld", "Donné %lld"),
 "leer, Notizen: %@": ("empty, notes: %@", "vacía, notas: %@", "vide, notes : %@"),
 "Notizen automatisch streichen": ("Remove notes automatically", "Quitar notas automáticamente", "Effacer les notes automatiquement"),
 "Notizen füllen": ("Fill in notes", "Rellenar notas", "Remplir les notes"),
 "In diesem Feld passt nur noch eine Zahl.": ("Only one number still fits in this cell.", "En esta casilla solo cabe ya un número.", "Un seul chiffre convient encore dans cette case."),
 "In der markierten Reihe, Spalte, Box oder Diagonale passt eine Zahl nur an diese Stelle.": ("In the marked row, column, box or diagonal, one number fits only in this place.", "En la fila, columna, caja o diagonal marcada, un número solo cabe en este lugar.", "Dans la ligne, colonne, bloc ou diagonale marqué, un chiffre ne convient qu'à cet endroit."),
 "Das passt nicht.": ("That doesn't fit.", "Eso no encaja.", "Cela ne convient pas."),
 "Du kannst zum letzten fehlerfreien Stand zurück oder einfach weiterspielen.": ("You can go back to the last error-free state or simply keep playing.", "Puedes volver al último estado sin errores o seguir jugando.", "Tu peux revenir au dernier état sans erreur ou simplement continuer."),
 "Rätsel wird gebaut …": ("Building puzzle …", "Creando el puzzle …", "Création de la grille …"),
 "Heute spielen": ("Play today's", "Jugar el de hoy", "Jouer celle du jour"),
 "Heute gelöst – noch einmal spielen": ("Solved today – play again", "Resuelto hoy: jugar otra vez", "Résolue aujourd'hui – rejouer"),
 "Serie: %lld Tage, heute ist noch Zeit": ("Streak: %lld days, there is still time today", "Racha: %lld días, aún hay tiempo hoy", "Série : %lld jours, il reste du temps aujourd'hui"),
 "Techniken üben": ("Practice techniques", "Practicar técnicas", "S'entraîner aux techniques"),
 "Übe Schritt für Schritt die Tricks der Profis, von der einzigen Möglichkeit bis zum X-Wing.": ("Practice the pros' tricks step by step, from the only possibility up to the X-Wing.", "Practica paso a paso los trucos de los expertos, desde la única posibilidad hasta el X-Wing.", "Entraîne-toi pas à pas aux astuces des pros, de la seule possibilité jusqu'au X-Wing."),
 "Rätsel eingeben": ("Enter a puzzle", "Introducir un puzzle", "Saisir une grille"),
 "Tippe ein Rätsel aus Zeitung oder Buch ab. Die App prüft, ob es genau eine Lösung hat, und du spielst es mit Tipps und Notizen.": ("Type in a puzzle from a newspaper or book. The app checks that it has exactly one solution, and you play it with hints and notes.", "Copia un puzzle de un periódico o libro. La app comprueba que tenga exactamente una solución y lo juegas con pistas y notas.", "Saisis une grille d'un journal ou d'un livre. L'appli vérifie qu'elle a exactement une solution, et tu la joues avec indices et notes."),
 "Tippe ein Feld an und trage die Zahlen deines Rätsels ein. Dann lass es prüfen.": ("Tap a cell and enter the numbers of your puzzle. Then have it checked.", "Toca una casilla e introduce los números de tu puzzle. Después haz que se compruebe.", "Touche une case et saisis les chiffres de ta grille. Fais-la ensuite vérifier."),
 "Trage zuerst ein paar Zahlen ein.": ("Enter a few numbers first.", "Introduce primero algunos números.", "Saisis d'abord quelques chiffres."),
 "Eine Zahl kommt doppelt vor (rot markiert).": ("A number appears twice (marked in red).", "Un número aparece dos veces (marcado en rojo).", "Un chiffre apparaît deux fois (marqué en rouge)."),
 "Dieses Rätsel hat keine Lösung. Prüfe die Zahlen noch einmal.": ("This puzzle has no solution. Check the numbers again.", "Este puzzle no tiene solución. Revisa los números.", "Cette grille n'a pas de solution. Vérifie les chiffres."),
 "Dieses Rätsel hat mehr als eine Lösung. Trage weitere Zahlen ein.": ("This puzzle has more than one solution. Enter more numbers.", "Este puzzle tiene más de una solución. Introduce más números.", "Cette grille a plusieurs solutions. Saisis d'autres chiffres."),
 "Das Rätsel hat genau eine Lösung.": ("The puzzle has exactly one solution.", "El puzzle tiene exactamente una solución.", "La grille a exactement une solution."),
 "Keine Übungen gefunden": ("No exercises found", "No se encontraron ejercicios", "Aucun exercice trouvé"),
 "Die Übungen konnten nicht geladen werden.": ("The exercises could not be loaded.", "No se pudieron cargar los ejercicios.", "Les exercices n'ont pas pu être chargés."),
 "Nochmal": ("Again", "Otra vez", "Encore"),
 "Starten": ("Start", "Empezar", "Démarrer"),
 "Zum Lernweg": ("To the learning path", "Al camino de aprendizaje", "Vers le parcours"),
}

d = json.load(open(PFAD))
neu = 0
for schluessel, (en, es, fr) in T.items():
    if schluessel in d["strings"]:
        continue
    d["strings"][schluessel] = {"localizations": {
        "de": {"stringUnit": {"state": "translated", "value": schluessel}},
        "en": {"stringUnit": {"state": "translated", "value": en}},
        "es": {"stringUnit": {"state": "translated", "value": es}},
        "fr": {"stringUnit": {"state": "translated", "value": fr}},
    }}
    neu += 1
with open(PFAD, "w") as f:
    f.write(json.dumps(d, indent=2, ensure_ascii=False, separators=(",", ": ")) + "\n")
print(f"{neu} neue Schlüssel eingetragen, {len(T) - neu} schon vorhanden")
