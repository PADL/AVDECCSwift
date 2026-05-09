/*
 * Copyright (C) 2026, PADL Software Pty Ltd
 *
 * This file is part of AVDECCSwift.
 *
 * AVDECCSwift is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * AVDECCSwift is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with AVDECCSwift.  If not, see <http://www.gnu.org/licenses/>.
 */

// Minimal C++ helpers driven from Swift via Swift 6 C++ interop.
//
// Helpers are added here only when Swift cannot reach the la_avdecc C++ API
// directly. Per swift.org/documentation/cxx-interop/, that is mostly:
//   - `std::shared_ptr` cannot be a SWIFT_SHARED_REFERENCE — Swift requires
//     intrusive refcounting for foreign reference types. Each la_avdecc
//     UniquePointer (Executor, ProtocolInterface, AggregateEntity) gets a
//     thin owner wrapper that inherits IntrusiveReferenceCounted<Self>.
//   - C++ classes can't be subclassed from Swift — so each la_avdecc
//     pure-virtual Observer/Delegate gets one concrete C++ subclass that
//     stores clang blocks and dispatches each virtual to the matching block.
//   - `std::function` arguments aren't reachable from Swift closures — so
//     each handler-shape gets one block→std::function bridge helper (one
//     per signature shape, not per la_avdecc method).
#pragma once

#include <atomic>
#include <cstdint>
#include <functional>
#include <mutex>
#include <stdexcept>
#include <string>
#include <utility>

#include <la/avdecc/executor.hpp>
#include <la/avdecc/logger.hpp>
#include <la/avdecc/internals/aggregateEntity.hpp>
#include <la/avdecc/internals/protocolInterface.hpp>

#include "AVDECCSwiftBlock.hpp"

// Inlined excerpt from `<swift/bridging>` (Swift toolchain header). We can't
// rely on Swift's include directory being on the C++ search path since
// SwiftPM doesn't surface it for C++-only targets. The full upstream header
// has more macros; this file only needs SWIFT_SHARED_REFERENCE and
// SWIFT_RETURNS_RETAINED. Add others as we need them.
#if defined(__has_attribute) && __has_attribute(swift_attr)
#  define _AVDECC_SWIFT_STR(_x) #_x
#  define SWIFT_SHARED_REFERENCE(_retain, _release) \
       __attribute__((swift_attr("import_reference"))) \
       __attribute__((swift_attr("retain:" _AVDECC_SWIFT_STR(_retain)))) \
       __attribute__((swift_attr("release:" _AVDECC_SWIFT_STR(_release))))
#  define SWIFT_RETURNS_RETAINED \
       __attribute__((swift_attr("returns_retained")))
#else
#  define SWIFT_SHARED_REFERENCE(_retain, _release)
#  define SWIFT_RETURNS_RETAINED
#endif

namespace AVDECCSwift {

/// Captured-exception bundle. Each `create()` helper takes one of these
/// by reference; on failure we fill in everything Swift needs to throw a
/// typed AVDECCSwift error. `protocolInterfaceErrorCode` is non-zero
/// only if the exception was a
/// `la::avdecc::protocol::ProtocolInterface::Exception` (so callers can
/// dispatch on it). `message` is the `what()` text — empty if
/// unavailable.
struct CapturedException {
  uint8_t protocolInterfaceErrorCode = 0;
  std::string message;
};

/// Invoke `fn` with full la_avdecc-aware exception capture. Catches by
/// most-specific subclass first so the typed Error code from
/// ProtocolInterface::Exception is preserved; everything else collapses
/// to InternalError but we still try to capture a useful `what()`
/// string. On success `protocolInterfaceErrorCode` stays 0 (NoError);
/// the caller checks the returned pointer/value, not the code, to
/// distinguish success from failure.
///
/// We're only contractually required to bridge AVDECC exceptions, so
/// non-AVDECC ones (std::exception, ...) all map to the same
/// InternalError code; the message field gives callers any extra
/// context they need.
template <typename Fn>
auto invokeCapturingException(CapturedException& out, Fn&& fn) noexcept
    -> decltype(fn()) {
  using R = decltype(fn());
  out.protocolInterfaceErrorCode = static_cast<uint8_t>(
      la::avdecc::protocol::ProtocolInterface::Error::NoError);
  out.message.clear();
  try {
    return fn();
  } catch (la::avdecc::protocol::ProtocolInterface::Exception const& e) {
    out.protocolInterfaceErrorCode = static_cast<uint8_t>(e.getError());
    try { out.message = e.what(); } catch (...) {}
    return R{};
  } catch (la::avdecc::Exception const& e) {
    out.protocolInterfaceErrorCode = static_cast<uint8_t>(
        la::avdecc::protocol::ProtocolInterface::Error::InternalError);
    try { out.message = e.what(); } catch (...) {}
    return R{};
  } catch (std::exception const& e) {
    out.protocolInterfaceErrorCode = static_cast<uint8_t>(
        la::avdecc::protocol::ProtocolInterface::Error::InternalError);
    try { out.message = e.what(); } catch (...) {}
    return R{};
  } catch (...) {
    out.protocolInterfaceErrorCode = static_cast<uint8_t>(
        la::avdecc::protocol::ProtocolInterface::Error::InternalError);
    return R{};
  }
}

/// CRTP base providing intrusive reference counting for SWIFT_SHARED_REFERENCE
/// types. Each concrete owner class inherits, e.g.:
///
///     class SWIFT_SHARED_REFERENCE(AVDECCSwift_FooOwner_retain,
///                                  AVDECCSwift_FooOwner_release)
///         FooOwner final : public IntrusiveReferenceCounted<FooOwner> { ... };
///
/// The matching `AVDECCSwift_FooOwner_retain` / `_release` free functions
/// live at translation-unit scope (Swift's importer parses the
/// swift_attr string and resolves it as a top-level identifier, not a
/// namespaced one — qualified names don't compile). The `AVDECCSwift_`
/// prefix scopes the names to *us* rather than la_avdecc, since these
/// are our helpers, not part of la_avdecc's public API. Definitions are
/// pooled at the bottom of the file as `inline` functions, one per
/// owner type.
template <typename Derived>
class IntrusiveReferenceCounted {
public:
  void retain() noexcept { rc_.fetch_add(1, std::memory_order_relaxed); }
  void release() noexcept {
    if (rc_.fetch_sub(1, std::memory_order_acq_rel) == 1) {
      delete static_cast<Derived*>(this);
    }
  }

protected:
  IntrusiveReferenceCounted() noexcept = default;
  ~IntrusiveReferenceCounted() noexcept = default;
  IntrusiveReferenceCounted(IntrusiveReferenceCounted const&) = delete;
  IntrusiveReferenceCounted& operator=(IntrusiveReferenceCounted const&) = delete;

private:
  std::atomic<int> rc_{1};
};

class ExecutorOwner;

} // namespace AVDECCSwift

void AVDECCSwift_ExecutorOwner_retain(AVDECCSwift::ExecutorOwner* p) noexcept;
void AVDECCSwift_ExecutorOwner_release(AVDECCSwift::ExecutorOwner* p) noexcept;

namespace AVDECCSwift {

/// Owns an la_avdecc dispatch-queue executor + ExecutorManager registration.
/// Necessary because none of la_avdecc's executor classes (Executor,
/// ExecutorManager, ExecutorWithDispatchQueue) reach Swift's C++ importer
/// — they use std::function / std::thread::id / templated members the
/// importer skips, and the factories return move-only Executor::UniquePointer.
class SWIFT_SHARED_REFERENCE(AVDECCSwift_ExecutorOwner_retain,
                             AVDECCSwift_ExecutorOwner_release)
    ExecutorOwner final : public IntrusiveReferenceCounted<ExecutorOwner> {
public:
  /// On failure, fills `outErr` with the captured exception (typed code
  /// if from the ProtocolInterface::Exception hierarchy, otherwise
  /// `InternalError` plus any `what()` string). la_avdecc's
  /// `ExecutorManager::registerExecutor` throws `std::invalid_argument`
  /// on duplicate registration; that surfaces as `InternalError` with
  /// the message text intact.
  SWIFT_RETURNS_RETAINED
  static ExecutorOwner* create(std::string const& name,
                               CapturedException& outErr) noexcept {
    return invokeCapturingException(outErr, [&]() -> ExecutorOwner* {
      auto exec = la::avdecc::ExecutorWithDispatchQueue::create(name);
      auto wrapper = la::avdecc::ExecutorManager::getInstance().registerExecutor(
          name, std::move(exec));
      return new ExecutorOwner(name, std::move(wrapper));
    });
  }

  /// Idempotent early teardown. Drops the la_avdecc executor + its manager
  /// registration before __cxa_finalize so the manager's destructor doesn't
  /// run with a dangling wrapper. The ExecutorOwner itself stays alive
  /// until all Swift references are released.
  void close() noexcept { wrapper_.reset(); }

  std::string const& name() const noexcept { return name_; }

private:
  friend class IntrusiveReferenceCounted<ExecutorOwner>;
  ExecutorOwner(
      std::string name,
      la::avdecc::ExecutorManager::ExecutorWrapper::UniquePointer wrapper) noexcept
      : name_(std::move(name)), wrapper_(std::move(wrapper)) {}
  ~ExecutorOwner() noexcept = default;

  std::string name_;
  la::avdecc::ExecutorManager::ExecutorWrapper::UniquePointer wrapper_;
};

/* ------------------------------------------------------------------- */
/* Logger                                                              */
/* ------------------------------------------------------------------- */

class LoggerOwner;

} // namespace AVDECCSwift

void AVDECCSwift_LoggerOwner_retain(AVDECCSwift::LoggerOwner* p) noexcept;
void AVDECCSwift_LoggerOwner_release(AVDECCSwift::LoggerOwner* p) noexcept;

namespace AVDECCSwift {

/// Bridge between la_avdecc's `Logger::Observer` (singleton, pointer-
/// registered) and a Swift block. Each instance registers itself with
/// the global la_avdecc Logger on construction and unregisters on
/// `close()` / destruction. Swift sets a single block slot via
/// `setOnLogItem`; la_avdecc fires it from arbitrary internal threads,
/// so the slot read/write is mutex-guarded (same pattern as the PI
/// observer).
///
/// Message passes as (data, size) UTF-8 — Swift constructs a String
/// without going through Foundation, which keeps the log path off the
/// CFString TSD setup that we audited out earlier.
class SWIFT_SHARED_REFERENCE(AVDECCSwift_LoggerOwner_retain,
                             AVDECCSwift_LoggerOwner_release)
    LoggerOwner final
    : public IntrusiveReferenceCounted<LoggerOwner> {
public:
  SWIFT_RETURNS_RETAINED
  static LoggerOwner* create() noexcept { return new LoggerOwner(); }

  /// Idempotent. Detaches the observer from la_avdecc's Logger singleton.
  /// Block slot is cleared so any in-flight notifications complete with
  /// no-op forwarding.
  void close() noexcept {
    if (registered_) {
      la::avdecc::logger::Logger::getInstance().unregisterObserver(&observer_);
      registered_ = false;
    }
    observer_.clearSlot();
  }

  void registerObserver() noexcept {
    if (!registered_) {
      la::avdecc::logger::Logger::getInstance().registerObserver(&observer_);
      registered_ = true;
    }
  }

  void setOnLogItem(void (^cb)(uint8_t /*level*/,
                               uint8_t /*layer*/,
                               char const* /*data*/,
                               size_t /*size*/)) noexcept {
    observer_.setSlot(cb);
  }

  /// la_avdecc's global emit-level filter. Messages below this level
  /// are dropped before our observer is even invoked, saving the
  /// std::string allocation for getMessage(). Swift typically sets
  /// this to the most permissive level any consumer wants and then
  /// per-consumer-filters in the block.
  void setLevel(uint8_t level) noexcept {
    la::avdecc::logger::Logger::getInstance().setLevel(
        static_cast<la::avdecc::logger::Level>(level));
  }
  uint8_t getLevel() const noexcept {
    return static_cast<uint8_t>(
        la::avdecc::logger::Logger::getInstance().getLevel());
  }

private:
  friend class IntrusiveReferenceCounted<LoggerOwner>;

  // The actual la_avdecc-facing Observer. Holds the block slot under a
  // mutex so concurrent setSlot / onLogItem calls don't tear.
  class Observer final : public la::avdecc::logger::Logger::Observer {
  public:
    void setSlot(void (^cb)(uint8_t, uint8_t, char const*, size_t)) noexcept {
      std::lock_guard<std::mutex> lock(mutex_);
      slot_ = Block<void, uint8_t, uint8_t, char const*, size_t>(cb);
    }
    void clearSlot() noexcept {
      std::lock_guard<std::mutex> lock(mutex_);
      slot_.reset();
    }

  private:
    void onLogItem(la::avdecc::logger::Level const level,
                   la::avdecc::logger::LogItem const* const item) noexcept override {
      // Copy slot under lock so the local copy survives concurrent
      // setSlot() during dispatch (Block_copy retain on copy ctor).
      auto blk = [&]() noexcept {
        std::lock_guard<std::mutex> lock(mutex_);
        return slot_;
      }();
      if (!blk || !item) return;
      auto const msg = item->getMessage();
      blk(static_cast<uint8_t>(level),
          static_cast<uint8_t>(item->getLayer()),
          msg.data(), msg.size());
    }

    mutable std::mutex mutex_;
    Block<void, uint8_t, uint8_t, char const*, size_t> slot_;
  };

  LoggerOwner() noexcept = default;
  ~LoggerOwner() noexcept { close(); }

  Observer observer_;
  bool registered_ = false;
};

/* ------------------------------------------------------------------- */
/* ProtocolInterface                                                   */
/* ------------------------------------------------------------------- */

class ProtocolInterfaceOwner;

} // namespace AVDECCSwift

void AVDECCSwift_ProtocolInterfaceOwner_retain(AVDECCSwift::ProtocolInterfaceOwner* p) noexcept;
void AVDECCSwift_ProtocolInterfaceOwner_release(AVDECCSwift::ProtocolInterfaceOwner* p) noexcept;

namespace AVDECCSwift {

/// Pull la::avdecc::protocol::* PDU types up to AVDECCSwift::* so Swift can
/// at least name them. Swift's C++ importer accepts
/// `la.avdecc.\`protocol\`` as an empty namespace enum but doesn't surface
/// its members because `protocol` is a Swift reserved word — member lookup
/// inside that namespace fails, and the importer follows typedef aliases
/// back to the original namespace, so even calls through the typedef
/// don't reach the methods. We use the typedef to type the Swift pointers
/// and route field reads through the free accessor functions defined
/// below (they live in AVDECCSwift::, are reachable from Swift, and
/// dispatch on the original C++ type).
using Aecpdu = la::avdecc::protocol::Aecpdu;
using AemAecpdu = la::avdecc::protocol::AemAecpdu;
using MvuAecpdu = la::avdecc::protocol::MvuAecpdu;
using Acmpdu = la::avdecc::protocol::Acmpdu;
using Adpdu = la::avdecc::protocol::Adpdu;

// la::avdecc::entity::Entity::getInterfacesInformation() returns
// std::map<AvbInterfaceIndex, InterfaceInformation> const& — the by-ref
// return doesn't surface to Swift, and std::map is opaque even when it
// does. Expose just the count, which is what consumers need.
inline size_t entity_getInterfaceInformationCount(
    la::avdecc::entity::Entity const* e) noexcept {
  return e->getInterfacesInformation().size();
}

// PDU field accessors — free functions in AVDECCSwift:: that Swift can call
// (the equivalent member methods on the imported PDU types are invisible
// because of the `protocol` namespace-name keyword collision; even the
// `using Aecpdu = ...` typedef in this namespace doesn't surface as a
// Swift-visible type, so we have to pass and unbox `void const*`).
// Callers must pass a pointer to the matching la_avdecc PDU type — the
// Swift wrapper structs (Aecpdu / AemAecpdu / Acmpdu) enforce this at
// construction.
inline uint64_t aecpdu_getTargetEntityID(void const* p) noexcept {
  return static_cast<Aecpdu const*>(p)->getTargetEntityID().getValue();
}
inline uint64_t aecpdu_getControllerEntityID(void const* p) noexcept {
  return static_cast<Aecpdu const*>(p)->getControllerEntityID().getValue();
}
inline uint16_t aecpdu_getSequenceID(void const* p) noexcept {
  return static_cast<Aecpdu const*>(p)->getSequenceID();
}
inline uint8_t aecpdu_getMessageType(void const* p) noexcept {
  return static_cast<Aecpdu const*>(p)->getMessageType().getValue();
}
inline uint8_t aecpdu_getStatus(void const* p) noexcept {
  return static_cast<Aecpdu const*>(p)->getStatus().getValue();
}

inline uint16_t aem_aecpdu_getCommandType(void const* p) noexcept {
  return static_cast<AemAecpdu const*>(p)->getCommandType().getValue();
}

inline uint64_t acmpdu_getControllerEntityID(void const* p) noexcept {
  return static_cast<Acmpdu const*>(p)->getControllerEntityID().getValue();
}
inline uint16_t acmpdu_getSequenceID(void const* p) noexcept {
  return static_cast<Acmpdu const*>(p)->getSequenceID();
}
inline uint8_t acmpdu_getMessageType(void const* p) noexcept {
  return static_cast<Acmpdu const*>(p)->getMessageType().getValue();
}
inline uint8_t acmpdu_getStatus(void const* p) noexcept {
  return static_cast<Acmpdu const*>(p)->getStatus().getValue();
}
inline uint64_t acmpdu_getTalkerEntityID(void const* p) noexcept {
  return static_cast<Acmpdu const*>(p)->getTalkerEntityID().getValue();
}
inline uint64_t acmpdu_getListenerEntityID(void const* p) noexcept {
  return static_cast<Acmpdu const*>(p)->getListenerEntityID().getValue();
}
inline uint16_t acmpdu_getTalkerUniqueID(void const* p) noexcept {
  return static_cast<Acmpdu const*>(p)->getTalkerUniqueID();
}
inline uint16_t acmpdu_getListenerUniqueID(void const* p) noexcept {
  return static_cast<Acmpdu const*>(p)->getListenerUniqueID();
}
// std::array<uint8_t,6> doesn't import as a typed Swift value cleanly; copy
// the 6 bytes into a caller-supplied buffer instead.
inline void acmpdu_copyStreamDestAddress(void const* p, uint8_t out[6]) noexcept {
  auto const& mac = static_cast<Acmpdu const*>(p)->getStreamDestAddress();
  for (size_t i = 0; i < 6; ++i) out[i] = mac[i];
}
inline uint16_t acmpdu_getConnectionCount(void const* p) noexcept {
  return static_cast<Acmpdu const*>(p)->getConnectionCount();
}
inline uint16_t acmpdu_getFlags(void const* p) noexcept {
  return static_cast<Acmpdu const*>(p)->getFlags().value();
}
inline uint16_t acmpdu_getStreamVlanID(void const* p) noexcept {
  return static_cast<Acmpdu const*>(p)->getStreamVlanID();
}

// (la_avdecc's EnumBitfield<>::value() imports cleanly through Swift's C++
// interop, so capability/flag extraction lives Swift-side rather than as
// trivial wrapper helpers here. Same goes for iterating std::set /
// std::unordered_map fields on descriptors — Swift uses
// __beginUnsafe()/__endUnsafe()/successor()/pointee directly.)

// ============================================================================
// PDU send-side accessors. Mirrors of the read accessors above for the three
// raw-send entry points (sendAdpMessage / sendAecpMessage / sendAcmpMessage).
// Swift cannot construct la::avdecc::protocol::* PDU types directly (the
// `protocol` keyword shadows the namespace), so we expose:
//   * `<pdu>_create() -> void*` — heap-allocates a fresh PDU.
//   * `<pdu>_destroy(void*)`    — frees via the PDU's virtual destroy().
//   * `<pdu>_set<Field>(void*, value)` — one per writable field.
// Swift wraps the void* in a final class; deinit calls destroy. The PDU is
// then handed to ProtocolInterfaceOwner::send<X>Message(void const*) by raw
// pointer for transmission. la_avdecc copies the PDU during send, so the
// wrapper may continue to mutate or hand the same PDU to a second send call.
// ============================================================================

// la_avdecc's PDU `createRaw*` and `destroy()` are private to each PDU
// class, accessible only through the `<X>::create()` factory + the
// non-capturing-lambda deleter the factory bakes into the UniquePointer.
// We squeeze the deleter out via `get_deleter()` at static-init time
// (paying for one throwaway alloc per PDU type per process), then use
// it to free PDUs created via `create().release()`.
template <typename PDU>
inline auto _pduDeleter() noexcept {
  static auto del = []{
    auto tmp = PDU::create();
    return tmp.get_deleter();
  }();
  return del;
}

// AemAecpdu's create takes (bool isResponse) so it doesn't fit the
// zero-arg template above; it lives in the AEM section below.
template <typename PDU>
inline void* _pduCreate() noexcept { return PDU::create().release(); }

template <typename PDU>
inline void _pduDestroy(void* p) noexcept {
  if (p) _pduDeleter<PDU>()(static_cast<PDU*>(p));
}

inline la::networkInterface::MacAddress _macFromBytes(uint8_t const mac[6]) noexcept {
  return la::networkInterface::MacAddress{mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]};
}

// ---- ADP --------------------------------------------------------------------
inline void* adpdu_create() noexcept { return _pduCreate<Adpdu>(); }
inline void adpdu_destroy(void* p) noexcept { _pduDestroy<Adpdu>(p); }
inline void adpdu_setSrcAddress(void* p, uint8_t const mac[6]) noexcept {
  static_cast<Adpdu*>(p)->setSrcAddress(_macFromBytes(mac));
}
inline void adpdu_setDestAddressMulticast(void* p) noexcept {
  static_cast<Adpdu*>(p)->setDestAddress(Adpdu::Multicast_Mac_Address);
}
inline void adpdu_setDestAddress(void* p, uint8_t const mac[6]) noexcept {
  static_cast<Adpdu*>(p)->setDestAddress(_macFromBytes(mac));
}
inline void adpdu_setMessageType(void* p, uint8_t v) noexcept {
  static_cast<Adpdu*>(p)->setMessageType(la::avdecc::protocol::AdpMessageType{v});
}
inline void adpdu_setValidTime(void* p, uint8_t v) noexcept {
  static_cast<Adpdu*>(p)->setValidTime(v);
}
inline void adpdu_setEntityID(void* p, uint64_t v) noexcept {
  static_cast<Adpdu*>(p)->setEntityID(la::avdecc::UniqueIdentifier(v));
}
inline void adpdu_setEntityModelID(void* p, uint64_t v) noexcept {
  static_cast<Adpdu*>(p)->setEntityModelID(la::avdecc::UniqueIdentifier(v));
}
inline void adpdu_setEntityCapabilities(void* p, uint32_t v) noexcept {
  la::avdecc::entity::EntityCapabilities f; f.assign(v);
  static_cast<Adpdu*>(p)->setEntityCapabilities(f);
}
inline void adpdu_setTalkerStreamSources(void* p, uint16_t v) noexcept {
  static_cast<Adpdu*>(p)->setTalkerStreamSources(v);
}
inline void adpdu_setTalkerCapabilities(void* p, uint16_t v) noexcept {
  la::avdecc::entity::TalkerCapabilities f; f.assign(v);
  static_cast<Adpdu*>(p)->setTalkerCapabilities(f);
}
inline void adpdu_setListenerStreamSinks(void* p, uint16_t v) noexcept {
  static_cast<Adpdu*>(p)->setListenerStreamSinks(v);
}
inline void adpdu_setListenerCapabilities(void* p, uint16_t v) noexcept {
  la::avdecc::entity::ListenerCapabilities f; f.assign(v);
  static_cast<Adpdu*>(p)->setListenerCapabilities(f);
}
inline void adpdu_setControllerCapabilities(void* p, uint32_t v) noexcept {
  la::avdecc::entity::ControllerCapabilities f; f.assign(v);
  static_cast<Adpdu*>(p)->setControllerCapabilities(f);
}
inline void adpdu_setAvailableIndex(void* p, uint32_t v) noexcept {
  static_cast<Adpdu*>(p)->setAvailableIndex(v);
}
inline void adpdu_setGptpGrandmasterID(void* p, uint64_t v) noexcept {
  static_cast<Adpdu*>(p)->setGptpGrandmasterID(la::avdecc::UniqueIdentifier(v));
}
inline void adpdu_setGptpDomainNumber(void* p, uint8_t v) noexcept {
  static_cast<Adpdu*>(p)->setGptpDomainNumber(v);
}
inline void adpdu_setIdentifyControlIndex(void* p, uint16_t v) noexcept {
  static_cast<Adpdu*>(p)->setIdentifyControlIndex(v);
}
inline void adpdu_setInterfaceIndex(void* p, uint16_t v) noexcept {
  static_cast<Adpdu*>(p)->setInterfaceIndex(v);
}
inline void adpdu_setAssociationID(void* p, uint64_t v) noexcept {
  static_cast<Adpdu*>(p)->setAssociationID(la::avdecc::UniqueIdentifier(v));
}

// ---- ACMP -------------------------------------------------------------------
inline void* acmpdu_create() noexcept { return _pduCreate<Acmpdu>(); }
inline void acmpdu_destroy(void* p) noexcept { _pduDestroy<Acmpdu>(p); }
inline void acmpdu_setSrcAddress(void* p, uint8_t const mac[6]) noexcept {
  static_cast<Acmpdu*>(p)->setSrcAddress(_macFromBytes(mac));
}
inline void acmpdu_setDestAddressMulticast(void* p) noexcept {
  static_cast<Acmpdu*>(p)->setDestAddress(Acmpdu::Multicast_Mac_Address);
}
inline void acmpdu_setDestAddress(void* p, uint8_t const mac[6]) noexcept {
  static_cast<Acmpdu*>(p)->setDestAddress(_macFromBytes(mac));
}
inline void acmpdu_setMessageType(void* p, uint8_t v) noexcept {
  static_cast<Acmpdu*>(p)->setMessageType(la::avdecc::protocol::AcmpMessageType{v});
}
inline void acmpdu_setStatus(void* p, uint8_t v) noexcept {
  static_cast<Acmpdu*>(p)->setStatus(la::avdecc::protocol::AcmpStatus{v});
}
inline void acmpdu_setControllerEntityID(void* p, uint64_t v) noexcept {
  static_cast<Acmpdu*>(p)->setControllerEntityID(la::avdecc::UniqueIdentifier(v));
}
inline void acmpdu_setTalkerEntityID(void* p, uint64_t v) noexcept {
  static_cast<Acmpdu*>(p)->setTalkerEntityID(la::avdecc::UniqueIdentifier(v));
}
inline void acmpdu_setListenerEntityID(void* p, uint64_t v) noexcept {
  static_cast<Acmpdu*>(p)->setListenerEntityID(la::avdecc::UniqueIdentifier(v));
}
inline void acmpdu_setTalkerUniqueID(void* p, uint16_t v) noexcept {
  static_cast<Acmpdu*>(p)->setTalkerUniqueID(v);
}
inline void acmpdu_setListenerUniqueID(void* p, uint16_t v) noexcept {
  static_cast<Acmpdu*>(p)->setListenerUniqueID(v);
}
inline void acmpdu_setStreamDestAddress(void* p, uint8_t const mac[6]) noexcept {
  static_cast<Acmpdu*>(p)->setStreamDestAddress(_macFromBytes(mac));
}
inline void acmpdu_setConnectionCount(void* p, uint16_t v) noexcept {
  static_cast<Acmpdu*>(p)->setConnectionCount(v);
}
inline void acmpdu_setSequenceID(void* p, uint16_t v) noexcept {
  static_cast<Acmpdu*>(p)->setSequenceID(v);
}
inline void acmpdu_setFlags(void* p, uint16_t v) noexcept {
  la::avdecc::entity::ConnectionFlags f; f.assign(v);
  static_cast<Acmpdu*>(p)->setFlags(f);
}
inline void acmpdu_setStreamVlanID(void* p, uint16_t v) noexcept {
  static_cast<Acmpdu*>(p)->setStreamVlanID(v);
}

// ---- AEM-AECP ---------------------------------------------------------------
// `isResponse` flips the AEM-vs-Response bit at construction time and cannot
// be changed afterward — pick the right value when creating. AEM-specific
// methods (setUnsolicited, setCommandType, setCommandSpecificData) live on
// AemAecpdu; base AECP fields (target, controller, sequence, status) live
// on Aecpdu. We expose both via the same opaque void*.
inline auto _aemAecpduDeleter() noexcept {
  static auto del = []{
    auto tmp = AemAecpdu::create(false /*isResponse*/);
    return tmp.get_deleter();
  }();
  return del;
}
inline void* aemAecpdu_create(bool isResponse) noexcept {
  return AemAecpdu::create(isResponse).release();
}
inline void aemAecpdu_destroy(void* p) noexcept {
  if (p) _aemAecpduDeleter()(static_cast<AemAecpdu*>(p));
}
inline void aecpdu_setSrcAddress(void* p, uint8_t const mac[6]) noexcept {
  static_cast<Aecpdu*>(p)->setSrcAddress(_macFromBytes(mac));
}
inline void aecpdu_setDestAddress(void* p, uint8_t const mac[6]) noexcept {
  static_cast<Aecpdu*>(p)->setDestAddress(_macFromBytes(mac));
}
inline void aecpdu_setStatus(void* p, uint8_t v) noexcept {
  static_cast<Aecpdu*>(p)->setStatus(la::avdecc::protocol::AecpStatus{v});
}
inline void aecpdu_setTargetEntityID(void* p, uint64_t v) noexcept {
  static_cast<Aecpdu*>(p)->setTargetEntityID(la::avdecc::UniqueIdentifier(v));
}
inline void aecpdu_setControllerEntityID(void* p, uint64_t v) noexcept {
  static_cast<Aecpdu*>(p)->setControllerEntityID(la::avdecc::UniqueIdentifier(v));
}
inline void aecpdu_setSequenceID(void* p, uint16_t v) noexcept {
  static_cast<Aecpdu*>(p)->setSequenceID(v);
}
inline void aem_aecpdu_setUnsolicited(void* p, bool v) noexcept {
  static_cast<AemAecpdu*>(p)->setUnsolicited(v);
}
inline void aem_aecpdu_setCommandType(void* p, uint16_t v) noexcept {
  static_cast<AemAecpdu*>(p)->setCommandType(la::avdecc::protocol::AemCommandType{v});
}
inline void aem_aecpdu_setCommandSpecificData(
    void* p, void const* data, size_t len) noexcept {
  static_cast<AemAecpdu*>(p)->setCommandSpecificData(data, len);
}

/// Concrete subclass of la::avdecc::protocol::ProtocolInterface::Observer
/// that dispatches each virtual to a stored clang block. Swift sets the
/// blocks at runtime; null blocks are no-ops. PDU pointers are passed
/// through opaquely (Swift may inspect them via C++ interop).
///
/// Each block is held in an AVDECCSwift::Block<> RAII wrapper that calls
/// Block_copy on store and Block_release on destroy. Without that, a Swift
/// closure-converted-to-block dies as soon as the setter returns and the
/// next observer fire walks into a dangling block.
///
/// Thread-safety: la_avdecc fires observer callbacks on its executor
/// thread. Swift may concurrently rebind / clear slots from any thread.
/// All slot reads and writes are serialised by `slotsMutex_`. Each
/// notification override copies the slot under the lock (Block<> copy
/// ctor calls Block_copy) and invokes the local copy outside the lock,
/// so observer callbacks run without holding our mutex and may freely
/// re-enter ProtocolInterfaceOwner.
///
/// Callback contract: Swift closures bridged through Block<> must not
/// throw C++ exceptions. The block invocation in `Block<>::operator()`
/// is `noexcept`, so an escaping exception terminates the process. This
/// matches Swift's own no-throw contract for `@convention(block)`
/// closures.
class BlockProtocolInterfaceObserver final
    : public la::avdecc::protocol::ProtocolInterface::Observer {
public:
  // Slot accessor used by ProtocolInterfaceOwner setters: takes the
  // slots-mutex, then assigns under the lock. The Block<> wrapper's
  // copy/move assignment handles Block_copy / Block_release of the
  // outgoing/incoming pointer.
  template <typename SlotT, typename ValueT>
  void setSlot(SlotT BlockProtocolInterfaceObserver::* slot, ValueT&& value) noexcept {
    std::lock_guard<std::mutex> lock(slotsMutex_);
    (this->*slot) = std::forward<ValueT>(value);
  }

  // Bulk reset under one lock. Called from ProtocolInterfaceOwner when
  // the observer is being detached.
  void clearAllSlots() noexcept {
    std::lock_guard<std::mutex> lock(slotsMutex_);
    onTransportError_.reset();
    onLocalEntityOnline_.reset();
    onLocalEntityOffline_.reset();
    onLocalEntityUpdated_.reset();
    onRemoteEntityOnline_.reset();
    onRemoteEntityOffline_.reset();
    onRemoteEntityUpdated_.reset();
    onAecpCommand_.reset();
    onAecpAemUnsolicitedResponse_.reset();
    onAecpAemIdentifyNotification_.reset();
    onAcmpCommand_.reset();
    onAcmpResponse_.reset();
  }

private:
  friend class ProtocolInterfaceOwner;

  // Copy a slot under the lock and return the local copy. Block<>'s copy
  // ctor calls Block_copy, so the returned value owns its own retain;
  // releasing it (when the local goes out of scope) is independent of
  // any further assignment to the slot from another thread.
  template <typename SlotT>
  SlotT copySlotLocked(SlotT const& slot) const noexcept {
    std::lock_guard<std::mutex> lock(slotsMutex_);
    return slot;
  }

  void onTransportError(la::avdecc::protocol::ProtocolInterface* pi) noexcept override {
    auto blk = copySlotLocked(onTransportError_);
    if (blk) blk(pi);
  }
  void onLocalEntityOnline(la::avdecc::protocol::ProtocolInterface* pi,
                           la::avdecc::entity::Entity const& e) noexcept override {
    auto blk = copySlotLocked(onLocalEntityOnline_);
    if (blk) blk(pi, &e);
  }
  void onLocalEntityOffline(la::avdecc::protocol::ProtocolInterface* pi,
                            la::avdecc::UniqueIdentifier const id) noexcept override {
    auto blk = copySlotLocked(onLocalEntityOffline_);
    if (blk) blk(pi, id.getValue());
  }
  void onLocalEntityUpdated(la::avdecc::protocol::ProtocolInterface* pi,
                            la::avdecc::entity::Entity const& e) noexcept override {
    auto blk = copySlotLocked(onLocalEntityUpdated_);
    if (blk) blk(pi, &e);
  }
  void onRemoteEntityOnline(la::avdecc::protocol::ProtocolInterface* pi,
                            la::avdecc::entity::Entity const& e) noexcept override {
    auto blk = copySlotLocked(onRemoteEntityOnline_);
    if (blk) blk(pi, &e);
  }
  void onRemoteEntityOffline(la::avdecc::protocol::ProtocolInterface* pi,
                             la::avdecc::UniqueIdentifier const id) noexcept override {
    auto blk = copySlotLocked(onRemoteEntityOffline_);
    if (blk) blk(pi, id.getValue());
  }
  void onRemoteEntityUpdated(la::avdecc::protocol::ProtocolInterface* pi,
                             la::avdecc::entity::Entity const& e) noexcept override {
    auto blk = copySlotLocked(onRemoteEntityUpdated_);
    if (blk) blk(pi, &e);
  }
  void onAecpCommand(la::avdecc::protocol::ProtocolInterface* pi,
                     la::avdecc::protocol::Aecpdu const& pdu) noexcept override {
    auto blk = copySlotLocked(onAecpCommand_);
    if (blk) blk(pi, &pdu);
  }
  void onAecpAemUnsolicitedResponse(la::avdecc::protocol::ProtocolInterface* pi,
                                    la::avdecc::protocol::AemAecpdu const& pdu) noexcept override {
    auto blk = copySlotLocked(onAecpAemUnsolicitedResponse_);
    if (blk) blk(pi, &pdu);
  }
  void onAecpAemIdentifyNotification(la::avdecc::protocol::ProtocolInterface* pi,
                                     la::avdecc::protocol::AemAecpdu const& pdu) noexcept override {
    auto blk = copySlotLocked(onAecpAemIdentifyNotification_);
    if (blk) blk(pi, &pdu);
  }
  void onAcmpCommand(la::avdecc::protocol::ProtocolInterface* pi,
                     la::avdecc::protocol::Acmpdu const& pdu) noexcept override {
    auto blk = copySlotLocked(onAcmpCommand_);
    if (blk) blk(pi, &pdu);
  }
  void onAcmpResponse(la::avdecc::protocol::ProtocolInterface* pi,
                      la::avdecc::protocol::Acmpdu const& pdu) noexcept override {
    auto blk = copySlotLocked(onAcmpResponse_);
    if (blk) blk(pi, &pdu);
  }
  // onAdpduReceived / onAecpduReceived / onAcmpduReceived inherit the
  // base no-op; we don't expose them to Swift yet. (Add slots + setters
  // following the pattern above when needed.)

  mutable std::mutex slotsMutex_;

  Block<void, la::avdecc::protocol::ProtocolInterface*> onTransportError_;

  Block<void, la::avdecc::protocol::ProtocolInterface*,
        la::avdecc::entity::Entity const*> onLocalEntityOnline_;
  Block<void, la::avdecc::protocol::ProtocolInterface*,
        uint64_t /*entityID*/> onLocalEntityOffline_;
  Block<void, la::avdecc::protocol::ProtocolInterface*,
        la::avdecc::entity::Entity const*> onLocalEntityUpdated_;
  Block<void, la::avdecc::protocol::ProtocolInterface*,
        la::avdecc::entity::Entity const*> onRemoteEntityOnline_;
  Block<void, la::avdecc::protocol::ProtocolInterface*,
        uint64_t /*entityID*/> onRemoteEntityOffline_;
  Block<void, la::avdecc::protocol::ProtocolInterface*,
        la::avdecc::entity::Entity const*> onRemoteEntityUpdated_;

  Block<void, la::avdecc::protocol::ProtocolInterface*,
        la::avdecc::protocol::Aecpdu const*> onAecpCommand_;
  Block<void, la::avdecc::protocol::ProtocolInterface*,
        la::avdecc::protocol::AemAecpdu const*> onAecpAemUnsolicitedResponse_;
  Block<void, la::avdecc::protocol::ProtocolInterface*,
        la::avdecc::protocol::AemAecpdu const*> onAecpAemIdentifyNotification_;

  Block<void, la::avdecc::protocol::ProtocolInterface*,
        la::avdecc::protocol::Acmpdu const*> onAcmpCommand_;
  Block<void, la::avdecc::protocol::ProtocolInterface*,
        la::avdecc::protocol::Acmpdu const*> onAcmpResponse_;
};

/// Owns an la_avdecc ProtocolInterface (move-only `UniquePointer`) plus the
/// observer adapter. Necessary because la_avdecc's ProtocolInterface class
/// uses std::function-typed handlers and template-based Subject<> observer
/// machinery the Swift importer skips, and the factory returns a move-only
/// UniquePointer Swift cannot hold itself.
class SWIFT_SHARED_REFERENCE(AVDECCSwift_ProtocolInterfaceOwner_retain,
                             AVDECCSwift_ProtocolInterfaceOwner_release)
    ProtocolInterfaceOwner final
    : public IntrusiveReferenceCounted<ProtocolInterfaceOwner> {
public:
  /// Returns nullptr on failure (la_avdecc throws on invalid arguments etc.).
  /// type/interfaceID/executorName follow la_avdecc's ProtocolInterface::create
  /// signature. Refcount of returned object is 1; Swift assumes the +1.
  /// On failure, fills `outErr` per the contract on
  /// `invokeCapturingException`: typed code if the thrown exception is a
  /// `ProtocolInterface::Exception`, otherwise `InternalError` plus
  /// whatever `what()` text we could capture.
  SWIFT_RETURNS_RETAINED
  static ProtocolInterfaceOwner* create(uint8_t type,
                                        std::string const& networkInterfaceID,
                                        std::string const& executorName,
                                        CapturedException& outErr) noexcept {
    return invokeCapturingException(outErr, [&]() -> ProtocolInterfaceOwner* {
      auto pi = la::avdecc::protocol::ProtocolInterface::create(
          static_cast<la::avdecc::protocol::ProtocolInterface::Type>(type),
          networkInterfaceID, executorName);
      return new ProtocolInterfaceOwner(std::move(pi));
    });
  }

  /// Idempotent. Detaches the observer (if any) and tears down the
  /// ProtocolInterface (which also unwinds la_avdecc's static
  /// ProtocolInterfaceManager entry). Outlives until refcount hits 0.
  void close() noexcept {
    if (!pi_) return;
    if (observerAttached_) {
      pi_->Subject::unregisterObserver(&observer_);
      observerAttached_ = false;
    }
    pi_.reset();
  }

  /// Pointer to the underlying la_avdecc ProtocolInterface. Lifetime tied to
  /// `this`. Used by LocalEntity creation, sync method calls, etc.
  la::avdecc::protocol::ProtocolInterface* get() const noexcept { return pi_.get(); }

  /// MAC address bytes copied into a 6-byte caller buffer. Returns false if
  /// the interface has been closed. (Returning the C++ MacAddress
  /// (`std::array<uint8_t,6>`) directly doesn't import into Swift cleanly,
  /// so we copy.)
  bool copyMacAddress(uint8_t out[6]) const noexcept {
    if (!pi_) return false;
    auto const& mac = pi_->getMacAddress();
    for (int i = 0; i < 6; ++i) out[i] = mac[static_cast<size_t>(i)];
    return true;
  }

  /// Allocate a dynamic EID (la_avdecc returns one valid for this interface
  /// kind). Returns 0 on failure.
  uint64_t getDynamicEID() const noexcept {
    if (!pi_) return 0u;
    return pi_->getDynamicEID().getValue();
  }

  /// Release a dynamic EID previously allocated via getDynamicEID.
  void releaseDynamicEID(uint64_t entityID) const noexcept {
    if (!pi_) return;
    pi_->releaseDynamicEID(la::avdecc::UniqueIdentifier(entityID));
  }

  /// Tear down the underlying ProtocolInterface (idempotent here — we
  /// rely on `close()` for the destructive path and just expose the C++
  /// `shutdown()` separately for callers that want the explicit name).
  void shutdown() noexcept {
    if (pi_) pi_->shutdown();
  }

  /// Drop la_avdecc's cached state for a remote entity. Useful before
  /// re-discovering a misbehaving talker/listener.
  void forgetRemoteEntity(uint64_t entityID) const noexcept {
    if (!pi_) return;
    pi_->forgetRemoteEntity(la::avdecc::UniqueIdentifier(entityID));
  }

  /// True if the underlying transport supports `sendAdpMessage`/`...`. The
  /// PCAP transport supports it; the macOS native transport does not.
  bool isDirectMessageSupported() const noexcept {
    return pi_ ? pi_->isDirectMessageSupported() : false;
  }

  // Coarse lock around la_avdecc's internal state. Exposed for callers
  // that need to atomically observe and mutate (e.g. take a snapshot of
  // remote entities). Recursive on the same thread.
  void lock() const noexcept { if (pi_) pi_->lock(); }
  void unlock() const noexcept { if (pi_) pi_->unlock(); }
  bool isSelfLocked() const noexcept {
    return pi_ ? pi_->isSelfLocked() : false;
  }

  /// Returns la_avdecc Error code (cast to uint8_t). 0 == NoError.
  uint8_t registerLocalEntity(la::avdecc::entity::LocalEntity& entity) noexcept {
    if (!pi_) return static_cast<uint8_t>(la::avdecc::protocol::ProtocolInterface::Error::InvalidParameters);
    return static_cast<uint8_t>(pi_->registerLocalEntity(entity));
  }
  uint8_t unregisterLocalEntity(la::avdecc::entity::LocalEntity& entity) noexcept {
    if (!pi_) return static_cast<uint8_t>(la::avdecc::protocol::ProtocolInterface::Error::InvalidParameters);
    return static_cast<uint8_t>(pi_->unregisterLocalEntity(entity));
  }

  // Raw PDU send entry points. The PDU is constructed Swift-side via the
  // AVDECCSwift::adpdu_*/acmpdu_*/aemAecpdu_* free functions (mutators in
  // the same namespace as the existing read accessors); Swift hands an
  // opaque `void*` pointing at a heap-allocated PDU here and we cast back.
  //
  // Lifetime: the PDU is owned by the Swift wrapper class and freed via
  // `*_destroy(void*)` in deinit. Send uses pass-by-const-reference (la_avdecc
  // copies internally), so the PDU may be reused for retransmits and
  // mutated freely across sends.
  //
  // Transport support: only when isDirectMessageSupported() is true (PCAP
  // transport on Linux + macOS; macOS-native is not). On unsupported
  // transports la_avdecc returns TransportError.
  uint8_t sendAdpMessage(void const* pdu) const noexcept {
    if (!pi_ || !pdu) return static_cast<uint8_t>(
        la::avdecc::protocol::ProtocolInterface::Error::InvalidParameters);
    return static_cast<uint8_t>(pi_->sendAdpMessage(
        *static_cast<la::avdecc::protocol::Adpdu const*>(pdu)));
  }
  uint8_t sendAecpMessage(void const* pdu) const noexcept {
    if (!pi_ || !pdu) return static_cast<uint8_t>(
        la::avdecc::protocol::ProtocolInterface::Error::InvalidParameters);
    return static_cast<uint8_t>(pi_->sendAecpMessage(
        *static_cast<la::avdecc::protocol::Aecpdu const*>(pdu)));
  }
  uint8_t sendAcmpMessage(void const* pdu) const noexcept {
    if (!pi_ || !pdu) return static_cast<uint8_t>(
        la::avdecc::protocol::ProtocolInterface::Error::InvalidParameters);
    return static_cast<uint8_t>(pi_->sendAcmpMessage(
        *static_cast<la::avdecc::protocol::Acmpdu const*>(pdu)));
  }

  /// Observer block setters. Each one stores a clang block (in an
  /// AVDECCSwift::Block<> wrapper that Block_copy's on store, Block_release's
  /// on destroy / replace) that fires when the matching la_avdecc virtual is
  /// called. PDU callbacks take `void const*` (Swift sees as UnsafeRawPointer)
  /// because la::avdecc::protocol::* types don't surface through Swift's C++
  /// importer — the `protocol` namespace name collides with a Swift keyword
  /// and member lookup inside it fails. Entity callbacks pass the imported
  /// C++ type directly.
  ///
  /// Each setter routes through `BlockProtocolInterfaceObserver::setSlot`,
  /// which takes the observer's slots-mutex before the assignment so it
  /// is safe to rebind from any thread while la_avdecc is delivering
  /// notifications on the executor thread.
  void setOnTransportError(void (^cb)(void* /*pi*/)) noexcept {
    using BT = void (^)(la::avdecc::protocol::ProtocolInterface*);
    observer_.setSlot(&BlockProtocolInterfaceObserver::onTransportError_,
                      Block<void, la::avdecc::protocol::ProtocolInterface*>((BT)cb));
  }
  void setOnLocalEntityOnline(
      void (^cb)(void* /*pi*/, la::avdecc::entity::Entity const*)) noexcept {
    using BT = void (^)(la::avdecc::protocol::ProtocolInterface*,
                        la::avdecc::entity::Entity const*);
    observer_.setSlot(&BlockProtocolInterfaceObserver::onLocalEntityOnline_,
                      Block<void, la::avdecc::protocol::ProtocolInterface*,
                            la::avdecc::entity::Entity const*>((BT)cb));
  }
  void setOnLocalEntityOffline(void (^cb)(void* /*pi*/, uint64_t /*entityID*/)) noexcept {
    using BT = void (^)(la::avdecc::protocol::ProtocolInterface*, uint64_t);
    observer_.setSlot(&BlockProtocolInterfaceObserver::onLocalEntityOffline_,
                      Block<void, la::avdecc::protocol::ProtocolInterface*, uint64_t>((BT)cb));
  }
  void setOnLocalEntityUpdated(
      void (^cb)(void* /*pi*/, la::avdecc::entity::Entity const*)) noexcept {
    using BT = void (^)(la::avdecc::protocol::ProtocolInterface*,
                        la::avdecc::entity::Entity const*);
    observer_.setSlot(&BlockProtocolInterfaceObserver::onLocalEntityUpdated_,
                      Block<void, la::avdecc::protocol::ProtocolInterface*,
                            la::avdecc::entity::Entity const*>((BT)cb));
  }
  void setOnRemoteEntityOnline(
      void (^cb)(void* /*pi*/, la::avdecc::entity::Entity const*)) noexcept {
    using BT = void (^)(la::avdecc::protocol::ProtocolInterface*,
                        la::avdecc::entity::Entity const*);
    observer_.setSlot(&BlockProtocolInterfaceObserver::onRemoteEntityOnline_,
                      Block<void, la::avdecc::protocol::ProtocolInterface*,
                            la::avdecc::entity::Entity const*>((BT)cb));
  }
  void setOnRemoteEntityOffline(void (^cb)(void* /*pi*/, uint64_t /*entityID*/)) noexcept {
    using BT = void (^)(la::avdecc::protocol::ProtocolInterface*, uint64_t);
    observer_.setSlot(&BlockProtocolInterfaceObserver::onRemoteEntityOffline_,
                      Block<void, la::avdecc::protocol::ProtocolInterface*, uint64_t>((BT)cb));
  }
  void setOnRemoteEntityUpdated(
      void (^cb)(void* /*pi*/, la::avdecc::entity::Entity const*)) noexcept {
    using BT = void (^)(la::avdecc::protocol::ProtocolInterface*,
                        la::avdecc::entity::Entity const*);
    observer_.setSlot(&BlockProtocolInterfaceObserver::onRemoteEntityUpdated_,
                      Block<void, la::avdecc::protocol::ProtocolInterface*,
                            la::avdecc::entity::Entity const*>((BT)cb));
  }
  // PDU setters take `void const*` blocks because the underlying types
  // (la::avdecc::protocol::Aecpdu etc.) cannot be named in Swift type
  // annotations — the `protocol` namespace name is a Swift keyword and
  // even AVDECCSwift::* typedef aliases don't surface. The Swift wrapper
  // structs (Aecpdu / AemAecpdu / Acmpdu) read fields via the free
  // accessors above, which static_cast the void* back to the matching
  // PDU type.
  void setOnAecpCommand(void (^cb)(void* /*pi*/, void const* /*Aecpdu*/)) noexcept {
    using BT = void (^)(la::avdecc::protocol::ProtocolInterface*,
                        la::avdecc::protocol::Aecpdu const*);
    observer_.setSlot(&BlockProtocolInterfaceObserver::onAecpCommand_,
                      Block<void, la::avdecc::protocol::ProtocolInterface*,
                            la::avdecc::protocol::Aecpdu const*>((BT)cb));
  }
  void setOnAecpAemUnsolicitedResponse(
      void (^cb)(void* /*pi*/, void const* /*AemAecpdu*/)) noexcept {
    using BT = void (^)(la::avdecc::protocol::ProtocolInterface*,
                        la::avdecc::protocol::AemAecpdu const*);
    observer_.setSlot(&BlockProtocolInterfaceObserver::onAecpAemUnsolicitedResponse_,
                      Block<void, la::avdecc::protocol::ProtocolInterface*,
                            la::avdecc::protocol::AemAecpdu const*>((BT)cb));
  }
  void setOnAecpAemIdentifyNotification(
      void (^cb)(void* /*pi*/, void const* /*AemAecpdu*/)) noexcept {
    using BT = void (^)(la::avdecc::protocol::ProtocolInterface*,
                        la::avdecc::protocol::AemAecpdu const*);
    observer_.setSlot(&BlockProtocolInterfaceObserver::onAecpAemIdentifyNotification_,
                      Block<void, la::avdecc::protocol::ProtocolInterface*,
                            la::avdecc::protocol::AemAecpdu const*>((BT)cb));
  }
  void setOnAcmpCommand(void (^cb)(void* /*pi*/, void const* /*Acmpdu*/)) noexcept {
    using BT = void (^)(la::avdecc::protocol::ProtocolInterface*,
                        la::avdecc::protocol::Acmpdu const*);
    observer_.setSlot(&BlockProtocolInterfaceObserver::onAcmpCommand_,
                      Block<void, la::avdecc::protocol::ProtocolInterface*,
                            la::avdecc::protocol::Acmpdu const*>((BT)cb));
  }
  void setOnAcmpResponse(void (^cb)(void* /*pi*/, void const* /*Acmpdu*/)) noexcept {
    using BT = void (^)(la::avdecc::protocol::ProtocolInterface*,
                        la::avdecc::protocol::Acmpdu const*);
    observer_.setSlot(&BlockProtocolInterfaceObserver::onAcmpResponse_,
                      Block<void, la::avdecc::protocol::ProtocolInterface*,
                            la::avdecc::protocol::Acmpdu const*>((BT)cb));
  }

  void clearObserverBlocks() noexcept { observer_.clearAllSlots(); }

  void registerObserver() noexcept {
    if (pi_ && !observerAttached_) {
      pi_->Subject::registerObserver(&observer_);
      observerAttached_ = true;
    }
  }
  void unregisterObserver() noexcept {
    if (pi_ && observerAttached_) {
      pi_->Subject::unregisterObserver(&observer_);
      observerAttached_ = false;
    }
  }

private:
  friend class IntrusiveReferenceCounted<ProtocolInterfaceOwner>;
  explicit ProtocolInterfaceOwner(
      la::avdecc::protocol::ProtocolInterface::UniquePointer pi) noexcept
      : pi_(std::move(pi)) {}
  ~ProtocolInterfaceOwner() noexcept { close(); }

  la::avdecc::protocol::ProtocolInterface::UniquePointer pi_;
  BlockProtocolInterfaceObserver observer_;
  bool observerAttached_ = false;
};


/* ------------------------------------------------------------------- */
/* LocalEntity (controller flavour, backed by AggregateEntity)         */
/* ------------------------------------------------------------------- */

/// Bridges la_avdecc's `controller::Delegate` (~80 virtual on*Changed
/// callbacks fired when other controllers mutate an entity, when sniffed
/// ACMP traffic arrives, when counters tick, etc.) into clang blocks Swift
/// can fill in.
///
/// Inherits `DefaultedDelegate` so unimplemented overrides fall through to
/// la_avdecc's empty defaults; we only override the ones we surface. Each
/// override copies the matching Block<> slot under `slotsMutex_`, releases
/// the lock, and invokes — same lock-then-copy discipline as
/// `BlockProtocolInterfaceObserver`. Threading: la_avdecc fires these on
/// arbitrary internal threads (executor, ACMP state machine, statistics).
///
/// Slot grouping: 80 callbacks fall into ~30 distinct argument shapes;
/// shared `using` aliases above the slot list keep the storage footprint
/// readable. Where a la_avdecc callback uses a value type Swift can't
/// see (`StreamIdentification`, `MemoryBuffer`, `std::chrono::*`, the
/// `std::optional<>` fields inside `MediaClockReferenceInfo`), we flatten
/// at the C++ side and pass the exploded scalars across the ABI.
class BlockControllerDelegate final
    : public la::avdecc::entity::controller::DefaultedDelegate {
public:
  template <typename SlotT, typename ValueT>
  void setSlot(SlotT BlockControllerDelegate::* slot, ValueT&& value) noexcept {
    std::lock_guard<std::mutex> lock(slotsMutex_);
    (this->*slot) = std::forward<ValueT>(value);
  }

  void clearAllSlots() noexcept;

private:
  friend class LocalEntityOwner;

  template <typename SlotT>
  SlotT copySlotLocked(SlotT const& slot) const noexcept {
    std::lock_guard<std::mutex> lock(slotsMutex_);
    return slot;
  }

  // ---- Shared block shapes ----------------------------------------------
  // Group identical (entityID-only, entity-ref, acquire-shape, name shapes,
  // counters shapes, etc.) callbacks under one Block<> typedef each so the
  // slot block below stays at ~80 lines.

  using JustEntityBlock = Block<void, uint64_t /*entityID*/>;
  using EntityRefBlock =
      Block<void, uint64_t, la::avdecc::entity::Entity const* /*entity*/>;
  using AcquireBlock = Block<void, uint64_t /*entityID*/,
                             uint64_t /*owningEntity*/,
                             uint16_t /*descType*/, uint16_t /*descIdx*/>;
  using StreamFormatBlock = Block<void, uint64_t /*entityID*/,
                                  uint16_t /*streamIndex*/,
                                  uint64_t /*streamFormat*/>;
  using StreamMappingsChangedBlock =
      Block<void, uint64_t, uint16_t /*streamPortIndex*/,
            uint16_t /*numberOfMaps*/, uint16_t /*mapIndex*/,
            la::avdecc::entity::model::AudioMapping const*, size_t>;
  using StreamMappingsBlock =
      Block<void, uint64_t, uint16_t /*streamPortIndex*/,
            la::avdecc::entity::model::AudioMapping const*, size_t>;
  using StreamInfoChangedBlock =
      Block<void, uint64_t, uint16_t /*streamIndex*/,
            la::avdecc::entity::model::StreamInfo const*,
            bool /*fromGetStreamInfoResponse*/>;
  using EntityNameBlock =
      Block<void, uint64_t,
            la::avdecc::entity::model::AvdeccFixedString const*>;
  using ConfigNameBlock =
      Block<void, uint64_t, uint16_t /*configIdx*/,
            la::avdecc::entity::model::AvdeccFixedString const*>;
  using DescNameBlock =
      Block<void, uint64_t, uint16_t /*configIdx*/, uint16_t /*descIdx*/,
            la::avdecc::entity::model::AvdeccFixedString const*>;
  using SamplingRateBlock =
      Block<void, uint64_t, uint16_t /*descIdx*/, uint32_t /*samplingRate*/>;
  using StreamIdxBlock = Block<void, uint64_t, uint16_t /*streamIndex*/>;
  using EntityCountersBlock =
      Block<void, uint64_t, uint32_t /*validCounters*/,
            uint32_t const* /*counters[32]*/>;
  using DescCountersBlock =
      Block<void, uint64_t, uint16_t /*descIdx*/,
            uint32_t /*validCounters*/, uint32_t const* /*counters[32]*/>;
  using AcmpSniffedBlock =
      Block<void, uint64_t /*talkerEID*/, uint16_t /*talkerStreamIdx*/,
            uint64_t /*listenerEID*/, uint16_t /*listenerStreamIdx*/,
            uint16_t /*count*/, uint16_t /*flags*/, uint16_t /*status*/>;

  // ---- Slots ------------------------------------------------------------

  // Global / lifecycle
  Block<void> onTransportError_;
  EntityRefBlock onEntityOnline_;
  EntityRefBlock onEntityUpdate_;
  JustEntityBlock onEntityOffline_;
  JustEntityBlock onEntityIdentifyNotification_;
  JustEntityBlock onDeregisteredFromUnsolicitedNotifications_;

  // Sniffed ACMP responses — six shapes, all `(talker, listener, count,
  // flags, status)`. The ACMP status is `LocalEntity::ControlStatus`, a
  // distinct enum from AEM (see Swift `LocalEntityControlStatus`).
  AcmpSniffedBlock onControllerConnectResponseSniffed_;
  AcmpSniffedBlock onControllerDisconnectResponseSniffed_;
  AcmpSniffedBlock onListenerConnectResponseSniffed_;
  AcmpSniffedBlock onListenerDisconnectResponseSniffed_;
  AcmpSniffedBlock onGetTalkerStreamStateResponseSniffed_;
  AcmpSniffedBlock onGetListenerStreamStateResponseSniffed_;

  // Lock / acquire — shape (entityID, owningOrLockingEntityID, descType,
  // descIdx). la_avdecc passes a UniqueIdentifier for the second slot;
  // absent owners come through as 0.
  AcquireBlock onEntityAcquired_;
  AcquireBlock onEntityReleased_;
  AcquireBlock onEntityLocked_;
  AcquireBlock onEntityUnlocked_;

  // Configuration / clock-source / association
  Block<void, uint64_t, uint16_t /*configurationIndex*/> onConfigurationChanged_;
  Block<void, uint64_t, uint64_t /*associationID*/> onAssociationIDChanged_;
  Block<void, uint64_t, uint16_t /*clockDomainIdx*/,
        uint16_t /*clockSourceIdx*/> onClockSourceChanged_;

  // Stream format / info / mappings / start-stop
  StreamFormatBlock onStreamInputFormatChanged_;
  StreamFormatBlock onStreamOutputFormatChanged_;
  StreamMappingsChangedBlock onStreamPortInputAudioMappingsChanged_;
  StreamMappingsChangedBlock onStreamPortOutputAudioMappingsChanged_;
  StreamMappingsBlock onStreamPortInputAudioMappingsAdded_;
  StreamMappingsBlock onStreamPortOutputAudioMappingsAdded_;
  StreamMappingsBlock onStreamPortInputAudioMappingsRemoved_;
  StreamMappingsBlock onStreamPortOutputAudioMappingsRemoved_;
  StreamInfoChangedBlock onStreamInputInfoChanged_;
  StreamInfoChangedBlock onStreamOutputInfoChanged_;
  StreamIdxBlock onStreamInputStarted_;
  StreamIdxBlock onStreamOutputStarted_;
  StreamIdxBlock onStreamInputStopped_;
  StreamIdxBlock onStreamOutputStopped_;
  Block<void, uint64_t, uint16_t /*streamIndex*/,
        uint64_t /*nanoseconds*/> onMaxTransitTimeChanged_;

  // Names — `AvdeccFixedString` const& trailing arg.
  EntityNameBlock onEntityNameChanged_;
  EntityNameBlock onEntityGroupNameChanged_;
  ConfigNameBlock onConfigurationNameChanged_;
  DescNameBlock onAudioUnitNameChanged_;
  DescNameBlock onStreamInputNameChanged_;
  DescNameBlock onStreamOutputNameChanged_;
  DescNameBlock onJackInputNameChanged_;
  DescNameBlock onJackOutputNameChanged_;
  DescNameBlock onAvbInterfaceNameChanged_;
  DescNameBlock onClockSourceNameChanged_;
  DescNameBlock onMemoryObjectNameChanged_;
  DescNameBlock onAudioClusterNameChanged_;
  DescNameBlock onControlNameChanged_;
  DescNameBlock onClockDomainNameChanged_;
  DescNameBlock onTimingNameChanged_;
  DescNameBlock onPtpInstanceNameChanged_;
  DescNameBlock onPtpPortNameChanged_;

  // Sampling rates — la_avdecc's SamplingRate is a uint32 wrapper.
  SamplingRateBlock onAudioUnitSamplingRateChanged_;
  SamplingRateBlock onVideoClusterSamplingRateChanged_;
  SamplingRateBlock onSensorClusterSamplingRateChanged_;

  // Counters — entity-level and per-descriptor variants.
  EntityCountersBlock onEntityCountersChanged_;
  DescCountersBlock onAvbInterfaceCountersChanged_;
  DescCountersBlock onClockDomainCountersChanged_;
  DescCountersBlock onStreamInputCountersChanged_;
  DescCountersBlock onStreamOutputCountersChanged_;

  // AVB info / AS path / control values
  Block<void, uint64_t, uint16_t /*avbInterfaceIdx*/,
        la::avdecc::entity::model::AvbInfo const*> onAvbInfoChanged_;
  Block<void, uint64_t, uint16_t /*avbInterfaceIdx*/,
        la::avdecc::entity::model::AsPath const*> onAsPathChanged_;
  Block<void, uint64_t, uint16_t /*controlIdx*/,
        uint8_t const* /*packed*/, size_t /*len*/> onControlValuesChanged_;

  // Memory object / operation
  Block<void, uint64_t, uint16_t /*configurationIndex*/,
        uint16_t /*memoryObjectIndex*/, uint64_t /*length*/>
      onMemoryObjectLengthChanged_;
  Block<void, uint64_t, uint16_t /*descType*/, uint16_t /*descIdx*/,
        uint16_t /*operationID*/, uint16_t /*percentComplete*/>
      onOperationStatus_;

  // Milan MVU
  Block<void, uint64_t, uint64_t /*systemUniqueID*/,
        la::avdecc::entity::model::AvdeccFixedString const*>
      onSystemUniqueIDChanged_;
  Block<void, uint64_t, uint16_t /*clockDomainIdx*/, uint8_t /*defaultPriority*/,
        bool /*hasUserPrio*/, uint8_t /*userPrio*/, bool /*hasName*/,
        la::avdecc::entity::model::AvdeccFixedString const* /*domainName*/>
      onMediaClockReferenceInfoChanged_;
  Block<void, uint64_t, uint16_t /*streamIndex*/,
        uint64_t /*talkerEID*/, uint16_t /*talkerStreamIdx*/,
        uint16_t /*flags*/> onBindStream_;
  StreamIdxBlock onUnbindStream_;
  Block<void, uint64_t, uint16_t /*streamIndex*/,
        la::avdecc::entity::model::StreamInputInfoEx const*>
      onStreamInputInfoExChanged_;

  // Statistics
  JustEntityBlock onAecpRetry_;
  JustEntityBlock onAecpTimeout_;
  JustEntityBlock onAecpUnexpectedResponse_;
  Block<void, uint64_t, uint64_t /*responseTimeMs*/> onAecpResponseTime_;
  Block<void, uint64_t, uint16_t /*sequenceID*/> onAemAecpUnsolicitedReceived_;
  Block<void, uint64_t, uint16_t /*sequenceID*/> onMvuAecpUnsolicitedReceived_;

  mutable std::mutex slotsMutex_;

  // ---- Override declarations ---------------------------------------------
  // Each follows the same recipe: copy slot under lock, fire if non-null.
  // Order matches la_avdecc's `Delegate` declaration in
  // controllerEntity.hpp.

  using DT = la::avdecc::entity::controller::Interface const* const;
  using UID = la::avdecc::UniqueIdentifier const;

  void onTransportError(DT) noexcept override {
    auto blk = copySlotLocked(onTransportError_);
    if (blk) blk();
  }

  // ADP
  void onEntityOnline(DT, UID id, la::avdecc::entity::Entity const& e) noexcept override {
    auto blk = copySlotLocked(onEntityOnline_);
    if (blk) blk(id.getValue(), &e);
  }
  void onEntityUpdate(DT, UID id, la::avdecc::entity::Entity const& e) noexcept override {
    auto blk = copySlotLocked(onEntityUpdate_);
    if (blk) blk(id.getValue(), &e);
  }
  void onEntityOffline(DT, UID id) noexcept override {
    auto blk = copySlotLocked(onEntityOffline_);
    if (blk) blk(id.getValue());
  }

  // Sniffed ACMP
  void onControllerConnectResponseSniffed(
      DT, la::avdecc::entity::model::StreamIdentification const& t,
      la::avdecc::entity::model::StreamIdentification const& l,
      uint16_t const count, la::avdecc::entity::ConnectionFlags const flags,
      la::avdecc::entity::LocalEntity::ControlStatus const status) noexcept override {
    auto blk = copySlotLocked(onControllerConnectResponseSniffed_);
    if (blk) blk(t.entityID.getValue(), t.streamIndex,
                 l.entityID.getValue(), l.streamIndex,
                 count, flags.value(), static_cast<uint16_t>(status));
  }
  void onControllerDisconnectResponseSniffed(
      DT, la::avdecc::entity::model::StreamIdentification const& t,
      la::avdecc::entity::model::StreamIdentification const& l,
      uint16_t const count, la::avdecc::entity::ConnectionFlags const flags,
      la::avdecc::entity::LocalEntity::ControlStatus const status) noexcept override {
    auto blk = copySlotLocked(onControllerDisconnectResponseSniffed_);
    if (blk) blk(t.entityID.getValue(), t.streamIndex,
                 l.entityID.getValue(), l.streamIndex,
                 count, flags.value(), static_cast<uint16_t>(status));
  }
  void onListenerConnectResponseSniffed(
      DT, la::avdecc::entity::model::StreamIdentification const& t,
      la::avdecc::entity::model::StreamIdentification const& l,
      uint16_t const count, la::avdecc::entity::ConnectionFlags const flags,
      la::avdecc::entity::LocalEntity::ControlStatus const status) noexcept override {
    auto blk = copySlotLocked(onListenerConnectResponseSniffed_);
    if (blk) blk(t.entityID.getValue(), t.streamIndex,
                 l.entityID.getValue(), l.streamIndex,
                 count, flags.value(), static_cast<uint16_t>(status));
  }
  void onListenerDisconnectResponseSniffed(
      DT, la::avdecc::entity::model::StreamIdentification const& t,
      la::avdecc::entity::model::StreamIdentification const& l,
      uint16_t const count, la::avdecc::entity::ConnectionFlags const flags,
      la::avdecc::entity::LocalEntity::ControlStatus const status) noexcept override {
    auto blk = copySlotLocked(onListenerDisconnectResponseSniffed_);
    if (blk) blk(t.entityID.getValue(), t.streamIndex,
                 l.entityID.getValue(), l.streamIndex,
                 count, flags.value(), static_cast<uint16_t>(status));
  }
  void onGetTalkerStreamStateResponseSniffed(
      DT, la::avdecc::entity::model::StreamIdentification const& t,
      la::avdecc::entity::model::StreamIdentification const& l,
      uint16_t const count, la::avdecc::entity::ConnectionFlags const flags,
      la::avdecc::entity::LocalEntity::ControlStatus const status) noexcept override {
    auto blk = copySlotLocked(onGetTalkerStreamStateResponseSniffed_);
    if (blk) blk(t.entityID.getValue(), t.streamIndex,
                 l.entityID.getValue(), l.streamIndex,
                 count, flags.value(), static_cast<uint16_t>(status));
  }
  void onGetListenerStreamStateResponseSniffed(
      DT, la::avdecc::entity::model::StreamIdentification const& t,
      la::avdecc::entity::model::StreamIdentification const& l,
      uint16_t const count, la::avdecc::entity::ConnectionFlags const flags,
      la::avdecc::entity::LocalEntity::ControlStatus const status) noexcept override {
    auto blk = copySlotLocked(onGetListenerStreamStateResponseSniffed_);
    if (blk) blk(t.entityID.getValue(), t.streamIndex,
                 l.entityID.getValue(), l.streamIndex,
                 count, flags.value(), static_cast<uint16_t>(status));
  }

  // Unsolicited
  void onDeregisteredFromUnsolicitedNotifications(DT, UID id) noexcept override {
    auto blk = copySlotLocked(onDeregisteredFromUnsolicitedNotifications_);
    if (blk) blk(id.getValue());
  }
  void onEntityAcquired(DT, UID id, UID owning,
                        la::avdecc::entity::model::DescriptorType const dt,
                        la::avdecc::entity::model::DescriptorIndex const di) noexcept override {
    auto blk = copySlotLocked(onEntityAcquired_);
    if (blk) blk(id.getValue(), owning.getValue(),
                 static_cast<uint16_t>(dt), di);
  }
  void onEntityReleased(DT, UID id, UID owning,
                        la::avdecc::entity::model::DescriptorType const dt,
                        la::avdecc::entity::model::DescriptorIndex const di) noexcept override {
    auto blk = copySlotLocked(onEntityReleased_);
    if (blk) blk(id.getValue(), owning.getValue(),
                 static_cast<uint16_t>(dt), di);
  }
  void onEntityLocked(DT, UID id, UID locking,
                      la::avdecc::entity::model::DescriptorType const dt,
                      la::avdecc::entity::model::DescriptorIndex const di) noexcept override {
    auto blk = copySlotLocked(onEntityLocked_);
    if (blk) blk(id.getValue(), locking.getValue(),
                 static_cast<uint16_t>(dt), di);
  }
  void onEntityUnlocked(DT, UID id, UID locking,
                        la::avdecc::entity::model::DescriptorType const dt,
                        la::avdecc::entity::model::DescriptorIndex const di) noexcept override {
    auto blk = copySlotLocked(onEntityUnlocked_);
    if (blk) blk(id.getValue(), locking.getValue(),
                 static_cast<uint16_t>(dt), di);
  }
  void onConfigurationChanged(DT, UID id,
                              la::avdecc::entity::model::ConfigurationIndex const cfg) noexcept override {
    auto blk = copySlotLocked(onConfigurationChanged_);
    if (blk) blk(id.getValue(), cfg);
  }
  void onStreamInputFormatChanged(DT, UID id,
                                  la::avdecc::entity::model::StreamIndex const si,
                                  la::avdecc::entity::model::StreamFormat const fmt) noexcept override {
    auto blk = copySlotLocked(onStreamInputFormatChanged_);
    if (blk) blk(id.getValue(), si, fmt.getValue());
  }
  void onStreamOutputFormatChanged(DT, UID id,
                                   la::avdecc::entity::model::StreamIndex const si,
                                   la::avdecc::entity::model::StreamFormat const fmt) noexcept override {
    auto blk = copySlotLocked(onStreamOutputFormatChanged_);
    if (blk) blk(id.getValue(), si, fmt.getValue());
  }
  void onStreamPortInputAudioMappingsChanged(DT, UID id,
                                             la::avdecc::entity::model::StreamPortIndex const sp,
                                             la::avdecc::entity::model::MapIndex const numMaps,
                                             la::avdecc::entity::model::MapIndex const mi,
                                             la::avdecc::entity::model::AudioMappings const& m) noexcept override {
    auto blk = copySlotLocked(onStreamPortInputAudioMappingsChanged_);
    if (blk) blk(id.getValue(), sp, numMaps, mi, m.data(), m.size());
  }
  void onStreamPortOutputAudioMappingsChanged(DT, UID id,
                                              la::avdecc::entity::model::StreamPortIndex const sp,
                                              la::avdecc::entity::model::MapIndex const numMaps,
                                              la::avdecc::entity::model::MapIndex const mi,
                                              la::avdecc::entity::model::AudioMappings const& m) noexcept override {
    auto blk = copySlotLocked(onStreamPortOutputAudioMappingsChanged_);
    if (blk) blk(id.getValue(), sp, numMaps, mi, m.data(), m.size());
  }
  void onStreamInputInfoChanged(DT, UID id,
                                la::avdecc::entity::model::StreamIndex const si,
                                la::avdecc::entity::model::StreamInfo const& info,
                                bool const fromGet) noexcept override {
    auto blk = copySlotLocked(onStreamInputInfoChanged_);
    if (blk) blk(id.getValue(), si, &info, fromGet);
  }
  void onStreamOutputInfoChanged(DT, UID id,
                                 la::avdecc::entity::model::StreamIndex const si,
                                 la::avdecc::entity::model::StreamInfo const& info,
                                 bool const fromGet) noexcept override {
    auto blk = copySlotLocked(onStreamOutputInfoChanged_);
    if (blk) blk(id.getValue(), si, &info, fromGet);
  }
  void onEntityNameChanged(DT, UID id,
                           la::avdecc::entity::model::AvdeccFixedString const& n) noexcept override {
    auto blk = copySlotLocked(onEntityNameChanged_);
    if (blk) blk(id.getValue(), &n);
  }
  void onEntityGroupNameChanged(DT, UID id,
                                la::avdecc::entity::model::AvdeccFixedString const& n) noexcept override {
    auto blk = copySlotLocked(onEntityGroupNameChanged_);
    if (blk) blk(id.getValue(), &n);
  }
  void onConfigurationNameChanged(DT, UID id,
                                  la::avdecc::entity::model::ConfigurationIndex const cfg,
                                  la::avdecc::entity::model::AvdeccFixedString const& n) noexcept override {
    auto blk = copySlotLocked(onConfigurationNameChanged_);
    if (blk) blk(id.getValue(), cfg, &n);
  }

  // Descriptor-level name changes — all share `(id, configIdx, descIdx, &name)`.
  void onAudioUnitNameChanged(DT, UID id,
                              la::avdecc::entity::model::ConfigurationIndex const cfg,
                              la::avdecc::entity::model::AudioUnitIndex const au,
                              la::avdecc::entity::model::AvdeccFixedString const& n) noexcept override {
    auto blk = copySlotLocked(onAudioUnitNameChanged_);
    if (blk) blk(id.getValue(), cfg, au, &n);
  }
  void onStreamInputNameChanged(DT, UID id,
                                la::avdecc::entity::model::ConfigurationIndex const cfg,
                                la::avdecc::entity::model::StreamIndex const si,
                                la::avdecc::entity::model::AvdeccFixedString const& n) noexcept override {
    auto blk = copySlotLocked(onStreamInputNameChanged_);
    if (blk) blk(id.getValue(), cfg, si, &n);
  }
  void onStreamOutputNameChanged(DT, UID id,
                                 la::avdecc::entity::model::ConfigurationIndex const cfg,
                                 la::avdecc::entity::model::StreamIndex const si,
                                 la::avdecc::entity::model::AvdeccFixedString const& n) noexcept override {
    auto blk = copySlotLocked(onStreamOutputNameChanged_);
    if (blk) blk(id.getValue(), cfg, si, &n);
  }
  void onJackInputNameChanged(DT, UID id,
                              la::avdecc::entity::model::ConfigurationIndex const cfg,
                              la::avdecc::entity::model::JackIndex const j,
                              la::avdecc::entity::model::AvdeccFixedString const& n) noexcept override {
    auto blk = copySlotLocked(onJackInputNameChanged_);
    if (blk) blk(id.getValue(), cfg, j, &n);
  }
  void onJackOutputNameChanged(DT, UID id,
                               la::avdecc::entity::model::ConfigurationIndex const cfg,
                               la::avdecc::entity::model::JackIndex const j,
                               la::avdecc::entity::model::AvdeccFixedString const& n) noexcept override {
    auto blk = copySlotLocked(onJackOutputNameChanged_);
    if (blk) blk(id.getValue(), cfg, j, &n);
  }
  void onAvbInterfaceNameChanged(DT, UID id,
                                 la::avdecc::entity::model::ConfigurationIndex const cfg,
                                 la::avdecc::entity::model::AvbInterfaceIndex const a,
                                 la::avdecc::entity::model::AvdeccFixedString const& n) noexcept override {
    auto blk = copySlotLocked(onAvbInterfaceNameChanged_);
    if (blk) blk(id.getValue(), cfg, a, &n);
  }
  void onClockSourceNameChanged(DT, UID id,
                                la::avdecc::entity::model::ConfigurationIndex const cfg,
                                la::avdecc::entity::model::ClockSourceIndex const cs,
                                la::avdecc::entity::model::AvdeccFixedString const& n) noexcept override {
    auto blk = copySlotLocked(onClockSourceNameChanged_);
    if (blk) blk(id.getValue(), cfg, cs, &n);
  }
  void onMemoryObjectNameChanged(DT, UID id,
                                 la::avdecc::entity::model::ConfigurationIndex const cfg,
                                 la::avdecc::entity::model::MemoryObjectIndex const mo,
                                 la::avdecc::entity::model::AvdeccFixedString const& n) noexcept override {
    auto blk = copySlotLocked(onMemoryObjectNameChanged_);
    if (blk) blk(id.getValue(), cfg, mo, &n);
  }
  void onAudioClusterNameChanged(DT, UID id,
                                 la::avdecc::entity::model::ConfigurationIndex const cfg,
                                 la::avdecc::entity::model::ClusterIndex const cl,
                                 la::avdecc::entity::model::AvdeccFixedString const& n) noexcept override {
    auto blk = copySlotLocked(onAudioClusterNameChanged_);
    if (blk) blk(id.getValue(), cfg, cl, &n);
  }
  void onControlNameChanged(DT, UID id,
                            la::avdecc::entity::model::ConfigurationIndex const cfg,
                            la::avdecc::entity::model::ControlIndex const ci,
                            la::avdecc::entity::model::AvdeccFixedString const& n) noexcept override {
    auto blk = copySlotLocked(onControlNameChanged_);
    if (blk) blk(id.getValue(), cfg, ci, &n);
  }
  void onClockDomainNameChanged(DT, UID id,
                                la::avdecc::entity::model::ConfigurationIndex const cfg,
                                la::avdecc::entity::model::ClockDomainIndex const cd,
                                la::avdecc::entity::model::AvdeccFixedString const& n) noexcept override {
    auto blk = copySlotLocked(onClockDomainNameChanged_);
    if (blk) blk(id.getValue(), cfg, cd, &n);
  }
  void onTimingNameChanged(DT, UID id,
                           la::avdecc::entity::model::ConfigurationIndex const cfg,
                           la::avdecc::entity::model::TimingIndex const ti,
                           la::avdecc::entity::model::AvdeccFixedString const& n) noexcept override {
    auto blk = copySlotLocked(onTimingNameChanged_);
    if (blk) blk(id.getValue(), cfg, ti, &n);
  }
  void onPtpInstanceNameChanged(DT, UID id,
                                la::avdecc::entity::model::ConfigurationIndex const cfg,
                                la::avdecc::entity::model::PtpInstanceIndex const pi,
                                la::avdecc::entity::model::AvdeccFixedString const& n) noexcept override {
    auto blk = copySlotLocked(onPtpInstanceNameChanged_);
    if (blk) blk(id.getValue(), cfg, pi, &n);
  }
  void onPtpPortNameChanged(DT, UID id,
                            la::avdecc::entity::model::ConfigurationIndex const cfg,
                            la::avdecc::entity::model::PtpPortIndex const pp,
                            la::avdecc::entity::model::AvdeccFixedString const& n) noexcept override {
    auto blk = copySlotLocked(onPtpPortNameChanged_);
    if (blk) blk(id.getValue(), cfg, pp, &n);
  }
  void onAssociationIDChanged(DT, UID id, UID assoc) noexcept override {
    auto blk = copySlotLocked(onAssociationIDChanged_);
    if (blk) blk(id.getValue(), assoc.getValue());
  }
  void onAudioUnitSamplingRateChanged(DT, UID id,
                                      la::avdecc::entity::model::AudioUnitIndex const au,
                                      la::avdecc::entity::model::SamplingRate const sr) noexcept override {
    auto blk = copySlotLocked(onAudioUnitSamplingRateChanged_);
    if (blk) blk(id.getValue(), au, sr.getValue());
  }
  void onVideoClusterSamplingRateChanged(DT, UID id,
                                         la::avdecc::entity::model::ClusterIndex const c,
                                         la::avdecc::entity::model::SamplingRate const sr) noexcept override {
    auto blk = copySlotLocked(onVideoClusterSamplingRateChanged_);
    if (blk) blk(id.getValue(), c, sr.getValue());
  }
  void onSensorClusterSamplingRateChanged(DT, UID id,
                                          la::avdecc::entity::model::ClusterIndex const c,
                                          la::avdecc::entity::model::SamplingRate const sr) noexcept override {
    auto blk = copySlotLocked(onSensorClusterSamplingRateChanged_);
    if (blk) blk(id.getValue(), c, sr.getValue());
  }
  void onClockSourceChanged(DT, UID id,
                            la::avdecc::entity::model::ClockDomainIndex const cd,
                            la::avdecc::entity::model::ClockSourceIndex const cs) noexcept override {
    auto blk = copySlotLocked(onClockSourceChanged_);
    if (blk) blk(id.getValue(), cd, cs);
  }
  void onControlValuesChanged(DT, UID id,
                              la::avdecc::entity::model::ControlIndex const ci,
                              la::avdecc::MemoryBuffer const& packed) noexcept override {
    auto blk = copySlotLocked(onControlValuesChanged_);
    if (blk) blk(id.getValue(), ci, packed.data(), packed.size());
  }
  void onStreamInputStarted(DT, UID id,
                            la::avdecc::entity::model::StreamIndex const si) noexcept override {
    auto blk = copySlotLocked(onStreamInputStarted_);
    if (blk) blk(id.getValue(), si);
  }
  void onStreamOutputStarted(DT, UID id,
                             la::avdecc::entity::model::StreamIndex const si) noexcept override {
    auto blk = copySlotLocked(onStreamOutputStarted_);
    if (blk) blk(id.getValue(), si);
  }
  void onStreamInputStopped(DT, UID id,
                            la::avdecc::entity::model::StreamIndex const si) noexcept override {
    auto blk = copySlotLocked(onStreamInputStopped_);
    if (blk) blk(id.getValue(), si);
  }
  void onStreamOutputStopped(DT, UID id,
                             la::avdecc::entity::model::StreamIndex const si) noexcept override {
    auto blk = copySlotLocked(onStreamOutputStopped_);
    if (blk) blk(id.getValue(), si);
  }
  void onAvbInfoChanged(DT, UID id,
                        la::avdecc::entity::model::AvbInterfaceIndex const a,
                        la::avdecc::entity::model::AvbInfo const& info) noexcept override {
    auto blk = copySlotLocked(onAvbInfoChanged_);
    if (blk) blk(id.getValue(), a, &info);
  }
  void onAsPathChanged(DT, UID id,
                       la::avdecc::entity::model::AvbInterfaceIndex const a,
                       la::avdecc::entity::model::AsPath const& path) noexcept override {
    auto blk = copySlotLocked(onAsPathChanged_);
    if (blk) blk(id.getValue(), a, &path);
  }
  void onEntityCountersChanged(DT, UID id,
                               la::avdecc::entity::EntityCounterValidFlags const valid,
                               la::avdecc::entity::model::DescriptorCounters const& c) noexcept override {
    auto blk = copySlotLocked(onEntityCountersChanged_);
    if (blk) blk(id.getValue(), valid.value(), c.data());
  }
  void onAvbInterfaceCountersChanged(DT, UID id,
                                     la::avdecc::entity::model::AvbInterfaceIndex const a,
                                     la::avdecc::entity::AvbInterfaceCounterValidFlags const valid,
                                     la::avdecc::entity::model::DescriptorCounters const& c) noexcept override {
    auto blk = copySlotLocked(onAvbInterfaceCountersChanged_);
    if (blk) blk(id.getValue(), a, valid.value(), c.data());
  }
  void onClockDomainCountersChanged(DT, UID id,
                                    la::avdecc::entity::model::ClockDomainIndex const cd,
                                    la::avdecc::entity::ClockDomainCounterValidFlags const valid,
                                    la::avdecc::entity::model::DescriptorCounters const& c) noexcept override {
    auto blk = copySlotLocked(onClockDomainCountersChanged_);
    if (blk) blk(id.getValue(), cd, valid.value(), c.data());
  }
  void onStreamInputCountersChanged(DT, UID id,
                                    la::avdecc::entity::model::StreamIndex const si,
                                    la::avdecc::entity::StreamInputCounterValidFlags const valid,
                                    la::avdecc::entity::model::DescriptorCounters const& c) noexcept override {
    auto blk = copySlotLocked(onStreamInputCountersChanged_);
    if (blk) blk(id.getValue(), si, valid.value(), c.data());
  }
  void onStreamOutputCountersChanged(DT, UID id,
                                     la::avdecc::entity::model::StreamIndex const si,
                                     la::avdecc::entity::StreamOutputCounterValidFlags const valid,
                                     la::avdecc::entity::model::DescriptorCounters const& c) noexcept override {
    auto blk = copySlotLocked(onStreamOutputCountersChanged_);
    if (blk) blk(id.getValue(), si, valid.value(), c.data());
  }
  void onStreamPortInputAudioMappingsAdded(DT, UID id,
                                           la::avdecc::entity::model::StreamPortIndex const sp,
                                           la::avdecc::entity::model::AudioMappings const& m) noexcept override {
    auto blk = copySlotLocked(onStreamPortInputAudioMappingsAdded_);
    if (blk) blk(id.getValue(), sp, m.data(), m.size());
  }
  void onStreamPortOutputAudioMappingsAdded(DT, UID id,
                                            la::avdecc::entity::model::StreamPortIndex const sp,
                                            la::avdecc::entity::model::AudioMappings const& m) noexcept override {
    auto blk = copySlotLocked(onStreamPortOutputAudioMappingsAdded_);
    if (blk) blk(id.getValue(), sp, m.data(), m.size());
  }
  void onStreamPortInputAudioMappingsRemoved(DT, UID id,
                                             la::avdecc::entity::model::StreamPortIndex const sp,
                                             la::avdecc::entity::model::AudioMappings const& m) noexcept override {
    auto blk = copySlotLocked(onStreamPortInputAudioMappingsRemoved_);
    if (blk) blk(id.getValue(), sp, m.data(), m.size());
  }
  void onStreamPortOutputAudioMappingsRemoved(DT, UID id,
                                              la::avdecc::entity::model::StreamPortIndex const sp,
                                              la::avdecc::entity::model::AudioMappings const& m) noexcept override {
    auto blk = copySlotLocked(onStreamPortOutputAudioMappingsRemoved_);
    if (blk) blk(id.getValue(), sp, m.data(), m.size());
  }
  void onMemoryObjectLengthChanged(DT, UID id,
                                   la::avdecc::entity::model::ConfigurationIndex const cfg,
                                   la::avdecc::entity::model::MemoryObjectIndex const mo,
                                   std::uint64_t const length) noexcept override {
    auto blk = copySlotLocked(onMemoryObjectLengthChanged_);
    if (blk) blk(id.getValue(), cfg, mo, length);
  }
  void onOperationStatus(DT, UID id,
                         la::avdecc::entity::model::DescriptorType const dt,
                         la::avdecc::entity::model::DescriptorIndex const di,
                         la::avdecc::entity::model::OperationID const op,
                         std::uint16_t const pct) noexcept override {
    auto blk = copySlotLocked(onOperationStatus_);
    if (blk) blk(id.getValue(), static_cast<uint16_t>(dt), di, op, pct);
  }
  void onMaxTransitTimeChanged(DT, UID id,
                               la::avdecc::entity::model::StreamIndex const si,
                               std::chrono::nanoseconds const& ns) noexcept override {
    auto blk = copySlotLocked(onMaxTransitTimeChanged_);
    if (blk) blk(id.getValue(), si, static_cast<uint64_t>(ns.count()));
  }
  void onSystemUniqueIDChanged(DT, UID id, UID sys,
                               la::avdecc::entity::model::AvdeccFixedString const& name) noexcept override {
    auto blk = copySlotLocked(onSystemUniqueIDChanged_);
    if (blk) blk(id.getValue(), sys.getValue(), &name);
  }
  void onMediaClockReferenceInfoChanged(
      DT, UID id, la::avdecc::entity::model::ClockDomainIndex const cd,
      la::avdecc::entity::model::DefaultMediaClockReferencePriority const def,
      la::avdecc::entity::model::MediaClockReferenceInfo const& info) noexcept override {
    auto blk = copySlotLocked(onMediaClockReferenceInfoChanged_);
    if (!blk) return;
    auto const hasPrio = info.userMediaClockPriority.has_value();
    auto const prio = hasPrio
        ? *info.userMediaClockPriority
        : la::avdecc::entity::model::MediaClockReferencePriority{0u};
    auto const hasName = info.mediaClockDomainName.has_value();
    blk(id.getValue(), cd, static_cast<uint8_t>(def),
        hasPrio, prio,
        hasName, hasName ? &(*info.mediaClockDomainName) : nullptr);
  }
  void onBindStream(DT, UID id,
                    la::avdecc::entity::model::StreamIndex const si,
                    la::avdecc::entity::model::StreamIdentification const& t,
                    la::avdecc::entity::BindStreamFlags const f) noexcept override {
    auto blk = copySlotLocked(onBindStream_);
    if (blk) blk(id.getValue(), si,
                 t.entityID.getValue(), t.streamIndex, f.value());
  }
  void onUnbindStream(DT, UID id,
                      la::avdecc::entity::model::StreamIndex const si) noexcept override {
    auto blk = copySlotLocked(onUnbindStream_);
    if (blk) blk(id.getValue(), si);
  }
  void onStreamInputInfoExChanged(DT, UID id,
                                  la::avdecc::entity::model::StreamIndex const si,
                                  la::avdecc::entity::model::StreamInputInfoEx const& info) noexcept override {
    auto blk = copySlotLocked(onStreamInputInfoExChanged_);
    if (blk) blk(id.getValue(), si, &info);
  }

  // Identification
  void onEntityIdentifyNotification(DT, UID id) noexcept override {
    auto blk = copySlotLocked(onEntityIdentifyNotification_);
    if (blk) blk(id.getValue());
  }

  // Statistics. la_avdecc passes UniqueIdentifier by const ref here (not
  // value); Delegate.hpp signatures use `UniqueIdentifier const&`.
  void onAecpRetry(DT, la::avdecc::UniqueIdentifier const& id) noexcept override {
    auto blk = copySlotLocked(onAecpRetry_);
    if (blk) blk(id.getValue());
  }
  void onAecpTimeout(DT, la::avdecc::UniqueIdentifier const& id) noexcept override {
    auto blk = copySlotLocked(onAecpTimeout_);
    if (blk) blk(id.getValue());
  }
  void onAecpUnexpectedResponse(DT, la::avdecc::UniqueIdentifier const& id) noexcept override {
    auto blk = copySlotLocked(onAecpUnexpectedResponse_);
    if (blk) blk(id.getValue());
  }
  void onAecpResponseTime(DT, la::avdecc::UniqueIdentifier const& id,
                          std::chrono::milliseconds const& ms) noexcept override {
    auto blk = copySlotLocked(onAecpResponseTime_);
    if (blk) blk(id.getValue(), static_cast<uint64_t>(ms.count()));
  }
  void onAemAecpUnsolicitedReceived(DT, la::avdecc::UniqueIdentifier const& id,
                                    la::avdecc::protocol::AecpSequenceID const seq) noexcept override {
    auto blk = copySlotLocked(onAemAecpUnsolicitedReceived_);
    if (blk) blk(id.getValue(), seq);
  }
  void onMvuAecpUnsolicitedReceived(DT, la::avdecc::UniqueIdentifier const& id,
                                    la::avdecc::protocol::AecpSequenceID const seq) noexcept override {
    auto blk = copySlotLocked(onMvuAecpUnsolicitedReceived_);
    if (blk) blk(id.getValue(), seq);
  }
};

inline void BlockControllerDelegate::clearAllSlots() noexcept {
  std::lock_guard<std::mutex> lock(slotsMutex_);
  onTransportError_.reset();
  onEntityOnline_.reset();
  onEntityUpdate_.reset();
  onEntityOffline_.reset();
  onEntityIdentifyNotification_.reset();
  onDeregisteredFromUnsolicitedNotifications_.reset();
  onControllerConnectResponseSniffed_.reset();
  onControllerDisconnectResponseSniffed_.reset();
  onListenerConnectResponseSniffed_.reset();
  onListenerDisconnectResponseSniffed_.reset();
  onGetTalkerStreamStateResponseSniffed_.reset();
  onGetListenerStreamStateResponseSniffed_.reset();
  onEntityAcquired_.reset();
  onEntityReleased_.reset();
  onEntityLocked_.reset();
  onEntityUnlocked_.reset();
  onConfigurationChanged_.reset();
  onAssociationIDChanged_.reset();
  onClockSourceChanged_.reset();
  onStreamInputFormatChanged_.reset();
  onStreamOutputFormatChanged_.reset();
  onStreamPortInputAudioMappingsChanged_.reset();
  onStreamPortOutputAudioMappingsChanged_.reset();
  onStreamPortInputAudioMappingsAdded_.reset();
  onStreamPortOutputAudioMappingsAdded_.reset();
  onStreamPortInputAudioMappingsRemoved_.reset();
  onStreamPortOutputAudioMappingsRemoved_.reset();
  onStreamInputInfoChanged_.reset();
  onStreamOutputInfoChanged_.reset();
  onStreamInputStarted_.reset();
  onStreamOutputStarted_.reset();
  onStreamInputStopped_.reset();
  onStreamOutputStopped_.reset();
  onMaxTransitTimeChanged_.reset();
  onEntityNameChanged_.reset();
  onEntityGroupNameChanged_.reset();
  onConfigurationNameChanged_.reset();
  onAudioUnitNameChanged_.reset();
  onStreamInputNameChanged_.reset();
  onStreamOutputNameChanged_.reset();
  onJackInputNameChanged_.reset();
  onJackOutputNameChanged_.reset();
  onAvbInterfaceNameChanged_.reset();
  onClockSourceNameChanged_.reset();
  onMemoryObjectNameChanged_.reset();
  onAudioClusterNameChanged_.reset();
  onControlNameChanged_.reset();
  onClockDomainNameChanged_.reset();
  onTimingNameChanged_.reset();
  onPtpInstanceNameChanged_.reset();
  onPtpPortNameChanged_.reset();
  onAudioUnitSamplingRateChanged_.reset();
  onVideoClusterSamplingRateChanged_.reset();
  onSensorClusterSamplingRateChanged_.reset();
  onEntityCountersChanged_.reset();
  onAvbInterfaceCountersChanged_.reset();
  onClockDomainCountersChanged_.reset();
  onStreamInputCountersChanged_.reset();
  onStreamOutputCountersChanged_.reset();
  onAvbInfoChanged_.reset();
  onAsPathChanged_.reset();
  onControlValuesChanged_.reset();
  onMemoryObjectLengthChanged_.reset();
  onOperationStatus_.reset();
  onSystemUniqueIDChanged_.reset();
  onMediaClockReferenceInfoChanged_.reset();
  onBindStream_.reset();
  onUnbindStream_.reset();
  onStreamInputInfoExChanged_.reset();
  onAecpRetry_.reset();
  onAecpTimeout_.reset();
  onAecpUnexpectedResponse_.reset();
  onAecpResponseTime_.reset();
  onAemAecpUnsolicitedReceived_.reset();
  onMvuAecpUnsolicitedReceived_.reset();
}

class LocalEntityOwner;

} // namespace AVDECCSwift

void AVDECCSwift_LocalEntityOwner_retain(AVDECCSwift::LocalEntityOwner* p) noexcept;
void AVDECCSwift_LocalEntityOwner_release(AVDECCSwift::LocalEntityOwner* p) noexcept;

namespace AVDECCSwift {


// When an async wrapper is invoked after the AggregateEntity has been
// closed (`agg_ == nullptr`), we still must fire the Swift-side callback
// exactly once — otherwise an awaiting `withCheckedThrowingContinuation`
// hangs forever. `fireFailureCallback` invokes `cb` with the supplied
// `status` and value-initialised defaults for every other argument
// (0 for arithmetic types, nullptr for pointers; Swift always inspects
// status before touching payload).
//
// Args... is deduced from the block type, so the helper covers every
// callback shape used by LocalEntityOwner without per-signature glue.
//
// Status code: la_avdecc's three relevant status enums (AemCommandStatus,
// ControlStatus, MvuCommandStatus) all use 999 for InternalError, so a
// single literal serves all three families. Static-asserted below.
template <typename... Args>
inline void fireFailureCallback(void (^cb)(uint16_t, Args...),
                                uint16_t status) noexcept {
  if (cb) cb(status, Args{}...);
}

inline constexpr uint16_t kInternalError = 999u;

static_assert(static_cast<uint16_t>(la::avdecc::entity::LocalEntity::AemCommandStatus::InternalError) == kInternalError,
              "AemCommandStatus::InternalError changed; revisit fireFailureCallback");
static_assert(static_cast<uint16_t>(la::avdecc::entity::LocalEntity::ControlStatus::InternalError) == kInternalError,
              "ControlStatus::InternalError changed; revisit fireFailureCallback");
static_assert(static_cast<uint16_t>(la::avdecc::entity::LocalEntity::MvuCommandStatus::InternalError) == kInternalError,
              "MvuCommandStatus::InternalError changed; revisit fireFailureCallback");

/// Bridge a Swift-bound `Block<>` into the la_avdecc handler signature.
/// Every la_avdecc AECP/MVU/AA handler starts with
/// `(controller::Interface const*, UniqueIdentifier, StatusType, ...)`
/// followed by per-command trailing args. This template:
///   1. discards the first two prefix args,
///   2. casts the typed `StatusType` enum to `uint16_t`,
///   3. forwards `(blk, status, trailing...)` into a per-command projection
///      lambda which adapts the trailing args to the Swift-block argument
///      shape and invokes the block.
///
/// `Status` is one of `LocalEntity::{AemCommand,Control,MvuCommand}Status`.
/// The `Block<>` is moved into the lambda capture (so Block_copy stays
/// balanced); the projection receives it by const reference.
template <typename Status, typename BlockT, typename Project>
auto avdeccHandler(BlockT blk, Project proj) noexcept {
  return [blk = std::move(blk), proj = std::move(proj)](
      la::avdecc::entity::controller::Interface const* const,
      la::avdecc::UniqueIdentifier const,
      Status const status,
      auto&&... rest) noexcept {
    if (blk) proj(blk, static_cast<uint16_t>(status),
                  std::forward<decltype(rest)>(rest)...);
  };
}

/// Owns an la_avdecc AggregateEntity (a LocalEntity that also implements
/// controller::Interface). Necessary because:
///   - AggregateEntity::create takes std::unique_ptr-with-deleter, a
///     std::map InterfacesInformation, and a controller::Delegate the Swift
///     importer cannot reach.
///   - controller::Interface methods take `std::function<...>` AECP handlers
///     Swift cannot construct.
/// Each AECP handler is wrapped here as a clang-block-taking method whose
/// implementation forwards to the matching std::function. PDU/descriptor
/// payloads pass as `void const*` (Swift sees as UnsafeRawPointer).
class SWIFT_SHARED_REFERENCE(AVDECCSwift_LocalEntityOwner_retain,
                             AVDECCSwift_LocalEntityOwner_release)
    LocalEntityOwner final
    : public IntrusiveReferenceCounted<LocalEntityOwner> {
public:
  /// Build a controller-only AggregateEntity owning a single network
  /// interface (the one represented by `piOwner`). Convenience over the
  /// full la_avdecc CommonInformation/InterfacesInformation surface so
  /// Swift callers don't have to construct std::map themselves. mac is
  /// 6 bytes. On failure, `outErr` is filled per the contract on
  /// `invokeCapturingException`. registerLocalEntity may throw a
  /// ProtocolInterface::Exception (DuplicateLocalEntityID etc.) which
  /// surfaces with a typed PI code; AggregateEntity::create may throw
  /// la_avdecc base Exceptions for entity-model validation issues.
  SWIFT_RETURNS_RETAINED
  static LocalEntityOwner* create(ProtocolInterfaceOwner* piOwner,
                                  uint64_t entityID,
                                  uint8_t const mac[6],
                                  CapturedException& outErr) noexcept {
    return invokeCapturingException(outErr, [&]() -> LocalEntityOwner* {
      if (!piOwner || !piOwner->get()) return nullptr;

      la::avdecc::entity::Entity::CommonInformation common{};
      common.entityID = la::avdecc::UniqueIdentifier(entityID);
      common.controllerCapabilities =
          la::avdecc::entity::ControllerCapabilities{
              la::avdecc::entity::ControllerCapability::Implemented};

      la::avdecc::entity::Entity::InterfaceInformation iface{};
      iface.macAddress = _macFromBytes(mac);
      // Temporary so the static constexpr GlobalAvbInterfaceIndex isn't
      // ODR-used in a way that needs its out-of-class definition.
      auto const idx = la::avdecc::entity::model::AvbInterfaceIndex{
          la::avdecc::entity::Entity::GlobalAvbInterfaceIndex};
      la::avdecc::entity::Entity::InterfacesInformation ifaces{{idx, iface}};

      auto agg = la::avdecc::entity::AggregateEntity::create(
          piOwner->get(), common, ifaces, /*entityModelTree*/ nullptr,
          /*controllerDelegate*/ nullptr);
      if (!agg) return nullptr;
      return new LocalEntityOwner(piOwner, std::move(agg));
    });
  }

  /// Idempotent. Drops the AggregateEntity (which unregisters from PI).
  /// Detaches the controller delegate first so la_avdecc cannot deliver a
  /// notification while we are tearing down.
  void close() noexcept {
    if (agg_ && delegateAttached_) {
      agg_->setControllerDelegate(nullptr);
      delegateAttached_ = false;
    }
    delegate_.clearAllSlots();
    agg_.reset();
  }

  la::avdecc::entity::AggregateEntity* get() const noexcept { return agg_.get(); }

  // ---- Controller delegate wiring -----------------------------------------
  // Mirror of the PI observer pattern: Swift sets blocks via the per-event
  // setOnX methods, then calls `attachDelegate()` to subscribe la_avdecc.
  // `detachDelegate()` unsubscribes; `clearDelegateBlocks()` resets every
  // slot. All three are safe to call on a closed owner.
  void attachDelegate() noexcept {
    if (agg_ && !delegateAttached_) {
      agg_->setControllerDelegate(&delegate_);
      delegateAttached_ = true;
    }
  }
  void detachDelegate() noexcept {
    if (agg_ && delegateAttached_) {
      agg_->setControllerDelegate(nullptr);
      delegateAttached_ = false;
    }
  }
  void clearDelegateBlocks() noexcept { delegate_.clearAllSlots(); }

  // Per-slot setters. Each takes a Swift-side `void (^)(...)` block and
  // routes it to the matching slot via BlockControllerDelegate::setSlot.
  // Block argument shapes mirror the C++ slot shapes; fields that la_avdecc
  // surfaces as value types (UniqueIdentifier, EnumBitfield, …) are flat
  // uint64/uint32/uint16 here so Swift can consume them without C++ interop
  // on the block boundary.

  void setOnTransportError(void (^cb)()) noexcept {
    using BT = void (^)();
    delegate_.setSlot(&BlockControllerDelegate::onTransportError_,
                      Block<void>((BT)cb));
  }
  void setOnEntityOnline(
      void (^cb)(uint64_t, la::avdecc::entity::Entity const*)) noexcept {
    using BT = void (^)(uint64_t, la::avdecc::entity::Entity const*);
    delegate_.setSlot(&BlockControllerDelegate::onEntityOnline_,
                      Block<void, uint64_t,
                            la::avdecc::entity::Entity const*>((BT)cb));
  }
  void setOnEntityUpdate(
      void (^cb)(uint64_t, la::avdecc::entity::Entity const*)) noexcept {
    using BT = void (^)(uint64_t, la::avdecc::entity::Entity const*);
    delegate_.setSlot(&BlockControllerDelegate::onEntityUpdate_,
                      Block<void, uint64_t,
                            la::avdecc::entity::Entity const*>((BT)cb));
  }
  void setOnEntityOffline(void (^cb)(uint64_t)) noexcept {
    delegate_.setSlot(&BlockControllerDelegate::onEntityOffline_,
                      Block<void, uint64_t>(cb));
  }
  void setOnEntityIdentifyNotification(void (^cb)(uint64_t)) noexcept {
    delegate_.setSlot(&BlockControllerDelegate::onEntityIdentifyNotification_,
                      Block<void, uint64_t>(cb));
  }
  void setOnDeregisteredFromUnsolicitedNotifications(void (^cb)(uint64_t)) noexcept {
    delegate_.setSlot(
        &BlockControllerDelegate::onDeregisteredFromUnsolicitedNotifications_,
        Block<void, uint64_t>(cb));
  }

  // Sniffed ACMP — single shape, six setters.
  void setOnControllerConnectResponseSniffed(
      void (^cb)(uint64_t, uint16_t, uint64_t, uint16_t,
                 uint16_t, uint16_t, uint16_t)) noexcept {
    delegate_.setSlot(&BlockControllerDelegate::onControllerConnectResponseSniffed_,
                      BlockControllerDelegate::AcmpSniffedBlock(cb));
  }
  void setOnControllerDisconnectResponseSniffed(
      void (^cb)(uint64_t, uint16_t, uint64_t, uint16_t,
                 uint16_t, uint16_t, uint16_t)) noexcept {
    delegate_.setSlot(&BlockControllerDelegate::onControllerDisconnectResponseSniffed_,
                      BlockControllerDelegate::AcmpSniffedBlock(cb));
  }
  void setOnListenerConnectResponseSniffed(
      void (^cb)(uint64_t, uint16_t, uint64_t, uint16_t,
                 uint16_t, uint16_t, uint16_t)) noexcept {
    delegate_.setSlot(&BlockControllerDelegate::onListenerConnectResponseSniffed_,
                      BlockControllerDelegate::AcmpSniffedBlock(cb));
  }
  void setOnListenerDisconnectResponseSniffed(
      void (^cb)(uint64_t, uint16_t, uint64_t, uint16_t,
                 uint16_t, uint16_t, uint16_t)) noexcept {
    delegate_.setSlot(&BlockControllerDelegate::onListenerDisconnectResponseSniffed_,
                      BlockControllerDelegate::AcmpSniffedBlock(cb));
  }
  void setOnGetTalkerStreamStateResponseSniffed(
      void (^cb)(uint64_t, uint16_t, uint64_t, uint16_t,
                 uint16_t, uint16_t, uint16_t)) noexcept {
    delegate_.setSlot(&BlockControllerDelegate::onGetTalkerStreamStateResponseSniffed_,
                      BlockControllerDelegate::AcmpSniffedBlock(cb));
  }
  void setOnGetListenerStreamStateResponseSniffed(
      void (^cb)(uint64_t, uint16_t, uint64_t, uint16_t,
                 uint16_t, uint16_t, uint16_t)) noexcept {
    delegate_.setSlot(&BlockControllerDelegate::onGetListenerStreamStateResponseSniffed_,
                      BlockControllerDelegate::AcmpSniffedBlock(cb));
  }

  // Acquire / release / lock / unlock — single shape.
  void setOnEntityAcquired(
      void (^cb)(uint64_t, uint64_t, uint16_t, uint16_t)) noexcept {
    delegate_.setSlot(&BlockControllerDelegate::onEntityAcquired_,
                      BlockControllerDelegate::AcquireBlock(cb));
  }
  void setOnEntityReleased(
      void (^cb)(uint64_t, uint64_t, uint16_t, uint16_t)) noexcept {
    delegate_.setSlot(&BlockControllerDelegate::onEntityReleased_,
                      BlockControllerDelegate::AcquireBlock(cb));
  }
  void setOnEntityLocked(
      void (^cb)(uint64_t, uint64_t, uint16_t, uint16_t)) noexcept {
    delegate_.setSlot(&BlockControllerDelegate::onEntityLocked_,
                      BlockControllerDelegate::AcquireBlock(cb));
  }
  void setOnEntityUnlocked(
      void (^cb)(uint64_t, uint64_t, uint16_t, uint16_t)) noexcept {
    delegate_.setSlot(&BlockControllerDelegate::onEntityUnlocked_,
                      BlockControllerDelegate::AcquireBlock(cb));
  }

  void setOnConfigurationChanged(void (^cb)(uint64_t, uint16_t)) noexcept {
    delegate_.setSlot(&BlockControllerDelegate::onConfigurationChanged_,
                      Block<void, uint64_t, uint16_t>(cb));
  }
  void setOnAssociationIDChanged(void (^cb)(uint64_t, uint64_t)) noexcept {
    delegate_.setSlot(&BlockControllerDelegate::onAssociationIDChanged_,
                      Block<void, uint64_t, uint64_t>(cb));
  }
  void setOnClockSourceChanged(
      void (^cb)(uint64_t, uint16_t, uint16_t)) noexcept {
    delegate_.setSlot(&BlockControllerDelegate::onClockSourceChanged_,
                      Block<void, uint64_t, uint16_t, uint16_t>(cb));
  }

  // Stream format / mappings / info / start-stop.
  void setOnStreamInputFormatChanged(
      void (^cb)(uint64_t, uint16_t, uint64_t)) noexcept {
    delegate_.setSlot(&BlockControllerDelegate::onStreamInputFormatChanged_,
                      BlockControllerDelegate::StreamFormatBlock(cb));
  }
  void setOnStreamOutputFormatChanged(
      void (^cb)(uint64_t, uint16_t, uint64_t)) noexcept {
    delegate_.setSlot(&BlockControllerDelegate::onStreamOutputFormatChanged_,
                      BlockControllerDelegate::StreamFormatBlock(cb));
  }
  void setOnStreamPortInputAudioMappingsChanged(
      void (^cb)(uint64_t, uint16_t, uint16_t, uint16_t,
                 la::avdecc::entity::model::AudioMapping const*, size_t)) noexcept {
    using BT = void (^)(uint64_t, uint16_t, uint16_t, uint16_t,
                        la::avdecc::entity::model::AudioMapping const*, size_t);
    delegate_.setSlot(&BlockControllerDelegate::onStreamPortInputAudioMappingsChanged_,
                      BlockControllerDelegate::StreamMappingsChangedBlock((BT)cb));
  }
  void setOnStreamPortOutputAudioMappingsChanged(
      void (^cb)(uint64_t, uint16_t, uint16_t, uint16_t,
                 la::avdecc::entity::model::AudioMapping const*, size_t)) noexcept {
    using BT = void (^)(uint64_t, uint16_t, uint16_t, uint16_t,
                        la::avdecc::entity::model::AudioMapping const*, size_t);
    delegate_.setSlot(&BlockControllerDelegate::onStreamPortOutputAudioMappingsChanged_,
                      BlockControllerDelegate::StreamMappingsChangedBlock((BT)cb));
  }
  void setOnStreamPortInputAudioMappingsAdded(
      void (^cb)(uint64_t, uint16_t,
                 la::avdecc::entity::model::AudioMapping const*, size_t)) noexcept {
    using BT = void (^)(uint64_t, uint16_t,
                        la::avdecc::entity::model::AudioMapping const*, size_t);
    delegate_.setSlot(&BlockControllerDelegate::onStreamPortInputAudioMappingsAdded_,
                      BlockControllerDelegate::StreamMappingsBlock((BT)cb));
  }
  void setOnStreamPortOutputAudioMappingsAdded(
      void (^cb)(uint64_t, uint16_t,
                 la::avdecc::entity::model::AudioMapping const*, size_t)) noexcept {
    using BT = void (^)(uint64_t, uint16_t,
                        la::avdecc::entity::model::AudioMapping const*, size_t);
    delegate_.setSlot(&BlockControllerDelegate::onStreamPortOutputAudioMappingsAdded_,
                      BlockControllerDelegate::StreamMappingsBlock((BT)cb));
  }
  void setOnStreamPortInputAudioMappingsRemoved(
      void (^cb)(uint64_t, uint16_t,
                 la::avdecc::entity::model::AudioMapping const*, size_t)) noexcept {
    using BT = void (^)(uint64_t, uint16_t,
                        la::avdecc::entity::model::AudioMapping const*, size_t);
    delegate_.setSlot(&BlockControllerDelegate::onStreamPortInputAudioMappingsRemoved_,
                      BlockControllerDelegate::StreamMappingsBlock((BT)cb));
  }
  void setOnStreamPortOutputAudioMappingsRemoved(
      void (^cb)(uint64_t, uint16_t,
                 la::avdecc::entity::model::AudioMapping const*, size_t)) noexcept {
    using BT = void (^)(uint64_t, uint16_t,
                        la::avdecc::entity::model::AudioMapping const*, size_t);
    delegate_.setSlot(&BlockControllerDelegate::onStreamPortOutputAudioMappingsRemoved_,
                      BlockControllerDelegate::StreamMappingsBlock((BT)cb));
  }
  void setOnStreamInputInfoChanged(
      void (^cb)(uint64_t, uint16_t,
                 la::avdecc::entity::model::StreamInfo const*, bool)) noexcept {
    using BT = void (^)(uint64_t, uint16_t,
                        la::avdecc::entity::model::StreamInfo const*, bool);
    delegate_.setSlot(&BlockControllerDelegate::onStreamInputInfoChanged_,
                      BlockControllerDelegate::StreamInfoChangedBlock((BT)cb));
  }
  void setOnStreamOutputInfoChanged(
      void (^cb)(uint64_t, uint16_t,
                 la::avdecc::entity::model::StreamInfo const*, bool)) noexcept {
    using BT = void (^)(uint64_t, uint16_t,
                        la::avdecc::entity::model::StreamInfo const*, bool);
    delegate_.setSlot(&BlockControllerDelegate::onStreamOutputInfoChanged_,
                      BlockControllerDelegate::StreamInfoChangedBlock((BT)cb));
  }
  void setOnStreamInputStarted(void (^cb)(uint64_t, uint16_t)) noexcept {
    delegate_.setSlot(&BlockControllerDelegate::onStreamInputStarted_,
                      BlockControllerDelegate::StreamIdxBlock(cb));
  }
  void setOnStreamOutputStarted(void (^cb)(uint64_t, uint16_t)) noexcept {
    delegate_.setSlot(&BlockControllerDelegate::onStreamOutputStarted_,
                      BlockControllerDelegate::StreamIdxBlock(cb));
  }
  void setOnStreamInputStopped(void (^cb)(uint64_t, uint16_t)) noexcept {
    delegate_.setSlot(&BlockControllerDelegate::onStreamInputStopped_,
                      BlockControllerDelegate::StreamIdxBlock(cb));
  }
  void setOnStreamOutputStopped(void (^cb)(uint64_t, uint16_t)) noexcept {
    delegate_.setSlot(&BlockControllerDelegate::onStreamOutputStopped_,
                      BlockControllerDelegate::StreamIdxBlock(cb));
  }
  void setOnMaxTransitTimeChanged(
      void (^cb)(uint64_t, uint16_t, uint64_t)) noexcept {
    delegate_.setSlot(&BlockControllerDelegate::onMaxTransitTimeChanged_,
                      Block<void, uint64_t, uint16_t, uint64_t>(cb));
  }

  // Names — entity / config / descriptor flavours.
  void setOnEntityNameChanged(
      void (^cb)(uint64_t,
                 la::avdecc::entity::model::AvdeccFixedString const*)) noexcept {
    using BT = void (^)(uint64_t,
                        la::avdecc::entity::model::AvdeccFixedString const*);
    delegate_.setSlot(&BlockControllerDelegate::onEntityNameChanged_,
                      BlockControllerDelegate::EntityNameBlock((BT)cb));
  }
  void setOnEntityGroupNameChanged(
      void (^cb)(uint64_t,
                 la::avdecc::entity::model::AvdeccFixedString const*)) noexcept {
    using BT = void (^)(uint64_t,
                        la::avdecc::entity::model::AvdeccFixedString const*);
    delegate_.setSlot(&BlockControllerDelegate::onEntityGroupNameChanged_,
                      BlockControllerDelegate::EntityNameBlock((BT)cb));
  }
  void setOnConfigurationNameChanged(
      void (^cb)(uint64_t, uint16_t,
                 la::avdecc::entity::model::AvdeccFixedString const*)) noexcept {
    using BT = void (^)(uint64_t, uint16_t,
                        la::avdecc::entity::model::AvdeccFixedString const*);
    delegate_.setSlot(&BlockControllerDelegate::onConfigurationNameChanged_,
                      BlockControllerDelegate::ConfigNameBlock((BT)cb));
  }
  // Descriptor-name shape: 14 setters, all DescNameBlock.
  void setOnAudioUnitNameChanged(
      void (^cb)(uint64_t, uint16_t, uint16_t,
                 la::avdecc::entity::model::AvdeccFixedString const*)) noexcept {
    using BT = void (^)(uint64_t, uint16_t, uint16_t,
                        la::avdecc::entity::model::AvdeccFixedString const*);
    delegate_.setSlot(&BlockControllerDelegate::onAudioUnitNameChanged_,
                      BlockControllerDelegate::DescNameBlock((BT)cb));
  }
  void setOnStreamInputNameChanged(
      void (^cb)(uint64_t, uint16_t, uint16_t,
                 la::avdecc::entity::model::AvdeccFixedString const*)) noexcept {
    using BT = void (^)(uint64_t, uint16_t, uint16_t,
                        la::avdecc::entity::model::AvdeccFixedString const*);
    delegate_.setSlot(&BlockControllerDelegate::onStreamInputNameChanged_,
                      BlockControllerDelegate::DescNameBlock((BT)cb));
  }
  void setOnStreamOutputNameChanged(
      void (^cb)(uint64_t, uint16_t, uint16_t,
                 la::avdecc::entity::model::AvdeccFixedString const*)) noexcept {
    using BT = void (^)(uint64_t, uint16_t, uint16_t,
                        la::avdecc::entity::model::AvdeccFixedString const*);
    delegate_.setSlot(&BlockControllerDelegate::onStreamOutputNameChanged_,
                      BlockControllerDelegate::DescNameBlock((BT)cb));
  }
  void setOnJackInputNameChanged(
      void (^cb)(uint64_t, uint16_t, uint16_t,
                 la::avdecc::entity::model::AvdeccFixedString const*)) noexcept {
    using BT = void (^)(uint64_t, uint16_t, uint16_t,
                        la::avdecc::entity::model::AvdeccFixedString const*);
    delegate_.setSlot(&BlockControllerDelegate::onJackInputNameChanged_,
                      BlockControllerDelegate::DescNameBlock((BT)cb));
  }
  void setOnJackOutputNameChanged(
      void (^cb)(uint64_t, uint16_t, uint16_t,
                 la::avdecc::entity::model::AvdeccFixedString const*)) noexcept {
    using BT = void (^)(uint64_t, uint16_t, uint16_t,
                        la::avdecc::entity::model::AvdeccFixedString const*);
    delegate_.setSlot(&BlockControllerDelegate::onJackOutputNameChanged_,
                      BlockControllerDelegate::DescNameBlock((BT)cb));
  }
  void setOnAvbInterfaceNameChanged(
      void (^cb)(uint64_t, uint16_t, uint16_t,
                 la::avdecc::entity::model::AvdeccFixedString const*)) noexcept {
    using BT = void (^)(uint64_t, uint16_t, uint16_t,
                        la::avdecc::entity::model::AvdeccFixedString const*);
    delegate_.setSlot(&BlockControllerDelegate::onAvbInterfaceNameChanged_,
                      BlockControllerDelegate::DescNameBlock((BT)cb));
  }
  void setOnClockSourceNameChanged(
      void (^cb)(uint64_t, uint16_t, uint16_t,
                 la::avdecc::entity::model::AvdeccFixedString const*)) noexcept {
    using BT = void (^)(uint64_t, uint16_t, uint16_t,
                        la::avdecc::entity::model::AvdeccFixedString const*);
    delegate_.setSlot(&BlockControllerDelegate::onClockSourceNameChanged_,
                      BlockControllerDelegate::DescNameBlock((BT)cb));
  }
  void setOnMemoryObjectNameChanged(
      void (^cb)(uint64_t, uint16_t, uint16_t,
                 la::avdecc::entity::model::AvdeccFixedString const*)) noexcept {
    using BT = void (^)(uint64_t, uint16_t, uint16_t,
                        la::avdecc::entity::model::AvdeccFixedString const*);
    delegate_.setSlot(&BlockControllerDelegate::onMemoryObjectNameChanged_,
                      BlockControllerDelegate::DescNameBlock((BT)cb));
  }
  void setOnAudioClusterNameChanged(
      void (^cb)(uint64_t, uint16_t, uint16_t,
                 la::avdecc::entity::model::AvdeccFixedString const*)) noexcept {
    using BT = void (^)(uint64_t, uint16_t, uint16_t,
                        la::avdecc::entity::model::AvdeccFixedString const*);
    delegate_.setSlot(&BlockControllerDelegate::onAudioClusterNameChanged_,
                      BlockControllerDelegate::DescNameBlock((BT)cb));
  }
  void setOnControlNameChanged(
      void (^cb)(uint64_t, uint16_t, uint16_t,
                 la::avdecc::entity::model::AvdeccFixedString const*)) noexcept {
    using BT = void (^)(uint64_t, uint16_t, uint16_t,
                        la::avdecc::entity::model::AvdeccFixedString const*);
    delegate_.setSlot(&BlockControllerDelegate::onControlNameChanged_,
                      BlockControllerDelegate::DescNameBlock((BT)cb));
  }
  void setOnClockDomainNameChanged(
      void (^cb)(uint64_t, uint16_t, uint16_t,
                 la::avdecc::entity::model::AvdeccFixedString const*)) noexcept {
    using BT = void (^)(uint64_t, uint16_t, uint16_t,
                        la::avdecc::entity::model::AvdeccFixedString const*);
    delegate_.setSlot(&BlockControllerDelegate::onClockDomainNameChanged_,
                      BlockControllerDelegate::DescNameBlock((BT)cb));
  }
  void setOnTimingNameChanged(
      void (^cb)(uint64_t, uint16_t, uint16_t,
                 la::avdecc::entity::model::AvdeccFixedString const*)) noexcept {
    using BT = void (^)(uint64_t, uint16_t, uint16_t,
                        la::avdecc::entity::model::AvdeccFixedString const*);
    delegate_.setSlot(&BlockControllerDelegate::onTimingNameChanged_,
                      BlockControllerDelegate::DescNameBlock((BT)cb));
  }
  void setOnPtpInstanceNameChanged(
      void (^cb)(uint64_t, uint16_t, uint16_t,
                 la::avdecc::entity::model::AvdeccFixedString const*)) noexcept {
    using BT = void (^)(uint64_t, uint16_t, uint16_t,
                        la::avdecc::entity::model::AvdeccFixedString const*);
    delegate_.setSlot(&BlockControllerDelegate::onPtpInstanceNameChanged_,
                      BlockControllerDelegate::DescNameBlock((BT)cb));
  }
  void setOnPtpPortNameChanged(
      void (^cb)(uint64_t, uint16_t, uint16_t,
                 la::avdecc::entity::model::AvdeccFixedString const*)) noexcept {
    using BT = void (^)(uint64_t, uint16_t, uint16_t,
                        la::avdecc::entity::model::AvdeccFixedString const*);
    delegate_.setSlot(&BlockControllerDelegate::onPtpPortNameChanged_,
                      BlockControllerDelegate::DescNameBlock((BT)cb));
  }

  void setOnAudioUnitSamplingRateChanged(
      void (^cb)(uint64_t, uint16_t, uint32_t)) noexcept {
    delegate_.setSlot(&BlockControllerDelegate::onAudioUnitSamplingRateChanged_,
                      BlockControllerDelegate::SamplingRateBlock(cb));
  }
  void setOnVideoClusterSamplingRateChanged(
      void (^cb)(uint64_t, uint16_t, uint32_t)) noexcept {
    delegate_.setSlot(&BlockControllerDelegate::onVideoClusterSamplingRateChanged_,
                      BlockControllerDelegate::SamplingRateBlock(cb));
  }
  void setOnSensorClusterSamplingRateChanged(
      void (^cb)(uint64_t, uint16_t, uint32_t)) noexcept {
    delegate_.setSlot(&BlockControllerDelegate::onSensorClusterSamplingRateChanged_,
                      BlockControllerDelegate::SamplingRateBlock(cb));
  }

  void setOnEntityCountersChanged(
      void (^cb)(uint64_t, uint32_t, uint32_t const*)) noexcept {
    delegate_.setSlot(&BlockControllerDelegate::onEntityCountersChanged_,
                      BlockControllerDelegate::EntityCountersBlock(cb));
  }
  void setOnAvbInterfaceCountersChanged(
      void (^cb)(uint64_t, uint16_t, uint32_t, uint32_t const*)) noexcept {
    delegate_.setSlot(&BlockControllerDelegate::onAvbInterfaceCountersChanged_,
                      BlockControllerDelegate::DescCountersBlock(cb));
  }
  void setOnClockDomainCountersChanged(
      void (^cb)(uint64_t, uint16_t, uint32_t, uint32_t const*)) noexcept {
    delegate_.setSlot(&BlockControllerDelegate::onClockDomainCountersChanged_,
                      BlockControllerDelegate::DescCountersBlock(cb));
  }
  void setOnStreamInputCountersChanged(
      void (^cb)(uint64_t, uint16_t, uint32_t, uint32_t const*)) noexcept {
    delegate_.setSlot(&BlockControllerDelegate::onStreamInputCountersChanged_,
                      BlockControllerDelegate::DescCountersBlock(cb));
  }
  void setOnStreamOutputCountersChanged(
      void (^cb)(uint64_t, uint16_t, uint32_t, uint32_t const*)) noexcept {
    delegate_.setSlot(&BlockControllerDelegate::onStreamOutputCountersChanged_,
                      BlockControllerDelegate::DescCountersBlock(cb));
  }

  void setOnAvbInfoChanged(
      void (^cb)(uint64_t, uint16_t,
                 la::avdecc::entity::model::AvbInfo const*)) noexcept {
    using BT = void (^)(uint64_t, uint16_t,
                        la::avdecc::entity::model::AvbInfo const*);
    delegate_.setSlot(&BlockControllerDelegate::onAvbInfoChanged_,
                      Block<void, uint64_t, uint16_t,
                            la::avdecc::entity::model::AvbInfo const*>((BT)cb));
  }
  void setOnAsPathChanged(
      void (^cb)(uint64_t, uint16_t,
                 la::avdecc::entity::model::AsPath const*)) noexcept {
    using BT = void (^)(uint64_t, uint16_t,
                        la::avdecc::entity::model::AsPath const*);
    delegate_.setSlot(&BlockControllerDelegate::onAsPathChanged_,
                      Block<void, uint64_t, uint16_t,
                            la::avdecc::entity::model::AsPath const*>((BT)cb));
  }
  void setOnControlValuesChanged(
      void (^cb)(uint64_t, uint16_t, uint8_t const*, size_t)) noexcept {
    delegate_.setSlot(&BlockControllerDelegate::onControlValuesChanged_,
                      Block<void, uint64_t, uint16_t,
                            uint8_t const*, size_t>(cb));
  }

  void setOnMemoryObjectLengthChanged(
      void (^cb)(uint64_t, uint16_t, uint16_t, uint64_t)) noexcept {
    delegate_.setSlot(&BlockControllerDelegate::onMemoryObjectLengthChanged_,
                      Block<void, uint64_t, uint16_t, uint16_t, uint64_t>(cb));
  }
  void setOnOperationStatus(
      void (^cb)(uint64_t, uint16_t, uint16_t, uint16_t, uint16_t)) noexcept {
    delegate_.setSlot(
        &BlockControllerDelegate::onOperationStatus_,
        Block<void, uint64_t, uint16_t, uint16_t, uint16_t, uint16_t>(cb));
  }

  // Milan MVU
  void setOnSystemUniqueIDChanged(
      void (^cb)(uint64_t, uint64_t,
                 la::avdecc::entity::model::AvdeccFixedString const*)) noexcept {
    using BT = void (^)(uint64_t, uint64_t,
                        la::avdecc::entity::model::AvdeccFixedString const*);
    delegate_.setSlot(&BlockControllerDelegate::onSystemUniqueIDChanged_,
                      Block<void, uint64_t, uint64_t,
                            la::avdecc::entity::model::AvdeccFixedString const*>((BT)cb));
  }
  void setOnMediaClockReferenceInfoChanged(
      void (^cb)(uint64_t, uint16_t, uint8_t, bool, uint8_t, bool,
                 la::avdecc::entity::model::AvdeccFixedString const*)) noexcept {
    using BT = void (^)(uint64_t, uint16_t, uint8_t, bool, uint8_t, bool,
                        la::avdecc::entity::model::AvdeccFixedString const*);
    delegate_.setSlot(
        &BlockControllerDelegate::onMediaClockReferenceInfoChanged_,
        Block<void, uint64_t, uint16_t, uint8_t, bool, uint8_t, bool,
              la::avdecc::entity::model::AvdeccFixedString const*>((BT)cb));
  }
  void setOnBindStream(
      void (^cb)(uint64_t, uint16_t, uint64_t, uint16_t, uint16_t)) noexcept {
    delegate_.setSlot(
        &BlockControllerDelegate::onBindStream_,
        Block<void, uint64_t, uint16_t, uint64_t, uint16_t, uint16_t>(cb));
  }
  void setOnUnbindStream(void (^cb)(uint64_t, uint16_t)) noexcept {
    delegate_.setSlot(&BlockControllerDelegate::onUnbindStream_,
                      BlockControllerDelegate::StreamIdxBlock(cb));
  }
  void setOnStreamInputInfoExChanged(
      void (^cb)(uint64_t, uint16_t,
                 la::avdecc::entity::model::StreamInputInfoEx const*)) noexcept {
    using BT = void (^)(uint64_t, uint16_t,
                        la::avdecc::entity::model::StreamInputInfoEx const*);
    delegate_.setSlot(
        &BlockControllerDelegate::onStreamInputInfoExChanged_,
        Block<void, uint64_t, uint16_t,
              la::avdecc::entity::model::StreamInputInfoEx const*>((BT)cb));
  }

  // Statistics
  void setOnAecpRetry(void (^cb)(uint64_t)) noexcept {
    delegate_.setSlot(&BlockControllerDelegate::onAecpRetry_,
                      Block<void, uint64_t>(cb));
  }
  void setOnAecpTimeout(void (^cb)(uint64_t)) noexcept {
    delegate_.setSlot(&BlockControllerDelegate::onAecpTimeout_,
                      Block<void, uint64_t>(cb));
  }
  void setOnAecpUnexpectedResponse(void (^cb)(uint64_t)) noexcept {
    delegate_.setSlot(&BlockControllerDelegate::onAecpUnexpectedResponse_,
                      Block<void, uint64_t>(cb));
  }
  void setOnAecpResponseTime(void (^cb)(uint64_t, uint64_t)) noexcept {
    delegate_.setSlot(&BlockControllerDelegate::onAecpResponseTime_,
                      Block<void, uint64_t, uint64_t>(cb));
  }
  void setOnAemAecpUnsolicitedReceived(void (^cb)(uint64_t, uint16_t)) noexcept {
    delegate_.setSlot(&BlockControllerDelegate::onAemAecpUnsolicitedReceived_,
                      Block<void, uint64_t, uint16_t>(cb));
  }
  void setOnMvuAecpUnsolicitedReceived(void (^cb)(uint64_t, uint16_t)) noexcept {
    delegate_.setSlot(&BlockControllerDelegate::onMvuAecpUnsolicitedReceived_,
                      Block<void, uint64_t, uint16_t>(cb));
  }

  // Synchronous (non-AEM) controls on the LocalEntity. The
  // `std::optional<AvbInterfaceIndex>` parameter is folded into a
  // `hasInterfaceIndex` bool + raw uint16 because Swift's importer
  // doesn't construct std::optional cleanly.
  bool enableEntityAdvertising(uint32_t availableDuration,
                               bool hasInterfaceIndex,
                               uint16_t interfaceIndex) noexcept {
    if (!agg_) return false;
    auto idx = hasInterfaceIndex
        ? std::optional<la::avdecc::entity::model::AvbInterfaceIndex>{
              la::avdecc::entity::model::AvbInterfaceIndex(interfaceIndex)}
        : std::nullopt;
    return agg_->enableEntityAdvertising(availableDuration, idx);
  }
  void disableEntityAdvertising(bool hasInterfaceIndex,
                                uint16_t interfaceIndex) noexcept {
    if (!agg_) return;
    auto idx = hasInterfaceIndex
        ? std::optional<la::avdecc::entity::model::AvbInterfaceIndex>{
              la::avdecc::entity::model::AvbInterfaceIndex(interfaceIndex)}
        : std::nullopt;
    agg_->disableEntityAdvertising(idx);
  }
  bool discoverRemoteEntities() const noexcept {
    return agg_ ? agg_->discoverRemoteEntities() : false;
  }
  bool discoverRemoteEntity(uint64_t entityID) const noexcept {
    return agg_ ? agg_->discoverRemoteEntity(la::avdecc::UniqueIdentifier(entityID)) : false;
  }
  void setAutomaticDiscoveryDelay(uint32_t milliseconds) noexcept {
    if (!agg_) return;
    agg_->setAutomaticDiscoveryDelay(std::chrono::milliseconds(milliseconds));
  }

  /// ACQUIRE / RELEASE / LOCK / UNLOCK Entity all share the la_avdecc
  /// handler shape `(status, holdingEntity, descriptorType, descriptorIndex)`
  /// and surface to Swift as `(status, holdingEntity_uint64)`. ACQUIRE is
  /// the odd one out — extra `isPersistent` flag — so it has its own
  /// public method below; the other three select the la_avdecc method via
  /// `lockImpl<>`. Both share `aclHandler()` for the response projection.
private:
  // Discards trailing (DescriptorType, DescriptorIndex), surfaces the
  // holding UniqueIdentifier as raw uint64.
  static auto aclHandler(Block<void, uint16_t, uint64_t> blk) noexcept {
    return avdeccHandler<la::avdecc::entity::LocalEntity::AemCommandStatus>(
        std::move(blk),
        [](auto const& blk, uint16_t status,
           la::avdecc::UniqueIdentifier const holding,
           la::avdecc::entity::model::DescriptorType const,
           la::avdecc::entity::model::DescriptorIndex const) noexcept {
          blk(status, holding.getValue());
        });
  }

  template <auto Method>
  void lockImpl(uint64_t targetEntityID,
                uint16_t descriptorType, uint16_t descriptorIndex,
                void (^cb)(uint16_t /*status*/, uint64_t /*holdingEntity*/)) const noexcept {
    if (!agg_) { fireFailureCallback(cb, kInternalError); return; }
    (agg_.get()->*Method)(
        la::avdecc::UniqueIdentifier(targetEntityID),
        static_cast<la::avdecc::entity::model::DescriptorType>(descriptorType),
        descriptorIndex, aclHandler(Block<void, uint16_t, uint64_t>(cb)));
  }

  // Generic descriptor read taking (configurationIndex, descriptorIndex).
  // Covers 21 of the 24 descriptor reads in la_avdecc — the la_avdecc
  // handler always trails with (ConfigurationIndex, IndexT, DescT const&)
  // and we surface (status, descIdx, &desc) to Swift. Used both directly
  // by the standalone reads and by the AVDECC_SWIFT_DESC_READ_HELPER
  // macro which differs only by the user-facing method name.
  template <auto Method, typename IndexT, typename DescT>
  void readDescImpl(uint64_t targetEntityID, uint16_t configurationIndex,
                    uint16_t descriptorIndex,
                    void (^cb)(uint16_t, uint16_t, DescT const*)) const noexcept {
    if (!agg_) { fireFailureCallback(cb, kInternalError); return; }
    (agg_.get()->*Method)(
        la::avdecc::UniqueIdentifier(targetEntityID), configurationIndex,
        IndexT(descriptorIndex),
        avdeccHandler<la::avdecc::entity::LocalEntity::AemCommandStatus>(
            Block<void, uint16_t, uint16_t, DescT const*>(cb),
            [](auto const& blk, uint16_t status,
               la::avdecc::entity::model::ConfigurationIndex const,
               IndexT const idx, DescT const& desc) noexcept {
              blk(status, idx, &desc);
            }));
  }

public:
  /// Acquire-Entity. `descriptorType`/`descriptorIndex` target a specific
  /// descriptor when partial acquisition is supported (default 0/0 means
  /// the whole entity). The block reports back the owning entity ID
  /// alongside status — non-zero status with a non-null owningEntity
  /// indicates the entity is already acquired by someone else.
  void acquireEntity(uint64_t targetEntityID, bool isPersistent,
                     uint16_t descriptorType, uint16_t descriptorIndex,
                     void (^cb)(uint16_t /*status*/, uint64_t /*owningEntity*/))
      const noexcept {
    if (!agg_) { fireFailureCallback(cb, kInternalError); return; }
    agg_->acquireEntity(
        la::avdecc::UniqueIdentifier(targetEntityID), isPersistent,
        static_cast<la::avdecc::entity::model::DescriptorType>(descriptorType),
        descriptorIndex, aclHandler(Block<void, uint16_t, uint64_t>(cb)));
  }

  void releaseEntity(uint64_t targetEntityID, uint16_t descriptorType,
                     uint16_t descriptorIndex,
                     void (^cb)(uint16_t, uint64_t)) const noexcept {
    lockImpl<&la::avdecc::entity::AggregateEntity::releaseEntity>(
        targetEntityID, descriptorType, descriptorIndex, cb);
  }
  void lockEntity(uint64_t targetEntityID, uint16_t descriptorType,
                  uint16_t descriptorIndex,
                  void (^cb)(uint16_t, uint64_t)) const noexcept {
    lockImpl<&la::avdecc::entity::AggregateEntity::lockEntity>(
        targetEntityID, descriptorType, descriptorIndex, cb);
  }
  void unlockEntity(uint64_t targetEntityID, uint16_t descriptorType,
                    uint16_t descriptorIndex,
                    void (^cb)(uint16_t, uint64_t)) const noexcept {
    lockImpl<&la::avdecc::entity::AggregateEntity::unlockEntity>(
        targetEntityID, descriptorType, descriptorIndex, cb);
  }

  // register/unregisterUnsolicitedNotifications — la_avdecc handler has no
  // trailing args after status, so we forward straight through.
  void registerUnsolicitedNotifications(
      uint64_t targetEntityID, void (^cb)(uint16_t /*status*/)) const noexcept {
    if (!agg_) { fireFailureCallback(cb, kInternalError); return; }
    agg_->registerUnsolicitedNotifications(
        la::avdecc::UniqueIdentifier(targetEntityID),
        avdeccHandler<la::avdecc::entity::LocalEntity::AemCommandStatus>(
            Block<void, uint16_t>(cb),
            [](auto const& blk, uint16_t status) noexcept { blk(status); }));
  }

  void unregisterUnsolicitedNotifications(
      uint64_t targetEntityID, void (^cb)(uint16_t /*status*/)) const noexcept {
    if (!agg_) { fireFailureCallback(cb, kInternalError); return; }
    agg_->unregisterUnsolicitedNotifications(
        la::avdecc::UniqueIdentifier(targetEntityID),
        avdeccHandler<la::avdecc::entity::LocalEntity::AemCommandStatus>(
            Block<void, uint16_t>(cb),
            [](auto const& blk, uint16_t status) noexcept { blk(status); }));
  }

  void getConfiguration(uint64_t targetEntityID,
                        void (^cb)(uint16_t /*status*/,
                                   uint16_t /*configurationIndex*/)) const noexcept {
    if (!agg_) { fireFailureCallback(cb, kInternalError); return; }
    agg_->getConfiguration(
        la::avdecc::UniqueIdentifier(targetEntityID),
        avdeccHandler<la::avdecc::entity::LocalEntity::AemCommandStatus>(
            Block<void, uint16_t, uint16_t>(cb),
            [](auto const& blk, uint16_t status,
               la::avdecc::entity::model::ConfigurationIndex const idx) noexcept {
              blk(status, idx);
            }));
  }

  void setConfiguration(uint64_t targetEntityID, uint16_t configurationIndex,
                        void (^cb)(uint16_t /*status*/,
                                   uint16_t /*configurationIndex*/)) const noexcept {
    if (!agg_) { fireFailureCallback(cb, kInternalError); return; }
    agg_->setConfiguration(
        la::avdecc::UniqueIdentifier(targetEntityID), configurationIndex,
        avdeccHandler<la::avdecc::entity::LocalEntity::AemCommandStatus>(
            Block<void, uint16_t, uint16_t>(cb),
            [](auto const& blk, uint16_t status,
               la::avdecc::entity::model::ConfigurationIndex const idx) noexcept {
              blk(status, idx);
            }));
  }

  // SET/GET _NAME family. Each takes a UTF-8 `name` C-string (Swift passes
  // via `withCString`), wrapped into `AvdeccFixedString` on the C++ side.
  // la_avdecc truncates strings longer than 64 bytes to fit the buffer.
  //
  // Three shapes:
  //   1. Entity-level (no extra args): setEntityName / getEntityName.
  //   2. Config-level (configIndex):   set/getEntityGroupName,
  //                                    set/getConfigurationName.
  //   3. Descriptor-level (configIndex + typed descriptor index):
  //                                    every other set/get<X>Name —
  //                                    generated via AVDECC_SWIFT_NAME_HELPERS.
  // All three share the same handler shape; just the trailing args differ.
private:
  // Set entity-level name (la_avdecc handler trailing args = AvdeccFixedString).
  template <auto Method>
  void setNameEntity(uint64_t targetEntityID, void const* nameBytes, size_t nameLen,
                     void (^cb)(uint16_t)) const noexcept {
    if (!agg_) { fireFailureCallback(cb, kInternalError); return; }
    la::avdecc::entity::model::AvdeccFixedString fixed(
        nameBytes ? nameBytes : "", nameBytes ? nameLen : 0);
    (agg_.get()->*Method)(
        la::avdecc::UniqueIdentifier(targetEntityID), fixed,
        avdeccHandler<la::avdecc::entity::LocalEntity::AemCommandStatus>(
            Block<void, uint16_t>(cb),
            [](auto const& blk, uint16_t status,
               la::avdecc::entity::model::AvdeccFixedString const&) noexcept {
              blk(status);
            }));
  }

  // Get entity-level name.
  template <auto Method>
  void getNameEntity(uint64_t targetEntityID,
                     void (^cb)(uint16_t,
                                la::avdecc::entity::model::AvdeccFixedString const*))
      const noexcept {
    if (!agg_) { fireFailureCallback(cb, kInternalError); return; }
    (agg_.get()->*Method)(
        la::avdecc::UniqueIdentifier(targetEntityID),
        avdeccHandler<la::avdecc::entity::LocalEntity::AemCommandStatus>(
            Block<void, uint16_t, la::avdecc::entity::model::AvdeccFixedString const*>(cb),
            [](auto const& blk, uint16_t status,
               la::avdecc::entity::model::AvdeccFixedString const& n) noexcept {
              blk(status, &n);
            }));
  }

  // Set config-level name (la_avdecc trailing args = ConfigIndex,
  // AvdeccFixedString).
  template <auto Method>
  void setNameConfig(uint64_t targetEntityID, uint16_t configurationIndex,
                     void const* nameBytes, size_t nameLen,
                     void (^cb)(uint16_t)) const noexcept {
    if (!agg_) { fireFailureCallback(cb, kInternalError); return; }
    la::avdecc::entity::model::AvdeccFixedString fixed(
        nameBytes ? nameBytes : "", nameBytes ? nameLen : 0);
    (agg_.get()->*Method)(
        la::avdecc::UniqueIdentifier(targetEntityID), configurationIndex, fixed,
        avdeccHandler<la::avdecc::entity::LocalEntity::AemCommandStatus>(
            Block<void, uint16_t>(cb),
            [](auto const& blk, uint16_t status,
               la::avdecc::entity::model::ConfigurationIndex const,
               la::avdecc::entity::model::AvdeccFixedString const&) noexcept {
              blk(status);
            }));
  }

  // Get config-level name.
  template <auto Method>
  void getNameConfig(uint64_t targetEntityID, uint16_t configurationIndex,
                     void (^cb)(uint16_t,
                                la::avdecc::entity::model::AvdeccFixedString const*))
      const noexcept {
    if (!agg_) { fireFailureCallback(cb, kInternalError); return; }
    (agg_.get()->*Method)(
        la::avdecc::UniqueIdentifier(targetEntityID), configurationIndex,
        avdeccHandler<la::avdecc::entity::LocalEntity::AemCommandStatus>(
            Block<void, uint16_t, la::avdecc::entity::model::AvdeccFixedString const*>(cb),
            [](auto const& blk, uint16_t status,
               la::avdecc::entity::model::ConfigurationIndex const,
               la::avdecc::entity::model::AvdeccFixedString const& n) noexcept {
              blk(status, &n);
            }));
  }

  // Set descriptor-level name (la_avdecc trailing = ConfigIndex, IndexT,
  // AvdeccFixedString). Used by the AVDECC_SWIFT_NAME_HELPERS macro.
  template <auto Method, typename IndexT>
  void setNameDesc(uint64_t targetEntityID, uint16_t configurationIndex,
                   uint16_t descriptorIndex, void const* nameBytes, size_t nameLen,
                   void (^cb)(uint16_t)) const noexcept {
    if (!agg_) { fireFailureCallback(cb, kInternalError); return; }
    la::avdecc::entity::model::AvdeccFixedString fixed(
        nameBytes ? nameBytes : "", nameBytes ? nameLen : 0);
    (agg_.get()->*Method)(
        la::avdecc::UniqueIdentifier(targetEntityID), configurationIndex,
        IndexT(descriptorIndex), fixed,
        avdeccHandler<la::avdecc::entity::LocalEntity::AemCommandStatus>(
            Block<void, uint16_t>(cb),
            [](auto const& blk, uint16_t status,
               la::avdecc::entity::model::ConfigurationIndex const,
               IndexT const,
               la::avdecc::entity::model::AvdeccFixedString const&) noexcept {
              blk(status);
            }));
  }

  // Get descriptor-level name.
  template <auto Method, typename IndexT>
  void getNameDesc(uint64_t targetEntityID, uint16_t configurationIndex,
                   uint16_t descriptorIndex,
                   void (^cb)(uint16_t,
                              la::avdecc::entity::model::AvdeccFixedString const*))
      const noexcept {
    if (!agg_) { fireFailureCallback(cb, kInternalError); return; }
    (agg_.get()->*Method)(
        la::avdecc::UniqueIdentifier(targetEntityID), configurationIndex,
        IndexT(descriptorIndex),
        avdeccHandler<la::avdecc::entity::LocalEntity::AemCommandStatus>(
            Block<void, uint16_t, la::avdecc::entity::model::AvdeccFixedString const*>(cb),
            [](auto const& blk, uint16_t status,
               la::avdecc::entity::model::ConfigurationIndex const,
               IndexT const,
               la::avdecc::entity::model::AvdeccFixedString const& n) noexcept {
              blk(status, &n);
            }));
  }

public:
  void setEntityName(uint64_t targetEntityID, void const* nameBytes, size_t nameLen,
                     void (^cb)(uint16_t)) const noexcept {
    setNameEntity<&la::avdecc::entity::AggregateEntity::setEntityName>(
        targetEntityID, nameBytes, nameLen, cb);
  }
  void setEntityGroupName(uint64_t targetEntityID, void const* nameBytes, size_t nameLen,
                          void (^cb)(uint16_t)) const noexcept {
    setNameEntity<&la::avdecc::entity::AggregateEntity::setEntityGroupName>(
        targetEntityID, nameBytes, nameLen, cb);
  }
  void getEntityGroupName(uint64_t targetEntityID,
                          void (^cb)(uint16_t,
                                     la::avdecc::entity::model::AvdeccFixedString const*))
      const noexcept {
    getNameEntity<&la::avdecc::entity::AggregateEntity::getEntityGroupName>(
        targetEntityID, cb);
  }
  void setConfigurationName(uint64_t targetEntityID, uint16_t configurationIndex,
                            void const* nameBytes, size_t nameLen,
                            void (^cb)(uint16_t)) const noexcept {
    setNameConfig<&la::avdecc::entity::AggregateEntity::setConfigurationName>(
        targetEntityID, configurationIndex, nameBytes, nameLen, cb);
  }

  // Per-descriptor get/set name. Each is a one-line stub onto
  // setNameDesc<>/getNameDesc<>; the matching la_avdecc method is
  // selected via member-function pointer plus the typed descriptor index.

  void setAudioUnitName(uint64_t e, uint16_t c, uint16_t i,
                        void const* n, size_t l, void (^cb)(uint16_t)) const noexcept {
    setNameDesc<&la::avdecc::entity::AggregateEntity::setAudioUnitName,
                la::avdecc::entity::model::AudioUnitIndex>(e, c, i, n, l, cb);
  }
  void getAudioUnitName(uint64_t e, uint16_t c, uint16_t i,
                        void (^cb)(uint16_t,
                                   la::avdecc::entity::model::AvdeccFixedString const*))
      const noexcept {
    getNameDesc<&la::avdecc::entity::AggregateEntity::getAudioUnitName,
                la::avdecc::entity::model::AudioUnitIndex>(e, c, i, cb);
  }

  void setStreamInputName(uint64_t e, uint16_t c, uint16_t i,
                          void const* n, size_t l, void (^cb)(uint16_t)) const noexcept {
    setNameDesc<&la::avdecc::entity::AggregateEntity::setStreamInputName,
                la::avdecc::entity::model::StreamIndex>(e, c, i, n, l, cb);
  }
  void getStreamInputName(uint64_t e, uint16_t c, uint16_t i,
                          void (^cb)(uint16_t,
                                     la::avdecc::entity::model::AvdeccFixedString const*))
      const noexcept {
    getNameDesc<&la::avdecc::entity::AggregateEntity::getStreamInputName,
                la::avdecc::entity::model::StreamIndex>(e, c, i, cb);
  }

  void setStreamOutputName(uint64_t e, uint16_t c, uint16_t i,
                           void const* n, size_t l, void (^cb)(uint16_t)) const noexcept {
    setNameDesc<&la::avdecc::entity::AggregateEntity::setStreamOutputName,
                la::avdecc::entity::model::StreamIndex>(e, c, i, n, l, cb);
  }
  void getStreamOutputName(uint64_t e, uint16_t c, uint16_t i,
                           void (^cb)(uint16_t,
                                      la::avdecc::entity::model::AvdeccFixedString const*))
      const noexcept {
    getNameDesc<&la::avdecc::entity::AggregateEntity::getStreamOutputName,
                la::avdecc::entity::model::StreamIndex>(e, c, i, cb);
  }

  void setJackInputName(uint64_t e, uint16_t c, uint16_t i,
                        void const* n, size_t l, void (^cb)(uint16_t)) const noexcept {
    setNameDesc<&la::avdecc::entity::AggregateEntity::setJackInputName,
                la::avdecc::entity::model::JackIndex>(e, c, i, n, l, cb);
  }
  void getJackInputName(uint64_t e, uint16_t c, uint16_t i,
                        void (^cb)(uint16_t,
                                   la::avdecc::entity::model::AvdeccFixedString const*))
      const noexcept {
    getNameDesc<&la::avdecc::entity::AggregateEntity::getJackInputName,
                la::avdecc::entity::model::JackIndex>(e, c, i, cb);
  }

  void setJackOutputName(uint64_t e, uint16_t c, uint16_t i,
                         void const* n, size_t l, void (^cb)(uint16_t)) const noexcept {
    setNameDesc<&la::avdecc::entity::AggregateEntity::setJackOutputName,
                la::avdecc::entity::model::JackIndex>(e, c, i, n, l, cb);
  }
  void getJackOutputName(uint64_t e, uint16_t c, uint16_t i,
                         void (^cb)(uint16_t,
                                    la::avdecc::entity::model::AvdeccFixedString const*))
      const noexcept {
    getNameDesc<&la::avdecc::entity::AggregateEntity::getJackOutputName,
                la::avdecc::entity::model::JackIndex>(e, c, i, cb);
  }

  void setAvbInterfaceName(uint64_t e, uint16_t c, uint16_t i,
                           void const* n, size_t l, void (^cb)(uint16_t)) const noexcept {
    setNameDesc<&la::avdecc::entity::AggregateEntity::setAvbInterfaceName,
                la::avdecc::entity::model::AvbInterfaceIndex>(e, c, i, n, l, cb);
  }
  void getAvbInterfaceName(uint64_t e, uint16_t c, uint16_t i,
                           void (^cb)(uint16_t,
                                      la::avdecc::entity::model::AvdeccFixedString const*))
      const noexcept {
    getNameDesc<&la::avdecc::entity::AggregateEntity::getAvbInterfaceName,
                la::avdecc::entity::model::AvbInterfaceIndex>(e, c, i, cb);
  }

  void setClockSourceName(uint64_t e, uint16_t c, uint16_t i,
                          void const* n, size_t l, void (^cb)(uint16_t)) const noexcept {
    setNameDesc<&la::avdecc::entity::AggregateEntity::setClockSourceName,
                la::avdecc::entity::model::ClockSourceIndex>(e, c, i, n, l, cb);
  }
  void getClockSourceName(uint64_t e, uint16_t c, uint16_t i,
                          void (^cb)(uint16_t,
                                     la::avdecc::entity::model::AvdeccFixedString const*))
      const noexcept {
    getNameDesc<&la::avdecc::entity::AggregateEntity::getClockSourceName,
                la::avdecc::entity::model::ClockSourceIndex>(e, c, i, cb);
  }

  void setMemoryObjectName(uint64_t e, uint16_t c, uint16_t i,
                           void const* n, size_t l, void (^cb)(uint16_t)) const noexcept {
    setNameDesc<&la::avdecc::entity::AggregateEntity::setMemoryObjectName,
                la::avdecc::entity::model::MemoryObjectIndex>(e, c, i, n, l, cb);
  }
  void getMemoryObjectName(uint64_t e, uint16_t c, uint16_t i,
                           void (^cb)(uint16_t,
                                      la::avdecc::entity::model::AvdeccFixedString const*))
      const noexcept {
    getNameDesc<&la::avdecc::entity::AggregateEntity::getMemoryObjectName,
                la::avdecc::entity::model::MemoryObjectIndex>(e, c, i, cb);
  }

  void setAudioClusterName(uint64_t e, uint16_t c, uint16_t i,
                           void const* n, size_t l, void (^cb)(uint16_t)) const noexcept {
    setNameDesc<&la::avdecc::entity::AggregateEntity::setAudioClusterName,
                la::avdecc::entity::model::ClusterIndex>(e, c, i, n, l, cb);
  }
  void getAudioClusterName(uint64_t e, uint16_t c, uint16_t i,
                           void (^cb)(uint16_t,
                                      la::avdecc::entity::model::AvdeccFixedString const*))
      const noexcept {
    getNameDesc<&la::avdecc::entity::AggregateEntity::getAudioClusterName,
                la::avdecc::entity::model::ClusterIndex>(e, c, i, cb);
  }

  void setControlName(uint64_t e, uint16_t c, uint16_t i,
                      void const* n, size_t l, void (^cb)(uint16_t)) const noexcept {
    setNameDesc<&la::avdecc::entity::AggregateEntity::setControlName,
                la::avdecc::entity::model::ControlIndex>(e, c, i, n, l, cb);
  }
  void getControlName(uint64_t e, uint16_t c, uint16_t i,
                      void (^cb)(uint16_t,
                                 la::avdecc::entity::model::AvdeccFixedString const*))
      const noexcept {
    getNameDesc<&la::avdecc::entity::AggregateEntity::getControlName,
                la::avdecc::entity::model::ControlIndex>(e, c, i, cb);
  }

  void setClockDomainName(uint64_t e, uint16_t c, uint16_t i,
                          void const* n, size_t l, void (^cb)(uint16_t)) const noexcept {
    setNameDesc<&la::avdecc::entity::AggregateEntity::setClockDomainName,
                la::avdecc::entity::model::ClockDomainIndex>(e, c, i, n, l, cb);
  }
  void getClockDomainName(uint64_t e, uint16_t c, uint16_t i,
                          void (^cb)(uint16_t,
                                     la::avdecc::entity::model::AvdeccFixedString const*))
      const noexcept {
    getNameDesc<&la::avdecc::entity::AggregateEntity::getClockDomainName,
                la::avdecc::entity::model::ClockDomainIndex>(e, c, i, cb);
  }

  void setTimingName(uint64_t e, uint16_t c, uint16_t i,
                     void const* n, size_t l, void (^cb)(uint16_t)) const noexcept {
    setNameDesc<&la::avdecc::entity::AggregateEntity::setTimingName,
                la::avdecc::entity::model::TimingIndex>(e, c, i, n, l, cb);
  }
  void getTimingName(uint64_t e, uint16_t c, uint16_t i,
                     void (^cb)(uint16_t,
                                la::avdecc::entity::model::AvdeccFixedString const*))
      const noexcept {
    getNameDesc<&la::avdecc::entity::AggregateEntity::getTimingName,
                la::avdecc::entity::model::TimingIndex>(e, c, i, cb);
  }

  void setPtpInstanceName(uint64_t e, uint16_t c, uint16_t i,
                          void const* n, size_t l, void (^cb)(uint16_t)) const noexcept {
    setNameDesc<&la::avdecc::entity::AggregateEntity::setPtpInstanceName,
                la::avdecc::entity::model::PtpInstanceIndex>(e, c, i, n, l, cb);
  }
  void getPtpInstanceName(uint64_t e, uint16_t c, uint16_t i,
                          void (^cb)(uint16_t,
                                     la::avdecc::entity::model::AvdeccFixedString const*))
      const noexcept {
    getNameDesc<&la::avdecc::entity::AggregateEntity::getPtpInstanceName,
                la::avdecc::entity::model::PtpInstanceIndex>(e, c, i, cb);
  }

  void setPtpPortName(uint64_t e, uint16_t c, uint16_t i,
                      void const* n, size_t l, void (^cb)(uint16_t)) const noexcept {
    setNameDesc<&la::avdecc::entity::AggregateEntity::setPtpPortName,
                la::avdecc::entity::model::PtpPortIndex>(e, c, i, n, l, cb);
  }
  void getPtpPortName(uint64_t e, uint16_t c, uint16_t i,
                      void (^cb)(uint16_t,
                                 la::avdecc::entity::model::AvdeccFixedString const*))
      const noexcept {
    getNameDesc<&la::avdecc::entity::AggregateEntity::getPtpPortName,
                la::avdecc::entity::model::PtpPortIndex>(e, c, i, cb);
  }

  void getEntityName(uint64_t targetEntityID,
                     void (^cb)(uint16_t,
                                la::avdecc::entity::model::AvdeccFixedString const*))
      const noexcept {
    getNameEntity<&la::avdecc::entity::AggregateEntity::getEntityName>(
        targetEntityID, cb);
  }

  void getConfigurationName(
      uint64_t targetEntityID, uint16_t configurationIndex,
      void (^cb)(uint16_t,
                 la::avdecc::entity::model::AvdeccFixedString const*)) const noexcept {
    getNameConfig<&la::avdecc::entity::AggregateEntity::getConfigurationName>(
        targetEntityID, configurationIndex, cb);
  }

  // start/stop StreamInput/Output — la_avdecc echoes the streamIndex in
  // the handler, which we discard since Swift's callback only needs status.
private:
  template <auto Method>
  void streamStartStopImpl(uint64_t targetEntityID, uint16_t streamIndex,
                           void (^cb)(uint16_t)) const noexcept {
    if (!agg_) { fireFailureCallback(cb, kInternalError); return; }
    (agg_.get()->*Method)(
        la::avdecc::UniqueIdentifier(targetEntityID), streamIndex,
        avdeccHandler<la::avdecc::entity::LocalEntity::AemCommandStatus>(
            Block<void, uint16_t>(cb),
            [](auto const& blk, uint16_t status,
               la::avdecc::entity::model::StreamIndex const) noexcept {
              blk(status);
            }));
  }

public:
  void startStreamInput(uint64_t e, uint16_t s, void (^cb)(uint16_t)) const noexcept {
    streamStartStopImpl<&la::avdecc::entity::AggregateEntity::startStreamInput>(e, s, cb);
  }
  void startStreamOutput(uint64_t e, uint16_t s, void (^cb)(uint16_t)) const noexcept {
    streamStartStopImpl<&la::avdecc::entity::AggregateEntity::startStreamOutput>(e, s, cb);
  }
  void stopStreamInput(uint64_t e, uint16_t s, void (^cb)(uint16_t)) const noexcept {
    streamStartStopImpl<&la::avdecc::entity::AggregateEntity::stopStreamInput>(e, s, cb);
  }
  void stopStreamOutput(uint64_t e, uint16_t s, void (^cb)(uint16_t)) const noexcept {
    streamStartStopImpl<&la::avdecc::entity::AggregateEntity::stopStreamOutput>(e, s, cb);
  }

  // get/set Stream{Input,Output}Format — la_avdecc handler trails with
  // (StreamIndex, StreamFormat); Swift surface is (status, streamIdx,
  // rawStreamFormat_uint64). The set variants take an extra format
  // argument before the handler. `streamFormatGetImpl` covers the two
  // getters; the setters need their own bodies because of the format
  // arg. Both share the projection lambda.
private:
  static auto streamFormatHandler(Block<void, uint16_t, uint16_t, uint64_t> blk) noexcept {
    return avdeccHandler<la::avdecc::entity::LocalEntity::AemCommandStatus>(
        std::move(blk),
        [](auto const& blk, uint16_t status,
           la::avdecc::entity::model::StreamIndex const idx,
           la::avdecc::entity::model::StreamFormat const fmt) noexcept {
          blk(status, idx, fmt.getValue());
        });
  }

  template <auto Method>
  void streamFormatGetImpl(uint64_t targetEntityID, uint16_t streamIndex,
                           void (^cb)(uint16_t, uint16_t, uint64_t)) const noexcept {
    if (!agg_) { fireFailureCallback(cb, kInternalError); return; }
    (agg_.get()->*Method)(
        la::avdecc::UniqueIdentifier(targetEntityID), streamIndex,
        streamFormatHandler(Block<void, uint16_t, uint16_t, uint64_t>(cb)));
  }

  template <auto Method>
  void streamFormatSetImpl(uint64_t targetEntityID, uint16_t streamIndex,
                           uint64_t streamFormat,
                           void (^cb)(uint16_t, uint16_t, uint64_t)) const noexcept {
    if (!agg_) { fireFailureCallback(cb, kInternalError); return; }
    (agg_.get()->*Method)(
        la::avdecc::UniqueIdentifier(targetEntityID), streamIndex,
        la::avdecc::entity::model::StreamFormat(streamFormat),
        streamFormatHandler(Block<void, uint16_t, uint16_t, uint64_t>(cb)));
  }

  // get StreamInput/OutputInfo — surface (status, streamIdx, &StreamInfo).
  template <auto Method>
  void streamInfoGetImpl(
      uint64_t targetEntityID, uint16_t streamIndex,
      void (^cb)(uint16_t, uint16_t,
                 la::avdecc::entity::model::StreamInfo const*)) const noexcept {
    if (!agg_) { fireFailureCallback(cb, kInternalError); return; }
    (agg_.get()->*Method)(
        la::avdecc::UniqueIdentifier(targetEntityID), streamIndex,
        avdeccHandler<la::avdecc::entity::LocalEntity::AemCommandStatus>(
            Block<void, uint16_t, uint16_t,
                  la::avdecc::entity::model::StreamInfo const*>(cb),
            [](auto const& blk, uint16_t status,
               la::avdecc::entity::model::StreamIndex const idx,
               la::avdecc::entity::model::StreamInfo const& info) noexcept {
              blk(status, idx, &info);
            }));
  }

  // Build a StreamInfo from flat scalars (Swift passes the writeable
  // fields by value; Milan-specific optionals stay default-constructed
  // because la_avdecc's setter ignores std::nullopt fields and the wire
  // PDU only carries the IEEE 1722.1 set). Hand it to the appropriate
  // setStreamInfo method via the (auto Method) template parameter.
  template <auto Method>
  void streamInfoSetImpl(
      uint64_t targetEntityID, uint16_t streamIndex,
      uint64_t streamFormat, uint32_t streamInfoFlagsRaw,
      uint64_t streamID, uint32_t msrpAccumulatedLatency,
      uint8_t const streamDestMac[6], uint16_t streamVlanID,
      void (^cb)(uint16_t, uint16_t,
                 la::avdecc::entity::model::StreamInfo const*)) const noexcept {
    if (!agg_) { fireFailureCallback(cb, kInternalError); return; }
    la::avdecc::entity::model::StreamInfo info;
    info.streamFormat = la::avdecc::entity::model::StreamFormat(streamFormat);
    info.streamInfoFlags.assign(streamInfoFlagsRaw);
    info.streamID = la::avdecc::UniqueIdentifier(streamID);
    info.msrpAccumulatedLatency = msrpAccumulatedLatency;
    for (size_t i = 0; i < 6; ++i) info.streamDestMac[i] = streamDestMac[i];
    info.streamVlanID = streamVlanID;
    (agg_.get()->*Method)(
        la::avdecc::UniqueIdentifier(targetEntityID), streamIndex, info,
        avdeccHandler<la::avdecc::entity::LocalEntity::AemCommandStatus>(
            Block<void, uint16_t, uint16_t,
                  la::avdecc::entity::model::StreamInfo const*>(cb),
            [](auto const& blk, uint16_t status,
               la::avdecc::entity::model::StreamIndex const idx,
               la::avdecc::entity::model::StreamInfo const& result) noexcept {
              blk(status, idx, &result);
            }));
  }

public:
  void getStreamInputFormat(uint64_t e, uint16_t s,
                            void (^cb)(uint16_t, uint16_t, uint64_t)) const noexcept {
    streamFormatGetImpl<&la::avdecc::entity::AggregateEntity::getStreamInputFormat>(e, s, cb);
  }
  void getStreamOutputFormat(uint64_t e, uint16_t s,
                             void (^cb)(uint16_t, uint16_t, uint64_t)) const noexcept {
    streamFormatGetImpl<&la::avdecc::entity::AggregateEntity::getStreamOutputFormat>(e, s, cb);
  }
  void setStreamInputFormat(uint64_t e, uint16_t s, uint64_t fmt,
                            void (^cb)(uint16_t, uint16_t, uint64_t)) const noexcept {
    streamFormatSetImpl<&la::avdecc::entity::AggregateEntity::setStreamInputFormat>(e, s, fmt, cb);
  }
  void setStreamOutputFormat(uint64_t e, uint16_t s, uint64_t fmt,
                             void (^cb)(uint16_t, uint16_t, uint64_t)) const noexcept {
    streamFormatSetImpl<&la::avdecc::entity::AggregateEntity::setStreamOutputFormat>(e, s, fmt, cb);
  }

  void getStreamInputInfo(
      uint64_t e, uint16_t s,
      void (^cb)(uint16_t, uint16_t,
                 la::avdecc::entity::model::StreamInfo const*)) const noexcept {
    streamInfoGetImpl<&la::avdecc::entity::AggregateEntity::getStreamInputInfo>(e, s, cb);
  }
  void getStreamOutputInfo(
      uint64_t e, uint16_t s,
      void (^cb)(uint16_t, uint16_t,
                 la::avdecc::entity::model::StreamInfo const*)) const noexcept {
    streamInfoGetImpl<&la::avdecc::entity::AggregateEntity::getStreamOutputInfo>(e, s, cb);
  }

  // SET_STREAM_INFO writers — IEEE 1722.1-2013 §7.4.16. Take the writable
  // StreamInfo fields as flat scalars; la_avdecc echoes the post-set
  // StreamInfo back through the same handler shape as the getter.
  void setStreamInputInfo(
      uint64_t e, uint16_t s,
      uint64_t streamFormat, uint32_t streamInfoFlags,
      uint64_t streamID, uint32_t msrpAccumulatedLatency,
      uint8_t const streamDestMac[6], uint16_t streamVlanID,
      void (^cb)(uint16_t, uint16_t,
                 la::avdecc::entity::model::StreamInfo const*)) const noexcept {
    streamInfoSetImpl<&la::avdecc::entity::AggregateEntity::setStreamInputInfo>(
        e, s, streamFormat, streamInfoFlags, streamID,
        msrpAccumulatedLatency, streamDestMac, streamVlanID, cb);
  }
  void setStreamOutputInfo(
      uint64_t e, uint16_t s,
      uint64_t streamFormat, uint32_t streamInfoFlags,
      uint64_t streamID, uint32_t msrpAccumulatedLatency,
      uint8_t const streamDestMac[6], uint16_t streamVlanID,
      void (^cb)(uint16_t, uint16_t,
                 la::avdecc::entity::model::StreamInfo const*)) const noexcept {
    streamInfoSetImpl<&la::avdecc::entity::AggregateEntity::setStreamOutputInfo>(
        e, s, streamFormat, streamInfoFlags, streamID,
        msrpAccumulatedLatency, streamDestMac, streamVlanID, cb);
  }

  // get/setClockSource — la_avdecc trails with (ClockDomainIndex,
  // ClockSourceIndex); Swift surface is (status, clockSrcIdx).
  void getClockSource(uint64_t targetEntityID, uint16_t clockDomainIndex,
                      void (^cb)(uint16_t, uint16_t)) const noexcept {
    if (!agg_) { fireFailureCallback(cb, kInternalError); return; }
    agg_->getClockSource(
        la::avdecc::UniqueIdentifier(targetEntityID), clockDomainIndex,
        avdeccHandler<la::avdecc::entity::LocalEntity::AemCommandStatus>(
            Block<void, uint16_t, uint16_t>(cb),
            [](auto const& blk, uint16_t status,
               la::avdecc::entity::model::ClockDomainIndex const,
               la::avdecc::entity::model::ClockSourceIndex const src) noexcept {
              blk(status, src);
            }));
  }

  void setClockSource(uint64_t targetEntityID, uint16_t clockDomainIndex,
                      uint16_t clockSourceIndex,
                      void (^cb)(uint16_t, uint16_t)) const noexcept {
    if (!agg_) { fireFailureCallback(cb, kInternalError); return; }
    agg_->setClockSource(
        la::avdecc::UniqueIdentifier(targetEntityID), clockDomainIndex,
        clockSourceIndex,
        avdeccHandler<la::avdecc::entity::LocalEntity::AemCommandStatus>(
            Block<void, uint16_t, uint16_t>(cb),
            [](auto const& blk, uint16_t status,
               la::avdecc::entity::model::ClockDomainIndex const,
               la::avdecc::entity::model::ClockSourceIndex const src) noexcept {
              blk(status, src);
            }));
  }

  /// Read-Entity-Descriptor. Block fires once with status + a borrowed
  /// pointer to la_avdecc's `EntityDescriptor`. The pointer is valid only
  /// for the duration of the block call; Swift copies the value into a
  /// Swift wrapper struct before returning.
  ///
  /// The block is wrapped in AVDECCSwift::Block<> so the lambda capture
  /// keeps it alive (Block_copy on capture, Block_release when la_avdecc's
  /// std::function is destroyed). Without that, the Swift-side closure
  /// would die when this method returns and the deferred std::function
  /// would invoke a dangling block.
  void readEntityDescriptor(uint64_t targetEntityID,
                            void (^cb)(uint16_t,
                                       la::avdecc::entity::model::EntityDescriptor const*))
      const noexcept {
    if (!agg_) { fireFailureCallback(cb, kInternalError); return; }
    agg_->readEntityDescriptor(
        la::avdecc::UniqueIdentifier(targetEntityID),
        avdeccHandler<la::avdecc::entity::LocalEntity::AemCommandStatus>(
            Block<void, uint16_t,
                  la::avdecc::entity::model::EntityDescriptor const*>(cb),
            [](auto const& blk, uint16_t status,
               la::avdecc::entity::model::EntityDescriptor const& d) noexcept {
              blk(status, &d);
            }));
  }

  void getAvbInfo(uint64_t targetEntityID, uint16_t avbInterfaceIndex,
                  void (^cb)(uint16_t, uint16_t,
                             la::avdecc::entity::model::AvbInfo const*)) const noexcept {
    if (!agg_) { fireFailureCallback(cb, kInternalError); return; }
    agg_->getAvbInfo(
        la::avdecc::UniqueIdentifier(targetEntityID), avbInterfaceIndex,
        avdeccHandler<la::avdecc::entity::LocalEntity::AemCommandStatus>(
            Block<void, uint16_t, uint16_t,
                  la::avdecc::entity::model::AvbInfo const*>(cb),
            [](auto const& blk, uint16_t status,
               la::avdecc::entity::model::AvbInterfaceIndex const idx,
               la::avdecc::entity::model::AvbInfo const& info) noexcept {
              blk(status, idx, &info);
            }));
  }

  // readConfigurationDescriptor differs from readDescImpl<> in that the
  // configuration index is *the* descriptor index; la_avdecc's handler
  // trails with (ConfigurationIndex, ConfigurationDescriptor) — no
  // separate sub-index. Stays bespoke.
  void readConfigurationDescriptor(
      uint64_t targetEntityID, uint16_t configurationIndex,
      void (^cb)(uint16_t, uint16_t,
                 la::avdecc::entity::model::ConfigurationDescriptor const*)) const noexcept {
    if (!agg_) { fireFailureCallback(cb, kInternalError); return; }
    agg_->readConfigurationDescriptor(
        la::avdecc::UniqueIdentifier(targetEntityID), configurationIndex,
        avdeccHandler<la::avdecc::entity::LocalEntity::AemCommandStatus>(
            Block<void, uint16_t, uint16_t,
                  la::avdecc::entity::model::ConfigurationDescriptor const*>(cb),
            [](auto const& blk, uint16_t status,
               la::avdecc::entity::model::ConfigurationIndex const idx,
               la::avdecc::entity::model::ConfigurationDescriptor const& desc) noexcept {
              blk(status, idx, &desc);
            }));
  }

  // The 12 descriptor reads below all share the same shape — only the
  // user-facing method name, the typed la_avdecc index, and the
  // descriptor type vary. Each is a one-line stub onto readDescImpl<>.
  // (`readEntityDescriptor` and `readConfigurationDescriptor` are
  // separate; one has no index, the other has only the config index.)

  void readAvbInterfaceDescriptor(
      uint64_t targetEntityID, uint16_t configurationIndex,
      uint16_t avbInterfaceIndex,
      void (^cb)(uint16_t, uint16_t,
                 la::avdecc::entity::model::AvbInterfaceDescriptor const*)) const noexcept {
    readDescImpl<&la::avdecc::entity::AggregateEntity::readAvbInterfaceDescriptor,
                 la::avdecc::entity::model::AvbInterfaceIndex,
                 la::avdecc::entity::model::AvbInterfaceDescriptor>(
        targetEntityID, configurationIndex, avbInterfaceIndex, cb);
  }

  void readStreamInputDescriptor(
      uint64_t targetEntityID, uint16_t configurationIndex, uint16_t streamIndex,
      void (^cb)(uint16_t, uint16_t,
                 la::avdecc::entity::model::StreamDescriptor const*)) const noexcept {
    readDescImpl<&la::avdecc::entity::AggregateEntity::readStreamInputDescriptor,
                 la::avdecc::entity::model::StreamIndex,
                 la::avdecc::entity::model::StreamDescriptor>(
        targetEntityID, configurationIndex, streamIndex, cb);
  }

  void readStreamOutputDescriptor(
      uint64_t targetEntityID, uint16_t configurationIndex, uint16_t streamIndex,
      void (^cb)(uint16_t, uint16_t,
                 la::avdecc::entity::model::StreamDescriptor const*)) const noexcept {
    readDescImpl<&la::avdecc::entity::AggregateEntity::readStreamOutputDescriptor,
                 la::avdecc::entity::model::StreamIndex,
                 la::avdecc::entity::model::StreamDescriptor>(
        targetEntityID, configurationIndex, streamIndex, cb);
  }

  void readAudioUnitDescriptor(
      uint64_t targetEntityID, uint16_t configurationIndex, uint16_t audioUnitIndex,
      void (^cb)(uint16_t, uint16_t,
                 la::avdecc::entity::model::AudioUnitDescriptor const*)) const noexcept {
    readDescImpl<&la::avdecc::entity::AggregateEntity::readAudioUnitDescriptor,
                 la::avdecc::entity::model::AudioUnitIndex,
                 la::avdecc::entity::model::AudioUnitDescriptor>(
        targetEntityID, configurationIndex, audioUnitIndex, cb);
  }

  void readJackInputDescriptor(
      uint64_t targetEntityID, uint16_t configurationIndex, uint16_t jackIndex,
      void (^cb)(uint16_t, uint16_t,
                 la::avdecc::entity::model::JackDescriptor const*)) const noexcept {
    readDescImpl<&la::avdecc::entity::AggregateEntity::readJackInputDescriptor,
                 la::avdecc::entity::model::JackIndex,
                 la::avdecc::entity::model::JackDescriptor>(
        targetEntityID, configurationIndex, jackIndex, cb);
  }

  void readJackOutputDescriptor(
      uint64_t targetEntityID, uint16_t configurationIndex, uint16_t jackIndex,
      void (^cb)(uint16_t, uint16_t,
                 la::avdecc::entity::model::JackDescriptor const*)) const noexcept {
    readDescImpl<&la::avdecc::entity::AggregateEntity::readJackOutputDescriptor,
                 la::avdecc::entity::model::JackIndex,
                 la::avdecc::entity::model::JackDescriptor>(
        targetEntityID, configurationIndex, jackIndex, cb);
  }

  void readClockSourceDescriptor(
      uint64_t targetEntityID, uint16_t configurationIndex, uint16_t clockSourceIndex,
      void (^cb)(uint16_t, uint16_t,
                 la::avdecc::entity::model::ClockSourceDescriptor const*)) const noexcept {
    readDescImpl<&la::avdecc::entity::AggregateEntity::readClockSourceDescriptor,
                 la::avdecc::entity::model::ClockSourceIndex,
                 la::avdecc::entity::model::ClockSourceDescriptor>(
        targetEntityID, configurationIndex, clockSourceIndex, cb);
  }

  void readMemoryObjectDescriptor(
      uint64_t targetEntityID, uint16_t configurationIndex, uint16_t memoryObjectIndex,
      void (^cb)(uint16_t, uint16_t,
                 la::avdecc::entity::model::MemoryObjectDescriptor const*)) const noexcept {
    readDescImpl<&la::avdecc::entity::AggregateEntity::readMemoryObjectDescriptor,
                 la::avdecc::entity::model::MemoryObjectIndex,
                 la::avdecc::entity::model::MemoryObjectDescriptor>(
        targetEntityID, configurationIndex, memoryObjectIndex, cb);
  }

  void readLocaleDescriptor(
      uint64_t targetEntityID, uint16_t configurationIndex, uint16_t localeIndex,
      void (^cb)(uint16_t, uint16_t,
                 la::avdecc::entity::model::LocaleDescriptor const*)) const noexcept {
    readDescImpl<&la::avdecc::entity::AggregateEntity::readLocaleDescriptor,
                 la::avdecc::entity::model::LocaleIndex,
                 la::avdecc::entity::model::LocaleDescriptor>(
        targetEntityID, configurationIndex, localeIndex, cb);
  }

  void readStringsDescriptor(
      uint64_t targetEntityID, uint16_t configurationIndex, uint16_t stringsIndex,
      void (^cb)(uint16_t, uint16_t,
                 la::avdecc::entity::model::StringsDescriptor const*)) const noexcept {
    readDescImpl<&la::avdecc::entity::AggregateEntity::readStringsDescriptor,
                 la::avdecc::entity::model::StringsIndex,
                 la::avdecc::entity::model::StringsDescriptor>(
        targetEntityID, configurationIndex, stringsIndex, cb);
  }

  void readAudioClusterDescriptor(
      uint64_t targetEntityID, uint16_t configurationIndex, uint16_t clusterIndex,
      void (^cb)(uint16_t, uint16_t,
                 la::avdecc::entity::model::AudioClusterDescriptor const*)) const noexcept {
    readDescImpl<&la::avdecc::entity::AggregateEntity::readAudioClusterDescriptor,
                 la::avdecc::entity::model::ClusterIndex,
                 la::avdecc::entity::model::AudioClusterDescriptor>(
        targetEntityID, configurationIndex, clusterIndex, cb);
  }

  void readClockDomainDescriptor(
      uint64_t targetEntityID, uint16_t configurationIndex, uint16_t clockDomainIndex,
      void (^cb)(uint16_t, uint16_t,
                 la::avdecc::entity::model::ClockDomainDescriptor const*)) const noexcept {
    readDescImpl<&la::avdecc::entity::AggregateEntity::readClockDomainDescriptor,
                 la::avdecc::entity::model::ClockDomainIndex,
                 la::avdecc::entity::model::ClockDomainDescriptor>(
        targetEntityID, configurationIndex, clockDomainIndex, cb);
  }

  void getAsPath(uint64_t targetEntityID, uint16_t avbInterfaceIndex,
                 void (^cb)(uint16_t, uint16_t,
                            la::avdecc::entity::model::AsPath const*)) const noexcept {
    if (!agg_) { fireFailureCallback(cb, kInternalError); return; }
    agg_->getAsPath(
        la::avdecc::UniqueIdentifier(targetEntityID), avbInterfaceIndex,
        avdeccHandler<la::avdecc::entity::LocalEntity::AemCommandStatus>(
            Block<void, uint16_t, uint16_t,
                  la::avdecc::entity::model::AsPath const*>(cb),
            [](auto const& blk, uint16_t status,
               la::avdecc::entity::model::AvbInterfaceIndex const idx,
               la::avdecc::entity::model::AsPath const& asPath) noexcept {
              blk(status, idx, &asPath);
            }));
  }

  // SamplingRate is just a uint32_t bitfield (pull<<29 | baseFrequency);
  // we pass the raw value across and let the Swift wrapper expose the
  // pull/baseFrequency split. Three index-types: AudioUnitIndex,
  // ClusterIndex (video), ClusterIndex (sensor) — all uint16_t.
  // The macro generates the user-visible method names; bodies are
  // 1-line stubs onto setSamplingRateImpl<>/getSamplingRateImpl<>.
private:
  template <auto Method, typename IndexT>
  void setSamplingRateImpl(uint64_t targetEntityID, uint16_t descriptorIndex,
                           uint32_t samplingRate,
                           void (^cb)(uint16_t, uint16_t, uint32_t)) const noexcept {
    if (!agg_) { fireFailureCallback(cb, kInternalError); return; }
    (agg_.get()->*Method)(
        la::avdecc::UniqueIdentifier(targetEntityID),
        IndexT(descriptorIndex),
        la::avdecc::entity::model::SamplingRate(samplingRate),
        avdeccHandler<la::avdecc::entity::LocalEntity::AemCommandStatus>(
            Block<void, uint16_t, uint16_t, uint32_t>(cb),
            [](auto const& blk, uint16_t status, IndexT const idx,
               la::avdecc::entity::model::SamplingRate const rate) noexcept {
              blk(status, idx, rate.getValue());
            }));
  }

  template <auto Method, typename IndexT>
  void getSamplingRateImpl(uint64_t targetEntityID, uint16_t descriptorIndex,
                           void (^cb)(uint16_t, uint16_t, uint32_t)) const noexcept {
    if (!agg_) { fireFailureCallback(cb, kInternalError); return; }
    (agg_.get()->*Method)(
        la::avdecc::UniqueIdentifier(targetEntityID),
        IndexT(descriptorIndex),
        avdeccHandler<la::avdecc::entity::LocalEntity::AemCommandStatus>(
            Block<void, uint16_t, uint16_t, uint32_t>(cb),
            [](auto const& blk, uint16_t status, IndexT const idx,
               la::avdecc::entity::model::SamplingRate const rate) noexcept {
              blk(status, idx, rate.getValue());
            }));
  }

public:
  void setAudioUnitSamplingRate(uint64_t e, uint16_t i, uint32_t r,
                                void (^cb)(uint16_t, uint16_t, uint32_t)) const noexcept {
    setSamplingRateImpl<&la::avdecc::entity::AggregateEntity::setAudioUnitSamplingRate,
                        la::avdecc::entity::model::AudioUnitIndex>(e, i, r, cb);
  }
  void getAudioUnitSamplingRate(uint64_t e, uint16_t i,
                                void (^cb)(uint16_t, uint16_t, uint32_t)) const noexcept {
    getSamplingRateImpl<&la::avdecc::entity::AggregateEntity::getAudioUnitSamplingRate,
                        la::avdecc::entity::model::AudioUnitIndex>(e, i, cb);
  }
  void setVideoClusterSamplingRate(uint64_t e, uint16_t i, uint32_t r,
                                   void (^cb)(uint16_t, uint16_t, uint32_t)) const noexcept {
    setSamplingRateImpl<&la::avdecc::entity::AggregateEntity::setVideoClusterSamplingRate,
                        la::avdecc::entity::model::ClusterIndex>(e, i, r, cb);
  }
  void getVideoClusterSamplingRate(uint64_t e, uint16_t i,
                                   void (^cb)(uint16_t, uint16_t, uint32_t)) const noexcept {
    getSamplingRateImpl<&la::avdecc::entity::AggregateEntity::getVideoClusterSamplingRate,
                        la::avdecc::entity::model::ClusterIndex>(e, i, cb);
  }
  void setSensorClusterSamplingRate(uint64_t e, uint16_t i, uint32_t r,
                                    void (^cb)(uint16_t, uint16_t, uint32_t)) const noexcept {
    setSamplingRateImpl<&la::avdecc::entity::AggregateEntity::setSensorClusterSamplingRate,
                        la::avdecc::entity::model::ClusterIndex>(e, i, r, cb);
  }
  void getSensorClusterSamplingRate(uint64_t e, uint16_t i,
                                    void (^cb)(uint16_t, uint16_t, uint32_t)) const noexcept {
    getSamplingRateImpl<&la::avdecc::entity::AggregateEntity::getSensorClusterSamplingRate,
                        la::avdecc::entity::model::ClusterIndex>(e, i, cb);
  }

  // GET/SET_MAX_TRANSIT_TIME — Milan-2019. la_avdecc takes/returns
  // std::chrono::nanoseconds; we surface raw uint64_t ns counts.
private:
  static auto maxTransitTimeHandler(Block<void, uint16_t, uint16_t, uint64_t> blk) noexcept {
    return avdeccHandler<la::avdecc::entity::LocalEntity::AemCommandStatus>(
        std::move(blk),
        [](auto const& blk, uint16_t status,
           la::avdecc::entity::model::StreamIndex const idx,
           std::chrono::nanoseconds const ns) noexcept {
          blk(status, idx, static_cast<uint64_t>(ns.count()));
        });
  }

public:
  void setMaxTransitTime(uint64_t targetEntityID, uint16_t streamIndex,
                         uint64_t maxTransitTimeNs,
                         void (^cb)(uint16_t, uint16_t, uint64_t)) const noexcept {
    if (!agg_) { fireFailureCallback(cb, kInternalError); return; }
    agg_->setMaxTransitTime(
        la::avdecc::UniqueIdentifier(targetEntityID), streamIndex,
        std::chrono::nanoseconds(maxTransitTimeNs),
        maxTransitTimeHandler(Block<void, uint16_t, uint16_t, uint64_t>(cb)));
  }

  void getMaxTransitTime(uint64_t targetEntityID, uint16_t streamIndex,
                         void (^cb)(uint16_t, uint16_t, uint64_t)) const noexcept {
    if (!agg_) { fireFailureCallback(cb, kInternalError); return; }
    agg_->getMaxTransitTime(
        la::avdecc::UniqueIdentifier(targetEntityID), streamIndex,
        maxTransitTimeHandler(Block<void, uint16_t, uint16_t, uint64_t>(cb)));
  }

  // GET/SET_MEMORY_OBJECT_LENGTH — IEEE1722.1-2013 Clause 7.4.72/73.
  // Both surface (status, length); la_avdecc trails with (configIdx,
  // memoryObjIdx, length).
private:
  static auto memoryObjectLengthHandler(Block<void, uint16_t, uint64_t> blk) noexcept {
    return avdeccHandler<la::avdecc::entity::LocalEntity::AemCommandStatus>(
        std::move(blk),
        [](auto const& blk, uint16_t status,
           la::avdecc::entity::model::ConfigurationIndex const,
           la::avdecc::entity::model::MemoryObjectIndex const,
           uint64_t const len) noexcept {
          blk(status, len);
        });
  }

public:
  void setMemoryObjectLength(uint64_t targetEntityID, uint16_t configurationIndex,
                             uint16_t memoryObjectIndex, uint64_t length,
                             void (^cb)(uint16_t, uint64_t)) const noexcept {
    if (!agg_) { fireFailureCallback(cb, kInternalError); return; }
    agg_->setMemoryObjectLength(
        la::avdecc::UniqueIdentifier(targetEntityID), configurationIndex,
        la::avdecc::entity::model::MemoryObjectIndex(memoryObjectIndex), length,
        memoryObjectLengthHandler(Block<void, uint16_t, uint64_t>(cb)));
  }

  void getMemoryObjectLength(uint64_t targetEntityID, uint16_t configurationIndex,
                             uint16_t memoryObjectIndex,
                             void (^cb)(uint16_t, uint64_t)) const noexcept {
    if (!agg_) { fireFailureCallback(cb, kInternalError); return; }
    agg_->getMemoryObjectLength(
        la::avdecc::UniqueIdentifier(targetEntityID), configurationIndex,
        la::avdecc::entity::model::MemoryObjectIndex(memoryObjectIndex),
        memoryObjectLengthHandler(Block<void, uint16_t, uint64_t>(cb)));
  }

  // ENTITY_AVAILABLE / CONTROLLER_AVAILABLE liveness pings.
  void queryEntityAvailable(uint64_t targetEntityID,
                            void (^cb)(uint16_t)) const noexcept {
    if (!agg_) { fireFailureCallback(cb, kInternalError); return; }
    agg_->queryEntityAvailable(
        la::avdecc::UniqueIdentifier(targetEntityID),
        avdeccHandler<la::avdecc::entity::LocalEntity::AemCommandStatus>(
            Block<void, uint16_t>(cb),
            [](auto const& blk, uint16_t status) noexcept { blk(status); }));
  }

  void queryControllerAvailable(uint64_t targetEntityID,
                                void (^cb)(uint16_t)) const noexcept {
    if (!agg_) { fireFailureCallback(cb, kInternalError); return; }
    agg_->queryControllerAvailable(
        la::avdecc::UniqueIdentifier(targetEntityID),
        avdeccHandler<la::avdecc::entity::LocalEntity::AemCommandStatus>(
            Block<void, uint16_t>(cb),
            [](auto const& blk, uint16_t status) noexcept { blk(status); }));
  }

  // GET_ASSOCIATION / SET_ASSOCIATION — UniqueIdentifier of the association.
private:
  static auto associationHandler(Block<void, uint16_t, uint64_t> blk) noexcept {
    return avdeccHandler<la::avdecc::entity::LocalEntity::AemCommandStatus>(
        std::move(blk),
        [](auto const& blk, uint16_t status,
           la::avdecc::UniqueIdentifier const assoc) noexcept {
          blk(status, assoc.getValue());
        });
  }

public:
  void setAssociation(uint64_t targetEntityID, uint64_t associationID,
                      void (^cb)(uint16_t, uint64_t)) const noexcept {
    if (!agg_) { fireFailureCallback(cb, kInternalError); return; }
    agg_->setAssociation(
        la::avdecc::UniqueIdentifier(targetEntityID),
        la::avdecc::UniqueIdentifier(associationID),
        associationHandler(Block<void, uint16_t, uint64_t>(cb)));
  }

  void getAssociation(uint64_t targetEntityID,
                      void (^cb)(uint16_t, uint64_t)) const noexcept {
    if (!agg_) { fireFailureCallback(cb, kInternalError); return; }
    agg_->getAssociation(
        la::avdecc::UniqueIdentifier(targetEntityID),
        associationHandler(Block<void, uint16_t, uint64_t>(cb)));
  }

  // GET_MILAN_INFO — Milan-2019 Clause 7.4.1. As of la_avdecc 4.3.x both
  // certificationVersion and specificationVersion are `MilanVersion` (a
  // packed major.minor.patch.build uint32 wrapper); we surface the raw
  // .getValue() word and let the Swift `MilanInfo` decode it.
  void getMilanInfo(uint64_t targetEntityID,
                    void (^cb)(uint16_t /*status*/,
                               uint32_t /*protocolVersion*/,
                               uint32_t /*featuresFlags*/,
                               uint32_t /*certificationVersion*/,
                               uint32_t /*specificationVersion*/)) const noexcept {
    if (!agg_) { fireFailureCallback(cb, kInternalError); return; }
    agg_->getMilanInfo(
        la::avdecc::UniqueIdentifier(targetEntityID),
        avdeccHandler<la::avdecc::entity::LocalEntity::MvuCommandStatus>(
            Block<void, uint16_t, uint32_t, uint32_t, uint32_t, uint32_t>(cb),
            [](auto const& blk, uint16_t status,
               la::avdecc::entity::model::MilanInfo const& info) noexcept {
              blk(status, info.protocolVersion, info.featuresFlags.value(),
                  info.certificationVersion.getValue(),
                  info.specificationVersion.getValue());
            }));
  }

  // GET_COUNTERS family. Each callback delivers a 32-uint32 counters array
  // (raw IEEE1722.1 layout) plus a per-descriptor "valid" bitfield. Swift
  // gets the array by copying out of the borrowed pointer; the bitfield
  // value is the raw uint32 from EnumBitfield::value().
  // `getEntityCounters` has no descriptor index; the per-descriptor
  // variants share `countersImpl<>`.
  void getEntityCounters(uint64_t targetEntityID,
                         void (^cb)(uint16_t /*status*/,
                                    uint32_t /*validCounters*/,
                                    uint32_t const* /*counters[32]*/)) const noexcept {
    if (!agg_) { fireFailureCallback(cb, kInternalError); return; }
    agg_->getEntityCounters(
        la::avdecc::UniqueIdentifier(targetEntityID),
        avdeccHandler<la::avdecc::entity::LocalEntity::AemCommandStatus>(
            Block<void, uint16_t, uint32_t, uint32_t const*>(cb),
            [](auto const& blk, uint16_t status,
               la::avdecc::entity::EntityCounterValidFlags const valid,
               la::avdecc::entity::model::DescriptorCounters const& counters) noexcept {
              blk(status, valid.value(), counters.data());
            }));
  }

  // Per-descriptor GET_COUNTERS family. Each instance varies only by the
  // method name, the descriptor-index la_avdecc type, and the matching
  // ValidFlags bitfield type. Public methods are one-line stubs onto
  // countersImpl<>.
private:
  template <auto Method, typename IndexCxxType, typename ValidFlagsCxxType>
  void countersImpl(uint64_t targetEntityID, uint16_t descriptorIndex,
                    void (^cb)(uint16_t, uint16_t, uint32_t, uint32_t const*)) const noexcept {
    if (!agg_) { fireFailureCallback(cb, kInternalError); return; }
    (agg_.get()->*Method)(
        la::avdecc::UniqueIdentifier(targetEntityID), descriptorIndex,
        avdeccHandler<la::avdecc::entity::LocalEntity::AemCommandStatus>(
            Block<void, uint16_t, uint16_t, uint32_t, uint32_t const*>(cb),
            [](auto const& blk, uint16_t status, IndexCxxType const idx,
               ValidFlagsCxxType const valid,
               la::avdecc::entity::model::DescriptorCounters const& counters) noexcept {
              blk(status, idx, valid.value(), counters.data());
            }));
  }

public:
  void getAvbInterfaceCounters(uint64_t targetEntityID, uint16_t avbInterfaceIndex,
                               void (^cb)(uint16_t, uint16_t, uint32_t, uint32_t const*)) const noexcept {
    countersImpl<&la::avdecc::entity::AggregateEntity::getAvbInterfaceCounters,
                 la::avdecc::entity::model::AvbInterfaceIndex,
                 la::avdecc::entity::AvbInterfaceCounterValidFlags>(
        targetEntityID, avbInterfaceIndex, cb);
  }
  void getClockDomainCounters(uint64_t targetEntityID, uint16_t clockDomainIndex,
                              void (^cb)(uint16_t, uint16_t, uint32_t, uint32_t const*)) const noexcept {
    countersImpl<&la::avdecc::entity::AggregateEntity::getClockDomainCounters,
                 la::avdecc::entity::model::ClockDomainIndex,
                 la::avdecc::entity::ClockDomainCounterValidFlags>(
        targetEntityID, clockDomainIndex, cb);
  }
  void getStreamInputCounters(uint64_t targetEntityID, uint16_t streamIndex,
                              void (^cb)(uint16_t, uint16_t, uint32_t, uint32_t const*)) const noexcept {
    countersImpl<&la::avdecc::entity::AggregateEntity::getStreamInputCounters,
                 la::avdecc::entity::model::StreamIndex,
                 la::avdecc::entity::StreamInputCounterValidFlags>(
        targetEntityID, streamIndex, cb);
  }
  void getStreamOutputCounters(uint64_t targetEntityID, uint16_t streamIndex,
                               void (^cb)(uint16_t, uint16_t, uint32_t, uint32_t const*)) const noexcept {
    countersImpl<&la::avdecc::entity::AggregateEntity::getStreamOutputCounters,
                 la::avdecc::entity::model::StreamIndex,
                 la::avdecc::entity::StreamOutputCounterValidFlags>(
        targetEntityID, streamIndex, cb);
  }

  // REBOOT and REBOOT_TO_FIRMWARE — both async, both report just an AEM
  // status. la_avdecc's REBOOT_TO_FIRMWARE handler also echoes the memory
  // object index that was rebooted to; we drop it on the Swift side because
  // it always equals the input.
  void reboot(uint64_t targetEntityID, void (^cb)(uint16_t)) const noexcept {
    if (!agg_) { fireFailureCallback(cb, kInternalError); return; }
    agg_->reboot(
        la::avdecc::UniqueIdentifier(targetEntityID),
        avdeccHandler<la::avdecc::entity::LocalEntity::AemCommandStatus>(
            Block<void, uint16_t>(cb),
            [](auto const& blk, uint16_t status) noexcept { blk(status); }));
  }

  void rebootToFirmware(uint64_t targetEntityID, uint16_t memoryObjectIndex,
                        void (^cb)(uint16_t)) const noexcept {
    if (!agg_) { fireFailureCallback(cb, kInternalError); return; }
    agg_->rebootToFirmware(
        la::avdecc::UniqueIdentifier(targetEntityID),
        la::avdecc::entity::model::MemoryObjectIndex(memoryObjectIndex),
        avdeccHandler<la::avdecc::entity::LocalEntity::AemCommandStatus>(
            Block<void, uint16_t>(cb),
            [](auto const& blk, uint16_t status,
               la::avdecc::entity::model::MemoryObjectIndex const) noexcept {
              blk(status);
            }));
  }

  // ACMP connection management. la_avdecc takes/returns
  // `StreamIdentification` (entityID + streamIndex pair); we flatten to
  // two u64/u16 arguments. The status here is `ControlStatus` (ACMP),
  // distinct from `AemCommandStatus`. The callback always delivers both
  // talker and listener identification because disconnectTalkerStream may
  // target a different listener than the caller expected.
  //
  // Two implementation templates: connect/disconnect/disconnectTalker
  // share the (talker, listener, cb) shape (acmpPairImpl); the two
  // get-state methods take only one stream identification (acmpStateImpl).
  // getTalkerStreamConnection has a unique extra `connectionIndex` and
  // stays expanded below.
private:
  // Shared lambda body — flatten the pair of StreamIdentifications back
  // into (talkerID, talkerIdx, listenerID, listenerIdx) plus the rest.
  using AcmpBlock = Block<void, uint16_t, uint64_t, uint16_t,
                          uint64_t, uint16_t, uint16_t, uint16_t>;

  static auto acmpHandler(AcmpBlock blk) noexcept {
    return [blk = std::move(blk)](
        la::avdecc::entity::controller::Interface const* const,
        la::avdecc::entity::model::StreamIdentification const& t,
        la::avdecc::entity::model::StreamIdentification const& l,
        uint16_t const count,
        la::avdecc::entity::ConnectionFlags const flags,
        la::avdecc::entity::LocalEntity::ControlStatus const status) {
      if (blk) blk(static_cast<uint16_t>(status),
                   t.entityID.getValue(), t.streamIndex,
                   l.entityID.getValue(), l.streamIndex,
                   count, flags.value());
    };
  }

  template <auto Method>
  void acmpPairImpl(uint64_t talkerEntityID, uint16_t talkerStreamIndex,
                    uint64_t listenerEntityID, uint16_t listenerStreamIndex,
                    void (^cb)(uint16_t, uint64_t, uint16_t,
                               uint64_t, uint16_t, uint16_t, uint16_t)) const noexcept {
    if (!agg_) { fireFailureCallback(cb, kInternalError); return; }
    la::avdecc::entity::model::StreamIdentification talker{
        la::avdecc::UniqueIdentifier(talkerEntityID), talkerStreamIndex};
    la::avdecc::entity::model::StreamIdentification listener{
        la::avdecc::UniqueIdentifier(listenerEntityID), listenerStreamIndex};
    (agg_.get()->*Method)(talker, listener, acmpHandler(AcmpBlock(cb)));
  }

  template <auto Method>
  void acmpStateImpl(uint64_t entityID, uint16_t streamIndex,
                     void (^cb)(uint16_t, uint64_t, uint16_t,
                                uint64_t, uint16_t, uint16_t, uint16_t)) const noexcept {
    if (!agg_) { fireFailureCallback(cb, kInternalError); return; }
    la::avdecc::entity::model::StreamIdentification stream{
        la::avdecc::UniqueIdentifier(entityID), streamIndex};
    (agg_.get()->*Method)(stream, acmpHandler(AcmpBlock(cb)));
  }

public:
  void connectStream(uint64_t talkerEntityID, uint16_t talkerStreamIndex,
                     uint64_t listenerEntityID, uint16_t listenerStreamIndex,
                     void (^cb)(uint16_t /*status*/,
                                uint64_t /*talkerEntityID*/, uint16_t /*talkerStreamIndex*/,
                                uint64_t /*listenerEntityID*/, uint16_t /*listenerStreamIndex*/,
                                uint16_t /*connectionCount*/,
                                uint16_t /*connectionFlags*/)) const noexcept {
    acmpPairImpl<&la::avdecc::entity::AggregateEntity::connectStream>(
        talkerEntityID, talkerStreamIndex, listenerEntityID, listenerStreamIndex, cb);
  }
  void disconnectStream(uint64_t talkerEntityID, uint16_t talkerStreamIndex,
                        uint64_t listenerEntityID, uint16_t listenerStreamIndex,
                        void (^cb)(uint16_t, uint64_t, uint16_t,
                                   uint64_t, uint16_t, uint16_t, uint16_t)) const noexcept {
    acmpPairImpl<&la::avdecc::entity::AggregateEntity::disconnectStream>(
        talkerEntityID, talkerStreamIndex, listenerEntityID, listenerStreamIndex, cb);
  }
  void disconnectTalkerStream(uint64_t talkerEntityID, uint16_t talkerStreamIndex,
                              uint64_t listenerEntityID, uint16_t listenerStreamIndex,
                              void (^cb)(uint16_t, uint64_t, uint16_t,
                                         uint64_t, uint16_t, uint16_t, uint16_t)) const noexcept {
    acmpPairImpl<&la::avdecc::entity::AggregateEntity::disconnectTalkerStream>(
        talkerEntityID, talkerStreamIndex, listenerEntityID, listenerStreamIndex, cb);
  }
  void getTalkerStreamState(uint64_t talkerEntityID, uint16_t talkerStreamIndex,
                            void (^cb)(uint16_t, uint64_t, uint16_t,
                                       uint64_t, uint16_t, uint16_t, uint16_t)) const noexcept {
    acmpStateImpl<&la::avdecc::entity::AggregateEntity::getTalkerStreamState>(
        talkerEntityID, talkerStreamIndex, cb);
  }
  void getListenerStreamState(uint64_t listenerEntityID, uint16_t listenerStreamIndex,
                              void (^cb)(uint16_t, uint64_t, uint16_t,
                                         uint64_t, uint16_t, uint16_t, uint16_t)) const noexcept {
    acmpStateImpl<&la::avdecc::entity::AggregateEntity::getListenerStreamState>(
        listenerEntityID, listenerStreamIndex, cb);
  }

  // Additional descriptor reads. STREAM_PORT_INPUT and STREAM_PORT_OUTPUT
  // share `StreamPortDescriptor`; same for AUDIO_MAP / CONTROL / TIMING /
  // PTP_INSTANCE / PTP_PORT and EXTERNAL_PORT_{INPUT,OUTPUT} (same struct,
  // distinct read entry points).

  void readStreamPortInputDescriptor(uint64_t e, uint16_t c, uint16_t i,
      void (^cb)(uint16_t, uint16_t,
                 la::avdecc::entity::model::StreamPortDescriptor const*)) const noexcept {
    readDescImpl<&la::avdecc::entity::AggregateEntity::readStreamPortInputDescriptor,
                 la::avdecc::entity::model::StreamPortIndex,
                 la::avdecc::entity::model::StreamPortDescriptor>(e, c, i, cb);
  }
  void readStreamPortOutputDescriptor(uint64_t e, uint16_t c, uint16_t i,
      void (^cb)(uint16_t, uint16_t,
                 la::avdecc::entity::model::StreamPortDescriptor const*)) const noexcept {
    readDescImpl<&la::avdecc::entity::AggregateEntity::readStreamPortOutputDescriptor,
                 la::avdecc::entity::model::StreamPortIndex,
                 la::avdecc::entity::model::StreamPortDescriptor>(e, c, i, cb);
  }
  void readExternalPortInputDescriptor(uint64_t e, uint16_t c, uint16_t i,
      void (^cb)(uint16_t, uint16_t,
                 la::avdecc::entity::model::ExternalPortDescriptor const*)) const noexcept {
    readDescImpl<&la::avdecc::entity::AggregateEntity::readExternalPortInputDescriptor,
                 la::avdecc::entity::model::ExternalPortIndex,
                 la::avdecc::entity::model::ExternalPortDescriptor>(e, c, i, cb);
  }
  void readExternalPortOutputDescriptor(uint64_t e, uint16_t c, uint16_t i,
      void (^cb)(uint16_t, uint16_t,
                 la::avdecc::entity::model::ExternalPortDescriptor const*)) const noexcept {
    readDescImpl<&la::avdecc::entity::AggregateEntity::readExternalPortOutputDescriptor,
                 la::avdecc::entity::model::ExternalPortIndex,
                 la::avdecc::entity::model::ExternalPortDescriptor>(e, c, i, cb);
  }
  void readInternalPortInputDescriptor(uint64_t e, uint16_t c, uint16_t i,
      void (^cb)(uint16_t, uint16_t,
                 la::avdecc::entity::model::InternalPortDescriptor const*)) const noexcept {
    readDescImpl<&la::avdecc::entity::AggregateEntity::readInternalPortInputDescriptor,
                 la::avdecc::entity::model::InternalPortIndex,
                 la::avdecc::entity::model::InternalPortDescriptor>(e, c, i, cb);
  }
  void readInternalPortOutputDescriptor(uint64_t e, uint16_t c, uint16_t i,
      void (^cb)(uint16_t, uint16_t,
                 la::avdecc::entity::model::InternalPortDescriptor const*)) const noexcept {
    readDescImpl<&la::avdecc::entity::AggregateEntity::readInternalPortOutputDescriptor,
                 la::avdecc::entity::model::InternalPortIndex,
                 la::avdecc::entity::model::InternalPortDescriptor>(e, c, i, cb);
  }
  void readAudioMapDescriptor(uint64_t e, uint16_t c, uint16_t i,
      void (^cb)(uint16_t, uint16_t,
                 la::avdecc::entity::model::AudioMapDescriptor const*)) const noexcept {
    readDescImpl<&la::avdecc::entity::AggregateEntity::readAudioMapDescriptor,
                 la::avdecc::entity::model::MapIndex,
                 la::avdecc::entity::model::AudioMapDescriptor>(e, c, i, cb);
  }
  void readControlDescriptor(uint64_t e, uint16_t c, uint16_t i,
      void (^cb)(uint16_t, uint16_t,
                 la::avdecc::entity::model::ControlDescriptor const*)) const noexcept {
    readDescImpl<&la::avdecc::entity::AggregateEntity::readControlDescriptor,
                 la::avdecc::entity::model::ControlIndex,
                 la::avdecc::entity::model::ControlDescriptor>(e, c, i, cb);
  }
  void readTimingDescriptor(uint64_t e, uint16_t c, uint16_t i,
      void (^cb)(uint16_t, uint16_t,
                 la::avdecc::entity::model::TimingDescriptor const*)) const noexcept {
    readDescImpl<&la::avdecc::entity::AggregateEntity::readTimingDescriptor,
                 la::avdecc::entity::model::TimingIndex,
                 la::avdecc::entity::model::TimingDescriptor>(e, c, i, cb);
  }
  void readPtpInstanceDescriptor(uint64_t e, uint16_t c, uint16_t i,
      void (^cb)(uint16_t, uint16_t,
                 la::avdecc::entity::model::PtpInstanceDescriptor const*)) const noexcept {
    readDescImpl<&la::avdecc::entity::AggregateEntity::readPtpInstanceDescriptor,
                 la::avdecc::entity::model::PtpInstanceIndex,
                 la::avdecc::entity::model::PtpInstanceDescriptor>(e, c, i, cb);
  }
  void readPtpPortDescriptor(uint64_t e, uint16_t c, uint16_t i,
      void (^cb)(uint16_t, uint16_t,
                 la::avdecc::entity::model::PtpPortDescriptor const*)) const noexcept {
    readDescImpl<&la::avdecc::entity::AggregateEntity::readPtpPortDescriptor,
                 la::avdecc::entity::model::PtpPortIndex,
                 la::avdecc::entity::model::PtpPortDescriptor>(e, c, i, cb);
  }

  // GET_AUDIO_MAP / ADD_AUDIO_MAPPINGS / REMOVE_AUDIO_MAPPINGS. Mappings
  // travel across the ABI as (AudioMapping const* data, size_t count) — the
  // four u16 fields of AudioMapping are POD so we hand the raw vector data
  // pointer to Swift, which copies. For add/remove, Swift hands us back the
  // same shape and we reconstruct a std::vector<AudioMapping>.
  // Public methods are 1-line stubs onto getAudioMapImpl<>/modifyAudioMapImpl<>.
private:
  template <auto Method>
  void getAudioMapImpl(
      uint64_t targetEntityID, uint16_t streamPortIndex, uint16_t mapIndex,
      void (^cb)(uint16_t, uint16_t, uint16_t, uint16_t,
                 la::avdecc::entity::model::AudioMapping const*, size_t)) const noexcept {
    if (!agg_) { fireFailureCallback(cb, kInternalError); return; }
    (agg_.get()->*Method)(
        la::avdecc::UniqueIdentifier(targetEntityID), streamPortIndex, mapIndex,
        avdeccHandler<la::avdecc::entity::LocalEntity::AemCommandStatus>(
            Block<void, uint16_t, uint16_t, uint16_t, uint16_t,
                  la::avdecc::entity::model::AudioMapping const*, size_t>(cb),
            [](auto const& blk, uint16_t status,
               la::avdecc::entity::model::StreamPortIndex const sp,
               la::avdecc::entity::model::MapIndex const numMaps,
               la::avdecc::entity::model::MapIndex const mi,
               la::avdecc::entity::model::AudioMappings const& mappings) noexcept {
              blk(status, sp, numMaps, mi, mappings.data(), mappings.size());
            }));
  }

  template <auto Method>
  void modifyAudioMapImpl(
      uint64_t targetEntityID, uint16_t streamPortIndex,
      la::avdecc::entity::model::AudioMapping const* mappingsData, size_t mappingsCount,
      void (^cb)(uint16_t, uint16_t,
                 la::avdecc::entity::model::AudioMapping const*, size_t)) const noexcept {
    if (!agg_) { fireFailureCallback(cb, kInternalError); return; }
    la::avdecc::entity::model::AudioMappings mappings(
        mappingsData, mappingsData + mappingsCount);
    (agg_.get()->*Method)(
        la::avdecc::UniqueIdentifier(targetEntityID), streamPortIndex, mappings,
        avdeccHandler<la::avdecc::entity::LocalEntity::AemCommandStatus>(
            Block<void, uint16_t, uint16_t,
                  la::avdecc::entity::model::AudioMapping const*, size_t>(cb),
            [](auto const& blk, uint16_t status,
               la::avdecc::entity::model::StreamPortIndex const sp,
               la::avdecc::entity::model::AudioMappings const& m) noexcept {
              blk(status, sp, m.data(), m.size());
            }));
  }

public:
  void getStreamPortInputAudioMap(uint64_t e, uint16_t sp, uint16_t mi,
      void (^cb)(uint16_t, uint16_t, uint16_t, uint16_t,
                 la::avdecc::entity::model::AudioMapping const*, size_t)) const noexcept {
    getAudioMapImpl<&la::avdecc::entity::AggregateEntity::getStreamPortInputAudioMap>(
        e, sp, mi, cb);
  }
  void addStreamPortInputAudioMappings(uint64_t e, uint16_t sp,
      la::avdecc::entity::model::AudioMapping const* d, size_t n,
      void (^cb)(uint16_t, uint16_t,
                 la::avdecc::entity::model::AudioMapping const*, size_t)) const noexcept {
    modifyAudioMapImpl<&la::avdecc::entity::AggregateEntity::addStreamPortInputAudioMappings>(
        e, sp, d, n, cb);
  }
  void removeStreamPortInputAudioMappings(uint64_t e, uint16_t sp,
      la::avdecc::entity::model::AudioMapping const* d, size_t n,
      void (^cb)(uint16_t, uint16_t,
                 la::avdecc::entity::model::AudioMapping const*, size_t)) const noexcept {
    modifyAudioMapImpl<&la::avdecc::entity::AggregateEntity::removeStreamPortInputAudioMappings>(
        e, sp, d, n, cb);
  }

  void getStreamPortOutputAudioMap(uint64_t e, uint16_t sp, uint16_t mi,
      void (^cb)(uint16_t, uint16_t, uint16_t, uint16_t,
                 la::avdecc::entity::model::AudioMapping const*, size_t)) const noexcept {
    getAudioMapImpl<&la::avdecc::entity::AggregateEntity::getStreamPortOutputAudioMap>(
        e, sp, mi, cb);
  }
  void addStreamPortOutputAudioMappings(uint64_t e, uint16_t sp,
      la::avdecc::entity::model::AudioMapping const* d, size_t n,
      void (^cb)(uint16_t, uint16_t,
                 la::avdecc::entity::model::AudioMapping const*, size_t)) const noexcept {
    modifyAudioMapImpl<&la::avdecc::entity::AggregateEntity::addStreamPortOutputAudioMappings>(
        e, sp, d, n, cb);
  }
  void removeStreamPortOutputAudioMappings(uint64_t e, uint16_t sp,
      la::avdecc::entity::model::AudioMapping const* d, size_t n,
      void (^cb)(uint16_t, uint16_t,
                 la::avdecc::entity::model::AudioMapping const*, size_t)) const noexcept {
    modifyAudioMapImpl<&la::avdecc::entity::AggregateEntity::removeStreamPortOutputAudioMappings>(
        e, sp, d, n, cb);
  }

  // getTalkerStreamConnection has a unique extra `connectionIndex` arg
  // before the handler. The handler is the same shape as connect/disconnect/
  // state, so it shares acmpHandler.
  void getTalkerStreamConnection(uint64_t talkerEntityID, uint16_t talkerStreamIndex,
                                 uint16_t connectionIndex,
                                 void (^cb)(uint16_t, uint64_t, uint16_t, uint64_t, uint16_t,
                                            uint16_t, uint16_t)) const noexcept {
    if (!agg_) { fireFailureCallback(cb, kInternalError); return; }
    la::avdecc::entity::model::StreamIdentification talker{
        la::avdecc::UniqueIdentifier(talkerEntityID), talkerStreamIndex};
    agg_->getTalkerStreamConnection(
        talker, connectionIndex, acmpHandler(AcmpBlock(cb)));
  }

  // ==========================================================================
  // Milan MVU commands (MvuCommandStatus). la_avdecc dispatches these as
  // AECP-MVU PDUs but the public C++ surface lives on the same Aggregate-
  // Entity as the AEM commands above.
  // ==========================================================================

  // BIND_STREAM / UNBIND_STREAM — Milan 1.3 Clause 5.4.4.6/5.4.4.7. Bind a
  // listener stream to a talker (id+streamIdx) with flags; unbind clears the
  // binding. la_avdecc surfaces the talker as a StreamIdentification, which
  // we flatten to (uint64_t entityID, uint16_t streamIndex) for Swift.
  // BindStreamFlags is a 16-bit EnumBitfield; we move the raw word in/out
  // via .assign()/.value().
  void bindStream(uint64_t targetEntityID, uint16_t streamIndex,
                  uint64_t talkerEntityID, uint16_t talkerStreamIndex,
                  uint16_t flagsRaw,
                  void (^cb)(uint16_t /*status*/, uint16_t /*streamIndex*/,
                             uint64_t /*talkerEntityID*/,
                             uint16_t /*talkerStreamIndex*/,
                             uint16_t /*flags*/)) const noexcept {
    if (!agg_) { fireFailureCallback(cb, kInternalError); return; }
    la::avdecc::entity::model::StreamIdentification talker{
        la::avdecc::UniqueIdentifier(talkerEntityID), talkerStreamIndex};
    la::avdecc::entity::BindStreamFlags flags;
    flags.assign(flagsRaw);
    agg_->bindStream(
        la::avdecc::UniqueIdentifier(targetEntityID),
        streamIndex, talker, flags,
        avdeccHandler<la::avdecc::entity::LocalEntity::MvuCommandStatus>(
            Block<void, uint16_t, uint16_t, uint64_t, uint16_t, uint16_t>(cb),
            [](auto const& blk, uint16_t status,
               la::avdecc::entity::model::StreamIndex const idx,
               la::avdecc::entity::model::StreamIdentification const& t,
               la::avdecc::entity::BindStreamFlags const f) noexcept {
              blk(status, idx, t.entityID.getValue(), t.streamIndex, f.value());
            }));
  }

  void unbindStream(uint64_t targetEntityID, uint16_t streamIndex,
                    void (^cb)(uint16_t /*status*/,
                               uint16_t /*streamIndex*/)) const noexcept {
    if (!agg_) { fireFailureCallback(cb, kInternalError); return; }
    agg_->unbindStream(
        la::avdecc::UniqueIdentifier(targetEntityID), streamIndex,
        avdeccHandler<la::avdecc::entity::LocalEntity::MvuCommandStatus>(
            Block<void, uint16_t, uint16_t>(cb),
            [](auto const& blk, uint16_t status,
               la::avdecc::entity::model::StreamIndex const idx) noexcept {
              blk(status, idx);
            }));
  }

  // GET/SET_SYSTEM_UNIQUE_ID — Milan 1.3 Clause 5.4.4.10. Pair-symmetric
  // handler shape; both trail (UniqueIdentifier systemUniqueID,
  // AvdeccFixedString systemName).
  void getSystemUniqueID(
      uint64_t targetEntityID,
      void (^cb)(uint16_t /*status*/, uint64_t /*systemUniqueID*/,
                 la::avdecc::entity::model::AvdeccFixedString const* /*systemName*/))
      const noexcept {
    if (!agg_) { fireFailureCallback(cb, kInternalError); return; }
    agg_->getSystemUniqueID(
        la::avdecc::UniqueIdentifier(targetEntityID),
        avdeccHandler<la::avdecc::entity::LocalEntity::MvuCommandStatus>(
            Block<void, uint16_t, uint64_t,
                  la::avdecc::entity::model::AvdeccFixedString const*>(cb),
            [](auto const& blk, uint16_t status,
               la::avdecc::UniqueIdentifier const sys,
               la::avdecc::entity::model::AvdeccFixedString const& name) noexcept {
              blk(status, sys.getValue(), &name);
            }));
  }

  void setSystemUniqueID(
      uint64_t targetEntityID, uint64_t systemUniqueID,
      void const* nameBytes, size_t nameLen,
      void (^cb)(uint16_t /*status*/, uint64_t /*systemUniqueID*/,
                 la::avdecc::entity::model::AvdeccFixedString const* /*systemName*/))
      const noexcept {
    if (!agg_) { fireFailureCallback(cb, kInternalError); return; }
    la::avdecc::entity::model::AvdeccFixedString fixed(
        nameBytes ? nameBytes : "", nameBytes ? nameLen : 0);
    agg_->setSystemUniqueID(
        la::avdecc::UniqueIdentifier(targetEntityID),
        la::avdecc::UniqueIdentifier(systemUniqueID), fixed,
        avdeccHandler<la::avdecc::entity::LocalEntity::MvuCommandStatus>(
            Block<void, uint16_t, uint64_t,
                  la::avdecc::entity::model::AvdeccFixedString const*>(cb),
            [](auto const& blk, uint16_t status,
               la::avdecc::UniqueIdentifier const sys,
               la::avdecc::entity::model::AvdeccFixedString const& name) noexcept {
              blk(status, sys.getValue(), &name);
            }));
  }

  // GET_STREAM_INPUT_INFO_EX — Milan 1.3 Clause 5.4.4.8. Same handler shape
  // as the AEM getStreamInputInfo getter but reports the resolved talker
  // identification + ProbingStatus + AcmpStatus (StreamInputInfoEx).
  void getStreamInputInfoEx(
      uint64_t targetEntityID, uint16_t streamIndex,
      void (^cb)(uint16_t /*status*/, uint16_t /*streamIndex*/,
                 la::avdecc::entity::model::StreamInputInfoEx const* /*info*/))
      const noexcept {
    if (!agg_) { fireFailureCallback(cb, kInternalError); return; }
    agg_->getStreamInputInfoEx(
        la::avdecc::UniqueIdentifier(targetEntityID), streamIndex,
        avdeccHandler<la::avdecc::entity::LocalEntity::MvuCommandStatus>(
            Block<void, uint16_t, uint16_t,
                  la::avdecc::entity::model::StreamInputInfoEx const*>(cb),
            [](auto const& blk, uint16_t status,
               la::avdecc::entity::model::StreamIndex const idx,
               la::avdecc::entity::model::StreamInputInfoEx const& info) noexcept {
              blk(status, idx, &info);
            }));
  }

  // GET/SET_MEDIA_CLOCK_REFERENCE_INFO — Milan 1.3 Clause 5.4.4.5. The set
  // payload uses two std::optional<>s (userPriority, domainName); we flatten
  // each to a (bool present, value) pair across the ABI. The response
  // handler trails (clockDomainIndex, DefaultMediaClockReferencePriority,
  // MediaClockReferenceInfo) — and MediaClockReferenceInfo's two fields are
  // also optional, so the surface to Swift is symmetric: present-flag plus
  // value (priority as u8, name as borrowed-AvdeccFixedString-or-null).
private:
  using McrInfoBlock =
      Block<void, uint16_t, uint16_t, uint8_t, bool, uint8_t, bool,
            la::avdecc::entity::model::AvdeccFixedString const*>;

  static auto mcrInfoHandler(McrInfoBlock blk) noexcept {
    return [blk = std::move(blk)](
        la::avdecc::entity::controller::Interface const* const,
        la::avdecc::UniqueIdentifier const,
        la::avdecc::entity::LocalEntity::MvuCommandStatus const status,
        la::avdecc::entity::model::ClockDomainIndex const idx,
        la::avdecc::entity::model::DefaultMediaClockReferencePriority const def,
        la::avdecc::entity::model::MediaClockReferenceInfo const& info) noexcept {
      if (!blk) return;
      auto const hasPrio = info.userMediaClockPriority.has_value();
      auto const prio = hasPrio
          ? *info.userMediaClockPriority
          : la::avdecc::entity::model::MediaClockReferencePriority{0u};
      auto const hasName = info.mediaClockDomainName.has_value();
      blk(static_cast<uint16_t>(status), idx,
          static_cast<uint8_t>(def),
          hasPrio, prio,
          hasName, hasName ? &(*info.mediaClockDomainName) : nullptr);
    };
  }

public:
  void getMediaClockReferenceInfo(
      uint64_t targetEntityID, uint16_t clockDomainIndex,
      void (^cb)(uint16_t /*status*/, uint16_t /*clockDomainIndex*/,
                 uint8_t /*defaultPriority*/,
                 bool /*hasUserPriority*/, uint8_t /*userPriority*/,
                 bool /*hasDomainName*/,
                 la::avdecc::entity::model::AvdeccFixedString const* /*domainName*/))
      const noexcept {
    if (!agg_) { fireFailureCallback(cb, kInternalError); return; }
    agg_->getMediaClockReferenceInfo(
        la::avdecc::UniqueIdentifier(targetEntityID), clockDomainIndex,
        mcrInfoHandler(McrInfoBlock(cb)));
  }

  void setMediaClockReferenceInfo(
      uint64_t targetEntityID, uint16_t clockDomainIndex,
      bool hasUserPriority, uint8_t userPriority,
      bool hasDomainName, void const* domainNameBytes, size_t domainNameLen,
      void (^cb)(uint16_t, uint16_t, uint8_t, bool, uint8_t, bool,
                 la::avdecc::entity::model::AvdeccFixedString const*))
      const noexcept {
    if (!agg_) { fireFailureCallback(cb, kInternalError); return; }
    std::optional<la::avdecc::entity::model::MediaClockReferencePriority> prio;
    if (hasUserPriority) prio = userPriority;
    std::optional<la::avdecc::entity::model::AvdeccFixedString> name;
    if (hasDomainName) {
      name = la::avdecc::entity::model::AvdeccFixedString(
          domainNameBytes ? domainNameBytes : "",
          domainNameBytes ? domainNameLen : 0);
    }
    agg_->setMediaClockReferenceInfo(
        la::avdecc::UniqueIdentifier(targetEntityID), clockDomainIndex,
        prio, name, mcrInfoHandler(McrInfoBlock(cb)));
  }

  // ==========================================================================
  // Operations (AEM) — IEEE1722.1-2013 Clause 7.4.53.
  // ==========================================================================

  // ABORT_OPERATION — handler trails (descType, descIdx, OperationID).
  void abortOperation(
      uint64_t targetEntityID, uint16_t descriptorType,
      uint16_t descriptorIndex, uint16_t operationID,
      void (^cb)(uint16_t /*status*/, uint16_t /*descType*/,
                 uint16_t /*descIdx*/, uint16_t /*operationID*/)) const noexcept {
    if (!agg_) { fireFailureCallback(cb, kInternalError); return; }
    agg_->abortOperation(
        la::avdecc::UniqueIdentifier(targetEntityID),
        static_cast<la::avdecc::entity::model::DescriptorType>(descriptorType),
        descriptorIndex, operationID,
        avdeccHandler<la::avdecc::entity::LocalEntity::AemCommandStatus>(
            Block<void, uint16_t, uint16_t, uint16_t, uint16_t>(cb),
            [](auto const& blk, uint16_t status,
               la::avdecc::entity::model::DescriptorType const dt,
               la::avdecc::entity::model::DescriptorIndex const di,
               la::avdecc::entity::model::OperationID const op) noexcept {
              blk(status, static_cast<uint16_t>(dt), di, op);
            }));
  }

  // START_OPERATION — payload travels both ways as MemoryBuffer; we expose
  // it across the ABI as (bytes, len). The MemoryBuffer ctor we use does a
  // memcpy on the request (so the caller's buffer needn't outlive this
  // call); the response payload pointer is borrowed and only valid while
  // the block runs.
  void startOperation(
      uint64_t targetEntityID, uint16_t descriptorType,
      uint16_t descriptorIndex, uint16_t operationType,
      void const* requestPayload, size_t requestPayloadLen,
      void (^cb)(uint16_t /*status*/, uint16_t /*descType*/,
                 uint16_t /*descIdx*/, uint16_t /*operationID*/,
                 uint16_t /*operationType*/,
                 uint8_t const* /*payload*/, size_t /*payloadLen*/)) const noexcept {
    if (!agg_) { fireFailureCallback(cb, kInternalError); return; }
    la::avdecc::MemoryBuffer mb;
    if (requestPayload && requestPayloadLen > 0) {
      mb.assign(requestPayload, requestPayloadLen);
    }
    agg_->startOperation(
        la::avdecc::UniqueIdentifier(targetEntityID),
        static_cast<la::avdecc::entity::model::DescriptorType>(descriptorType),
        descriptorIndex,
        static_cast<la::avdecc::entity::model::MemoryObjectOperationType>(operationType),
        mb,
        avdeccHandler<la::avdecc::entity::LocalEntity::AemCommandStatus>(
            Block<void, uint16_t, uint16_t, uint16_t, uint16_t, uint16_t,
                  uint8_t const*, size_t>(cb),
            [](auto const& blk, uint16_t status,
               la::avdecc::entity::model::DescriptorType const dt,
               la::avdecc::entity::model::DescriptorIndex const di,
               la::avdecc::entity::model::OperationID const op,
               la::avdecc::entity::model::MemoryObjectOperationType const ot,
               la::avdecc::MemoryBuffer const& payload) noexcept {
              blk(status, static_cast<uint16_t>(dt), di, op,
                  static_cast<uint16_t>(ot),
                  payload.data(), payload.size());
            }));
  }

private:
  friend class IntrusiveReferenceCounted<LocalEntityOwner>;
  LocalEntityOwner(ProtocolInterfaceOwner* piOwner,
                   la::avdecc::entity::AggregateEntity::UniquePointer agg) noexcept
      : piOwner_(piOwner), agg_(std::move(agg)) {
    if (piOwner_) AVDECCSwift_ProtocolInterfaceOwner_retain(piOwner_);
  }
  ~LocalEntityOwner() noexcept {
    close();
    if (piOwner_) AVDECCSwift_ProtocolInterfaceOwner_release(piOwner_);
  }

  // Strong reference to the PI owner — its underlying ProtocolInterface
  // must outlive the LocalEntity. Manual retain/release because the C++
  // side doesn't have Swift's ARC; we use the same retain/release
  // functions Swift uses.
  ProtocolInterfaceOwner* piOwner_;
  la::avdecc::entity::AggregateEntity::UniquePointer agg_;
  // Controller-delegate adapter. Always present; only attached to the
  // AggregateEntity when the Swift side has registered at least one
  // callback. `attachDelegate()` flips it on, `close()` and
  // `detachDelegate()` flip it off.
  BlockControllerDelegate delegate_;
  bool delegateAttached_ = false;
};

} // namespace AVDECCSwift

// retain/release definitions for every SWIFT_SHARED_REFERENCE owner.
// At translation-unit scope (Swift's importer parses the swift_attr
// retain/release names as top-level identifiers); inline so each TU
// gets a single symbol without ODR conflicts.
template <typename T>
inline void _avdeccswift_retain(T* p) noexcept { if (p) p->retain(); }
template <typename T>
inline void _avdeccswift_release(T* p) noexcept { if (p) p->release(); }

inline void AVDECCSwift_ExecutorOwner_retain(AVDECCSwift::ExecutorOwner* p) noexcept {
  _avdeccswift_retain(p);
}
inline void AVDECCSwift_ExecutorOwner_release(AVDECCSwift::ExecutorOwner* p) noexcept {
  _avdeccswift_release(p);
}

inline void AVDECCSwift_LoggerOwner_retain(AVDECCSwift::LoggerOwner* p) noexcept {
  _avdeccswift_retain(p);
}
inline void AVDECCSwift_LoggerOwner_release(AVDECCSwift::LoggerOwner* p) noexcept {
  _avdeccswift_release(p);
}

inline void AVDECCSwift_ProtocolInterfaceOwner_retain(AVDECCSwift::ProtocolInterfaceOwner* p) noexcept {
  _avdeccswift_retain(p);
}
inline void AVDECCSwift_ProtocolInterfaceOwner_release(AVDECCSwift::ProtocolInterfaceOwner* p) noexcept {
  _avdeccswift_release(p);
}

inline void AVDECCSwift_LocalEntityOwner_retain(AVDECCSwift::LocalEntityOwner* p) noexcept {
  _avdeccswift_retain(p);
}
inline void AVDECCSwift_LocalEntityOwner_release(AVDECCSwift::LocalEntityOwner* p) noexcept {
  _avdeccswift_release(p);
}
