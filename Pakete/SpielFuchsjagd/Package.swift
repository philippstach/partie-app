// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Fuchsjagd: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
let package = Package(
    name: "SpielFuchsjagd",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielFuchsjagd", targets: ["SpielFuchsjagd"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../Baukasten"), .package(path: "../SpielHilfen")],
    targets: [
        .target(name: "FuchsjagdKern"),
        .target(name: "SpielFuchsjagd", dependencies: ["FuchsjagdKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten"), .product(name: "SpielHilfen", package: "SpielHilfen")]),
        .testTarget(name: "FuchsjagdKernTests", dependencies: ["FuchsjagdKern"]),
    ],
    swiftLanguageModes: [.v5]
)
