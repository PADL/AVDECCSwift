/*
 * Copyright (C) 2023-2026, PADL Software Pty Ltd
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

internal import CxxAVDECC

final class Library {
  nonisolated(unsafe) static let shared = Library()

  static var interfaceVersion: UInt32 {
    la.avdecc.getInterfaceVersion()
  }

  static var version: String {
    String(la.avdecc.getVersion())
  }

  init() {
    precondition(la.avdecc.isCompatibleWithInterfaceVersion(la.avdecc.InterfaceVersion))
  }
}
