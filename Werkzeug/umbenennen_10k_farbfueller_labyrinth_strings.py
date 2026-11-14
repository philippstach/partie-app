#!/usr/bin/env python3
"""10k -> Zehntausend, Farbflut -> Farbfüller, Irrgang -> Labyrinth (10.11.2026, Entscheidung Philipp). Aufruf aus dem Projektordner."""
import json
KAT='App/Ressourcen/Localizable.xcstrings'
orig=open(KAT).read(); cat=json.loads(orig); s=cat['strings']
def put(k,en,es,fr):
    s[k]={'extractionState':'manual','localizations':{l:{'stringUnit':{'state':'translated','value':v}} for l,v in (('de',k),('en',en),('es',es),('fr',fr))}}
put('Zehntausend','Ten Thousand','Diez mil','Dix mille')
put('Farbfüller','Flood','Inundación','Inondation')
put('Labyrinth','Maze','Laberinto','Labyrinthe')
put('Zehntausend ist ein Würfelklassiker. Auch bekannt als 10k, Zonk oder Farkle.','Ten Thousand is a classic dice game, also known as 10k, Zonk or Farkle.','Diez mil es un clásico de los dados, también conocido como 10k, Farkle o Zonk.','Dix mille est un classique des jeux de dés, aussi connu sous le nom de 10k, Farkle ou Zonk.')
put('Ein Wurf ohne zählende Würfel. Bei Zehntausend sind dann alle Punkte der Runde weg.','A roll with no scoring dice. In Ten Thousand, all points of the round are then lost.','Una tirada sin dados que puntúen. En Diez mil se pierden entonces todos los puntos de la ronda.','Un lancer sans dé qui compte. À Dix mille, tous les points du tour sont alors perdus.')
for k in ['Farbflut','10k ist ein Würfelklassiker. Auch bekannt als Zehntausend, Zonk oder Farkle.','Ein Wurf ohne zählende Würfel. Bei 10k sind dann alle Punkte der Runde weg.']: s.pop(k,None)
open(KAT,'w').write(json.dumps(cat,ensure_ascii=False,indent=2,separators=(',',': '))+('\n' if orig.endswith('\n') else ''))
