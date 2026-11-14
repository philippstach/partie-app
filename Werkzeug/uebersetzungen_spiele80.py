#!/usr/bin/env python3
"""uebersetzungen_spiele80.py: en/es/fr-Texte für die VoiceOver-Beschriftungen aus dem Branch spiele-80.
Überschreibt nie vorhandene Übersetzungen. Aufruf aus dem Projektordner."""
import json
KAT = 'App/Ressourcen/Localizable.xcstrings'
U = {
"Spielbrett mit 100 Feldern": ("Board with 100 squares", "Tablero de 100 casillas", "Plateau de 100 cases"),
"Würfel: %lld und %lld": ("Dice: %lld and %lld", "Dados: %lld y %lld", "Dés : %lld et %lld"),
"Würfel: %lld, %lld, %lld": ("Dice: %lld, %lld, %lld", "Dados: %lld, %lld, %lld", "Dés : %lld, %lld, %lld"),
"Läuft": ("In progress", "En curso", "En cours"),
"Offen": ("Open", "Pendiente", "À venir"),
"%lld Paare": ("%lld pairs", "%lld parejas", "%lld paires"),
"Bau-Stapel %lld": ("Build pile %lld", "Pila %lld", "Pile %lld"),
"Ablage %lld": ("Discard %lld", "Descarte %lld", "Défausse %lld"),
"Tipp: Würfle – es steht noch nichts auf dem Spiel.": ("Hint: Roll – nothing is at stake yet.", "Pista: Tira, aún no hay nada en juego.", "Indice : lance, rien n’est encore en jeu."),
"Tipp: Sichere jetzt – %lld Punkte sind genug.": ("Hint: Bank now – %lld points are enough.", "Pista: Asegura ya, %lld puntos son suficientes.", "Indice : mets à l’abri maintenant, %lld points suffisent."),
"Tipp: Würfle weiter – %lld Punkte sind noch zu wenig.": ("Hint: Keep rolling – %lld points are not enough yet.", "Pista: Sigue tirando, %lld puntos aún son pocos.", "Indice : continue à lancer, %lld points ne suffisent pas encore."),
"Oberste Scheibe: %lld": ("Top disc: %lld", "Disco superior: %lld", "Disque du dessus : %lld"),
"Pasch %lld": ("Double %lld", "Doble %lld", "Double %lld"),
"Aufgedeckt: %@ – %@ verliert ein Leben. (Ansage von %@: %@)": ("Revealed: %@ – %@ loses a life. (Call by %@: %@)", "Descubierto: %@ – %@ pierde una vida. (Anuncio de %@: %@)", "Dévoilé : %@ – %@ perd une vie. (Annonce de %@ : %@)"),
"Doppeltippen, um die gewählte Karte anzulegen": ("Double-tap to add the selected card", "Toca dos veces para añadir la carta elegida", "Touche deux fois pour ajouter la carte choisie"),
"Pfote": ("Paw", "Huella", "Patte"),
"Echse": ("Lizard", "Lagarto", "Lézard"),
}
cat = json.load(open(KAT))
n = 0
for k, (en, es, fr) in U.items():
    e = cat['strings'].setdefault(k, {})
    loc = e.setdefault('localizations', {})
    for sp, v in (('de', k), ('en', en), ('es', es), ('fr', fr)):
        if sp not in loc:
            loc[sp] = {'stringUnit': {'state': 'translated', 'value': v}}; n += 1
orig = open(KAT).read()
open(KAT, 'w').write(json.dumps(cat, ensure_ascii=False, indent=2, separators=(',', ': ')) + ('\n' if orig.endswith('\n') else ''))
print('eingetragen:', n)
