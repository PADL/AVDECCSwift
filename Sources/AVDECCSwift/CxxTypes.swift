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

extension UniqueIdentifier {
    typealias AvdeccCxxType = la.avdecc.UniqueIdentifier

    public static var NullUniqueIdentifier: Self {
        Self(AvdeccCxxType.getNullUniqueIdentifier())
    }

    public static var UninitializedUniqueIdentifier: Self {
        Self(AvdeccCxxType.getUninitializedUniqueIdentifier())
    }

    init(_ id: AvdeccCxxType) {
        self.eui = id.getValue()
    }

    func bridgeToAvdeccCxxType() -> AvdeccCxxType {
        AvdeccCxxType(id)
    }

    public var vendorID: Any {
        bridgeToAvdeccCxxType().getVendorID()
    }

    public var isGroupIdentifier: Bool {
        bridgeToAvdeccCxxType().isGroupIdentifier()
    }

    public var isLocalIdentifier: Bool {
        bridgeToAvdeccCxxType().isLocalIdentifier()
    }

    public var isValid: Bool {
        bridgeToAvdeccCxxType().isValid()
    }
}
