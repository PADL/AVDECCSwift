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

// AVDECCSwift::Block<Ret, Args...> — RAII wrapper around a clang block,
// driving Block_copy on store and Block_release on destroy. Adapted from the
// pre-existing CAVDECC::Block<> in CAVDECCBlockShimsInternal.hpp; that file
// (and the rest of the CAVDECC C-binding shims) is slated for removal once
// the C++-interop migration is complete, so the template is hoisted here to
// keep the new helpers free of any CAVDECC includes.
//
// Why this is required: when Swift converts a closure to @convention(block),
// the block is owned by the surrounding Swift closure object. If C++ stores
// the bare block pointer past the call returning, the Swift closure dies and
// the block becomes dangling — the next invocation jumps to garbage. Block_
// copy promotes a stack/Swift-bridged block to a refcounted heap block; the
// matching Block_release frees it.
//
// Notes vs. CAVDECC::Block<>:
//   * No conditional ternary on block types. Clang block types and nullptr
//     have no common type for `?:` deduction (no implicit conversion in the
//     deducing direction), so we direct-init the member then call Block_copy
//     under an `if (block_)` guard.
//   * _Block_copy's return value is discarded. For Swift-bridged blocks (and
//     all other heap-allocated blocks the runtime hands back) Block_copy
//     bumps the refcount and returns the same pointer, so storing the input
//     pointer is correct in our use case. Stack blocks would need the
//     return value, but Swift never produces those.
#pragma once

#include <utility>

// Clang blocks must be enabled (-fblocks). Fail fast with a clear message
// rather than letting the `^` syntax below produce a wall of cryptic C++
// parse errors.
#if !defined(__BLOCKS__)
#  error "AVDECCSwift requires Clang blocks support; build CxxAVDECC with -fblocks"
#endif

#if __has_include(<Block.h>)
#  include <Block.h>
#elif __has_include(<Block/Block.h>)
#  include <Block/Block.h>
#else
extern "C" {
void* _Block_copy(void const* aBlock);
void _Block_release(void const* aBlock);
}
#endif

// On Darwin this header gets pulled into an ObjC++ translation unit with
// ARC enabled (Swift builds the CxxAVDECC clang module that way), and
// clang then refuses to convert a block pointer to `void const*` without
// an explicit __bridge cast. The cast carries no ownership — refcounting
// is handled by the explicit Block_copy / Block_release calls below. On
// Linux the header is compiled as plain C++ against libBlocksRuntime,
// where __bridge isn't a recognized keyword, so fall back to a regular
// reinterpret_cast there.
#if defined(__OBJC__) && defined(__has_feature) && __has_feature(objc_arc)
#  define AVDECCSWIFT_BLOCK_AS_VOIDP(b) ((__bridge void const*)(b))
#else
#  define AVDECCSWIFT_BLOCK_AS_VOIDP(b) (reinterpret_cast<void const*>(b))
#endif

namespace AVDECCSwift {

template <typename Ret, typename... Args>
class Block final {
  using BlockType = Ret (^)(Args...);

public:
  Block() noexcept : block_(nullptr) {}

  /*implicit*/ Block(BlockType const& blk) noexcept : block_(blk) {
    if (block_) ::_Block_copy(AVDECCSWIFT_BLOCK_AS_VOIDP(block_));
  }

  Block(Block const& other) noexcept : block_(other.block_) {
    if (block_) ::_Block_copy(AVDECCSWIFT_BLOCK_AS_VOIDP(block_));
  }

  Block(Block&& other) noexcept : block_(other.block_) { other.block_ = nullptr; }

  ~Block() noexcept { reset(); }

  Block& operator=(Block const& other) noexcept {
    if (this != &other) {
      reset();
      block_ = other.block_;
      if (block_) ::_Block_copy(AVDECCSWIFT_BLOCK_AS_VOIDP(block_));
    }
    return *this;
  }

  Block& operator=(Block&& other) noexcept {
    if (this != &other) {
      reset();
      block_ = other.block_;
      other.block_ = nullptr;
    }
    return *this;
  }

  void reset() noexcept {
    if (block_) {
      ::_Block_release(AVDECCSWIFT_BLOCK_AS_VOIDP(block_));
      block_ = nullptr;
    }
  }

  explicit operator bool() const noexcept { return block_ != nullptr; }
  BlockType get() const noexcept { return block_; }

  Ret operator()(Args... args) const noexcept {
    return block_(std::forward<Args>(args)...);
  }

private:
  BlockType block_;
};

} // namespace AVDECCSwift
