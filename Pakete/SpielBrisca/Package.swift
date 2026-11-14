// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Brisca: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
let package = Package(
    name: "SpielBrisca",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielBrisca", targets: ["SpielBrisca"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../Baukasten")],
    targets: [
        .target(name: "BriscaKern"),
        .target(name: "SpielBrisca", dependencies: ["BriscaKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten")]),
        .testTarget(name: "BriscaKernTests", dependencies: ["BriscaKern"]),
    ],
    swiftLanguageModes: [.v5]
)
