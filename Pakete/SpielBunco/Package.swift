// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Bunco: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
let package = Package(
    name: "SpielBunco",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielBunco", targets: ["SpielBunco"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../Baukasten")],
    targets: [
        .target(name: "BuncoKern"),
        .target(name: "SpielBunco", dependencies: ["BuncoKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten")]),
        .testTarget(name: "BuncoKernTests", dependencies: ["BuncoKern"]),
    ],
    swiftLanguageModes: [.v5]
)
