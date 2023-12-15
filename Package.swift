// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RxComposableArchitecture",
    platforms: [
      .iOS(.v11),
      .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "RxComposableArchitecture",
            targets: ["RxComposableArchitecture"])
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-case-paths", exact: Version(0, 9, 0)),
        .package(url: "https://github.com/ReactiveX/RxSwift.git", from: Version(6, 6, 0)),
        .package(url: "https://github.com/FluidGroup/TextureSwiftSupport", revision: "4fe38cfb8ab3a00fc9e792f4901955bc0ca711af")
    ],
    targets: [
        .target(
            name: "RxComposableArchitecture",
            dependencies: [
                .product(name: "CasePaths", package: "swift-case-paths"),
                .product(name: "RxSwift", package: "RxSwift"),
                .product(name: "RxCocoa", package: "RxSwift"),
                .product(name: "RxRelay", package: "RxSwift"),
                .product(name: "TextureSwiftSupport", package: "TextureSwiftSupport")
            ]
        ),
        .testTarget(
            name: "RxComposableArchitectureTests",
            dependencies: [
                "RxComposableArchitecture",
                .product(name: "RxTest", package: "RxSwift")
            ]
        )
    ]
)
