#!/usr/bin/env python3
"""uebernehmen.py <PaketName> <Quellordner mit Swift-Dateien> [--extra-dep Name=Pfad]...
Legt Pakete/<PaketName> an: kopiert Swift-Quellen (ohne KlarGlas-Kopien, ohne Tests), entfernt `@main`-Block,
setzt Imports KlarGlas + SpieleKern. Aufruf aus Partie/Haupt."""
import sys, os, re, shutil
name, src = sys.argv[1], os.path.expanduser(sys.argv[2])
extra = [a.split("=",1) for a in sys.argv[3:]]
dst = f"Pakete/{name}/Sources/{name}"
shutil.rmtree(f"Pakete/{name}", ignore_errors=True)
os.makedirs(dst)
for root,_,files in os.walk(src):
    for f in files:
        if not f.endswith(".swift") or f in ("KlarGlas.swift","KlarGlasBausteine.swift"): continue
        rel = os.path.relpath(os.path.join(root,f), src)
        if "Tests" in rel: continue
        t = os.path.join(dst, rel); os.makedirs(os.path.dirname(t), exist_ok=True)
        s = open(os.path.join(root,f)).read()
        # @main-Block entfernen (bis zur schließenden Klammer auf Spalte 0)
        m = re.search(r"^@main\s*\nstruct \w+: App \{.*?^\}\n", s, flags=re.S|re.M)
        if m: s = s[:m.start()] + s[m.end():]
        imps = "".join(f"import {i}\n" for i in ("KlarGlas","SpieleKern") if f"import {i}\n" not in s)
        if "import SwiftUI\n" in s: s = s.replace("import SwiftUI\n","import SwiftUI\n"+imps,1)
        else: s = imps + s
        open(t,"w").write(s)
deps = ['.package(path: "../../../_Gemeinsam/Baukasten")','.package(path: "../SpieleKern")'] + [f'.package(path: "{p}")' for _,p in extra]
prods = ['.product(name: "Baukasten", package: "Baukasten")','.product(name: "KlarGlas", package: "Baukasten")','.product(name: "SpieleKern", package: "SpieleKern")'] + [f'.product(name: "{n}", package: "{os.path.basename(p)}")' for n,p in extra]
open(f"Pakete/{name}/Package.swift","w").write(f'''// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "{name}",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "{name}", targets: ["{name}"])],
    dependencies: [
        {(","+chr(10)+"        ").join(deps)},
    ],
    targets: [
        .target(name: "{name}", dependencies: [
            {(","+chr(10)+"            ").join(prods)},
        ]),
    ]
)
''')
print("ok", name)
