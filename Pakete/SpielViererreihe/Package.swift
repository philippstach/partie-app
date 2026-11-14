// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Viererreihe : die eine Fassung des Spiels in der Sammlung.
// Der Regelkern wird geteilt: `Sources/SpielViererreihe/Kern/` enthält nur Verweise auf dieselben Dateien wie `KernViererreihe`
// (Quelle: SpielViererreihe/Sources/SpielViererreihe/Model). Eigener Modulname, damit beide Module in einer App liegen können.
// Tests: `swift test` auf dem Mac, ohne Simulator.
let package = Package(
    name: "SpielViererreihe",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielViererreihe", targets: ["SpielViererreihe"])],
    dependencies: [
        .package(path: "../Baukasten"),
        .package(path: "../SpieleKern"),
        .package(path: "../SpielHilfen"),
    ],
    targets: [
        .target(name: "SpielViererreihe", dependencies: [
            .product(name: "KlarGlas", package: "Baukasten"),
            .product(name: "SpieleKern", package: "SpieleKern"),
            .product(name: "SpielHilfen", package: "SpielHilfen"),
        ]),
        .testTarget(name: "SpielViererreiheTests", dependencies: ["SpielViererreihe", .product(name: "SpieleKern", package: "SpieleKern")]),
    ],
    swiftLanguageModes: [.v5]
)
