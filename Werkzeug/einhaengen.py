#!/usr/bin/env python3
"""einhaengen.py <Paketname ohne Spiel-Präfix, z. B. Mühle=Muehle> <ModulKlasse>: trägt ein neues Spielpaket in project.yml und PartieApp.swift ein."""
import sys
pk,modul=sys.argv[1],sys.argv[2]
y=open('project.yml').read()
if f"Spiel{pk}:" not in y:
    y=y.replace("  Spiel10k: { path: Pakete/Spiel10k }\n",f"  Spiel10k: {{ path: Pakete/Spiel10k }}\n  Spiel{pk}: {{ path: Pakete/Spiel{pk} }}\n",1)
    y=y.replace("        product: Spiel10kModul\n",f"        product: Spiel10kModul\n      - package: Spiel{pk}\n",1)
    open('project.yml','w').write(y)
a=open('App/PartieApp.swift').read()
if f"import Spiel{pk}\n" not in a:
    a=a.replace("import Spiel10kModul\n",f"import Spiel10kModul\nimport Spiel{pk}\n",1)
    a=a.replace("        ZehnKModul(),\n",f"        ZehnKModul(),\n        {modul}(),\n",1)
    open('App/PartieApp.swift','w').write(a)
