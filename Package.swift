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
let AvdeccAltLibPath = "/opt/inferno/lib"

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
            targets: ["AVDECCSwift"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "Discovery",
            dependencies: [
                "AVDECCSwift",
            ],
            path: "Examples/Discovery"
        ),
        .binaryTarget(
            name: "avdecc",
            path: "avdecc.artifactbundle.zip"
        ),
        .target(
            name: "CAVDECC",
            dependencies: [
                "avdecc",
            ],
            exclude: [
                AvdeccBuildDir,
                "avdecc/examples",
                "avdecc/externals",
                "avdecc/include/la/avdecc/logger.hpp",
                "avdecc/include/la/avdecc/avdecc.hpp",
                "avdecc/include/la/avdecc/controller/avdeccController.hpp",
                "avdecc/include/la/avdecc/controller/internals/avdeccControlledEntity.hpp",
                "avdecc/include/la/avdecc/controller/internals/avdeccControlledEntityModel.hpp",
                "avdecc/include/la/avdecc/controller/internals/exports.hpp",
                "avdecc/include/la/avdecc/controller/internals/logItems.hpp",
                "avdecc/include/la/avdecc/watchDog.hpp",
                "avdecc/include/la/avdecc/executor.hpp",
                "avdecc/include/la/avdecc/memoryBuffer.hpp",
                "avdecc/include/la/avdecc/utils.hpp",
                "avdecc/include/la/avdecc/internals/entityModelTypes.hpp",
                "avdecc/include/la/avdecc/internals/controllerEntity.hpp",
                "avdecc/include/la/avdecc/internals/entityEnums.hpp",
                "avdecc/include/la/avdecc/internals/endStation.hpp",
                "avdecc/include/la/avdecc/internals/entityModelTreeStatic.hpp",
                "avdecc/include/la/avdecc/internals/entityModelTreeDynamic.hpp",
                "avdecc/include/la/avdecc/internals/entityModelTree.hpp",
                "avdecc/include/la/avdecc/internals/protocolAvtpdu.hpp",
                "avdecc/include/la/avdecc/internals/protocolAecpdu.hpp",
                "avdecc/include/la/avdecc/internals/protocolAemPayloadSizes.hpp",
                "avdecc/include/la/avdecc/internals/aggregateEntity.hpp",
                "avdecc/include/la/avdecc/internals/entity.hpp",
                "avdecc/include/la/avdecc/internals/entityAddressAccessTypes.hpp",
                "avdecc/include/la/avdecc/internals/protocolMvuAecpdu.hpp",
                "avdecc/include/la/avdecc/internals/entityModelControlValuesTraits.hpp",
                "avdecc/include/la/avdecc/internals/exception.hpp",
                "avdecc/include/la/avdecc/internals/endian.hpp",
                "avdecc/include/la/avdecc/internals/entityModel.hpp",
                "avdecc/include/la/avdecc/internals/protocolAemAecpdu.hpp",
                "avdecc/include/la/avdecc/internals/protocolAdpdu.hpp",
                "avdecc/include/la/avdecc/internals/protocolAaAecpdu.hpp",
                "avdecc/include/la/avdecc/internals/protocolMvuPayloadSizes.hpp",
                "avdecc/include/la/avdecc/internals/exports.hpp",
                "avdecc/include/la/avdecc/internals/jsonTypes.hpp",
                "avdecc/include/la/avdecc/internals/logItems.hpp",
                "avdecc/include/la/avdecc/internals/entityModelControlValues.hpp",
                "avdecc/include/la/avdecc/internals/jsonSerialization.hpp",
                "avdecc/include/la/avdecc/internals/serialization.hpp",
                "avdecc/include/la/avdecc/internals/protocolInterface.hpp",
                "avdecc/include/la/avdecc/internals/streamFormatInfo.hpp",
                "avdecc/include/la/avdecc/internals/uniqueIdentifier.hpp",
                "avdecc/include/la/avdecc/internals/protocolAcmpdu.hpp",
                "avdecc/include/la/avdecc/internals/instrumentationNotifier.hpp",
                "avdecc/include/la/avdecc/internals/entityModelTreeCommon.hpp",
                "avdecc/include/la/avdecc/internals/protocolDefines.hpp",
                "avdecc/include/la/avdecc/internals/protocolVuAecpdu.hpp",
                "avdecc/resources",
                "avdecc/src",
                "avdecc/scripts",
                "avdecc/tests",
            ],
            cSettings: [
                .unsafeFlags(["-I", "/opt/swift/usr/lib/swift"]),
            ],
            cxxSettings: [
                .unsafeFlags(["-I", "/opt/swift/usr/lib/swift"]),
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
                "CAVDECC",
            ]
        ),
    ],
    cLanguageStandard: .c17,
    cxxLanguageStandard: .cxx17
)
