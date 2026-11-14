// swift-tools-version: 5.10
// SPDX-License-Identifier: MIT
import PackageDescription

let package = Package(
    name: "SpielRauswurf",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielRauswurf", targets: ["SpielRauswurf"])],
    dependencies: [
        .package(path: "../Baukasten"),
        .package(path: "../SpieleKern"),
    ],
    targets: [
        .target(name: "SpielRauswurf", dependencies: [
            .product(name: "Baukasten", package: "Baukasten"),
            .product(name: "KlarGlas", package: "Baukasten"),
            .product(name: "SpieleKern", package: "SpieleKern"),
        ]),
        .testTarget(name: "SpielRauswurfTests", dependencies: ["SpielRauswurf", .product(name: "SpieleKern", package: "SpieleKern")]),
    ]
)
