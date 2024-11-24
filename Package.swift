// swift-tools-version:5.9

import Foundation
import PackageDescription

// FIXME: make BuildConfigurationurable
#if os(Linux)
let BuildConfiguration = "debug"
#else
let BuildConfiguration = "release"
#endif

let Platform: String

#if os(Linux)
Platform = "linux"
#elseif canImport(Darwin)
Platform = "mac"
#endif

let Architecture: String

#if canImport(Darwin)
Architecture = "x64_arm64"
#elseif arch(x86_64)
Architecture = "x64"
#elseif arch(arm64)
Architecture = "arm64"
#endif

// FIXME: this is clearly not right

let AvdeccBuildDir = "_build_\(Platform)_\(Architecture)_makefiles_\(BuildConfiguration)"
let AvdeccArtifactRoot = ".build/artifacts/avdeccswift/avdecc"
let AvdeccIncludePath = "\(AvdeccArtifactRoot)/include"
let AvdeccCxxLibPath = "\(AvdeccArtifactRoot)/\(AvdeccBuildDir)/src"
let AvdeccCLibPath = "\(AvdeccCxxLibPath)/bindings/c"
let AvdeccCxxControllerLibPath = "\(AvdeccCxxLibPath)/controller"
let AvdeccAltLibPath = "/usr/local/lib"
let AvdeccDebugSuffix = BuildConfiguration == "debug" ? "-d" : ""

var AvdeccLinkerSettings = [LinkerSetting]()

// only necessary on Linux
#if !canImport(Darwin)
AvdeccLinkerSettings += [.linkedLibrary("BlocksRuntime")]
#endif

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
    .macOS(.v13),
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
    .package(url: "https://github.com/apple/swift-async-algorithms", from: "1.0.0"),
    // .package(url: "https://github.com/lhoward/AsyncExtensions", branch: "linux"),
  ],
  targets: [
    .binaryTarget(
      name: "avdecc",
      path: "avdecc.artifactbundle.zip"
//            url: "https://github.com/PADL/AVDECCSwift/raw/main/avdecc.artifactbundle.zip",
//            checksum: "8eeb26c186329c7849c18a14837b6d78cea5d9aecb3e7fbb720274869e79a810"
    ),
    .target(
      name: "CAVDECC",
      dependencies: [
        "avdecc",
      ],
      exclude: [
        "avdecc/\(AvdeccBuildDir)",
        "avdecc/examples",
        "avdecc/externals",
        "avdecc/resources",
        "avdecc/src",
        "avdecc/scripts",
        "avdecc/tests",
      ],
      cSettings: [
        .headerSearchPath("avdecc/include"),
        .headerSearchPath("avdecc/externals/nih/include"),
      ],
      cxxSettings: [
        .headerSearchPath("avdecc/include"),
        .headerSearchPath("avdecc/externals/nih/include"),
      ],
      swiftSettings: [
      ],
      linkerSettings: [
        .linkedLibrary("la_avdecc_c\(AvdeccDebugSuffix)"),
        .linkedLibrary("la_avdecc_cxx\(AvdeccDebugSuffix)"),
        .unsafeFlags(AvdeccUnsafeLinkerFlags),
      ] + AvdeccLinkerSettings
    ),
    .target(
      name: "AVDECCSwift",
      dependencies: [
        "CAVDECC",
      ],
      cSettings: [
        .headerSearchPath("../CAVDECC/avdecc/include"),
        .headerSearchPath("../CAVDECC/avdecc/externals/nih/include"),
      ],
      cxxSettings: [
        .headerSearchPath("../CAVDECC/avdecc/include"),
        .headerSearchPath("../CAVDECC/avdecc/externals/nih/include"),
      ],
      swiftSettings: [
      ]
    ),
    .executableTarget(
      name: "Discovery",
      dependencies: [
        "AVDECCSwift",
        .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
      ],
      path: "Examples/Discovery"
    ),
    .testTarget(
      name: "AVDECCSwiftTests",
      dependencies: [
        .target(name: "AVDECCSwift"),
      ]
    ),
  ],
  cLanguageStandard: .c17,
  cxxLanguageStandard: .cxx17
)
