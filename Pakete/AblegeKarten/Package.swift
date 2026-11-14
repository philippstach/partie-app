// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Baustein für Ablege-Kartenspiele (Tisch und Hand): Kartenfächer und Stapelanzeige, unabhängig vom Kartenbild.
// Gedacht für Elfer raus und Mau-Mau. Die Fächer-Rechnung (`FaecherMasse`) ist reine Logik und läuft mit `swift test`.
let package = Package(
    name: "AblegeKarten",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "AblegeKarten", targets: ["AblegeKarten"])],
    dependencies: [.package(path: "../Baukasten")],
    targets: [
        .target(name: "AblegeKarten", dependencies: [.product(name: "KlarGlas", package: "Baukasten")]),
        .testTarget(name: "AblegeKartenTests", dependencies: ["AblegeKarten"]),
    ],
    swiftLanguageModes: [.v5]
)
