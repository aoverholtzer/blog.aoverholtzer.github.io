// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "OverdesignedBlog",
    products: [
        .executable(
            name: "OverdesignedBlog",
            targets: ["OverdesignedBlog"]
        )
    ],
    dependencies: [
        .package(name: "Publish", url: "https://github.com/johnsundell/publish.git", from: "0.6.0"),
        .package(name: "HighlightJSPublishPlugin", url: "https://github.com/alex-ross/highlightjspublishplugin", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "OverdesignedBlog",
            dependencies: [
                "Publish",
                "HighlightJSPublishPlugin"
            ]
        )
    ]
)
