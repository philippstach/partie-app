#!/usr/bin/env python3
"""knopf.py <Datei.swift> <Strukturname> [klein]: setzt den Rundknopf „Sammlung“ vor das erste `Spacer()` und die Umgebungsvariable."""
import sys,re
p,name=sys.argv[1],sys.argv[2]; klein=len(sys.argv)>3
s=open(p).read()
s=s.replace("struct %s: View {\n"%name,"struct %s: View {\n    @Environment(\\.zurSammlung) private var zurSammlung\n"%name,1)
i=s.index("Spacer()"); ls=s.rfind("\n",0,i)+1; ind=s[ls:i]
k=", klein: true" if klein else ""
s=s[:ls]+ind+'if let zurSammlung { RundKnopf(symbol: "square.grid.2x2", beschriftung: "Sammlung"%s) { zurSammlung() } }\n'%k+s[ls:]
open(p,"w").write(s)
