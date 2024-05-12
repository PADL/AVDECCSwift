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

import CAVDECC

final class Library {
  static var shared = Library()

  private static func isCompatibleWithInterfaceVersion(_ version: Int32) -> Bool {
    LA_AVDECC_isCompatibleWithInterfaceVersion(avdecc_interface_version_t(version)) != 0
  }

  public static var interfaceVersion: avdecc_interface_version_t {
    LA_AVDECC_getInterfaceVersion()
  }

  public static var version: String {
    String(cString: LA_AVDECC_getVersion())
  }

  init() {
    precondition(Self.isCompatibleWithInterfaceVersion(LA_AVDECC_InterfaceVersion))
    LA_AVDECC_initialize()
  }

  deinit {
    LA_AVDECC_uninitialize()
  }
}
