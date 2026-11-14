// swift-tools-version: 5.10
// SPDX-License-Identifier: MIT
import PackageDescription

let package = Package(
    name: "SpielMinensuche",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SpielMinensuche", targets: ["SpielMinensuche"])],
    dependencies: [
        .package(path: "../Baukasten"),
        .package(path: "../SpieleKern"),
        .package(path: "../MinensucheKern"),
    ],
    targets: [
        .target(name: "SpielMinensuche", dependencies: [
            .product(name: "Baukasten", package: "Baukasten"),
            .product(name: "KlarGlas", package: "Baukasten"),
            .product(name: "SpieleKern", package: "SpieleKern"),
            .product(name: "MinensucheKern", package: "MinensucheKern"),
        ]),
        .testTarget(name: "SpielMinensucheTests", dependencies: ["SpielMinensuche", .product(name: "MinensucheKern", package: "MinensucheKern")]),
    ]
)
