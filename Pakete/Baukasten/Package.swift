// swift-tools-version: 5.10
// SPDX-License-Identifier: MIT
import PackageDescription

// Ein Paket, zwei Produkte (Design-Konzept 3.2):
//   `Baukasten` = Funktionen (App-Farbe, Trinkgeld, Bewertung, Mehr von mir, Über mich, Game Center, Erinnerung)
//   `KlarGlas`  = Optik (Designkern und alle Bausteine des CI-Handbuchs; Versionsnummer in `KlarGlas.version`)
// Beide Produkte sind unabhängig; Apps binden in der Regel beide ein. Nur der Design-Chat ändert `KlarGlas`.
// iOS 17 wie im Grundgerüst; macOS nur, damit `swift test` die Logik ohne Simulator prüft (die Ansichten sind iOS-only).
let package = Package(
    name: "Baukasten",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "Baukasten", targets: ["Baukasten"]),
        .library(name: "KlarGlas", targets: ["KlarGlas"]),
    ],
    targets: [
        .target(name: "Baukasten", resources: [.process("Resources")]),
        .target(name: "KlarGlas", resources: [.process("Resources")]),
        .testTarget(name: "BaukastenTests", dependencies: ["Baukasten"]),
        .testTarget(name: "KlarGlasTests", dependencies: ["KlarGlas"]),
    ]
)
