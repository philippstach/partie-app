#!/usr/bin/env python3
"""kreuzwort_umbenennen_strings.py: Wortpfeil heißt in der App „Kreuzworträtsel“ (10.11.2026). Aufruf aus dem Projektordner."""
import json
KAT='App/Ressourcen/Localizable.xcstrings'
orig=open(KAT).read(); cat=json.loads(orig); s=cat['strings']
s.pop('Wortpfeil',None); s.pop('Die Uhrzeit stellst du im Wortpfeil ein.',None)
k='Die Uhrzeit stellst du im Kreuzworträtsel ein.'
t={'de':k,'en':'You set the time in Crossword.','es':'La hora se ajusta en Crucigrama.','fr':'Tu règles l’heure dans Mots croisés.'}
s[k]={'extractionState':'manual','localizations':{l:{'stringUnit':{'state':'translated','value':v}} for l,v in t.items()}}
open(KAT,'w').write(json.dumps(cat,ensure_ascii=False,indent=2,separators=(',',': '))+('\n' if orig.endswith('\n') else ''))
