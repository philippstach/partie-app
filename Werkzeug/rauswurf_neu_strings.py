#!/usr/bin/env python3
"""Rauswurf (neu): trägt die neuen Texte (de/en/es/fr) in App/Ressourcen/Localizable.xcstrings ein.
Fehlende Schlüssel werden angelegt, vorhandene bleiben unberührt. Aufruf: python3 Werkzeug/rauswurf_neu_strings.py"""
import json, os

PFAD = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "App", "Ressourcen", "Localizable.xcstrings")

T = {
 "Rauswurf (neu)": ("Ludo (new)", "Parchís (nuevo)", "Petits chevaux (nouveau)"),
 "Würfeln, ziehen, rauswerfen": ("Roll, move, knock out", "Tirar, mover, echar", "Lancer, avancer, renvoyer"),
 "Bring als Erster alle deine Figuren ins Ziel.": ("Be the first to bring all your pieces home.", "Sé el primero en llevar todas tus fichas a la meta.", "Sois le premier à amener tous tes pions à l'arrivée."),
 "Jeder Spieler hat vier Figuren im Haus. Mit einer 6 kommt eine Figur auf dein Startfeld, dann darfst du nochmal würfeln. Du ziehst eine Figur um die gewürfelte Zahl auf der Laufbahn vorwärts. Landest du auf einer fremden Figur, wird sie rausgeworfen und muss zurück ins Haus. Wer zuerst alle Figuren ins Ziel gebracht hat, gewinnt. Vor der Partie wählst du eine Spielart und kannst einzelne Hausregeln ändern: Rauspflicht, Startfeld räumen, Schlagpflicht, drei Versuche, Teams und mehr.":
   ("Each player has four pieces in the house. With a 6, a piece enters your start square and you roll again. You move a piece forward along the track by the number rolled. If you land on another player's piece, it is knocked out and must return to the house. Whoever brings all pieces home first wins. Before the game you choose a variant and can change individual house rules: must leave with a 6, clear the start square, must capture, three tries, teams and more.",
    "Cada jugador tiene cuatro fichas en la casa. Con un 6, una ficha sale a tu casilla de salida y vuelves a tirar. Avanzas una ficha por el recorrido tantas casillas como indique el dado. Si caes sobre una ficha ajena, esta es expulsada y vuelve a la casa. Gana quien lleve primero todas sus fichas a la meta. Antes de la partida eliges una variante y puedes cambiar reglas de la casa: salir obligatoriamente con 6, despejar la salida, captura obligatoria, tres intentos, equipos y más.",
    "Chaque joueur a quatre pions dans sa maison. Avec un 6, un pion arrive sur ta case de départ et tu relances. Tu avances un pion sur le parcours du nombre obtenu. Si tu tombes sur un pion adverse, il est renvoyé et doit retourner à la maison. Le premier à amener tous ses pions à l'arrivée gagne. Avant la partie, tu choisis une variante et peux modifier des règles maison : sortie obligatoire avec un 6, libérer la case départ, prise obligatoire, trois essais, équipes et plus."),
 "Tippe den Würfel oder den Knopf „Würfeln“. Mit einer 6 kommt eine Figur aus dem Haus und du würfelst nochmal.": ("Tap the die or the Roll button. With a 6 a piece leaves the house and you roll again.", "Toca el dado o el botón Tirar. Con un 6 sale una ficha de la casa y vuelves a tirar.", "Touche le dé ou le bouton Lancer. Avec un 6, un pion sort de la maison et tu relances."),
 "Tippe eine leuchtende Figur an. Landest du auf einer fremden Figur, muss sie zurück ins Haus.": ("Tap a glowing piece. If you land on another player's piece, it must go back to the house.", "Toca una ficha iluminada. Si caes sobre una ficha ajena, esta vuelve a la casa.", "Touche un pion lumineux. Si tu tombes sur un pion adverse, il retourne à la maison."),
 "Spielart": ("Variant", "Variante", "Variante"),
 "Computer lässt Menschen gewinnen": ("Computer lets humans win", "El ordenador deja ganar a las personas", "L'ordinateur laisse gagner les humains"),
 "Haus %lld · Ziel %lld": ("House %lld · Goal %lld", "Casa %lld · Meta %lld", "Maison %lld · Arrivée %lld"),
 "%lld Spielzüge": ("%lld turns", "%lld turnos", "%lld tours"),
 "wirft %@ raus": ("knocks out %@", "echa a %@", "renvoie %@"),
 "kein Zug": ("no move", "sin movimiento", "pas de coup"),
 "Zahl eintippen": ("Enter number", "Introducir número", "Saisir le nombre"),
 "Figur wählen": ("Choose a piece", "Elegir una ficha", "Choisir un pion"),
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
