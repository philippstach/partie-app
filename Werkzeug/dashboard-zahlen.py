#!/usr/bin/env python3
"""Erzeugt Doku/dashboard-zahlen.json (Zeilen je Paket: Code = alle .swift außer Tests/, inkl. Package.swift; Tests = Tests/).
Aufruf im Repo-Wurzelordner: python3 Werkzeug/dashboard-zahlen.py > /tmp/zahlen.json"""
import json, os, re, subprocess, datetime
def zeilen(pfad, test):
    n = 0
    for root, _, fs in os.walk(pfad):
        if (os.sep + "Tests" in root + os.sep) != test: continue
        if ".build" in root: continue
        for f in fs:
            if f.endswith(".swift"): n += sum(1 for _ in open(os.path.join(root, f), errors="ignore"))
    return n
norm = lambda s: re.sub(r"[^a-z0-9]", "", s.lower().replace("ä","ae").replace("ö","oe").replace("ü","ue").replace("ß","ss").replace("(imbau)",""))
alt = json.load(open("Doku/dashboard-zahlen.json"))
alt_art = {norm(t["name"]): (t["name"].replace(" (im Bau)", ""), t["art"]) for t in alt["teile"]}
teile = []; arcade = 0; spiele = 0
for d in sorted(os.listdir("Pakete")):
    if not d.startswith("Spiel") or d in ("SpieleKern", "SpielHilfen"): continue
    p = f"Pakete/{d}"; key = norm(d[5:])
    modul = ""
    for root, _, fs in os.walk(p + "/Sources"):
        for f in fs:
            if f.endswith(".swift"):
                s = open(os.path.join(root, f)).read()
                if "Gattung." in s and "public let name" in s: modul = s
    m = re.search(r'public let name = "([^"]+)"', modul)
    art = "arcade" if "Gattung.arcade" in modul else None
    name, a = alt_art.get(key, (m.group(1) if m else d[5:], "neu"))
    if art: a = "arcade"
    if a == "arcade": arcade += 1
    spiele += 1
    teile.append(dict(name=name, art=a, code=zeilen(p, False), tests=zeilen(p, True)))
teile.sort(key=lambda t: t["name"].lower())
teile += [dict(name="Gemeinsamer Kern", art="kern", code=zeilen("Pakete/SpieleKern", False) + zeilen("Pakete/SpielHilfen", False), tests=zeilen("Pakete/SpieleKern", True) + zeilen("Pakete/SpielHilfen", True)),
          dict(name="Hülle (App)", art="huelle", code=zeilen("App", False), tests=0),
          dict(name="Widget", art="huelle", code=zeilen("Widget", False), tests=0),
          dict(name="KlarGlas (Design-Paket)", art="design", code=zeilen("../_Gemeinsam/Baukasten", False), tests=zeilen("../_Gemeinsam/Baukasten", True))]
h = subprocess.check_output(["git", "rev-parse", "--short", "HEAD"], text=True).strip()
n = int(subprocess.check_output(["git", "rev-list", "--count", "HEAD"], text=True))
print(json.dumps(dict(stand=datetime.datetime.now().strftime("%d.%m.%Y, %H:%M"), commit=h, commits=n, spielzahl=spiele, arcadeGebaut=arcade, teile=teile), ensure_ascii=False, indent=1))
