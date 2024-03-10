// swift-tools-version:5.9

import Foundation
import PackageDescription

// FIXME: make BuildConfigurationurable
let BuildConfiguration = "debug"

let Platform: String

#if os(Linux)
Platform = "linux"
#elseif canImport(Darwin)
Platform = "darwin"
#endif

let Architecture: String

#if arch(x86_64)
Architecture = "x86"
#elseif arch(arm64)
Architecture = "arm64"
#endif

// FIXME: this is clearly not right
let AvdeccBuildDir = "avdecc/_build_\(Platform)_\(Architecture)_makefiles_\(BuildConfiguration)"
let AvdeccArtifactRoot = ".build/artifacts/avdeccswift/\(AvdeccBuildDir)"
let AvdeccCxxLibPath = "\(AvdeccArtifactRoot)/src"
let AvdeccCLibPath = "\(AvdeccCxxLibPath)/bindings/c"
let AvdeccCxxControllerLibPath = "\(AvdeccCxxLibPath)/controller"
let AvdeccAltLibPath = "/usr/local/lib"

let AvdeccUnsafeLinkerFlags: [String] = [
    "-Xlinker", "-L", "-Xlinker", AvdeccCxxLibPath,
    "-Xlinker", "-rpath", "-Xlinker", AvdeccCxxLibPath,
    "-Xlinker", "-L", "-Xlinker", AvdeccCLibPath,
    "-Xlinker", "-rpath", "-Xlinker", AvdeccCLibPath,
    "-Xlinker", "-L", "-Xlinker", AvdeccCxxControllerLibPath,
    "-Xlinker", "-rpath", "-Xlinker", AvdeccCxxControllerLibPath,
    "-Xlinker", "-L", "-Xlinker", AvdeccAltLibPath,
    "-Xlinker", "-rpath", "-Xlinker", AvdeccAltLibPath,
]

let package = Package(
    name: "AVDECCSwift",
    platforms: [
        .macOS(.v10_15),
    ],
    products: [
        .library(
            name: "AVDECCSwift",
            type: .dynamic, // build dynamic library to comply with LGPL
            targets: ["AVDECCSwift"]
        ),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/apple/swift-async-algorithms", from: "0.1.0"),
        // .package(url: "https://github.com/lhoward/AsyncExtensions", branch: "linux"),
    ],
    targets: [
        .binaryTarget(
            name: "avdecc",
            path: "avdecc.artifactbundle.zip"
        ),
        .target(
            name: "CxxAVDECC",
            dependencies: [
                "avdecc",
            ],
            exclude: [
                AvdeccBuildDir,
                "avdecc/examples",
                "avdecc/externals",
                "avdecc/resources",
                "avdecc/src",
                "avdecc/scripts",
                "avdecc/tests",
            ],
            cSettings: [
                .headerSearchPath("../CxxAVDECC/avdecc/include"),
                .headerSearchPath("../CxxAVDECC/avdecc/include/la"),
                .headerSearchPath("../CxxAVDECC/avdecc/include/la/avdecc"),
                .headerSearchPath("../CxxAVDECC/avdecc/externals/nih/include"),
            ],
            cxxSettings: [
                .headerSearchPath("../CxxAVDECC/avdecc/include"),
                .headerSearchPath("../CxxAVDECC/avdecc/include/la"),
                .headerSearchPath("../CxxAVDECC/avdecc/include/la/avdecc"),
                .headerSearchPath("../CxxAVDECC/avdecc/externals/nih/include"),
            ],
            swiftSettings: [
                .interoperabilityMode(.Cxx),
                .enableExperimentalFeature("StrictConcurrency")
            ],
            linkerSettings: [
                .linkedLibrary("la_avdecc_c-d"),
                .linkedLibrary("la_avdecc_cxx-d"),
                .linkedLibrary("BlocksRuntime"),
                .unsafeFlags(AvdeccUnsafeLinkerFlags),
            ]
        ),
        .target(
            name: "AVDECCSwift",
            dependencies: [
                "CxxAVDECC",
            ],
            cSettings: [
                .headerSearchPath("../CxxAVDECC/avdecc/include"),
                .headerSearchPath("../CxxAVDECC/avdecc/include/la"),
                .headerSearchPath("../CxxAVDECC/avdecc/include/la/avdecc"),
                .headerSearchPath("../CxxAVDECC/avdecc/externals/nih/include"),
            ],
            cxxSettings: [
                .headerSearchPath("../CxxAVDECC/avdecc/include"),
                .headerSearchPath("../CxxAVDECC/avdecc/include/la"),
                .headerSearchPath("../CxxAVDECC/avdecc/include/la/avdecc"),
                .headerSearchPath("../CxxAVDECC/avdecc/externals/nih/include"),
            ],
            swiftSettings: [
                .interoperabilityMode(.Cxx),
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .executableTarget(
            name: "Discovery",
            dependencies: [
                "AVDECCSwift",
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
            ],
            path: "Examples/Discovery",
            swiftSettings: [.interoperabilityMode(.Cxx)]
        ),
    ],
    cLanguageStandard: .c17,
    cxxLanguageStandard: .cxx17
)
