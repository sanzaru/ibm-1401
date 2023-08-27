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

import Lib1401

typealias Word = UInt8
extension Word {
    var isNegative: Bool {
        self & 0b00100000 == 0b00100000
    }

    var isBlank: Bool {
        self & 0b01000000 == 0
    }

    var hasWordmark: Bool {
        self & 0b10000000 == 0b10000000
    }

    var bitCount: Int {
        var count = 0

        (0..<8).forEach {
            if self >> $0 & 1 == 1 {
                count += 1
            }
        }

        return count
    }

    var valid: Bool {
        var check = false
        Lib1401.CharacterEncodings.shared.simh.forEach {
            if self & $1 == 0 {
                check = true
                return
            }
        }

        return check
    }

    var parityCheck: Bool {
        var count = 0

        for i in 0...6 {
            if (self >> i) & 1 == 1 {
                count += 1
            }
        }

        return count % 2 != 0
    }

    var dropWordmark: Word {
        self & 0b01111111
    }

    var char: Character? {
        return Lib1401.CharacterEncodings.shared.simh.first(where: { (self & 0b01111111) ^ ($0.value & 0b01111111) == 0 })?.key
    }

    var decoded: Word {
        if let item = Lib1401.CharacterEncodings.shared.simh.first(where: { $0.value.dropWordmark == dropWordmark }) {
            return Word(String(item.key)) ?? 0
        }

        return 0
    }

    var intValue: Int {
        let val = self.decoded
        return isNegative ? Int(val)*(-1) : Int(val)
    }

    var encoded: Word {
        for (key, value) in Lib1401.CharacterEncodings.shared.simh {
            if String(key) == String(self) {
                return hasWordmark ? value ^ 0b10000000 : value
            }
        }

        return 0
    }

    var binaryString: String {
        var str = ""
        for i in 0...7 {
            str += self >> i & 1 == 1 ? "1" : "0"
        }

        return String(str.reversed())
    }

    func isOpCode(code: Character) -> Bool {
        guard let c = Lib1401.CharacterEncodings.shared.simh[code] else {
            return false
        }

        // Drop WM and C bit from both sides
        return (self & 0b00111111) ^ (c & 0b00111111) == 0
    }

    // MARK: - Mutating
    mutating func setWordMark() {
        self |= 0b10000000
        
        if !parityCheck {
            self ^= 0b01000000
        }
    }

    mutating func setCheckBit() {
        self |= 0b01000000
        
        if !parityCheck {
            self ^= 0b01000000
        }
    }    
}
