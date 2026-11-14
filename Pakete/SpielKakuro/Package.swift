// swift-tools-version: 6.0
// SPDX-License-Identifier: MIT
import PackageDescription

// Kakuro: Logik (Foundation, mit swift test auf dem Mac prüfbar) und Oberfläche getrennt.
let package = Package(
    name: "SpielKakuro",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielKakuro", targets: ["SpielKakuro"])],
    dependencies: [.package(path: "../SpieleKern"), .package(path: "../Baukasten"), .package(path: "../SpielHilfen"), .package(path: "../../Test/DesignBilder")],
    targets: [
        .target(name: "KakuroKern"),
        .target(name: "SpielKakuro", dependencies: ["KakuroKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten"), .product(name: "SpielHilfen", package: "SpielHilfen")]),
        .testTarget(name: "KakuroKernTests", dependencies: ["KakuroKern"]),
        .testTarget(name: "KakuroKlarTests", dependencies: ["SpielKakuro", "KakuroKern", .product(name: "SpieleKern", package: "SpieleKern"), .product(name: "KlarGlas", package: "Baukasten"), .product(name: "DesignBilder", package: "DesignBilder")]),
    ],
    swiftLanguageModes: [.v5]
)
