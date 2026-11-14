#!/usr/bin/env python3
"""funde_b12_zwei_strings.py: de/en/es/fr für Build-12-Funde (Branch build12-funde-2). Überschreibt nie vorhandene Übersetzungen. Aufruf aus dem Projektordner."""
import json
KAT='App/Ressourcen/Localizable.xcstrings'
U={"Setzt diese Partie fort":("Resumes this game","Continúa esta partida","Reprend cette partie"),
"Bitte zuerst alle Namen eintragen.":("Please enter all names first.","Escribe primero todos los nombres.","Saisis d’abord tous les noms."),
"Jeder Spieler braucht einen Namen.":("Every player needs a name.","Cada jugador necesita un nombre.","Chaque joueur doit avoir un nom."),
"Du spielst allein.":("You play alone.","Juegas solo.","Tu joues seul.")}
cat=json.load(open(KAT)); s=cat['strings']
for k,t in U.items():
    loc=s.setdefault(k,{}).setdefault('localizations',{})
    if 'en' in loc and 'fr' in loc: continue
    loc.setdefault('de',{"stringUnit":{"state":"translated","value":k}})
    for sp,v in zip(('en','es','fr'),t): loc[sp]={"stringUnit":{"state":"translated","value":v}}
open(KAT,'w').write(json.dumps(cat,ensure_ascii=False,indent=2)+"\n")
