// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Termul",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "Termul",
            targets: ["Termul"]
        )
    ],
    targets: [
        .executableTarget(
            name: "Termul",
            path: "Termul",
            exclude: [
                "Info.plist",
                "Termul.entitlements"
            ],
            resources: [
                .process("Resources")
            ],
            linkerSettings: [
                .unsafeFlags(["-Xlinker", "-sectcreate", "-Xlinker", "__TEXT", "-Xlinker", "__info_plist", "-Xlinker", "Termul/Info.plist"], .when(platforms: [.macOS]))
            ]
        )
    ]
)
