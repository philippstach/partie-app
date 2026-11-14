// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Irrgang: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
let package = Package(
    name: "SpielIrrgang",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielIrrgang", targets: ["SpielIrrgang"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../Baukasten"), .package(path: "../SpielHilfen"), .package(path: "../../Test/DesignBilder")],
    targets: [
        .target(name: "IrrgangKern"),
        .target(name: "SpielIrrgang", dependencies: ["IrrgangKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten"), .product(name: "SpielHilfen", package: "SpielHilfen")]),
        .testTarget(name: "IrrgangKernTests", dependencies: ["IrrgangKern"]),
        .testTarget(name: "IrrgangKlarTests", dependencies: ["SpielIrrgang", "IrrgangKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten"), .product(name: "DesignBilder", package: "DesignBilder")]),
    ],
    swiftLanguageModes: [.v5]
)
