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

import CxxAVDECC
import CxxStdlib

// transitional support for C++ bridged types

protocol AvdeccCxxBridgeable: Sendable {
    associatedtype AvdeccCxxType

    init(_: AvdeccCxxType)

    func bridgeToAvdeccCxxType() -> AvdeccCxxType
}

extension AvdeccCxxBridgeable {
    init(_ entity: UnsafePointer<AvdeccCxxType>) {
        self.init(entity.pointee)
    }
}

public extension UniqueIdentifier {
    internal typealias AvdeccCxxType = la.avdecc.UniqueIdentifier

    static var NullUniqueIdentifier: Self {
        Self(AvdeccCxxType.getNullUniqueIdentifier())
    }

    static var UninitializedUniqueIdentifier: Self {
        Self(AvdeccCxxType.getUninitializedUniqueIdentifier())
    }

    internal init(_ id: AvdeccCxxType) {
        eui = id.getValue()
    }

    internal func bridgeToAvdeccCxxType() -> AvdeccCxxType {
        AvdeccCxxType(id)
    }

    var vendorID: Any {
        bridgeToAvdeccCxxType().getVendorID()
    }

    var isGroupIdentifier: Bool {
        bridgeToAvdeccCxxType().isGroupIdentifier()
    }

    var isLocalIdentifier: Bool {
        bridgeToAvdeccCxxType().isLocalIdentifier()
    }

    var isValid: Bool {
        bridgeToAvdeccCxxType().isValid()
    }
}
