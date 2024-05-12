//
// Copyright (c) 2024 PADL Software Pty Ltd
//
// Licensed under the Apache License, Version 2.0 (the License);
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an 'AS IS' BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

@testable import AVDECCSwift
import XCTest

final class AVDECCSwiftTests: XCTestCase {
  func test61883_6FormatString() async throws {
    let formatString = EntityModelStreamFormat(format: 0x00A0_0208_4000_0800)
    XCTAssertEqual(formatString.version, .version_0)
    XCTAssertEqual(formatString.subtype, .iec61883iidc)
    XCTAssertEqual(formatString.isFloatingPoint, false)
    XCTAssertEqual(formatString.sampleRate, 48000)
    XCTAssertEqual(formatString.bitDepth, 24)
    XCTAssertEqual(formatString.channelsPerFrame, 8)
  }

  func testAafFormatString() async throws {
    let formatString = EntityModelStreamFormat(format: 0x0205_0220_0040_6000)
    XCTAssertEqual(formatString.version, .version_0)
    XCTAssertEqual(formatString.subtype, .aaf)
    XCTAssertEqual(formatString.isFloatingPoint, false)
    XCTAssertEqual(formatString.sampleRate, 48000)
    XCTAssertEqual(formatString.bitDepth, 32)
    XCTAssertEqual(formatString.channelsPerFrame, 1)
    XCTAssertEqual(formatString.samplesPerFrame, 6)
  }
}
