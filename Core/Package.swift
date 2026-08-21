// swift-tools-version: 6.0
import PackageDescription

// KodKirintisiCore — platform bağımsız çekirdek.
//
// KURAL: Bu paket Linux'ta derlenip test edilebilmeli.
// UIKit / SwiftUI / WidgetKit / AppIntents / CoreSpotlight import ETME.
// Sadece Foundation.

let package = Package(
    name: "KodKirintisiCore",
    platforms: [
        .iOS(.v18),
        .macOS(.v14) // yerel `swift test` için
    ],
    products: [
        .library(name: "KodKirintisiCore", targets: ["KodKirintisiCore"])
    ],
    targets: [
        .target(
            name: "KodKirintisiCore",
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "KodKirintisiCoreTests",
            dependencies: ["KodKirintisiCore"],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        )
    ]
)
