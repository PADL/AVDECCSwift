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

// CxxAVDECC is the Clang module that lets Swift (with C++ interop) reach
// la_avdecc's C++ public types and our small helper layer for the things
// Swift cannot do itself: bridging Swift closures into std::function and
// providing concrete subclasses of la_avdecc's pure-virtual observer/delegate
// interfaces.
#pragma once

#include <la/avdecc/avdecc.hpp>
#include <la/avdecc/executor.hpp>
#include <la/avdecc/internals/aggregateEntity.hpp>
#include <la/avdecc/internals/protocolInterface.hpp>
#include <la/avdecc/internals/protocolAecpdu.hpp>
#include <la/avdecc/internals/protocolAemAecpdu.hpp>
#include <la/avdecc/internals/protocolMvuAecpdu.hpp>
#include <la/avdecc/internals/protocolAcmpdu.hpp>
#include <la/avdecc/internals/protocolAdpdu.hpp>
#include <la/avdecc/internals/uniqueIdentifier.hpp>
#include <la/networkInterfaceHelper/networkInterfaceHelper.hpp>

#include "AVDECCSwiftHelpers.hpp"
