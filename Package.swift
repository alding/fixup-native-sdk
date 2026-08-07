// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FixupModule",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "FixupModule",
            targets: ["FixupModule", "FixupModuleResources"]
        ),
    ],
    targets: [
        .binaryTarget(
            name: "FixupModule",
            url: "https://github.com/alding/fixup-native-sdk/releases/download/1.2.0/FixupModule.xcframework.zip",
            checksum: "ed839f15d9753d0cc582f1b9be8797a67d36621521a1bc09795b5981f9fa1796"
        ),
        .target(
            name: "FixupModuleResources",
            path: "Sources/FixupModuleResources",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
