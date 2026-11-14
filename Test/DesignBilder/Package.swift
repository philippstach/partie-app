// swift-tools-version: 5.10
// SPDX-License-Identifier: MIT
import PackageDescription

// Designwechsel F.1: Vorschaubilder ohne Simulator. Die Tests zeichnen Ansichten unter Mac Catalyst als PNG
// (390 × 844, Maßstab 2) nach Partie/DesignWechsel/Bilder. Aufruf: Werkzeug/designwechsel_bilder.sh
let package = Package(
    name: "DesignBilder",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "DesignBilder", targets: ["DesignBilder"])],
    dependencies: [
        .package(path: "../../../_Gemeinsam/Baukasten"),
        .package(path: "../../Pakete/SpieleKern"),
        .package(path: "../../Pakete/SpielHilfen"),
        .package(path: "../../Pakete/SpielSchiebepuzzle"),
        .package(path: "../../Pakete/SpielFarbflut"),
        .package(path: "../../Pakete/SpielKoenigsweg"),
        .package(path: "../../Pakete/SpielMinensuche"),
        .package(path: "../../Pakete/SpielWortpfeil"),
        .package(path: "../../Pakete/MinensucheKern"),
        .package(path: "../../Pakete/SpielMauMau"),
        .package(path: "../../Pakete/SpielSchwimmen"),
        .package(path: "../../Pakete/SpielElferRaus"),
        .package(path: "../../Pakete/SpielSiebzehn"),
        .package(path: "../../Pakete/SpielMaexchen"),
        .package(path: "../../Pakete/SpielChicago"),
        .package(path: "../../Pakete/SpielPokerwurf"),
        .package(path: "../../Pakete/SpielRauswurf"),
        .package(path: "../../Pakete/SpielGalgenmaennchen"),
        .package(path: "../../Pakete/SpielHerzensjagd"),
        .package(path: "../../Pakete/SpielRomme"),
        .package(path: "../../Pakete/SpielMogeln"),
    ],
    targets: [
        .target(name: "Fangen"),
        .target(name: "DesignBilder", dependencies: [
            "Fangen",
            .product(name: "KlarGlas", package: "Baukasten"),
            .product(name: "SpieleKern", package: "SpieleKern"),
        ]),
        // Die echten Startseiten-Dateien der App (Verweise auf App/Start) mit Attrappen für Katalog und Layout.
        .target(name: "HuelleBilder", dependencies: [
            .product(name: "KlarGlas", package: "Baukasten"),
            .product(name: "SpieleKern", package: "SpieleKern"),
        ]),
        .testTarget(name: "DesignBilderTests", dependencies: ["DesignBilder", "HuelleBilder", .product(name: "Baukasten", package: "Baukasten"), .product(name: "SpielHilfen", package: "SpielHilfen"), .product(name: "SpielSchiebepuzzle", package: "SpielSchiebepuzzle"), .product(name: "SpielFarbflut", package: "SpielFarbflut"), .product(name: "SpielKoenigsweg", package: "SpielKoenigsweg"), .product(name: "SpielMinensuche", package: "SpielMinensuche"), .product(name: "SpielWortpfeil", package: "SpielWortpfeil"), .product(name: "SpielMauMau", package: "SpielMauMau"), .product(name: "SpielSchwimmen", package: "SpielSchwimmen"), .product(name: "SpielElferRaus", package: "SpielElferRaus"), .product(name: "SpielSiebzehn", package: "SpielSiebzehn"), .product(name: "SpielMaexchen", package: "SpielMaexchen"), .product(name: "SpielChicago", package: "SpielChicago"), .product(name: "SpielPokerwurf", package: "SpielPokerwurf"), .product(name: "SpielRauswurf", package: "SpielRauswurf"), .product(name: "SpielGalgenmaennchen", package: "SpielGalgenmaennchen"), .product(name: "SpielHerzensjagd", package: "SpielHerzensjagd"), .product(name: "SpielRomme", package: "SpielRomme"), .product(name: "SpielMogeln", package: "SpielMogeln"), .product(name: "FarbflutKern", package: "SpielFarbflut"), .product(name: "MinensucheKern", package: "MinensucheKern")]),
    ]
)
