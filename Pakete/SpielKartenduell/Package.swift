// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Kartenduell: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
let package = Package(
    name: "SpielKartenduell",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielKartenduell", targets: ["SpielKartenduell"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../Baukasten")],
    targets: [
        .target(name: "KartenduellKern"),
        .target(name: "SpielKartenduell", dependencies: ["KartenduellKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten")]),
        .testTarget(name: "KartenduellKernTests", dependencies: ["KartenduellKern"]),
    ],
    swiftLanguageModes: [.v5]
)
