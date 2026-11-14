#!/usr/bin/env python3
"""Galgenmännchen (neu): trägt die neuen Texte (de/en/es/fr) in App/Ressourcen/Localizable.xcstrings ein.
Fehlende Schlüssel werden angelegt, vorhandene bleiben unberührt. Aufruf: python3 Werkzeug/galgen_neu_strings.py"""
import json, os

PFAD = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "App", "Ressourcen", "Localizable.xcstrings")

T = {
 "Galgenmännchen (neu)": ("Hangman (new)", "El ahorcado (nuevo)", "Le pendu (nouveau)"),
 "Rate das Wort, bevor die Ballons platzen": ("Guess the word before the balloons pop", "Adivina la palabra antes de que estallen los globos", "Devine le mot avant que les ballons n'éclatent"),
 "Errate das Wort, bevor alle acht Ballons geplatzt sind.": ("Guess the word before all eight balloons have popped.", "Adivina la palabra antes de que estallen los ocho globos.", "Devine le mot avant que les huit ballons n'aient éclaté."),
 "Allein oder mit mehreren: Allein rätst du Wörter, mit zwei bis vier Personen spielt ihr Party.": ("Alone or together: alone you guess words, with two to four people you play Party.", "Solo o en grupo: solo adivinas palabras, de dos a cuatro personas jugáis Fiesta.", "Seul ou à plusieurs : seul tu devines des mots, de deux à quatre personnes vous jouez en mode Fête."),
 "Ein Wort ist gesucht. Rate Buchstaben: Jeder Treffer deckt das Wort auf, jeder Fehler lässt einen von acht Ballons platzen. Platzt der letzte, ist das Spiel verloren. Du kannst zwei Hinweise nehmen und das ganze Wort raten (ein falscher Versuch kostet zwei Ballons). Allein wählst du Kategorie und Stufe, spielst das Wort des Tages oder Überleben mit drei Leben. Mit mehreren spielt ihr Party: Reihum denkt sich einer ein Wort aus oder die App zieht eins, der Nächste rät. Du kannst auch eine eigene Wortliste anlegen.":
   ("A word is hidden. Guess letters: every hit reveals the word, every miss pops one of eight balloons. When the last one pops, the game is lost. You can take two hints and guess the whole word (a wrong attempt costs two balloons). Alone you choose category and level, play the word of the day or Survival with three lives. With several people you play Party: in turn one person thinks of a word or the app draws one, and the next person guesses. You can also create your own word list.",
    "Hay una palabra oculta. Adivina letras: cada acierto descubre la palabra, cada fallo revienta uno de ocho globos. Cuando revienta el último, pierdes. Puedes usar dos pistas y adivinar la palabra entera (un intento fallido cuesta dos globos). Solo eliges categoría y nivel, juegas la palabra del día o Supervivencia con tres vidas. En grupo jugáis Fiesta: por turnos uno piensa una palabra o la app saca una, y el siguiente adivina. También puedes crear tu propia lista de palabras.",
    "Un mot est caché. Devine des lettres : chaque bonne lettre dévoile le mot, chaque erreur fait éclater un des huit ballons. Quand le dernier éclate, c'est perdu. Tu peux prendre deux indices et deviner le mot entier (un essai raté coûte deux ballons). Seul, tu choisis la catégorie et le niveau, joues le mot du jour ou Survie avec trois vies. À plusieurs, vous jouez en mode Fête : à tour de rôle l'un pense à un mot ou l'appli en tire un, et le suivant devine. Tu peux aussi créer ta propre liste de mots."),
 "Eigene Wörter": ("Your own words", "Palabras propias", "Mes propres mots"),
 "Eigenes Wort": ("Own word", "Palabra propia", "Mot personnel"),
 "Wort eingeben": ("Enter word", "Introducir palabra", "Saisir le mot"),
 "Party": ("Party", "Fiesta", "Fête"),
 "Wörter selbst ausdenken": ("Think up your own words", "Inventar las palabras", "Inventer les mots soi-même"),
 "Reihum denkt sich einer ein Wort aus, der Nächste rät. Wer scheitert, gibt dem Wortgeber 3 Punkte.": ("In turn one person thinks of a word, the next one guesses. If the guesser fails, the word-giver gets 3 points.", "Por turnos uno piensa una palabra y el siguiente adivina. Si falla, quien la pensó recibe 3 puntos.", "À tour de rôle l'un pense à un mot, le suivant devine. S'il échoue, celui qui a choisi le mot reçoit 3 points."),
 "Die App zieht die Wörter, ihr ratet reihum.": ("The app draws the words, you guess in turn.", "La app saca las palabras y adivináis por turnos.", "L'appli tire les mots, vous devinez à tour de rôle."),
 "Wörter eintragen": ("Add words", "Añadir palabras", "Ajouter des mots"),
 "Wörter verwalten (%lld)": ("Manage words (%lld)", "Gestionar palabras (%lld)", "Gérer les mots (%lld)"),
 "Noch keine eigenen Wörter.": ("No words of your own yet.", "Aún no hay palabras propias.", "Pas encore de mots personnels."),
 "Hinweis (freiwillig)": ("Hint (optional)", "Pista (opcional)", "Indice (facultatif)"),
 "Schreib deine eigene Wortliste, zum Beispiel für Familie oder Schule, mit freiem Hinweis.": ("Write your own word list, for example for family or school, with a free hint.", "Escribe tu propia lista de palabras, por ejemplo para la familia o la escuela, con una pista libre.", "Écris ta propre liste de mots, par exemple pour la famille ou l'école, avec un indice libre."),
 "Löse Wort für Wort mit drei Leben. Wer ein Wort gut löst, gewinnt ein Leben zurück, und die Wörter werden schwerer.": ("Solve word after word with three lives. Solve a word well and you win a life back, and the words get harder.", "Resuelve palabra tras palabra con tres vidas. Si resuelves bien una palabra, recuperas una vida, y las palabras se vuelven más difíciles.", "Résous les mots l'un après l'autre avec trois vies. Un mot bien résolu rapporte une vie, et les mots deviennent plus difficiles."),
 "Überleben starten": ("Start Survival", "Empezar Supervivencia", "Lancer Survie"),
 "Kinderleicht: nur leichte Wörter, mehr Hinweise": ("Kid-friendly: easy words only, more hints", "Para niños: solo palabras fáciles, más pistas", "Pour les enfants : mots faciles, plus d'indices"),
 "Leben übrig": ("Lives left", "Vidas restantes", "Vies restantes"),
 "%lld Wörter gelöst": ("%lld words solved", "%lld palabras resueltas", "%lld mots résolus"),
 "Ein Leben weniger": ("One life less", "Una vida menos", "Une vie de moins"),
 "Gelöst – ein Leben dazu!": ("Solved – one life back!", "¡Resuelta – una vida más!", "Résolu – une vie en plus !"),
 "Das hast du schon versucht.": ("You already tried that.", "Eso ya lo has probado.", "Tu as déjà essayé cela."),
 "Das ist kein gültiges Wort.": ("That is not a valid word.", "Esa no es una palabra válida.", "Ce n'est pas un mot valide."),
 "Dein Lösungsversuch: %@": ("Your solution attempt: %@", "Tu intento de solución: %@", "Ta proposition : %@"),
 "Falsch geraten, zwei Ballons weniger. Noch %lld Ballons.": ("Wrong guess, two balloons less. %lld balloons left.", "Fallaste, dos globos menos. Quedan %lld globos.", "Raté, deux ballons de moins. Il reste %lld ballons."),
 "%lld Hinweise": ("%lld hints", "%lld pistas", "%lld indices"),
 "%lld Runden": ("%lld rounds", "%lld rondas", "%lld manches"),
 "%@ · %lld Buchstaben": ("%@ · %lld letters", "%@ · %lld letras", "%@ · %lld lettres"),
 "%@, denk dir ein Wort aus. %@ schaut nicht hin.": ("%@, think of a word. %@ is not looking.", "%@, piensa una palabra. %@ no mira.", "%@, pense à un mot. %@ ne regarde pas."),
 "Das Wort braucht mindestens %lld Buchstaben.": ("The word needs at least %lld letters.", "La palabra necesita al menos %lld letras.", "Le mot doit avoir au moins %lld lettres."),
 "Das Wort darf höchstens %lld Buchstaben haben.": ("The word may have at most %lld letters.", "La palabra puede tener como máximo %lld letras.", "Le mot peut avoir au plus %lld lettres."),
 "Nur Buchstaben, Leerzeichen und Bindestrich sind erlaubt.": ("Only letters, spaces and hyphens are allowed.", "Solo se permiten letras, espacios y guiones.", "Seuls les lettres, espaces et traits d'union sont autorisés."),
 "Das Wort war %@": ("The word was %@", "La palabra era %@", "Le mot était %@"),
 "ohne Fehler": ("without mistakes", "sin fallos", "sans erreur"),
 "Runden je Spieler: %lld": ("Rounds per player: %lld", "Rondas por jugador: %lld", "Manches par joueur : %lld"),
 "%@ hat das Wort erraten": ("%@ guessed the word", "%@ adivinó la palabra", "%@ a deviné le mot"),
 "%@ hat das Wort nicht erraten": ("%@ did not guess the word", "%@ no adivinó la palabra", "%@ n'a pas deviné le mot"),
 "Heute erraten. Morgen gibt es ein neues Wort.": ("Guessed today. A new word tomorrow.", "Acertada hoy. Mañana habrá una nueva palabra.", "Trouvé aujourd'hui. Demain, un nouveau mot."),
 "Heute nicht erraten. Morgen gibt es ein neues Wort.": ("Not guessed today. A new word tomorrow.", "No acertada hoy. Mañana habrá una nueva palabra.", "Pas trouvé aujourd'hui. Demain, un nouveau mot."),
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
