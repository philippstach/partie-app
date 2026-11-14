// swift-tools-version: 5.10
// SPDX-License-Identifier: MIT
import PackageDescription

let package = Package(
    name: "SpielFarbraetsel",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielFarbraetsel", targets: ["SpielFarbraetsel"])],
    dependencies: [
        .package(path: "../Baukasten"),
        .package(path: "../SpieleKern"),
    ],
    targets: [
        .target(name: "SpielFarbraetsel", dependencies: [
            .product(name: "Baukasten", package: "Baukasten"),
            .product(name: "KlarGlas", package: "Baukasten"),
            .product(name: "SpieleKern", package: "SpieleKern"),
        ]),
        .testTarget(name: "SpielFarbraetselTests", dependencies: ["SpielFarbraetsel"]),
    ]
)
