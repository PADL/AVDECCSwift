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

public enum ExecutorError: UInt8, Error {
    case alreadyExists = 1
    case notFound = 2
    case invalidProtocolInterfaceHandle = 98
    case internalError = 99

    init(_ value: avdecc_executor_error_t) {
        self = Self(rawValue: value) ?? .internalError
    }
}

// FIXME: integrate C++ library with libdispatch

public final class Executor {
    public let shared = try! Executor()

    let library = Library()
    var handle: UnsafeMutableRawPointer!

    public init(name: String = DefaultExecutorName) throws {
        let err = LA_AVDECC_Executor_createQueueExecutor(name, &handle)
        if err != 0 {
            throw ExecutorError(err)
        }
    }

    deinit {
        if handle != nil {
            LA_AVDECC_Executor_destroy(handle)
        }
    }
}

public let DefaultExecutorName = "avdecc::protocol::PI"
