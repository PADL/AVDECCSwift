# AVDECCSwift

Async Swift wrapper around the L-Acoustics [AVDECC library](https://github.com/L-Acoustics/avdecc) (`la_avdecc`), an
implementation of IEEE 1722.1 (AVDECC) and the Milan Vendor Unique extensions.

## Status

- Built on **Swift 6.3 C++ interop** — talks to la_avdecc 4.3.x directly,
  no C-bindings layer.
- Linux + macOS targets.
- Controller-flavour `LocalEntity` only (no talker/listener entity
  publishing yet).

## Capabilities

| Surface | Status |
|---|---|
| Network discovery (`ProtocolInterface`, `ProtocolInterfaceObserver`) | ✓ |
| Controller commands (AEM, MVU, ACMP) | ✓ except `get/setControlValues`, `addressAccess`, `getDynamicInfo` |
| Change notifications (`LocalEntityDelegate`) | ✓ |
| Raw PDU send (`sendAdpMessage` / `sendAecpMessage` / `sendAcmpMessage`) | ✓ |
| Logger bridge to [swift-log](https://github.com/apple/swift-log) | ✓ |
| Talker / listener entity publishing | ✗ |

## Quick taste

```swift
import AVDECCSwift

let pi = try ProtocolInterface(type: .pCap, interfaceID: "eth0")
let entity = try LocalEntity(
    protocolInterface: pi,
    entityID: try pi.getDynamicEID()
)

// Discover remote entities and read their entity descriptors.
final class Spy: ProtocolInterfaceObserver {
    func onRemoteEntityOnline(_ pi: ProtocolInterface, entity: Entity) {
        Task {
            let desc = try? await entity.readEntityDescriptor(id: entity.entityID)
            print(desc as Any)
        }
    }
}
let spy = Spy()
pi.observer = spy
```

See `Examples/Discovery/Discovery.swift` for a complete, runnable example.

## Building

The wrapper depends on a pre-built la_avdecc binary distributed as a
[SwiftPM artifact bundle](https://www.swift.org/documentation/articles/distributing-binary-frameworks-as-swift-packages.html).
The bundle ships in this repository as `avdecc.artifactbundle.zip`.

To rebuild it from the la_avdecc submodule:

```sh
git submodule update --init --recursive
./build-artifacts.sh
```

That script invokes `gen_cmake.sh` inside `Sources/CxxAVDECC/avdecc`,
runs `make -j9`, and zips the result back into
`avdecc.artifactbundle.zip`.

## Architecture

la_avdecc's public surface uses several patterns Swift's C++ importer
can't see directly: `std::function<…>`-typed callbacks, move-only
`std::unique_ptr` factories with custom deleters, templated `Subject<>`
observer machinery, `std::map<>` parameters, exceptions, and a
namespace named `protocol` (collides with a Swift keyword).

We bridge those gaps with a small C++ layer in
`Sources/CxxAVDECC/include/AVDECCSwiftHelpers.hpp`:

- `ExecutorOwner`, `LoggerOwner`, `ProtocolInterfaceOwner`,
  `LocalEntityOwner` — refcounted owners exposed to Swift via
  `SWIFT_SHARED_REFERENCE`, so Swift ARC drives lifetime.
- Clang blocks (`-fblocks`) bridge Swift closures into the
  `std::function` callback slots la_avdecc expects.
- `BlockProtocolInterfaceObserver` and `BlockControllerDelegate` adapt
  la_avdecc's observer / delegate virtuals to swappable Block<> slots,
  guarded by a slots-mutex.
- C++ exceptions are caught at the boundary and reported as a
  `CapturedException` value (typed code + `what()` text).
- la_avdecc PDU types (`Adpdu` / `Aecpdu` / `Acmpdu`) are reachable from
  Swift through opaque `void const*` pointers plus free
  `aecpdu_get*` / `acmpdu_get*` accessors that `static_cast` back to
  the typed pointer.

All the shaping that's awkward across the boundary (variant `std::optional<>`
arguments, `std::chrono::*` durations, `std::vector` payloads) is flattened
to scalar pairs in the helper layer.

## License

LGPL-3.0 (matching la_avdecc).
