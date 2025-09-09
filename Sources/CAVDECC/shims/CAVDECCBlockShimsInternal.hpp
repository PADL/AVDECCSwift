/*
 * Copyright (C) 2023, PADL Software Pty Ltd
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

#pragma once

#include "CAVDECC.h"

#include <cassert>
#include "la/avdecc/avdecc.h"
#include <la/avdecc/internals/aggregateEntity.hpp>
#include <la/avdecc/internals/entity.hpp>

#include "utils.hpp"

#if __has_include(<Block.h>)
#include <Block.h>
#elif __has_include(<Block/Block.h>)
#include <Block/Block.h>
#else
extern "C" void *_Block_copy(const void *);
extern "C" void _Block_release(const void *);
#endif

namespace la {
namespace avdecc {
namespace bindings {

la::avdecc::entity::AggregateEntity &
getAggregateEntity(LA_AVDECC_LOCAL_ENTITY_HANDLE const handle);
la::avdecc::protocol::ProtocolInterface &
getProtocolInterface(LA_AVDECC_PROTOCOL_INTERFACE_HANDLE const handle);
} // namespace bindings
} // namespace avdecc
} // namespace la

namespace CAVDECC {
// Block smart pointer
template <typename Ret, typename... Args> class Block final {
  typedef Ret (^BlockType)(Args...);

public:
  Block(BlockType const &block) noexcept {
    if (block)
      ::_Block_copy(block);
    _block = block;
  }

  ~Block() {
    if (_block)
      ::_Block_release(_block);
  }

  Block &operator=(const Block &block) noexcept {
    if (this != &block) {
      if (block._block)
        ::_Block_copy(block._block);
      if (_block)
        ::_Block_release(_block);
      _block = block._block;
    }
    return *this;
  }

  Block(const Block &block) noexcept {
    if (block._block)
      ::_Block_copy(block._block);
    _block = block._block;
  }

  Block(Block &&dyingObj) noexcept : _block(nullptr) {
    *this = std::move(dyingObj);
  }

  Block &operator=(Block &&dyingObj) noexcept {
    if (_block)
      ::_Block_release(_block);
    _block = dyingObj._block;
    dyingObj._block = nullptr;

    return *this;
  }

  BlockType get() const { return _block; }
  BlockType operator->() const { return _block; }

  operator const void *() const noexcept { return static_cast<void *>(_block); }

  Ret operator()(Args &&...arg) const noexcept {
    assert(_block && "Cannot call null block");
    return _block(std::forward<Args>(arg)...);
  }

private:
  BlockType _block;
};
} // namespace CAVDECC
