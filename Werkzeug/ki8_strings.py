# KI-8 (Siri und Spotlight): trägt die neuen Texte der Intents „Neue Partie“, „Gegen den Computer“, „Tagesrätsel“ und ihrer Antworten
# in App/Ressourcen/Localizable.xcstrings ein (de, en, es, fr). Bestehende Schlüssel bleiben unberührt.
import json, pathlib
P = pathlib.Path(__file__).resolve().parent.parent / "App/Ressourcen/Localizable.xcstrings"
T = {
"Startet eine neue Partie eines Spiels, auf Wunsch mit Spielerzahl und Computergegnern.": (None,
    "Starts a new game of a title, optionally with a number of players and computer opponents.",
    "Empieza una partida nueva de un juego, si quieres con número de jugadores y rivales del ordenador.",
    "Lance une nouvelle partie d’un jeu, si tu veux avec un nombre de joueurs et des adversaires ordinateur."),
"Menschen": (None, "People", "Personas", "Personnes"),
"Wie viele Menschen mitspielen.": (None, "How many people play.", "Cuántas personas juegan.", "Combien de personnes jouent."),
"Wie viele Computergegner mitspielen.": (None, "How many computer opponents play.", "Cuántos rivales del ordenador juegan.", "Combien d’adversaires ordinateur jouent."),
"Neue Partie ${spiel}": (None, "New game of ${spiel}", "Nueva partida de ${spiel}", "Nouvelle partie de ${spiel}"),
"Gegen den Computer": (None, "Against the computer", "Contra el ordenador", "Contre l’ordinateur"),
"Startet eine neue Partie gegen den Computer.": (None, "Starts a new game against the computer.", "Empieza una partida nueva contra el ordenador.", "Lance une nouvelle partie contre l’ordinateur."),
"${spiel} gegen den Computer": (None, "${spiel} against the computer", "${spiel} contra el ordenador", "${spiel} contre l’ordinateur"),
"Öffnet das nächste Tagesrätsel, das du heute noch nicht gelöst hast.": (None, "Opens the next daily puzzle you have not solved today.", "Abre el siguiente acertijo del día que aún no has resuelto hoy.", "Ouvre la prochaine énigme du jour que tu n’as pas encore résolue aujourd’hui."),
"Dieses Spiel gibt es nicht.": (None, "There is no such game.", "Ese juego no existe.", "Ce jeu n’existe pas."),
"Ich starte eine neue Partie %@.": (None, "Starting a new game of %@.", "Empiezo una partida nueva de %@.", "Je lance une nouvelle partie de %@."),
"%@ hat keinen Computergegner. Ich starte ohne.": (None, "%@ has no computer opponent. Starting without.", "%@ no tiene rival del ordenador. Empiezo sin él.", "%@ n’a pas d’adversaire ordinateur. Je lance sans."),
"%@ spielst du allein. Ich starte eine neue Partie.": (None, "You play %@ alone. Starting a new game.", "A %@ juegas solo. Empiezo una partida nueva.", "%@ se joue en solo. Je lance une nouvelle partie."),
"So viele Plätze hat %@ nicht. Ich starte mit der größtmöglichen Runde.": (None, "%@ does not have that many seats. Starting with the largest possible round.", "%@ no tiene tantos puestos. Empiezo con la ronda más grande posible.", "%@ n’a pas autant de places. Je lance avec la plus grande partie possible."),
}
d = json.loads(P.read_text(encoding="utf-8")); neu = 0
for k, (de, en, es, fr) in T.items():
    if k in d["strings"]: continue
    d["strings"][k] = {"localizations": {l: {"stringUnit": {"state": "translated", "value": v}} for l, v in (("de", de or k), ("en", en), ("es", es), ("fr", fr))}}
    neu += 1
P.write_text(json.dumps(d, ensure_ascii=False, indent=2, separators=(",", ": ")) + "\n", encoding="utf-8")
print("neu:", neu)
