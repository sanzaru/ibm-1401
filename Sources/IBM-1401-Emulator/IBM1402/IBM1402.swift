// Copyright 2023 Martin Albrecht
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation
import Lib1401

final class IBM1402 {
    var count: Int { readStack.count }

    enum LineSize: Int {
        case normal = 80, stub = 51
    }

    private var readStack = [[UInt8]]()
    private var readIndex = 0

    private let linesize: LineSize

    init(_ linesize: LineSize = .normal) {
        self.linesize = linesize
    }

    func load(from string: String) throws -> [UInt8]? {
        readStack = try string.split(separator: "\n").reversed().map { card in
            try Lib1401.CharacterEncodings.shared.encode(code: String(card))
        }

        Logger.debug("IBM-1402: Loaded \(readStack.count) \(readStack.count == 1 ? "card" : "cards")")

        return read()
    }

    func read() -> [UInt8]? {
        readStack.popLast()
    }
}
