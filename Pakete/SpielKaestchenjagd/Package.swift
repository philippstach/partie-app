// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Kaestchenjagd: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
let package = Package(
    name: "SpielKaestchenjagd",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielKaestchenjagd", targets: ["SpielKaestchenjagd"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../Baukasten")],
    targets: [
        .target(name: "KaestchenjagdKern"),
        .target(name: "SpielKaestchenjagd", dependencies: ["KaestchenjagdKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten")]),
        .testTarget(name: "KaestchenjagdKernTests", dependencies: ["KaestchenjagdKern"]),
    ],
    swiftLanguageModes: [.v5]
)
