# ADR 001: Post C++ Migration Glue Layer Audit

**Status:** Accepted
**Date:** 2026-05-09

## Context

After the C++ migration (PR #6/#7) the glue layer in `Sources/CxxAVDECC/include/` grew to 4,514 lines across two files:

- `AVDECCSwiftHelpers.hpp` (4,377 lines) — bridges la_avdecc's C++ public API to Swift via Swift 6 C++ interop
- `AVDECCSwiftBlock.hpp` (137 lines) — clang block trampolines for `std::function` callback slots

This ADR records the findings of the audit conducted in issue #8 and documents which portions are permanently load-bearing so that future contributors do not repeat the same investigation.

## Findings

### F1: `std::function` bridge — block trampolines are permanently load-bearing

Swift 6.3 C++ interop does **not** support `std::function`. This is documented on the Swift/C++ interop status page and confirmed by compiler behaviour. The clang block trampolines in `AVDECCSwiftBlock.hpp` (`Block<>` RAII wrapper, block-slot holder pattern) and the concrete observer/delegate classes in `AVDECCSwiftHelpers.hpp` (`BlockProtocolInterfaceObserver`, `BlockControllerDelegate`) exist specifically to bridge `std::function`-typed callback slots. They cannot be removed or replaced.

**Do not remove `AVDECCSwiftBlock.hpp` or the block-slot observer/delegate classes.** Any future reconsideration requires first checking the Swift/C++ interop status page for `std::function` support.

### F2: Observer/delegate C++ subclasses are permanently load-bearing

Swift 6.3 C++ interop does **not** support subclassing C++ classes with virtual methods from Swift. `BlockProtocolInterfaceObserver` and `BlockControllerDelegate` subclass pure-virtual la_avdecc observer/delegate types. There is no way to do this from Swift directly. These classes must remain in C++.

### F3: `void const*` PDU accessor free functions are permanently load-bearing

The PDU type aliases in `AVDECCSwift::` (e.g. `using Aecpdu = la::avdecc::protocol::Aecpdu`) look like they should allow Swift to call PDU member functions through the alias, eliminating the need for the `void const*`-based free-function accessor family. They do not.

The Swift importer follows `using`-aliases back to the declaration's original namespace. `la::avdecc::protocol::Aecpdu` lives in the `protocol` namespace, which shadows a Swift keyword. The importer cannot bridge any type whose canonical namespace contains `protocol`. Exposing the raw la_avdecc types in the public API is also excluded by project policy (confirmed by @lhoward).

**Do not remove the PDU accessor free functions.** The typedef aliases and the accessor functions are both necessary and must coexist.

### F4: Owner wrapper classes are permanently load-bearing

Each owner class (`ExecutorOwner`, `LoggerOwner`, `ProtocolInterfaceOwner`, `LocalEntityOwner`) wraps a la_avdecc factory or lifecycle-management type. The wrapping is necessary because:

- Factory functions return `std::unique_ptr<T>` — move-only types that cannot cross the Swift/C++ boundary without a wrapper that converts them to raw pointers with manual retain/release.
- The `SWIFT_SHARED_REFERENCE` macro-based reference counting system requires the retain/release functions to be at top-level scope (not methods), which is enforced by the Swift importer.

### F5: What was safely reduced

The audit found three categories of redundancy that were eliminated without changing observable behaviour:

1. **C++20 upgrade** (`Package.swift`): Changed `cxxLanguageStandard` from `.cxx17` to `.cxx20`. This makes concepts and `requires` clauses available for future contributors using the glue layer. The la_avdecc headers are C++17-compatible and do not prohibit a C++20 translation unit.

2. **MAC address helper** (`AVDECCSwiftHelpers.hpp`): Seven identical `la::networkInterface::MacAddress{mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]}` constructions in ADP, ACMP, and AECP setter functions were replaced with calls to a new `_macFromBytes()` inline helper.

3. **Retain/release template** (`AVDECCSwiftHelpers.hpp`): Eight trivial retain/release functions (two per owner class) each had the same two-line body `if (p) p->retain()` / `if (p) p->release()`. A template helper pair `_avdeccswift_retain<T>` / `_avdeccswift_release<T>` was introduced and the eight functions were updated to delegate to it.

### F6: Macros that cannot be templated

`SWIFT_SHARED_REFERENCE` and `SWIFT_RETURNS_RETAINED` expand to `__attribute__((swift_attr("...")))` annotations. There is no template or `constexpr` equivalent for attribute syntax. These macros are retained as-is.

## Decision

The permanent constraints documented above (F1–F4) are not addressable with any currently available version of Swift's C++ importer. Future contributors wishing to reduce the glue layer further should:

1. Check the [Swift C++ Interop Status](https://swift.org/documentation/cxx-interop/status/) page for `std::function` support.
2. Check whether Swift has gained the ability to subclass C++ virtual classes.
3. Test whether typedef aliases into keyword-shadowed namespaces are bridged correctly by the version of the Swift toolchain in use.

The reductions in F5 are committed to the `fabrik/issue-8` branch (issue #8).

## Consequences

- `AVDECCSwiftBlock.hpp` must not be deleted or modified to remove the block machinery.
- The PDU accessor free-function family must not be removed even though `AVDECCSwift::` typedef aliases for those PDU types exist in the same file.
- C++20 is now the language standard for the CxxAVDECC translation unit; contributors may use C++20 features in new glue code.
