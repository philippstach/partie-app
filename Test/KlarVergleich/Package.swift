// swift-tools-version: 5.10
// SPDX-License-Identifier: MIT
import PackageDescription
import Foundation

// Designwechsel: Beweis, dass „Klar & Glas“ unverändert aussieht. Dieselben Szenen werden einmal mit dem Stand von
// Build 12 (Baukasten 2.16, SpieleKern aus e405298e) und einmal mit dem Designwechsel-Stand (Design „klar“) gezeichnet;
// Werkzeug/designwechsel_klar_vergleich.sh stellt beide Bäume bereit und vergleicht die Bilder Punkt für Punkt.
// Die Paketpfade sind in beiden Bäumen gleich. „NEU“ ist gesetzt, wenn der Baukasten den Designwechsel enthält.
let neu = FileManager.default.fileExists(atPath: Context.packageDirectory + "/../../../_Gemeinsam/Baukasten/Sources/KlarGlas/DesignWahl.swift")

let package = Package(
    name: "KlarVergleich",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "KlarFangen", targets: ["KlarFangen"])],
    dependencies: [
        .package(path: "../../../_Gemeinsam/Baukasten"),
        .package(path: "../../Pakete/SpieleKern"),
    ],
    targets: [
        .target(name: "KlarFangen"),
        .testTarget(name: "KlarVergleichTests", dependencies: [
            "KlarFangen",
            .product(name: "KlarGlas", package: "Baukasten"),
            .product(name: "SpieleKern", package: "SpieleKern"),
        ], swiftSettings: neu ? [.define("NEU")] : []),
    ]
)
