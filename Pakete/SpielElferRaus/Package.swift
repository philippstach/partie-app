// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Elfer raus : die eine Fassung des Spiels in der Sammlung.
// Regeln (Kern/) getrennt von der Oberfläche, `swift test` auf dem Mac ohne Simulator.
let package = Package(
    name: "SpielElferRaus",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielElferRaus", targets: ["SpielElferRaus"])],
    dependencies: [
        .package(path: "../Baukasten"),
        .package(path: "../SpieleKern"),
        .package(path: "../SpielHilfen"),
        .package(path: "../AblegeKarten"),
        .package(path: "../../Test/DesignBilder"),
    ],
    targets: [
        .target(name: "SpielElferRaus", dependencies: [
            .product(name: "KlarGlas", package: "Baukasten"),
            .product(name: "SpieleKern", package: "SpieleKern"),
            .product(name: "SpielHilfen", package: "SpielHilfen"),
            .product(name: "AblegeKarten", package: "AblegeKarten"),
        ]),
        .testTarget(name: "SpielElferRausTests", dependencies: ["SpielElferRaus", .product(name: "DesignBilder", package: "DesignBilder")]),
    ],
    swiftLanguageModes: [.v5]
)
