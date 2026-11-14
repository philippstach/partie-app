// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Oware: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
let package = Package(
    name: "SpielOware",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielOware", targets: ["SpielOware"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../Baukasten"), .package(path: "../SpielHilfen")],
    targets: [
        .target(name: "OwareKern"),
        .target(name: "SpielOware", dependencies: ["OwareKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten"), .product(name: "SpielHilfen", package: "SpielHilfen")]),
        .testTarget(name: "OwareKernTests", dependencies: ["OwareKern", .product(name: "SpieleKern", package: "SpieleKern")]),
    ],
    swiftLanguageModes: [.v5]
)
