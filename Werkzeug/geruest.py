#!/usr/bin/env python3
"""geruest.py <Name> : legt Pakete/Spiel<Name> mit Kern-Ziel (<Name>Kern), Oberflächen-Ziel und Tests an (Dateien selbst schreiben)."""
import sys,os
n=sys.argv[1]
b=f"Pakete/Spiel{n}"
for d in (f"{b}/Sources/{n}Kern",f"{b}/Sources/Spiel{n}",f"{b}/Tests/{n}KernTests"): os.makedirs(d,exist_ok=True)
open(f"{b}/Package.swift","w").write(f'''// swift-tools-version: 6.0
import PackageDescription

// {n}: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
let package = Package(
    name: "Spiel{n}",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "Spiel{n}", targets: ["Spiel{n}"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../../../_Gemeinsam/Baukasten")],
    targets: [
        .target(name: "{n}Kern"),
        .target(name: "Spiel{n}", dependencies: ["{n}Kern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten")]),
        .testTarget(name: "{n}KernTests", dependencies: ["{n}Kern"]),
    ],
    swiftLanguageModes: [.v5]
)
''')
