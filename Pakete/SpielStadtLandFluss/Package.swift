// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// StadtLandFluss: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
let package = Package(
    name: "SpielStadtLandFluss",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielStadtLandFluss", targets: ["SpielStadtLandFluss"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../Baukasten")],
    targets: [
        .target(name: "StadtLandFlussKern"),
        .target(name: "SpielStadtLandFluss", dependencies: ["StadtLandFlussKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten")]),
        .testTarget(name: "StadtLandFlussKernTests", dependencies: ["StadtLandFlussKern"]),
    ],
    swiftLanguageModes: [.v5]
)
