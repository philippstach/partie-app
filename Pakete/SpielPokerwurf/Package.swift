// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Pokerwurf: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
let package = Package(
    name: "SpielPokerwurf",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielPokerwurf", targets: ["SpielPokerwurf"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../Baukasten"), .package(path: "../SpielHilfen")],
    targets: [
        .target(name: "PokerwurfKern", dependencies: [.product(name: "SpieleKern", package: "SpieleKern")]),
        .target(name: "SpielPokerwurf", dependencies: ["PokerwurfKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten"), .product(name: "SpielHilfen", package: "SpielHilfen")]),
        .testTarget(name: "PokerwurfKernTests", dependencies: ["PokerwurfKern"]),
    ],
    swiftLanguageModes: [.v5]
)
