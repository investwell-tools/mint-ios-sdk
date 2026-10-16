// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MintSDK",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "MintSDK",
            targets: ["MintFrameworks", "VoltFramework"]
        ),
        .library(
            name: "MintFrameworks",
            targets: ["MintFrameworks"]
        )
    ],
    targets: [
        .binaryTarget(
            name: "MintFrameworks",
            url: "https://github.com/investwell-tools/mint-ios-sdk/releases/download/1.1.2/MintFrameworks.xcframework.zip",
            checksum: "6ca29eaa636276312caaddca1f9e2707d03ce487caafb09d3b7fae05a8942ba6"
        ),
        .binaryTarget(
            name: "VoltFramework",
            url: "https://github.com/investwell-tools/mint-ios-sdk/releases/download/1.1.2/VoltFramework.xcframework.zip",
            checksum: "a914a019a8e9e902df0090159d863d09ccb931611189a7b7323d77c2ad8cb9df"
        )
    ]
)
